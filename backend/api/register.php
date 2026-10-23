<?php
include 'db.php';
require_once __DIR__ . '/mailer.php';

$house_name = requireText($_POST, 'house_name', 100, 'Ev adı');
$email = inputString($_POST, 'email');
$password = is_string($_POST['password'] ?? null) ? $_POST['password'] : '';

if (!$email || !$password) {
    jsonError("Eksik bilgi gönderildi");
}

if (strlen($email) > 255 || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    jsonError("Geçersiz e-posta adresi");
}

if ($error = passwordError($password)) {
    jsonError($error);
}

try {
    // Toplu hesap açma / mail bombardımanı koruması
    if (isRateLimited($conn, 'register_ip', clientIp(), 5, 3600)) {
        jsonError("Çok fazla kayıt denemesi yapıldı. Lütfen bir saat sonra tekrar deneyin.");
    }
    recordAttempt($conn, 'register_ip', clientIp());

    $checkStmt = $conn->prepare("SELECT id, house_name, email_verified FROM users WHERE email = ?");
    $checkStmt->execute([$email]);
    $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);

    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
    $token = bin2hex(random_bytes(32));

    // E-posta kayıtlı olsa da olmasa da aynı cevabı veriyoruz; aksi halde
    // bu ekran üzerinden hangi e-postaların kayıtlı olduğu tek tek denenebilir.
    if ($existing && (int)$existing['email_verified'] === 1) {
        $mailSent = sendAccountExistsEmail($email, $existing['house_name']);
    } elseif ($existing) {
        // Doğrulanmamış hesap: son kayıt bilgileriyle güncelle ve yeni link gönder.
        // Böylece başkası bu e-postayla önceden kayıt olup şifreyi "rezerve" edemez;
        // hesabı, maile erişip linke tıklayan kişinin belirlediği şifre açar.
        $conn->prepare("UPDATE users SET house_name = ?, password = ?, verification_token = ? WHERE id = ?")
            ->execute([$house_name, $hashedPassword, hashToken($token), $existing['id']]);
        $mailSent = sendVerificationEmail($email, $house_name, $token);
    } else {
        $stmt = $conn->prepare(
            "INSERT INTO users (house_name, email, password, email_verified, verification_token)
             VALUES (?, ?, ?, 0, ?)"
        );
        $stmt->execute([$house_name, $email, $hashedPassword, hashToken($token)]);
        $mailSent = sendVerificationEmail($email, $house_name, $token);
    }

    echo json_encode([
        "status" => "success",
        "message" => $mailSent
            ? "Kayıt başarılı! Lütfen e-postanızı kontrol edip hesabınızı doğrulayın."
            : "Kayıt alındı ancak doğrulama maili gönderilemedi. Lütfen daha sonra tekrar deneyin.",
    ]);
} catch (Exception $e) {
    serverError($e);
}
?>
