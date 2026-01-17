<?php
include 'db.php';
header('Content-Type: application/json; charset=utf-8');

$house_id = $_GET['house_id'];

try {
    $stmt = $conn->prepare("SELECT * FROM house_chores WHERE creator_id = ? ORDER BY is_done ASC, id DESC");
    $stmt->execute([$house_id]);
    
    $chores = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($chores);

} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>