<?php
include 'db.php';
header('Content-Type: application/json; charset=utf-8');

$house_name = $_POST['house_name'];
$email = $_POST['email'];
$password = $_POST['password'];

try {

    $checkStmt = $conn->prepare("SELECT id FROM users WHERE email = :email");
    $checkStmt->execute(['email' => $email]);

    if ($checkStmt->rowCount() > 0) {
        echo json_encode(["status" => "error", "message" => "Bu mail zaten kayıtlı"]);
    } else {

        $sql = "INSERT INTO users (house_name, email, password) VALUES (:house_name, :email, :password)";
        $stmt = $conn->prepare($sql);
        
        if ($stmt->execute(['house_name' => $house_name, 'email' => $email, 'password' => $password])) {
            echo json_encode(["status" => "success", "message" => "Kayıt başarılı"]);
        } else {
            echo json_encode(["status" => "error", "message" => "Kayıt oluşturulamadı"]);
        }
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => "Veritabanı hatası: " . $e->getMessage()]);
}
?>