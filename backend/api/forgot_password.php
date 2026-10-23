<?php
include 'db.php';
require_once __DIR__ . '/mailer.php';

$email = inputString($_POST, 'email');

if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError("Geçerli bir e-posta adresi girin");
}

// Not: E-posta kayıtlı olsun ya da olmasın aynı mesajı döneriz, böylece
// kayıtlı e-postaların tahmin edilmesi (enumeration) engellenmiş olur.
$genericResponse = [
    "status" => "success",
    "message" => "Bu e-posta kayıtlıysa, şifre sıfırlama bağlantısı gönderildi."
];

try {
    // Mail bombardımanı koruması: sınır aşılırsa sessizce mail atlanır,
    // cevap yine aynıdır (sınırın kendisi de e-posta hakkında bilgi vermesin).
    $limited = isRateLimited($conn, 'forgot_email', $email, 3, 3600)
        || isRateLimited($conn, 'forgot_ip', clientIp(), 10, 3600);

    if (!$limited) {
        recordAttempt($conn, 'forgot_email', $email);
        recordAttempt($conn, 'forgot_ip', clientIp());

        $stmt = $conn->prepare("SELECT id, house_name FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($user) {
            $token = bin2hex(random_bytes(32));

            // Veritabanına token'ın hash'i yazılır, düz hali sadece mailde.
            // Süre (1 saat) MySQL'de hesaplanır: reset_password.php de NOW() ile
            // kontrol ediyor, PHP ile MySQL saat dilimi farklı olsa bile tutarlı kalır.
            $update = $conn->prepare("UPDATE users SET reset_token = ?, reset_token_expires = NOW() + INTERVAL 1 HOUR WHERE id = ?");
            $update->execute([hashToken($token), $user['id']]);

            sendPasswordResetEmail($email, $user['house_name'], $token);
        }
    }

    echo json_encode($genericResponse);
} catch (Exception $e) {
    error_log("[homepal] forgot_password: " . $e->getMessage());
    echo json_encode($genericResponse);
}
?>
