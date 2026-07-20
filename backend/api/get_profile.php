<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);

echo json_encode([
    "status" => "success",
    "house_name" => $user['house_name'],
    "email" => $user['email']
]);
?>
