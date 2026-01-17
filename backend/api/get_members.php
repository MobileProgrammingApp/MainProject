<?php
include 'db.php';
header('Content-Type: application/json; charset=utf-8');

$house_id = $_GET['house_id'];
try {
    $stmt = $conn->prepare("SELECT * FROM home_members WHERE house_id = :house_id");
    $stmt->execute(['house_id' => $house_id]);
    
    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($members);
} catch (PDOException $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>