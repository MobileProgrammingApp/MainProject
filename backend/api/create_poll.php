<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/polls_helper.php';

// Yeni anket açar. Evde aynı anda birden fazla anket olabilir: açık ya da biten
// anketler yerinde kalır (1.2.0'a kadar yenisi eskisini siliyordu).

const MAX_POLL_OPTIONS = 10;

$user = authenticateRequest($conn);
$house_id = $user['id'];

// JSON olarak gelen veri: {"question": "...", "options": ["Pizza", "Burger"],
// "duration_hours": 24, "member_id": 3}. Son ikisi isteğe bağlı (1.2.0 ve öncesi göndermez).
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

$hours = POLL_DEFAULT_HOURS;
if (isset($data['duration_hours'])) {
    $hours = filter_var($data['duration_hours'], FILTER_VALIDATE_INT, ["options" => ["min_range" => 1, "max_range" => POLL_MAX_HOURS]]);
    if ($hours === false) {
        jsonError("Geçersiz anket süresi");
    }
}

// Anketi açan üye: "kim sordu" gösterilir ve kendisine bildirim gitmez
$creator_id = null;
if (!empty($data['member_id'])) {
    $creator_id = requireInt($data, 'member_id');
    if (!memberBelongsToHouse($conn, $creator_id, $house_id)) {
        jsonError("Geçersiz üye");
    }
}

try {
    $openStmt = $conn->prepare("SELECT COUNT(*) FROM polls WHERE house_id = ? AND ends_at > NOW()");
    $openStmt->execute([$house_id]);
    if ((int) $openStmt->fetchColumn() >= MAX_OPEN_POLLS) {
        jsonError("Aynı anda en fazla " . MAX_OPEN_POLLS . " anket açık olabilir");
    }

    $conn->beginTransaction();

    // 1. Yeni Anketi Oluştur
    $stmt = $conn->prepare(
        "INSERT INTO polls (house_id, question, ends_at, created_by) VALUES (?, ?, NOW() + INTERVAL ? HOUR, ?)"
    );
    $stmt->execute([$house_id, $question, $hours, $creator_id]);
    $poll_id = $conn->lastInsertId();

    // 2. Seçenekleri Ekle
    $stmtOpt = $conn->prepare("INSERT INTO poll_options (poll_id, option_text) VALUES (?, ?)");
    foreach ($options as $opt) {
        $stmtOpt->execute([$poll_id, $opt]);
    }

    $conn->commit();

    notifyMembers($conn, houseTokens($conn, (int) $house_id, $creator_id), "Yeni Anket", $question, "home");

    echo json_encode(["status" => "success", "poll_id" => (int) $poll_id]);
} catch (Exception $e) {
    if ($conn->inTransaction()) {
        $conn->rollBack();
    }
    serverError($e);
}
