<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$house_id = $user['id'];

$poll_id = requireInt($_POST, 'poll_id');
$option_id = requireInt($_POST, 'option_id');
$member_id = requireInt($_POST, 'member_id');

if (!memberBelongsToHouse($conn, $member_id, $house_id)) {
    jsonError("Geçersiz üye");
}

try {
    // Süresi dolan (24 saat) ankete oy verilemez; bkz. get_active_poll.php
    $pollCheck = $conn->prepare("SELECT id FROM polls WHERE id = ? AND house_id = ? AND created_at > NOW() - INTERVAL 24 HOUR");
    $pollCheck->execute([$poll_id, $house_id]);
    if (!$pollCheck->fetch(PDO::FETCH_ASSOC)) {
        jsonError("Anket bulunamadı");
    }

    $optionCheck = $conn->prepare("SELECT id FROM poll_options WHERE id = ? AND poll_id = ?");
    $optionCheck->execute([$option_id, $poll_id]);
    if (!$optionCheck->fetch(PDO::FETCH_ASSOC)) {
        jsonError("Geçersiz seçenek");
    }

    // Oy ve sayaç birlikte yazılsın. Aynı anda gelen iki istekte çift oyu
    // poll_votes'taki UNIQUE (poll_id, member_id) indeksi engeller.
    $conn->beginTransaction();

    $insert = $conn->prepare("INSERT INTO poll_votes (poll_id, house_id, member_id, option_id) VALUES (?, ?, ?, ?)");
    $insert->execute([$poll_id, $house_id, $member_id, $option_id]);

    $update = $conn->prepare("UPDATE poll_options SET vote_count = vote_count + 1 WHERE id = ?");
    $update->execute([$option_id]);

    $conn->commit();

    echo json_encode(["status" => "success"]);
} catch (PDOException $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    if ($e->getCode() === '23000') {
        jsonError("Zaten oy kullandınız");
    }
    serverError($e);
}
