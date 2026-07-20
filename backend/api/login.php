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

        // Hesap bazlı, sabit bir token: aynı ev hesabıyla birden fazla
        // cihaz/aile üyesi aynı anda giriş yapabildiği için her girişte
        // yeniden üretilmiyor, sadece ilk seferinde oluşturuluyor.
        if (empty($row['api_token'])) {
            $apiToken = bin2hex(random_bytes(32));
            $conn->prepare("UPDATE users SET api_token = ? WHERE id = ?")->execute([$apiToken, $row['id']]);
        } else {
            $apiToken = $row['api_token'];
        }

        echo json_encode([
            "status" => "success",
            "user_id" => $row['id'],
            "house_name" => $row['house_name'],
            "api_token" => $apiToken
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
