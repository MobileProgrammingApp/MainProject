<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

// Bu cihazın bildirim token'ını "Ben kimim?" ile seçilen üyeye bağlar ya da kaldırır.
// Bir üyenin birden fazla cihazı olabilir (member_devices); bir cihaz ise tek üyeye
// bağlıdır: profil değişince token yeni üyeye taşınır.
$user = authenticateRequest($conn);

$member_id = requireInt($_POST, 'member_id');
if (!isset($_POST['fcm_token'])) {
    jsonError("Parametreler eksik");
}
$fcm_token = inputString($_POST, 'fcm_token');
// FCM token'ları ASCII; kolon da öyle (benzersiz indeks için)
if ($fcm_token !== '' && !preg_match('/^[\x21-\x7E]{1,1024}$/', $fcm_token)) {
    jsonError("Geçersiz token");
}
// 1.3.0+ bildirim kapatılınca ve çıkışta bu cihazın token'ını enabled=0 ile gönderir
$enabled = inputString($_POST, 'enabled') !== '0';

if (!memberBelongsToHouse($conn, $member_id, $user['id'])) {
    jsonError("Geçersiz üye");
}

try {
    if ($fcm_token === '') {
        // Eski sürümler bildirimi kapatırken boş token gönderir; hangi cihaz olduğu
        // bilinmediği için üyenin bütün cihazları silinir (bildirimi açık olan
        // cihazlar uygulama açılınca kendini yeniden kaydeder).
        $conn->prepare("DELETE FROM member_devices WHERE member_id = ?")->execute([$member_id]);
    } elseif (!$enabled) {
        // Sadece bu cihaz; başka evin kaydına dokunulmaz
        $conn->prepare(
            "DELETE d FROM member_devices d JOIN home_members m ON m.id = d.member_id
             WHERE d.fcm_token = ? AND m.house_id = ?"
        )->execute([$fcm_token, $user['id']]);
    } else {
        // Token benzersiz: aynı cihaz başka üyeye (veya başka eve) kayıtlıysa buraya taşınır
        $conn->prepare(
            "INSERT INTO member_devices (member_id, fcm_token) VALUES (?, ?)
             ON DUPLICATE KEY UPDATE member_id = VALUES(member_id), updated_at = CURRENT_TIMESTAMP"
        )->execute([$member_id, $fcm_token]);
    }

    echo json_encode(["status" => "success", "message" => "Token güncellendi"]);
} catch (Exception $e) {
    serverError($e);
}
