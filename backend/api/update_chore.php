<?php
include 'db.php';
require_once __DIR__ . '/fcm_helper.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$id = requireInt($_POST, 'id');

try {
    $choreStmt = $conn->prepare("SELECT assigned_to_id, task_name FROM house_chores WHERE id = ? AND creator_id = ?");
    $choreStmt->execute([$id, $user['id']]);
    $chore = $choreStmt->fetch(PDO::FETCH_ASSOC);

    if (!$chore) {
        jsonError("Görev bulunamadı");
    }

    $stmt = $conn->prepare("UPDATE house_chores SET is_done = 1 WHERE id = ?");
    $stmt->execute([$id]);

    $assigneeStmt = $conn->prepare("SELECT name FROM home_members WHERE id = ?");
    $assigneeStmt->execute([$chore['assigned_to_id']]);
    $assigneeName = $assigneeStmt->fetchColumn() ?: 'Bir ev arkadaşı';

    $membersStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE house_id = ? AND id != ?");
    $membersStmt->execute([$user['id'], $chore['assigned_to_id']]);

    notifyMembers(
        $conn,
        $membersStmt->fetchAll(PDO::FETCH_COLUMN),
        "Görev Tamamlandı",
        $assigneeName . " \"" . $chore['task_name'] . "\" görevini tamamladı.",
        "chores"
    );

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
