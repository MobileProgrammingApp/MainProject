<?php
include 'db.php';
require_once __DIR__ . '/mailer.php';

// Doğrulama maili gelmeyen (ör. spam'e düşen) kullanıcılar için yeni bağlantı.
// E-posta kayıtlı olsun olmasın aynı cevap döner (hangi e-postaların kayıtlı
// olduğu bu ekrandan tahmin edilemesin).
$email = inputString($_POST, 'email');

if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError("Geçerli bir e-posta adresi girin");
}

$genericResponse = [
    "status" => "success",
    "message" => "Hesap doğrulanmamışsa yeni bir doğrulama bağlantısı gönderildi. Gelen kutunuzu ve spam klasörünü kontrol edin."
];

try {
    // Mail bombardımanı koruması; sınır aşılırsa sessizce atlanır
    $limited = isRateLimited($conn, 'resend_email', $email, 3, 3600)
        || isRateLimited($conn, 'resend_ip', clientIp(), 10, 3600);

    if (!$limited) {
        recordAttempt($conn, 'resend_email', $email);
        recordAttempt($conn, 'resend_ip', clientIp());

        $stmt = $conn->prepare("SELECT id, house_name FROM users WHERE email = ? AND email_verified = 0");
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            // Eski bağlantı geçersiz olur; veritabanında yeni token'ın hash'i durur
            $token = bin2hex(random_bytes(32));
            $conn->prepare("UPDATE users SET verification_token = ? WHERE id = ?")
                ->execute([hashToken($token), $user['id']]);
            sendVerificationEmail($email, $user['house_name'], $token);
        }
    }

    echo json_encode($genericResponse);
} catch (Exception $e) {
    error_log("[homepal] resend_verification: " . $e->getMessage());
    echo json_encode($genericResponse);
}
