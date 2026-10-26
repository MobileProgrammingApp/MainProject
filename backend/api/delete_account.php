<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/mailer.php';

// Uygulama içinden hesap silme (Google Play: hesap açılabilen uygulamalarda
// silme seçeneği uygulamanın içinde bulunmalı). Ev hesabı ve ona bağlı her şey
// (üyeler, görevler, market listesi, ev bilgileri, anketler, oturumlar)
// veritabanındaki ON DELETE CASCADE ilişkileriyle birlikte silinir.
$user = authenticateRequest($conn);

$password = is_string($_POST['password'] ?? null) ? $_POST['password'] : '';
if ($password === '') {
    jsonError("Hesabı silmek için şifrenizi girin");
}

try {
    // Ele geçirilmiş bir token ile şifre tahmini yapılmasın
    if (isRateLimited($conn, 'delete_account', (string)$user['id'], 5, 900)) {
        jsonError("Çok fazla hatalı deneme yapıldı. Lütfen 15 dakika sonra tekrar deneyin.");
    }

    $stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
    $stmt->execute([$user['id']]);
    $hash = $stmt->fetchColumn();

    if (!$hash || !password_verify($password, $hash)) {
        recordAttempt($conn, 'delete_account', (string)$user['id']);
        jsonError("Şifre hatalı");
    }

    $conn->prepare("DELETE FROM users WHERE id = ?")->execute([$user['id']]);

    // Hesap silindikten sonra bilgilendirme; gönderilemese de silme geçerli
    sendAccountDeletedEmail($user['email'], $user['house_name']);

    echo json_encode(["status" => "success", "message" => "Hesabınız ve tüm verileriniz silindi."]);
} catch (Exception $e) {
    serverError($e);
}
