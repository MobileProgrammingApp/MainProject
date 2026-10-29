<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/polls_helper.php';

// Anketi (açık ya da bitmiş) seçenekleri ve oylarıyla siler. Yetki bitirmeyle aynı:
// açan kişi belliyse sadece o, belli değilse evdeki herkes. Silinmeyen anket
// bittikten POLL_RESULT_HOURS sonra kendiliğinden silinir (cleanup_polls.php).
$user = authenticateRequest($conn);
$house_id = (int) $user['id'];

$poll_id = requireInt($_POST, 'poll_id');
// Silen kişi (cihazda "Ben kimim?" ile seçilen üye); seçilmediyse 0
$member_id = (int)($_POST['member_id'] ?? 0) > 0 ? requireInt($_POST, 'member_id') : null;

if ($member_id && !memberBelongsToHouse($conn, $member_id, $house_id)) {
    jsonError("Geçersiz üye");
}

try {
    $poll = findPoll($conn, $poll_id, $house_id, $member_id);
    if (!$poll) {
        jsonError("Anket bulunamadı");
    }
    if (!$poll['can_manage']) {
        jsonError("Anketi sadece açan kişi silebilir");
    }

    // Seçenekler ve oylar FOREIGN KEY (ON DELETE CASCADE) ile birlikte silinir
    $conn->prepare("DELETE FROM polls WHERE id = ? AND house_id = ?")->execute([$poll_id, $house_id]);

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
