<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$id = $_POST['id'];

try {
    $check = $conn->prepare("SELECT id FROM house_infos WHERE id = ? AND house_id = ?");
    $check->execute([$id, $user['id']]);
    if (!$check->fetch(PDO::FETCH_ASSOC)) {
        echo json_encode(["status" => "error", "message" => "Bulunamadı"]);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM house_infos WHERE id = ?");
    $stmt->execute([$id]);
    echo json_encode(["status" => "success"]);
} catch(Exception $e) { echo json_encode(["status" => "error"]); }
?>
