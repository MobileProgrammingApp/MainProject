<?php
include 'db.php'; // veya db.php (senin dosya adın neyse)
header('Content-Type: application/json; charset=utf-8');

$house_id = $_POST['house_id'];
$name = $_POST['name'];

try {
    $stmt = $conn->prepare("INSERT INTO home_members (house_id, name) VALUES (:house_id, :name)");
    if ($stmt->execute(['house_id' => $house_id, 'name' => $name])) {
        echo json_encode(["status" => "success"]);
    } else {
        echo json_encode(["status" => "error", "message" => "Eklenemedi"]);
    }
} catch (PDOException $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>