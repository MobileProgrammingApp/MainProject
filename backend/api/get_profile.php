<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

echo json_encode([
    "status" => "success",
    "house_name" => $user['house_name'],
    "email" => $user['email']
]);
