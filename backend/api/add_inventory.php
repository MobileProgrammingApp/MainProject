<?php
include 'db.php';
$house_id = $_POST['house_id'];
$item_name = $_POST['item_name'];
$location = $_POST['location'];

try {
    $stmt = $conn->prepare("INSERT INTO house_inventory (house_id, item_name, location) VALUES (?, ?, ?)");
    $stmt->execute([$house_id, $item_name, $location]);
    echo json_encode(["status" => "success"]);
} catch(Exception $e) { echo json_encode(["status" => "error"]); }
?>