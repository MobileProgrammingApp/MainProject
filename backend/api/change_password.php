<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
header('Content-Type: application/json; charset=utf-8');

$user = authenticateRequest($conn);

$currentPassword = $_POST['current_password'] ?? '';
$newPassword = $_POST['new_password'] ?? '';

if (!$currentPassword || !$newPassword) {
    echo json_encode(["status" => "error", "message" => "Eksik bilgi gönderildi"]);
    exit;
}

if (strlen($newPassword) < 6) {
    echo json_encode(["status" => "error", "message" => "Yeni şifre en az 6 karakter olmalı"]);
    exit;
}

try {
    $stmt = $conn->prepare("SELECT password FROM users WHERE id = ?");
    $stmt->execute([$user['id']]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$row || !password_verify($currentPassword, $row['password'])) {
        echo json_encode(["status" => "error", "message" => "Mevcut şifre hatalı"]);
        exit;
    }

    $hashed = password_hash($newPassword, PASSWORD_BCRYPT);
    $conn->prepare("UPDATE users SET password = ? WHERE id = ?")->execute([$hashed, $user['id']]);

    echo json_encode(["status" => "success", "message" => "Şifre güncellendi"]);
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
