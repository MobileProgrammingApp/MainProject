<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);

try {

    $stmt = $conn->prepare("SELECT * FROM shopping_list WHERE user_id = ? ORDER BY is_bought ASC, id DESC");
    $stmt->execute([$user['id']]);

    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode($items);

} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
