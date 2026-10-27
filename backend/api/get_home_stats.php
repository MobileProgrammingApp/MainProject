<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/chores_helper.php';

$user = authenticateRequest($conn);

try {
    reopenDueChores($conn, (int) $user['id']);

    $stmtChores = $conn->prepare("SELECT COUNT(*) FROM house_chores WHERE creator_id = ? AND is_done = 0");
    $stmtChores->execute([$user['id']]);

    $stmtShopping = $conn->prepare("SELECT COUNT(*) FROM shopping_list WHERE user_id = ? AND is_bought = 0");
    $stmtShopping->execute([$user['id']]);

    echo json_encode([
        "status" => "success",
        "house_name" => $user['house_name'],
        "pending_chores" => $stmtChores->fetchColumn(),
        "pending_items" => $stmtShopping->fetchColumn()
    ]);
} catch (Exception $e) {
    serverError($e);
}
