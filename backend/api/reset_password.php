<?php
include 'db.php';

header('Content-Type: text/html; charset=utf-8');

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
}

$token = $_GET['token'] ?? $_POST['token'] ?? '';

if (!$token) {
    renderPage("Geçersiz Bağlantı", "<p class='message error'>Geçersiz bağlantı.</p>");
    exit;
}

try {
    $stmt = $conn->prepare("SELECT id FROM users WHERE reset_token = ? AND reset_token_expires > NOW()");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        renderPage("Bağlantı Geçersiz", "<p class='message error'>Bu şifre sıfırlama bağlantısının süresi dolmuş veya geçersiz. Lütfen uygulamadan tekrar 'Şifremi Unuttum' isteği gönderin.</p>");
        exit;
    }

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $newPassword = $_POST['new_password'] ?? '';
        $confirmPassword = $_POST['confirm_password'] ?? '';

        if (strlen($newPassword) < 6) {
            renderPage("Şifre Sıfırlama", "<h2>Yeni Şifre Belirle</h2><p class='error'>Şifre en az 6 karakter olmalı.</p>"
                . "<form method='post'><input type='hidden' name='token' value='" . htmlspecialchars($token) . "'>"
                . "<input type='password' name='new_password' placeholder='Yeni şifre' required>"
                . "<input type='password' name='confirm_password' placeholder='Yeni şifre (tekrar)' required>"
                . "<button type='submit'>Şifreyi Güncelle</button></form>");
            exit;
        }

        if ($newPassword !== $confirmPassword) {
            renderPage("Şifre Sıfırlama", "<h2>Yeni Şifre Belirle</h2><p class='error'>Şifreler eşleşmiyor.</p>"
                . "<form method='post'><input type='hidden' name='token' value='" . htmlspecialchars($token) . "'>"
                . "<input type='password' name='new_password' placeholder='Yeni şifre' required>"
                . "<input type='password' name='confirm_password' placeholder='Yeni şifre (tekrar)' required>"
                . "<button type='submit'>Şifreyi Güncelle</button></form>");
            exit;
        }

        $hashed = password_hash($newPassword, PASSWORD_BCRYPT);
        $update = $conn->prepare("UPDATE users SET password = ?, reset_token = NULL, reset_token_expires = NULL WHERE id = ?");
        $update->execute([$hashed, $user['id']]);

        renderPage("Şifre Güncellendi", "<p class='message success'>Şifreniz başarıyla güncellendi. Artık Homepal uygulamasına yeni şifrenizle giriş yapabilirsiniz.</p>");
        exit;
    }

    // GET: formu göster
    renderPage("Şifre Sıfırlama", "<h2>Yeni Şifre Belirle</h2>"
        . "<form method='post'><input type='hidden' name='token' value='" . htmlspecialchars($token) . "'>"
        . "<input type='password' name='new_password' placeholder='Yeni şifre' required>"
        . "<input type='password' name='confirm_password' placeholder='Yeni şifre (tekrar)' required>"
        . "<button type='submit'>Şifreyi Güncelle</button></form>");
} catch (PDOException $e) {
    renderPage("Hata", "<p class='message error'>Bir hata oluştu, lütfen daha sonra tekrar deneyin.</p>");
}
?>
