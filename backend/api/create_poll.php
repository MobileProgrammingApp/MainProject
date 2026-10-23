<?php
include 'db.php';
require_once __DIR__ . '/fcm_helper.php';
require_once __DIR__ . '/auth.php';

const MAX_POLL_OPTIONS = 10;

$user = authenticateRequest($conn);
$house_id = $user['id'];

// JSON olarak gelen veriyi al: {"question": "...", "options": ["Pizza", "Burger"]}
$data = json_decode(file_get_contents('php://input'), true);
if (!is_array($data)) {
    jsonError("Eksik veri gönderildi");
}

$question = requireText($data, 'question', 255, 'Soru');

$options = $data['options'] ?? null;
if (!is_array($options) || count($options) < 2) {
    jsonError("En az 2 seçenek gerekli");
}
if (count($options) > MAX_POLL_OPTIONS) {
    jsonError("En fazla " . MAX_POLL_OPTIONS . " seçenek eklenebilir");
}
$options = array_map(function ($i) use ($options) {
    return requireText($options, $i, 100, 'Seçenek');
}, array_keys($options));

try {
    $conn->beginTransaction();

    // 1. Varsa eski anketleri sil (Evde tek aktif anket olsun diye)
    $conn->prepare("DELETE FROM polls WHERE house_id = ?")->execute([$house_id]);

    // 2. Yeni Anketi Oluştur
    $stmt = $conn->prepare("INSERT INTO polls (house_id, question, is_active) VALUES (?, ?, 1)");
    $stmt->execute([$house_id, $question]);
    $poll_id = $conn->lastInsertId();

    // 3. Seçenekleri Ekle
    $stmtOpt = $conn->prepare("INSERT INTO poll_options (poll_id, option_text, vote_count) VALUES (?, ?, 0)");
    foreach ($options as $opt) {
        $stmtOpt->execute([$poll_id, $opt]);
    }

    $conn->commit();

    $membersStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE house_id = ?");
    $membersStmt->execute([$house_id]);
    notifyMembers($conn, $membersStmt->fetchAll(PDO::FETCH_COLUMN), "Yeni Anket", $question);

    echo json_encode(["status" => "success"]);
} catch (Exception $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    serverError($e);
}
