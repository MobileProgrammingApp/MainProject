<?php
include 'db.php';
require_once __DIR__ . '/chores_helper.php';
require_once __DIR__ . '/auth.php';

$user = authenticateRequest($conn);

$id = requireInt($_POST, 'id');
$assigned_to_id = requireInt($_POST, 'assigned_to_id');
$task_name = requireText($_POST, 'task_name', 255, 'Görev adı');
// Tekrar ayarı gönderilmediyse (1.2.0 ve öncesi) olduğu gibi kalır
$repeatSent = isset($_POST['repeat']);
$repeat = choreRepeatInput($_POST);
$rotate = $repeat !== null && inputString($_POST, 'rotate') === '1';

if (!memberBelongsToHouse($conn, $assigned_to_id, $user['id'])) {
    jsonError("Geçersiz üye");
}

try {
    $choreStmt = $conn->prepare("SELECT assigned_to_id, is_done, repeat_every, repeat_start, rotate, next_due FROM house_chores WHERE id = ? AND creator_id = ?");
    $choreStmt->execute([$id, $user['id']]);
    $chore = $choreStmt->fetch(PDO::FETCH_ASSOC);
    if (!$chore) {
        jsonError("Görev bulunamadı");
    }

    if ($repeatSent) {
        // Aralık değişince takvim bugünden başlar; sadece "sırayla" değiştiyse eski gün korunur
        $start = $repeat === null ? null
            : ($repeat === $chore['repeat_every'] && $chore['repeat_start'] ? $chore['repeat_start'] : choreToday()->format('Y-m-d'));
        $nextDue = $chore['is_done'] ? choreNextDue($repeat, $start) : null;
    } else {
        [$repeat, $start, $rotate, $nextDue] = [$chore['repeat_every'], $chore['repeat_start'], (bool) $chore['rotate'], $chore['next_due']];
    }

    $stmt = $conn->prepare("UPDATE house_chores SET task_name = ?, assigned_to_id = ?, repeat_every = ?, repeat_start = ?, rotate = ?, next_due = ? WHERE id = ?");
    $stmt->execute([$task_name, $assigned_to_id, $repeat, $start, (int) $rotate, $nextDue, $id]);

    // Görev başka birine verildiyse yeni sorumlusu haberdar olsun; sadece adı
    // düzeltildiyse kimseye bildirim gitmez
    if ((int) $chore['assigned_to_id'] !== $assigned_to_id && !$chore['is_done']) {
        notifyMembers($conn, memberTokens($conn, $assigned_to_id), "Yeni Görev!", "Sana bir görev atandı: " . $task_name, "chores");
    }
    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    serverError($e);
}
