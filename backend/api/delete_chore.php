<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);
$id = $_POST['id'];

try {
    $check = $conn->prepare("SELECT id FROM house_chores WHERE id = ? AND creator_id = ?");
    $check->execute([$id, $user['id']]);
    if (!$check->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode(["status" => "error", "message" => "Görev bulunamadı"]);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM house_chores WHERE id = :id");
    if ($stmt->execute(['id' => $id])) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Silinemedi"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
