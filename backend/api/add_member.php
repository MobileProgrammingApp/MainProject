<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

const MAX_MEMBERS_PER_HOUSE = 50;

$user = authenticateRequest($conn);
$name = requireText($_POST, 'name', 100, 'İsim');

try {
    $countStmt = $conn->prepare("SELECT COUNT(*) FROM home_members WHERE house_id = ?");
    $countStmt->execute([$user['id']]);
    if ((int) $countStmt->fetchColumn() >= MAX_MEMBERS_PER_HOUSE) {
        jsonError("Bir eve en fazla " . MAX_MEMBERS_PER_HOUSE . " üye eklenebilir");
    }

    $stmt = $conn->prepare("INSERT INTO home_members (house_id, name) VALUES (?, ?)");
    $stmt->execute([$user['id'], $name]);
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
