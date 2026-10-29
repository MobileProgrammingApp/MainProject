<?php
// Anket kuralları ve ortak sorgular: create_poll, get_polls, get_active_poll,
// end_poll, delete_poll ve cleanup_polls kullanır.
// Anketin açık olup olmadığı polls.ends_at'ten anlaşılır (erken bitirilince şimdi olur).
// 1.3.0'dan beri evde aynı anda birden fazla anket olabilir: yenisi açılınca eskiler kalır.
require_once __DIR__ . '/fcm_helper.php';

// Süre gönderilmezse (1.2.0 ve öncesi) anket 24 saat açık kalır
const POLL_DEFAULT_HOURS = 24;
const POLL_MAX_HOURS = 24 * 7;
// Biten anket sonuçlarıyla bu kadar süre daha görünür, sonra cron siler
const POLL_RESULT_HOURS = 24;
// Aynı anda açık olabilecek anket sayısı (panel kalabalıklaşmasın)
const MAX_OPEN_POLLS = 10;

/**
 * Evin görünen anketleri; seçenekleri ve oy sayılarıyla. Açık anketler önce
 * (en yakında kapanan başta), sonra biten anketler (en son biten başta).
 * $includeClosed false ise sadece açık anketler. $memberId verilirse o üyenin oyu da döner.
 * Alan adları ve tipleri get_active_poll.php'nin eski cevabıyla aynı (eski sürümler okuyor).
 */
function housePolls(PDO $conn, int $houseId, ?int $memberId, bool $includeClosed): array {
    // Temizlik henüz çalışmamış olsa da süresi geçen anket gösterilmesin
    $visibleSince = $includeClosed ? "NOW() - INTERVAL " . POLL_RESULT_HOURS . " HOUR" : "NOW()";
    $stmt = $conn->prepare(
        "SELECT p.id, p.question, p.ends_at > NOW() AS is_open,
                GREATEST(0, TIMESTAMPDIFF(MINUTE, NOW(), p.ends_at)) AS minutes_left,
                GREATEST(0, TIMESTAMPDIFF(MINUTE, NOW(), p.ends_at + INTERVAL " . POLL_RESULT_HOURS . " HOUR)) AS result_minutes_left,
                m.id AS created_by, m.name AS created_by_name
         FROM polls p
         LEFT JOIN home_members m ON m.id = p.created_by
         WHERE p.house_id = ? AND p.ends_at > $visibleSince
         ORDER BY is_open DESC, CASE WHEN p.ends_at > NOW() THEN p.ends_at END, p.ends_at DESC, p.id DESC"
    );
    $stmt->execute([$houseId]);
    $polls = $stmt->fetchAll(PDO::FETCH_ASSOC);
    if (!$polls) {
        return [];
    }

    $ids = array_column($polls, 'id');
    $in = implode(',', array_fill(0, count($ids), '?'));

    // Oy sayıları poll_votes'tan: oy değişince ve üye silinince de doğru kalır
    $optionStmt = $conn->prepare(
        "SELECT o.poll_id, o.id, o.option_text, COUNT(v.id) AS vote_count
         FROM poll_options o
         LEFT JOIN poll_votes v ON v.option_id = o.id
         WHERE o.poll_id IN ($in)
         GROUP BY o.poll_id, o.id, o.option_text
         ORDER BY o.id"
    );
    $optionStmt->execute($ids);
    $options = [];
    foreach ($optionStmt->fetchAll(PDO::FETCH_ASSOC) as $o) {
        $options[$o['poll_id']][] = ['id' => $o['id'], 'option_text' => $o['option_text'], 'vote_count' => $o['vote_count']];
    }

    $votes = [];
    if ($memberId) {
        $voteStmt = $conn->prepare("SELECT poll_id, option_id FROM poll_votes WHERE member_id = ? AND poll_id IN ($in)");
        $voteStmt->execute(array_merge([$memberId], $ids));
        $votes = $voteStmt->fetchAll(PDO::FETCH_KEY_PAIR);
    }

    return array_map(fn($p) => [
        "poll_id" => $p['id'],
        "question" => $p['question'],
        "options" => $options[$p['id']] ?? [],
        "is_open" => (bool) $p['is_open'],
        "minutes_left" => (int) $p['minutes_left'],
        // Biten anket bu kadar dakika sonra kendiliğinden silinir
        "result_minutes_left" => (int) $p['result_minutes_left'],
        // Anketi sadece açan kişi bitirip silebilir; null ise herkes (bkz. findPoll)
        "created_by" => $p['created_by'] !== null ? (int) $p['created_by'] : null,
        "created_by_name" => $p['created_by_name'],
        "has_voted" => isset($votes[$p['id']]),
        "voted_option_id" => $votes[$p['id']] ?? null,
    ], $polls);
}

