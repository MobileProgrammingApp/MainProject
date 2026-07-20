<?php
include 'db.php';

function renderResult(bool $success, string $message): void {
    header('Content-Type: text/html; charset=utf-8');
    $color = $success ? '#2e7d32' : '#c62828';
    echo "<!DOCTYPE html><html lang=\"tr\"><head><meta charset=\"utf-8\">"
        . "<title>Homepal - E-posta Doğrulama</title></head>"
        . "<body style=\"font-family:sans-serif;text-align:center;margin-top:80px;\">"
        . "<h2 style=\"color:$color;\">" . htmlspecialchars($message) . "</h2>"
        . "</body></html>";
    exit;
}

$token = $_GET['token'] ?? '';

if (!$token) {
    renderResult(false, "Geçersiz bağlantı.");
}

try {
    $stmt = $conn->prepare("SELECT id FROM users WHERE verification_token = ?");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        renderResult(false, "Bu doğrulama bağlantısı geçersiz veya zaten kullanılmış.");
    }

    $update = $conn->prepare("UPDATE users SET email_verified = 1, verification_token = NULL WHERE id = ?");
    $update->execute([$user['id']]);

    renderResult(true, "E-posta adresiniz doğrulandı! Artık Homepal uygulamasına giriş yapabilirsiniz.");
} catch (Exception $e) {
    renderResult(false, "Bir hata oluştu, lütfen daha sonra tekrar deneyin.");
}
?>
