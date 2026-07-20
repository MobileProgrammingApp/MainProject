<?php
include 'db.php';
require_once __DIR__ . '/mailer.php';
header('Content-Type: application/json; charset=utf-8');

$house_name = trim($_POST['house_name'] ?? '');
$email = trim($_POST['email'] ?? '');
$password = $_POST['password'] ?? '';

if (!$house_name || !$email || !$password) {
    echo json_encode(["status" => "error", "message" => "Eksik bilgi gönderildi"]);
    exit;
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "error", "message" => "Geçersiz e-posta adresi"]);
    exit;
}

if (strlen($password) < 6) {
    echo json_encode(["status" => "error", "message" => "Şifre en az 6 karakter olmalı"]);
    exit;
}

try {
    $checkStmt = $conn->prepare("SELECT id FROM users WHERE email = :email");
    $checkStmt->execute(['email' => $email]);

    if ($checkStmt->rowCount() > 0) {
        echo json_encode(["status" => "error", "message" => "Bu mail zaten kayıtlı"]);
        exit;
    }

    $hashedPassword = password_hash($password, PASSWORD_BCRYPT);
    $token = bin2hex(random_bytes(32));

    $sql = "INSERT INTO users (house_name, email, password, email_verified, verification_token)
            VALUES (:house_name, :email, :password, 0, :token)";
    $stmt = $conn->prepare($sql);
    $stmt->execute([
        'house_name' => $house_name,
        'email' => $email,
        'password' => $hashedPassword,
        'token' => $token,
    ]);

    $mailSent = sendVerificationEmail($email, $house_name, $token);

    echo json_encode([
        "status" => "success",
        "message" => $mailSent
            ? "Kayıt başarılı! Lütfen e-postanızı kontrol edip hesabınızı doğrulayın."
            : "Kayıt başarılı ancak doğrulama maili gönderilemedi. Lütfen daha sonra tekrar deneyin.",
    ]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => "Veritabanı hatası: " . $e->getMessage()]);
}
?>
