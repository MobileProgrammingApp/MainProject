<?php
include 'db.php';
header('Content-Type: application/json; charset=utf-8');

$poll_id = $_POST['poll_id'];
$option_id = $_POST['option_id'];
$house_id = $_POST['house_id'];   
$member_id = $_POST['member_id']; 

try {
    
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