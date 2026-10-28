<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

// Anketi süresi dolmadan bitirir: oylama kapanır, sonuçlar herkese görünür
// (get_active_poll include_closed=1). Açan kişi belliyse sadece o bitirebilir;
// belli değilse (1.2.0 ile açılmış ya da açan silinmiş) evdeki herkes.
$user = authenticateRequest($conn);
$house_id = $user['id'];

$poll_id = requireInt($_POST, 'poll_id');
// Bitiren kişi (cihazda "Ben kimim?" ile seçilen üye); seçilmediyse 0
$member_id = (int)($_POST['member_id'] ?? 0) > 0 ? requireInt($_POST, 'member_id') : null;

if ($member_id && !memberBelongsToHouse($conn, $member_id, $house_id)) {
    jsonError("Geçersiz üye");
}

try {
    $stmt = $conn->prepare(
        "SELECT p.ends_at > NOW() AS is_open, m.id AS creator
         FROM polls p
         LEFT JOIN home_members m ON m.id = p.created_by
         WHERE p.id = ? AND p.house_id = ?"
    );
    $stmt->execute([$poll_id, $house_id]);
    $poll = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$poll) {
        jsonError("Anket bulunamadı");
    }

    // Zaten bitmişse (süresi dolmuş ya da açan az önce bitirmiş) sonuç değişmesin, başarılı say
    if ($poll['is_open']) {
        if ($poll['creator'] !== null && (int) $poll['creator'] !== $member_id) {
            jsonError("Anketi sadece açan kişi bitirebilir");
        }
        $conn->prepare("UPDATE polls SET ends_at = NOW() WHERE id = ? AND ends_at > NOW()")->execute([$poll_id]);
    }

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
