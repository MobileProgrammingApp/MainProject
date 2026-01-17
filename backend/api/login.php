<?php
include 'db.php'; 

header('Content-Type: application/json; charset=utf-8');

$email = $_POST['email'];
$password = $_POST['password'];

try {

    $stmt = $conn->prepare("SELECT * FROM users WHERE email = :email AND password = :password");
    
    $stmt->execute(['email' => $email, 'password' => $password]);
    
    if ($stmt->rowCount() > 0) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        echo json_encode([
            "status" => "success", 
            "user_id" => $row['id'], 
            "house_name" => $row['house_name']
        ]);
    } else {
        echo json_encode([
            "status" => "error", 
            "message" => "Mail veya şifre hatalı"
        ]);
    }

} catch (PDOException $e) {
    echo json_encode([
        "status" => "error", 
        "message" => "Sorgu hatası: " . $e->getMessage()
    ]);
}
?>