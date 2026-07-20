<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);
$house_id = $user['id'];

$poll_id = $_POST['poll_id'];
$option_id = $_POST['option_id'];
$member_id = $_POST['member_id'];

if (!memberBelongsToHouse($conn, $member_id, $house_id)) {
    echo json_encode(["status" => "error", "message" => "Geçersiz üye"]);
    exit;
}

try {
    $pollCheck = $conn->prepare("SELECT id FROM polls WHERE id = ? AND house_id = ?");
    $pollCheck->execute([$poll_id, $house_id]);
    if (!$pollCheck->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode(["status" => "error", "message" => "Anket bulunamadı"]);
        exit;
    }

    $optionCheck = $conn->prepare("SELECT id FROM poll_options WHERE id = ? AND poll_id = ?");
    $optionCheck->execute([$option_id, $poll_id]);
    if (!$optionCheck->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode(["status" => "error", "message" => "Geçersiz seçenek"]);
        exit;
    }

    $check = $conn->prepare("SELECT id FROM poll_votes WHERE poll_id = ? AND member_id = ?");
    $check->execute([$poll_id, $member_id]);

    if ($check->rowCount() > 0) {
        echo json_encode(["status" => "error", "message" => "Zaten oy kullandınız"]);
        exit();
    }

    $insert = $conn->prepare("INSERT INTO poll_votes (poll_id, house_id, member_id, option_id) VALUES (?, ?, ?, ?)");
    $insert->execute([$poll_id, $house_id, $member_id, $option_id]);

    $update = $conn->prepare("UPDATE poll_options SET vote_count = vote_count + 1 WHERE id = ?");
    $update->execute([$option_id]);

    echo json_encode(["status" => "success"]);

} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
