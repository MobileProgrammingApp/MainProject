<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/fcm_helper.php';

$user = authenticateRequest($conn);
$item_name = $_POST['item_name'] ?? '';
$member_id = $_POST['member_id'] ?? null;

if (!$item_name) {
    echo json_encode(["status" => "error", "message" => "Ürün adı gerekli"]);
    exit;
}

if ($member_id && !memberBelongsToHouse($conn, $member_id, $user['id'])) {
    echo json_encode(["status" => "error", "message" => "Geçersiz üye"]);
    exit;
}

try {
    // is_bought değerini varsayılan 0 (alınmadı) olarak ekliyoruz
    $stmt = $conn->prepare("INSERT INTO shopping_list (user_id, item_name, is_bought, added_by_member_id) VALUES (?, ?, 0, ?)");
    $stmt->execute([$user['id'], $item_name, $member_id]);

    $projectId = $_ENV['PROJECT_ID'] ?? null;
    $keyFilePath = $_ENV['KEY_FILEPATH'] ?? null;

    if ($projectId && $keyFilePath) {
        if ($member_id) {
            $membersStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE house_id = ? AND id != ? AND fcm_token IS NOT NULL AND fcm_token != ''");
            $membersStmt->execute([$user['id'], $member_id]);
        } else {
            $membersStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE house_id = ? AND fcm_token IS NOT NULL AND fcm_token != ''");
            $membersStmt->execute([$user['id']]);
        }
        $tokens = $membersStmt->fetchAll(PDO::FETCH_COLUMN);

        sendFCMToMembers($projectId, $keyFilePath, $tokens, "Market Listesi", "\"$item_name\" listeye eklendi.");
    }

    echo json_encode(["status" => "success"]);
} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
