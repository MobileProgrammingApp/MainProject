<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);
$id = requireInt($_POST, 'id');
$is_bought = inputString($_POST, 'is_bought') === '1' ? 1 : 0;

try {
    $stmt = $conn->prepare("UPDATE shopping_list SET is_bought = ? WHERE id = ? AND user_id = ?");
    $stmt->execute([$is_bought, $id, $user['id']]);

    // rowCount değer değişmediyse de 0 döner; bu yüzden kaydın varlığını ayrıca kontrol et
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
