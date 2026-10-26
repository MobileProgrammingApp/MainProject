<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/fcm_helper.php';

$user = authenticateRequest($conn);
$item_name = requireText($_POST, 'item_name', 255, 'Ürün adı');
// Eski sürümler member_id göndermiyor, bu yüzden opsiyonel
$member_id = isset($_POST['member_id']) && $_POST['member_id'] !== '' ? requireInt($_POST, 'member_id') : null;

if ($member_id && !memberBelongsToHouse($conn, $member_id, $user['id'])) {
    jsonError("Geçersiz üye");
}

try {
    // is_bought değerini varsayılan 0 (alınmadı) olarak ekliyoruz
    $stmt = $conn->prepare("INSERT INTO shopping_list (user_id, item_name, is_bought, added_by_member_id) VALUES (?, ?, 0, ?)");
    $stmt->execute([$user['id'], $item_name, $member_id]);

    // Ekleyen üye biliniyorsa ona bildirim gitmez
    $membersStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE house_id = ? AND id != ?");
    $membersStmt->execute([$user['id'], $member_id ?? 0]);

    notifyMembers($conn, $membersStmt->fetchAll(PDO::FETCH_COLUMN), "Market Listesi", "\"$item_name\" listeye eklendi.", "shopping");

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
