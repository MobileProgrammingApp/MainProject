<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);

try {
    $houseName = $user['house_name'];

    $stmtChores = $conn->prepare("SELECT COUNT(*) as count FROM house_chores WHERE creator_id = ? AND is_done = 0");
    $stmtChores->execute([$user['id']]);
    $choreCount = $stmtChores->fetch(PDO::FETCH_ASSOC)['count'];

    $stmtShopping = $conn->prepare("SELECT COUNT(*) as count FROM shopping_list WHERE user_id = ? AND is_bought = 0");
    $stmtShopping->execute([$user['id']]);
    $shoppingCount = $stmtShopping->fetch(PDO::FETCH_ASSOC)['count'];

    echo json_encode([
        "status" => "success",
        "house_name" => $houseName,
        "pending_chores" => $choreCount,
        "pending_items" => $shoppingCount
    ]);

} catch (Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
