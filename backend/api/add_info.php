<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$title = $_POST['title'] ?? '';
$value = $_POST['value'] ?? '';

if (!$title || !$value) {
    echo json_encode(["status" => "error", "message" => "Eksik veri"]);
    exit;
}

try {
    $stmt = $conn->prepare("INSERT INTO house_infos (house_id, title, value) VALUES (?, ?, ?)");
    $stmt->execute([$user['id'], $title, $value]);
    echo json_encode(["status" => "success"]);
} catch(Exception $e) { echo json_encode(["status" => "error"]); }
?>
