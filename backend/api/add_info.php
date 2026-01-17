<?php
include 'db.php';
$house_id = $_POST['house_id'];
$title = $_POST['title'];
$value = $_POST['value'];

try {
    $stmt = $conn->prepare("INSERT INTO house_infos (house_id, title, value) VALUES (?, ?, ?)");
    $stmt->execute([$house_id, $title, $value]);
    echo json_encode(["status" => "success"]);
} catch(Exception $e) { echo json_encode(["status" => "error"]); }
?>