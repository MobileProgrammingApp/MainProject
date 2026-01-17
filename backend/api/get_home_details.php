<?php
include 'db.php';
header('Content-Type: application/json; charset=utf-8');

$house_id = $_GET['house_id'];

try {
    // Bilgileri Çek
    $stmtInfo = $conn->prepare("SELECT * FROM house_infos WHERE house_id = ? ORDER BY id DESC");
    $stmtInfo->execute([$house_id]);
    $infos = $stmtInfo->fetchAll(PDO::FETCH_ASSOC);

    // Envanteri Çek
    $stmtInv = $conn->prepare("SELECT * FROM house_inventory WHERE house_id = ? ORDER BY id DESC");
    $stmtInv->execute([$house_id]);
    $inventory = $stmtInv->fetchAll(PDO::FETCH_ASSOC);

    echo json_encode([
        "status" => "success",
        "infos" => $infos,
        "inventory" => $inventory
    ]);

} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>