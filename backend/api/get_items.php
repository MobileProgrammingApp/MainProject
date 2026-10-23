<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

try {
    $stmt = $conn->prepare("SELECT * FROM shopping_list WHERE user_id = ? ORDER BY is_bought ASC, id DESC");
    $stmt->execute([$user['id']]);

    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    serverError($e);
}
