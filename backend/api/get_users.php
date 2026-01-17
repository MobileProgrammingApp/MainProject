<?php
include 'db.php';

try {
    $stmt = $conn->query("SELECT id, email FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($users);
} catch(Exception $e) {
    echo json_encode(["error" => $e->getMessage()]);
}
?>