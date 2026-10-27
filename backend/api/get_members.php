<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

try {
    // fcm_token kasıtlı olarak dönülmüyor: diğer üyelerin cihaz token'larını
    // istemcinin bilmesine gerek yok
    $stmt = $conn->prepare("SELECT id, house_id, name, role FROM home_members WHERE house_id = ? ORDER BY id");
    $stmt->execute([$user['id']]);

    echo json_encode($stmt->fetchAll(PDO::FETCH_ASSOC));
} catch (Exception $e) {
    serverError($e);
}
