<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

// Kayıtlı olmayan e-postalarda da bir bcrypt doğrulaması yapmak için (cost 10,
// password_hash varsayılanı). Böylece yanıt süresinden e-postanın kayıtlı olup
// olmadığı anlaşılamaz.
const DUMMY_PASSWORD_HASH = '$2y$10$5rSZXAk2WjbYPcM.qmqBMuzI62svA4aZDgEbmcovsX6t15W/9cY.m';

$email = inputString($_POST, 'email');
$password = is_string($_POST['password'] ?? null) ? $_POST['password'] : '';
$ip = clientIp();

try {
    // Kaba kuvvet koruması: sadece başarısız denemeler sayılır
    if (isRateLimited($conn, 'login_ip', $ip, 20, 900) || isRateLimited($conn, 'login_email', $email, 10, 900)) {
        jsonError("Çok fazla hatalı deneme yapıldı. Lütfen 15 dakika sonra tekrar deneyin.");
    }

    $stmt = $conn->prepare("SELECT id, house_name, password, email_verified FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!password_verify($password, $row['password'] ?? DUMMY_PASSWORD_HASH) || !$row) {
        recordAttempt($conn, 'login_ip', $ip);
        recordAttempt($conn, 'login_email', $email);
        jsonError("Mail veya şifre hatalı");
    }

    if ((int)$row['email_verified'] !== 1) {
        jsonError("Giriş yapmadan önce e-postanızı doğrulamanız gerekiyor.");
    }

    // Her giriş bu cihaz için yeni bir token açar; aynı hesaptaki diğer
    // cihazların oturumu etkilenmez.
    $apiToken = issueApiToken($conn, (int)$row['id']);

    echo json_encode([
        "status" => "success",
        "user_id" => $row['id'],
        "house_name" => $row['house_name'],
        "api_token" => $apiToken
    ]);
} catch (Exception $e) {
    serverError($e);
}
?>
