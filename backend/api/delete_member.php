<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);
$id = $_POST['id'];

try {
    if (!memberBelongsToHouse($conn, $id, $user['id'])) {
        echo json_encode(["status" => "error", "message" => "Üye bulunamadı"]);
        exit;
    }

    $stmt = $conn->prepare("DELETE FROM home_members WHERE id = :id");

    if ($stmt->execute(['id' => $id])) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Silinemedi"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
