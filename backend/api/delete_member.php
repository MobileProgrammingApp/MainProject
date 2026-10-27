<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/chores_helper.php';

$user = authenticateRequest($conn);
$id = requireInt($_POST, 'id');

try {
    // Kişi silinince görevleri de silinir (FOREIGN KEY); sırayla dönen görevler
    // onunla birlikte kaybolmasın, sıradaki kişiye geçsin
    $next = nextMemberId($conn, (int) $user['id'], $id);
    if ($next !== null) {
        $conn->prepare("UPDATE house_chores SET assigned_to_id = ? WHERE assigned_to_id = ? AND creator_id = ? AND rotate = 1")
            ->execute([$next, $id, $user['id']]);
    }

    // Sahiplik kontrolü sorgunun içinde: başka evin üyesi silinemez
    $stmt = $conn->prepare("DELETE FROM home_members WHERE id = ? AND house_id = ?");
    $stmt->execute([$id, $user['id']]);

    if ($stmt->rowCount() === 0) {
        jsonError("Üye bulunamadı");
    }
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
