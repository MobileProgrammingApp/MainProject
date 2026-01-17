<?php
include 'db.php';
$id = $_POST['id'];
try {
    $stmt = $conn->prepare("DELETE FROM house_infos WHERE id = ?");
    $stmt->execute([$id]);
    echo json_encode(["status" => "success"]);
} catch(Exception $e) { echo json_encode(["status" => "error"]); }
?>