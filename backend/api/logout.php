<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

// Bu cihazın oturumunu sunucuda kapatır; token çalınmış olsa bile artık işe yaramaz.
$user = authenticateRequest($conn);

try {
    $conn->prepare("DELETE FROM api_tokens WHERE id = ?")->execute([$user['token_id']]);
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
