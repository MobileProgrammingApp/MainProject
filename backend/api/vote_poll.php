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
    $pollCheck = $conn->prepare("SELECT ends_at > NOW() AS is_open FROM polls WHERE id = ? AND house_id = ?");
    $pollCheck->execute([$poll_id, $house_id]);
    $poll = $pollCheck->fetch(PDO::FETCH_ASSOC);
    if (!$poll) {
        jsonError("Anket bulunamadı");
    }
    // Süresi dolan veya erken bitirilen ankete oy verilemez
    if (!$poll['is_open']) {
        jsonError("Anket sona erdi");
    }

    $optionCheck = $conn->prepare("SELECT id FROM poll_options WHERE id = ? AND poll_id = ?");
    $optionCheck->execute([$option_id, $poll_id]);
    if (!$optionCheck->fetch(PDO::FETCH_ASSOC)) {
        jsonError("Geçersiz seçenek");
    }

    // Anket açıkken oy değiştirilebilir. Üye başına tek satırı poll_votes'taki
    // UNIQUE (poll_id, member_id) indeksi garanti eder (aynı anda gelen isteklerde de).
    $vote = $conn->prepare(
        "INSERT INTO poll_votes (poll_id, house_id, member_id, option_id) VALUES (?, ?, ?, ?)
         ON DUPLICATE KEY UPDATE option_id = VALUES(option_id), created_at = CURRENT_TIMESTAMP"
    );
    $vote->execute([$poll_id, $house_id, $member_id, $option_id]);

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
