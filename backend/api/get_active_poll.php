<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/polls_helper.php';

$user = authenticateRequest($conn);
$house_id = $user['id'];

// Profil ("Ben kimim?") henüz seçilmediyse uygulama 0 gönderir: anket yine
// gösterilir, sadece oy bilgisi boş döner (oy vermek için profil gerekir).
$member_id = (int)($_GET['member_id'] ?? 0) > 0 ? requireInt($_GET, 'member_id') : null;

if ($member_id && !memberBelongsToHouse($conn, $member_id, $house_id)) {
    jsonError("Geçersiz üye");
}

// 1.3.0+ biten anketi de (sonuçlarıyla, POLL_RESULT_HOURS boyunca) ister. Eski sürümler
// bunu bilmediği için onlara sadece açık anket döner: bitmiş ankete oy vermeye çalışmasınlar.
$include_closed = ($_GET['include_closed'] ?? '') === '1';

try {
    // Saatlik temizlik henüz çalışmamış olsa da süresi geçen anket gösterilmesin
    $visibleSince = $include_closed ? "NOW() - INTERVAL " . POLL_RESULT_HOURS . " HOUR" : "NOW()";
    $stmt = $conn->prepare(
        "SELECT p.id, p.question, p.ends_at > NOW() AS is_open,
                GREATEST(0, TIMESTAMPDIFF(MINUTE, NOW(), p.ends_at)) AS minutes_left,
                m.id AS created_by, m.name AS created_by_name
         FROM polls p
         LEFT JOIN home_members m ON m.id = p.created_by
         WHERE p.house_id = ? AND p.ends_at > $visibleSince
         ORDER BY p.id DESC LIMIT 1"
    );
    $stmt->execute([$house_id]);
    $poll = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($poll) {
        // Oy sayıları poll_votes'tan: oy değişince ve üye silinince de doğru kalır
        $stmtOptions = $conn->prepare(
            "SELECT o.id, o.option_text, COUNT(v.id) AS vote_count
             FROM poll_options o
             LEFT JOIN poll_votes v ON v.option_id = o.id
             WHERE o.poll_id = ?
             GROUP BY o.id, o.option_text
             ORDER BY o.id"
        );
        $stmtOptions->execute([$poll['id']]);
        $options = $stmtOptions->fetchAll(PDO::FETCH_ASSOC);

        $myVote = false;
        if ($member_id) {
            $stmtVote = $conn->prepare("SELECT option_id FROM poll_votes WHERE poll_id = ? AND member_id = ?");
            $stmtVote->execute([$poll['id'], $member_id]);
            $myVote = $stmtVote->fetch(PDO::FETCH_ASSOC);
        }

        $memberCount = $conn->prepare("SELECT COUNT(*) FROM home_members WHERE house_id = ?");
        $memberCount->execute([$house_id]);

        echo json_encode([
            "status" => "success",
            "poll_id" => $poll['id'],
            "question" => $poll['question'],
            "options" => $options,
            "is_open" => (bool) $poll['is_open'],
            "minutes_left" => (int)$poll['minutes_left'],
            // Açık anketi sadece açan kişi bitirebilir/değiştirebilir; null ise herkes (bkz. end_poll.php)
            "created_by" => $poll['created_by'] !== null ? (int) $poll['created_by'] : null,
            "created_by_name" => $poll['created_by_name'],
            "member_count" => (int) $memberCount->fetchColumn(),
            "has_voted" => $myVote ? true : false,
            "voted_option_id" => $myVote ? $myVote['option_id'] : null
        ]);
    } else {
        echo json_encode(["status" => "empty", "message" => "Aktif anket yok"]);
    }
} catch (Exception $e) {
    serverError($e);
}
