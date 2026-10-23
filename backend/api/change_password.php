<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

$currentPassword = is_string($_POST['current_password'] ?? null) ? $_POST['current_password'] : '';
$newPassword = is_string($_POST['new_password'] ?? null) ? $_POST['new_password'] : '';

if (!$currentPassword || !$newPassword) {
    jsonError("Eksik bilgi gönderildi");
}

if ($error = passwordError($newPassword)) {
    jsonError($error);
}

try {
    // Ele geçirilmiş bir token ile mevcut şifrenin tahmin edilmesini engelle
    if (isRateLimited($conn, 'change_password', (string)$user['id'], 5, 900)) {
        jsonError("Çok fazla hatalı deneme yapıldı. Lütfen 15 dakika sonra tekrar deneyin.");
    }

    $stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
    $stmt->execute([$user['id']]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row || !password_verify($currentPassword, $row['password'])) {
        recordAttempt($conn, 'change_password', (string)$user['id']);
        jsonError("Mevcut şifre hatalı");
    }

    $hashed = password_hash($newPassword, PASSWORD_BCRYPT);
    $conn->prepare("UPDATE users SET password = ? WHERE id = ?")->execute([$hashed, $user['id']]);

    // Bu cihaz açık kalır, diğer cihazların oturumu kapanır
    revokeUserTokens($conn, (int)$user['id'], (int)$user['token_id']);

    echo json_encode(["status" => "success", "message" => "Şifre güncellendi. Diğer cihazlarda yeni şifreyle tekrar giriş yapılması gerekecek."]);
} catch (Exception $e) {
    serverError($e);
}
?>
