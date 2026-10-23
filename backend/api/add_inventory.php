<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$item_name = requireText($_POST, 'item_name', 100, 'Eşya adı');
$location = requireText($_POST, 'location', 255, 'Konum');

try {
    $stmt = $conn->prepare("INSERT INTO house_inventory (house_id, item_name, location) VALUES (?, ?, ?)");
    $stmt->execute([$user['id'], $item_name, $location]);
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
