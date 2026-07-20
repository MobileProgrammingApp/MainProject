<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$item_name = $_POST['item_name'] ?? '';

if (!$item_name) {
    echo json_encode(["status" => "error", "message" => "Ürün adı gerekli"]);
    exit;
}

try {
    // is_bought değerini varsayılan 0 (alınmadı) olarak ekliyoruz
    $stmt = $conn->prepare("INSERT INTO shopping_list (user_id, item_name, is_bought) VALUES (?, ?, 0)");
    $stmt->execute([$user['id'], $item_name]);
    echo json_encode(["status" => "success"]);
} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
