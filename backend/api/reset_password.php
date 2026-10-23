<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

header('Content-Type: text/html; charset=utf-8');
header("Content-Security-Policy: default-src 'none'; style-src 'unsafe-inline'; form-action 'self'");
header('Cache-Control: no-store');

function renderPage(string $title, string $bodyHtml): void {
    echo "<!DOCTYPE html><html lang=\"tr\"><head><meta charset=\"utf-8\">"
        . "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">"
        . "<title>Homepal - $title</title>"
        . "<style>
            body { font-family: -apple-system, Segoe UI, Roboto, Arial, sans-serif; max-width: 420px; margin: 60px auto; padding: 0 20px; color: #222; }
            h2 { text-align: center; }
            input { width: 100%; padding: 12px; margin: 8px 0 16px; box-sizing: border-box; border: 1px solid #ccc; border-radius: 8px; font-size: 16px; }
            button { width: 100%; padding: 12px; background: #2C3E50; color: white; border: none; border-radius: 8px; font-size: 16px; cursor: pointer; }
            .message { text-align: center; font-size: 18px; margin-top: 40px; }
            .error { color: #c62828; }
            .success { color: #2e7d32; }
        </style></head><body>$bodyHtml</body></html>";
    exit;
}

function renderForm(string $token, string $error = ''): void {
    renderPage("Şifre Sıfırlama", "<h2>Yeni Şifre Belirle</h2>"
        . ($error ? "<p class='error'>" . htmlspecialchars($error) . "</p>" : "")
        . "<form method='post'><input type='hidden' name='token' value='" . htmlspecialchars($token) . "'>"
        . "<input type='password' name='new_password' placeholder='Yeni şifre (en az 8 karakter)' minlength='8' maxlength='72' required>"
        . "<input type='password' name='confirm_password' placeholder='Yeni şifre (tekrar)' minlength='8' maxlength='72' required>"
        . "<button type='submit'>Şifreyi Güncelle</button></form>");
}

$token = inputString($_GET, 'token') ?: inputString($_POST, 'token');

if (!preg_match('/^[a-f0-9]{64}$/', $token)) {
    renderPage("Geçersiz Bağlantı", "<p class='message error'>Geçersiz bağlantı.</p>");
}

try {
    // Veritabanında token'ın kendisi değil sha256 hash'i saklanıyor
    $stmt = $conn->prepare("SELECT id FROM users WHERE reset_token = ? AND reset_token_expires > NOW()");
    $stmt->execute([hashToken($token)]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        renderPage("Bağlantı Geçersiz", "<p class='message error'>Bu şifre sıfırlama bağlantısının süresi dolmuş veya geçersiz. Lütfen uygulamadan tekrar 'Şifremi Unuttum' isteği gönderin.</p>");
    }

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        renderForm($token);
    }

    $newPassword = is_string($_POST['new_password'] ?? null) ? $_POST['new_password'] : '';
    $confirmPassword = is_string($_POST['confirm_password'] ?? null) ? $_POST['confirm_password'] : '';

    if ($error = passwordError($newPassword)) {
        renderForm($token, $error);
    }

    if ($newPassword !== $confirmPassword) {
        renderForm($token, "Şifreler eşleşmiyor.");
    }

    $hashed = password_hash($newPassword, PASSWORD_BCRYPT);
    $update = $conn->prepare("UPDATE users SET password = ?, reset_token = NULL, reset_token_expires = NULL WHERE id = ?");
    $update->execute([$hashed, $user['id']]);

    // Hesap kurtarıldı: eski şifreyle açılmış tüm cihaz oturumlarını kapat
    revokeUserTokens($conn, (int)$user['id']);

    renderPage("Şifre Güncellendi", "<p class='message success'>Şifreniz başarıyla güncellendi. Güvenliğiniz için tüm cihazlardaki oturumlar kapatıldı; Homepal uygulamasına yeni şifrenizle tekrar giriş yapabilirsiniz.</p>");
} catch (Exception $e) {
    error_log("[homepal] reset_password: " . $e->getMessage());
    renderPage("Hata", "<p class='message error'>Bir hata oluştu, lütfen daha sonra tekrar deneyin.</p>");
}
?>
