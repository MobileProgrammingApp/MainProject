<?php
include 'db.php';
require_once __DIR__ . '/fcm_helper.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

$id = requireInt($_POST, 'id');
$assigned_to_id = requireInt($_POST, 'assigned_to_id');
$task_name = requireText($_POST, 'task_name', 255, 'Görev adı');

if (!memberBelongsToHouse($conn, $assigned_to_id, $user['id'])) {
    jsonError("Geçersiz üye");
}

try {
    $choreStmt = $conn->prepare("SELECT assigned_to_id, is_done FROM house_chores WHERE id = ? AND creator_id = ?");
    $choreStmt->execute([$id, $user['id']]);
    $chore = $choreStmt->fetch(PDO::FETCH_ASSOC);

    if (!$chore) {
        jsonError("Görev bulunamadı");
    }

    $stmt = $conn->prepare("UPDATE house_chores SET task_name = ?, assigned_to_id = ? WHERE id = ?");
    $stmt->execute([$task_name, $assigned_to_id, $id]);

    // Görev başka birine verildiyse yeni sorumlusu haberdar olsun; sadece adı
    // düzeltildiyse kimseye bildirim gitmez
    if ((int) $chore['assigned_to_id'] !== $assigned_to_id && !$chore['is_done']) {
        $tokenStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE id = ?");
        $tokenStmt->execute([$assigned_to_id]);
        notifyMembers($conn, [$tokenStmt->fetchColumn()], "Yeni Görev!", "Sana bir görev atandı: " . $task_name, "chores");
    }

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
