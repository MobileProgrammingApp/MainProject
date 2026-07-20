<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);
$name = $_POST['name'] ?? '';

if (!$name) {
    echo json_encode(["status" => "error", "message" => "İsim gerekli"]);
    exit;
}

try {
    $stmt = $conn->prepare("INSERT INTO home_members (house_id, name) VALUES (:house_id, :name)");
    if ($stmt->execute(['house_id' => $user['id'], 'name' => $name])) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Eklenemedi"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
