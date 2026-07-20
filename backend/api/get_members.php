<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);

try {
    $stmt = $conn->prepare("SELECT * FROM home_members WHERE house_id = :house_id");
    $stmt->execute(['house_id' => $user['id']]);

    $members = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($members);
} catch (PDOException $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>
