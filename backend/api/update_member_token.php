<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

$member_id = requireInt($_POST, 'member_id');
if (!isset($_POST['fcm_token'])) {
    jsonError("Parametreler eksik");
}
// Boş token = bu üyeye bildirim gönderme (bildirim ayarı kapatıldı)
$fcm_token = inputString($_POST, 'fcm_token');
if (strlen($fcm_token) > 4096) {
    jsonError("Geçersiz token");
}

if (!memberBelongsToHouse($conn, $member_id, $user['id'])) {
    jsonError("Geçersiz üye");
}

try {
    if ($fcm_token !== '') {
        // Bir cihaz aynı anda tek profile bağlı olmalı: profil değiştirilince
        // önceki üyeye (veya başka bir hesaba) kayıtlı kalan aynı token'ı temizle
        $conn->prepare("UPDATE home_members SET fcm_token = NULL WHERE fcm_token = ? AND id != ?")
            ->execute([$fcm_token, $member_id]);
    }

    $stmt = $conn->prepare("UPDATE home_members SET fcm_token = ? WHERE id = ?");
    $stmt->execute([$fcm_token !== '' ? $fcm_token : null, $member_id]);

    echo json_encode(["status" => "success", "message" => "Token güncellendi"]);
} catch (Exception $e) {
    serverError($e);
}
