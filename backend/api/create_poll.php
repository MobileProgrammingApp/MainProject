<?php
include 'db.php';
require_once __DIR__ . '/fcm_helper.php';
header('Content-Type: application/json; charset=utf-8');

// JSON olarak gelen veriyi al (Flutter'dan karmaşık veri göndereceğiz)
$data = json_decode(file_get_contents('php://input'), true);

$house_id = $data['house_id'];
$question = $data['question'];
$options = $data['options']; // Array olarak gelecek ["Pizza", "Burger"]

try {
    // 1. Varsa eski aktif anketleri pasife çek veya sil (Evde tek aktif anket olsun diye)
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

    $projectId = $_ENV['PROJECT_ID'] ?? null;
    $keyFilePath = $_ENV['KEY_FILEPATH'] ?? null;

    if ($projectId && $keyFilePath) {
        $membersStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE house_id = ? AND fcm_token IS NOT NULL AND fcm_token != ''");
        $membersStmt->execute([$house_id]);
        $tokens = $membersStmt->fetchAll(PDO::FETCH_COLUMN);

        sendFCMToMembers($projectId, $keyFilePath, $tokens, "Yeni Anket", $question);
    }

    echo json_encode(["status" => "success"]);

} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}
?>
