<?php
include 'db.php';
header('Content-Type: application/json; charset=utf-8');

$user_id = $_GET['user_id'];
try {
    
    $stmtUser = $conn->prepare("SELECT house_name FROM users WHERE id = ?");
    $stmtUser->execute([$user_id]);
    $userRow = $stmtUser->fetch(PDO::FETCH_ASSOC);
    $houseName = $userRow ? $userRow['house_name'] : "Evim";

    $stmtChores = $conn->prepare("SELECT COUNT(*) as count FROM house_chores WHERE creator_id = ? AND is_done = 0");
    $stmtChores->execute([$user_id]);
    $choreCount = $stmtChores->fetch(PDO::FETCH_ASSOC)['count'];

    $stmtShopping = $conn->prepare("SELECT COUNT(*) as count FROM shopping_list WHERE user_id = ? AND is_bought = 0");
    $stmtShopping->execute([$user_id]);
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