function houseMemberCount(PDO $conn, int $houseId): int {
    $stmt = $conn->prepare("SELECT COUNT(*) FROM home_members WHERE house_id = ?");
    $stmt->execute([$houseId]);
    return (int) $stmt->fetchColumn();
}

/**
 * Bu evin anketi ve $memberId onu yönetebilir mi (bitirme, silme)? Açanı belli olan
 * anketi sadece açan kişi; belli değilse (1.2.0 öncesi açılmış ya da açan silinmiş)
 * evdeki herkes yönetebilir. Anket bu evin değilse null döner.
 */
function findPoll(PDO $conn, int $pollId, int $houseId, ?int $memberId): ?array {
    $stmt = $conn->prepare(
        "SELECT p.ends_at > NOW() AS is_open, m.id AS creator
         FROM polls p
         LEFT JOIN home_members m ON m.id = p.created_by
         WHERE p.id = ? AND p.house_id = ?"
    );
    $stmt->execute([$pollId, $houseId]);
    $poll = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$poll) {
        return null;
    }
    return [
        'is_open' => (bool) $poll['is_open'],
        'can_manage' => $poll['creator'] === null || (int) $poll['creator'] === $memberId,
    ];
}

/**
 * Biten anketin sonucunu evdekilere bildirir, her anket için bir kez (polls.end_notified).
 * Erken bitirilince bitiren kişiye gitmez; süresi dolunca cron herkese gönderir.
 */
function notifyPollEnded(PDO $conn, int $pollId, ?int $exceptMemberId = null): bool {
    // Bitiren kişi ve cron aynı anda denerse sadece biri gönderir
    $claim = $conn->prepare("UPDATE polls SET end_notified = 1 WHERE id = ? AND end_notified = 0 AND ends_at <= NOW()");
    $claim->execute([$pollId]);
    if ($claim->rowCount() === 0) {
        return false;
    }

    $pollStmt = $conn->prepare("SELECT house_id, question FROM polls WHERE id = ?");
    $pollStmt->execute([$pollId]);
    $poll = $pollStmt->fetch(PDO::FETCH_ASSOC);

    $optionStmt = $conn->prepare(
        "SELECT o.option_text, COUNT(v.id) AS votes
         FROM poll_options o
         LEFT JOIN poll_votes v ON v.option_id = o.id
         WHERE o.poll_id = ?
         GROUP BY o.id, o.option_text
         ORDER BY o.id"
    );
    $optionStmt->execute([$pollId]);
    $options = $optionStmt->fetchAll(PDO::FETCH_ASSOC);

    $top = max(array_map('intval', array_column($options, 'votes')) ?: [0]);
    $winners = array_column(array_filter($options, fn($o) => (int) $o['votes'] === $top), 'option_text');
    if ($top === 0) {
        $result = "Kimse oy vermedi";
    } elseif (count($winners) === 1) {
        $result = "Kazanan: " . $winners[0] . " ($top oy)";
    } else {
        $result = "Berabere: " . implode(", ", $winners);
    }

    notifyMembers(
        $conn,
        houseTokens($conn, (int) $poll['house_id'], $exceptMemberId),
        "Anket sona erdi",
        $poll['question'] . " • " . $result,
        "home"
    );
    return true;
}
