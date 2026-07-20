<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$item_name = $_POST['item_name'] ?? '';
$location = $_POST['location'] ?? '';

if (!$item_name || !$location) {
    echo json_encode(["status" => "error", "message" => "Eksik veri"]);
    exit;
}

try {
    $stmt = $conn->prepare("INSERT INTO house_inventory (house_id, item_name, location) VALUES (?, ?, ?)");
    $stmt->execute([$user['id'], $item_name, $location]);
    echo json_encode(["status" => "success"]);
} catch(Exception $e) { echo json_encode(["status" => "error"]); }
?>
