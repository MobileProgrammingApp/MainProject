<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

// Anketin ömrü; cleanup_polls.php de bu süreden eski anketleri siler
const POLL_LIFETIME_HOURS = 24;

$user = authenticateRequest($conn);
$house_id = $user['id'];

// Profil ("Ben kimim?") henüz seçilmediyse uygulama 0 gönderir: anket yine
// gösterilir, sadece oy bilgisi boş döner (oy vermek için profil gerekir).
$member_id = (int)($_GET['member_id'] ?? 0) > 0 ? requireInt($_GET, 'member_id') : null;

if ($member_id && !memberBelongsToHouse($conn, $member_id, $house_id)) {
    jsonError("Geçersiz üye");
}

try {
    // Saatlik temizlik henüz çalışmamış olsa da süresi dolan anket gösterilmesin
    $stmt = $conn->prepare(
        "SELECT id, question,
                GREATEST(0, TIMESTAMPDIFF(MINUTE, NOW(), created_at + INTERVAL " . POLL_LIFETIME_HOURS . " HOUR)) AS minutes_left
         FROM polls
         WHERE house_id = ? AND is_active = 1 AND created_at > NOW() - INTERVAL " . POLL_LIFETIME_HOURS . " HOUR
         ORDER BY id DESC LIMIT 1"
    );
    $stmt->execute([$house_id]);
    $poll = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($poll) {
        $stmtOptions = $conn->prepare("SELECT id, option_text, vote_count FROM poll_options WHERE poll_id = ?");
        $stmtOptions->execute([$poll['id']]);
        $options = $stmtOptions->fetchAll(PDO::FETCH_ASSOC);

        $myVote = false;
        if ($member_id) {
            $stmtVote = $conn->prepare("SELECT option_id FROM poll_votes WHERE poll_id = ? AND member_id = ?");
            $stmtVote->execute([$poll['id'], $member_id]);
            $myVote = $stmtVote->fetch(PDO::FETCH_ASSOC);
        }

        echo json_encode([
            "status" => "success",
            "poll_id" => $poll['id'],
            "question" => $poll['question'],
            "options" => $options,
            "minutes_left" => (int)$poll['minutes_left'],
            "has_voted" => $myVote ? true : false,
            "voted_option_id" => $myVote ? $myVote['option_id'] : null
        ]);
    } else {
        echo json_encode(["status" => "empty", "message" => "Aktif anket yok"]);
    }
} catch (Exception $e) {
    serverError($e);
}
