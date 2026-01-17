<?php
include 'db.php';

$user_id = $_POST['user_id'];
$item_name = $_POST['item_name'];

try {
    // is_bought değerini varsayılan 0 (alınmadı) olarak ekliyoruz
    $stmt = $conn->prepare("INSERT INTO shopping_list (user_id, item_name, is_bought) VALUES (?, ?, 0)");
    $stmt->execute([$user_id, $item_name]);
    echo json_encode(["status" => "success"]);
} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>