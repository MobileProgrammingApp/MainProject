<?php

include 'db.php';
require_once __DIR__ . '/fcm_helper.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

$projectId = $_ENV['PROJECT_ID'] ?? null;
$keyFilePath   = $_ENV['KEY_FILEPATH'] ?? null;

$creator_id = $user['id'];
$assigned_to_id = $_POST['assigned_to_id'] ?? null;
$task_name = $_POST['task_name'] ?? null;

if (!$assigned_to_id || !$task_name) {
    echo json_encode(["status" => "error", "message" => "Eksik veri gönderildi"]);
    exit;
}

if (!memberBelongsToHouse($conn, $assigned_to_id, $creator_id)) {
    echo json_encode(["status" => "error", "message" => "Geçersiz üye"]);
    exit;
}

try {

    $stmt = $conn->prepare("INSERT INTO house_chores (creator_id, assigned_to_id, task_name) VALUES (?, ?, ?)");
    $stmt->execute([$creator_id, $assigned_to_id, $task_name]);

    $tokenStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE id = ?");
    $tokenStmt->execute([$assigned_to_id]);
    $member = $tokenStmt->fetch(PDO::FETCH_ASSOC);

    if ($member && !empty($member['fcm_token']) && $projectId && $keyFilePath) {
        try {
            $result = sendFCMNotificationV1($projectId, $keyFilePath, $member['fcm_token'], "Yeni Görev!", "Sana bir görev atandı: " . $task_name);
            echo json_encode(["status" => "success", "fcm_response" => json_decode($result)]);
        } catch (Exception $e) {
            // Görev zaten eklendi; bildirim gönderilemedi diye istemciye hata dönmeyelim
            echo json_encode(["status" => "success", "message" => "Görev eklendi, bildirim gönderilemedi: " . $e->getMessage()]);
        }
    } else {
        echo json_encode(["status" => "success", "message" => "Görev eklendi ancak hedef üyenin token'ı bulunamadı."]);
    }

} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
