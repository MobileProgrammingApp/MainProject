<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

if(isset($_POST['id'])){
    $id = $_POST['id'];

    try {
        $check = $conn->prepare("SELECT id FROM shopping_list WHERE id = ? AND user_id = ?");
        $check->execute([$id, $user['id']]);
        if (!$check->fetch(PDO::FETCH_ASSOC)) {
            echo json_encode(["status" => "error", "message" => "Ürün bulunamadı"]);
            exit;
        }

        $stmt = $conn->prepare("DELETE FROM shopping_list WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(["status" => "success"]);
    } catch(Exception $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
}
?>
