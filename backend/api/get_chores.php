<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/chores_helper.php';

$user = authenticateRequest($conn);

try {
    reopenDueChores($conn, (int) $user['id']);

    $stmt = $conn->prepare("SELECT * FROM house_chores WHERE creator_id = ? ORDER BY is_done ASC, id DESC");
    $stmt->execute([$user['id']]);

    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    serverError($e);
}
