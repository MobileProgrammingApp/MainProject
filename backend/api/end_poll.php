<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/polls_helper.php';

// Anketi süresi dolmadan bitirir: oylama kapanır, sonuçlar herkese görünür ve
// evdekilere sonuç bildirimi gider. Açan kişi belliyse sadece o bitirebilir;
// belli değilse (1.2.0 ile açılmış ya da açan silinmiş) evdeki herkes.
$user = authenticateRequest($conn);
$house_id = (int) $user['id'];

$poll_id = requireInt($_POST, 'poll_id');
// Bitiren kişi (cihazda "Ben kimim?" ile seçilen üye); seçilmediyse 0
$member_id = (int)($_POST['member_id'] ?? 0) > 0 ? requireInt($_POST, 'member_id') : null;

if ($member_id && !memberBelongsToHouse($conn, $member_id, $house_id)) {
    jsonError("Geçersiz üye");
}

try {
    $poll = findPoll($conn, $poll_id, $house_id, $member_id);
    if (!$poll) {
        jsonError("Anket bulunamadı");
    }

    // Zaten bitmişse (süresi dolmuş ya da açan az önce bitirmiş) sonuç değişmesin, başarılı say
    if ($poll['is_open']) {
        if (!$poll['can_manage']) {
            jsonError("Anketi sadece açan kişi bitirebilir");
        }
        $conn->prepare("UPDATE polls SET ends_at = NOW() WHERE id = ? AND ends_at > NOW()")->execute([$poll_id]);
        // Bitiren kişi sonucu zaten görüyor; diğerlerine haber ver
        notifyPollEnded($conn, $poll_id, $member_id);
    }

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
