<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);
$house_id = $user['id'];
$member_id = $_GET['member_id'];

if (!memberBelongsToHouse($conn, $member_id, $house_id)) {
    echo json_encode(["status" => "error", "message" => "Geçersiz üye"]);
    exit;
}

try {
    $stmt = $conn->prepare("SELECT id, question FROM polls WHERE house_id = ? AND is_active = 1 ORDER BY id DESC LIMIT 1");
    $stmt->execute([$house_id]);
    $poll = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($poll) {
        $stmtOptions = $conn->prepare("SELECT id, option_text, vote_count FROM poll_options WHERE poll_id = ?");
        $stmtOptions->execute([$poll['id']]);
        $options = $stmtOptions->fetchAll(PDO::FETCH_ASSOC);

        $stmtVote = $conn->prepare("SELECT option_id FROM poll_votes WHERE poll_id = ? AND member_id = ?");
        $stmtVote->execute([$poll['id'], $member_id]);
        $myVote = $stmtVote->fetch(PDO::FETCH_ASSOC);

        echo json_encode([
            "status" => "success",
            "poll_id" => $poll['id'],
            "question" => $poll['question'],
            "options" => $options,
            "has_voted" => $myVote ? true : false,
            "voted_option_id" => $myVote ? $myVote['option_id'] : null
        ]);
    } else {
        echo json_encode(["status" => "empty", "message" => "Aktif anket yok"]);
    }

} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
