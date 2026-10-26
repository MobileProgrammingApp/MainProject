<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$id = requireInt($_POST, 'id');
$item_name = requireText($_POST, 'item_name', 255, 'Ürün adı');

try {
    $stmt = $conn->prepare("UPDATE shopping_list SET item_name = ? WHERE id = ? AND user_id = ?");
    $stmt->execute([$item_name, $id, $user['id']]);

    // rowCount ad değişmediyse de 0 döner; bu yüzden kaydın varlığını ayrıca kontrol et
    if ($stmt->rowCount() === 0) {
        $check = $conn->prepare("SELECT id FROM shopping_list WHERE id = ? AND user_id = ?");
        $check->execute([$id, $user['id']]);
        if (!$check->fetch()) {
            jsonError("Ürün bulunamadı");
        }
    }
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
