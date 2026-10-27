<?php
include 'db.php';
require_once __DIR__ . '/chores_helper.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

$assigned_to_id = requireInt($_POST, 'assigned_to_id');
$task_name = requireText($_POST, 'task_name', 255, 'Görev adı');
// Eski sürümler bu alanları göndermez: görev tek seferlik olur
$repeat = choreRepeatInput($_POST);
$rotate = $repeat !== null && inputString($_POST, 'rotate') === '1';

if (!memberBelongsToHouse($conn, $assigned_to_id, $user['id'])) {
    jsonError("Geçersiz üye");
}

try {
    $stmt = $conn->prepare("INSERT INTO house_chores (creator_id, assigned_to_id, task_name, repeat_every, repeat_start, rotate) VALUES (?, ?, ?, ?, ?, ?)");
    $stmt->execute([$user['id'], $assigned_to_id, $task_name, $repeat, $repeat ? choreToday()->format('Y-m-d') : null, (int) $rotate]);

    $tokenStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE id = ?");
    $tokenStmt->execute([$assigned_to_id]);

    // Görev zaten eklendi; bildirim gönderilemese de istemciye başarı dönüyoruz
    notifyMembers($conn, [$tokenStmt->fetchColumn()], "Yeni Görev!", "Sana bir görev atandı: " . $task_name, "chores");

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
