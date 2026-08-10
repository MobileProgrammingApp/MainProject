<?php
include 'db.php';
require_once __DIR__ . '/mailer.php';
header('Content-Type: application/json; charset=utf-8');

$email = trim($_POST['email'] ?? '');

if (!$email || !filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "error", "message" => "Geçerli bir e-posta adresi girin"]);
    exit;
}

// Not: E-posta kayıtlı olsun ya da olmasın aynı mesajı döneriz, böylece
// kayıtlı e-postaların tahmin edilmesi (enumeration) engellenmiş olur.
$genericResponse = [
    "status" => "success",
    "message" => "Bu e-posta kayıtlıysa, şifre sıfırlama bağlantısı gönderildi."
];

try {
    $stmt = $conn->prepare("SELECT id, house_name FROM users WHERE email = ?");
    $stmt->execute([$email]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($user) {
        $token = bin2hex(random_bytes(32));
        $expires = date('Y-m-d H:i:s', time() + 3600); // 1 saat geçerli

        $update = $conn->prepare("UPDATE users SET reset_token = ?, reset_token_expires = ? WHERE id = ?");
        $update->execute([$token, $expires, $user['id']]);

        sendPasswordResetEmail($email, $user['house_name'], $token);
    }

    echo json_encode($genericResponse);
} catch (PDOException $e) {
    echo json_encode($genericResponse);
}
?>
