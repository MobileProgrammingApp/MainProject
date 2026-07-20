<?php
include 'db.php';
require_once __DIR__ . '/fcm_helper.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

if(isset($_POST['id'])){
    $id = $_POST['id'];
    $projectId = $_ENV['PROJECT_ID'] ?? null;
    $keyFilePath = $_ENV['KEY_FILEPATH'] ?? null;

    try {
        $choreStmt = $conn->prepare("SELECT creator_id, assigned_to_id, task_name FROM house_chores WHERE id = ?");
        $choreStmt->execute([$id]);
        $chore = $choreStmt->fetch(PDO::FETCH_ASSOC);

        if (!$chore || (int)$chore['creator_id'] !== (int)$user['id']) {
            echo json_encode(["status" => "error", "message" => "Görev bulunamadı"]);
            exit;
        }

        $stmt = $conn->prepare("UPDATE house_chores SET is_done = 1 WHERE id = ?");
        $stmt->execute([$id]);

        if ($projectId && $keyFilePath) {
            $assigneeStmt = $conn->prepare("SELECT name FROM home_members WHERE id = ?");
            $assigneeStmt->execute([$chore['assigned_to_id']]);
            $assignee = $assigneeStmt->fetch(PDO::FETCH_ASSOC);
            $assigneeName = $assignee['name'] ?? 'Bir ev arkadaşı';

            $membersStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE house_id = ? AND id != ? AND fcm_token IS NOT NULL AND fcm_token != ''");
            $membersStmt->execute([$chore['creator_id'], $chore['assigned_to_id']]);
            $tokens = $membersStmt->fetchAll(PDO::FETCH_COLUMN);

            sendFCMToMembers(
                $projectId,
                $keyFilePath,
                $tokens,
                "Görev Tamamlandı",
                $assigneeName . " \"" . $chore['task_name'] . "\" görevini tamamladı."
            );
        }

        echo json_encode(["status" => "success"]);
    } catch(Exception $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
}
?>
