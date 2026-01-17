<?php
include 'db.php';
header('Content-Type: application/json; charset=utf-8');

$id = $_POST['id'];

try {
    $stmt = $conn->prepare("DELETE FROM home_members WHERE id = :id");
    
    if ($stmt->execute(['id' => $id])) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Silinemedi"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>