<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$id = requireInt($_POST, 'id');

try {
    // Sahiplik kontrolü sorgunun içinde: başka evin görevi silinemez
    $stmt = $conn->prepare("DELETE FROM house_chores WHERE id = ? AND creator_id = ?");
    $stmt->execute([$id, $user['id']]);

    if ($stmt->rowCount() === 0) {
        jsonError("Görev bulunamadı");
    }
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
