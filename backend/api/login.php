<?php
include 'db.php';

header('Content-Type: application/json; charset=utf-8');

$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

try {
    $stmt = $conn->prepare("SELECT * FROM users WHERE email = :email");
    $stmt->execute(['email' => $email]);

    if ($stmt->rowCount() > 0) {
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!password_verify($password, $row['password'])) {
            echo json_encode(["status" => "error", "message" => "Mail veya şifre hatalı"]);
            exit;
        }

        if ((int)$row['email_verified'] !== 1) {
            echo json_encode(["status" => "error", "message" => "Giriş yapmadan önce e-postanızı doğrulamanız gerekiyor."]);
            exit;
        }

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
