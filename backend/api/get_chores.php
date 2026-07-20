<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);

try {
    $stmt = $conn->prepare("SELECT * FROM house_chores WHERE creator_id = ? ORDER BY is_done ASC, id DESC");
    $stmt->execute([$user['id']]);

    $chores = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($chores);

} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
