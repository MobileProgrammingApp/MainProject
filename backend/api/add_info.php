<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$title = requireText($_POST, 'title', 100, 'Başlık');
$value = requireText($_POST, 'value', 255, 'Bilgi');

try {
    $stmt = $conn->prepare("INSERT INTO house_infos (house_id, title, value) VALUES (?, ?, ?)");
    $stmt->execute([$user['id'], $title, $value]);
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
