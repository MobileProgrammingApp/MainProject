<?php
include 'db.php';
require_once __DIR__ . '/fcm_helper.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

$assigned_to_id = requireInt($_POST, 'assigned_to_id');
$task_name = requireText($_POST, 'task_name', 255, 'Görev adı');

if (!memberBelongsToHouse($conn, $assigned_to_id, $user['id'])) {
    jsonError("Geçersiz üye");
}

try {
    $stmt = $conn->prepare("INSERT INTO house_chores (creator_id, assigned_to_id, task_name) VALUES (?, ?, ?)");
    $stmt->execute([$user['id'], $assigned_to_id, $task_name]);

    $tokenStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE id = ?");
    $tokenStmt->execute([$assigned_to_id]);

    // Görev zaten eklendi; bildirim gönderilemese de istemciye başarı dönüyoruz
    notifyMembers($conn, [$tokenStmt->fetchColumn()], "Yeni Görev!", "Sana bir görev atandı: " . $task_name, "chores");

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
