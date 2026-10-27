<?php
require_once __DIR__ . '/fcm_helper.php';

/**
 * Tekrarlayan görevler. Tamamlanan tekrarlı görev "Tamamlananlar"da bekler;
 * sıradaki günü (next_due) gelince sabah 08:00'den sonra yeniden açılır ve
 * sorumlusuna bildirim gider. "Sırayla" seçiliyse açılırken evdeki bir sonraki
 * kişiye geçer (üyeler eklenme sırasına göre dizilir).
 *
 * Günler Türkiye saatine göre hesaplanır; sunucu UTC'de çalışıyor.
 */

const CHORE_REPEATS = ['day', 'week', 'month'];
const CHORE_REOPEN_HOUR = 8;

function choreTimezone(): DateTimeZone {
    return new DateTimeZone('Europe/Istanbul');
}

function choreToday(): DateTimeImmutable {
    return new DateTimeImmutable('today', choreTimezone());
}

/** İstekteki tekrar seçeneği: 'day' | 'week' | 'month', tek seferlikse null. */
function choreRepeatInput(array $source): ?string {
    $repeat = inputString($source, 'repeat');
    if ($repeat === '' || $repeat === 'none') {
        return null;
    }
    if (!in_array($repeat, CHORE_REPEATS, true)) {
        jsonError("Geçersiz tekrar seçeneği");
    }
    return $repeat;
}

/**
 * $start gününden itibaren $every aralıklarla gelen günlerden $after'dan
 * sonraki ilki. Görev geç tamamlansa da takvim kaymaz: haftalık bir görev
 * hep başladığı gün açılır.
 */
function nextChoreDate(string $every, string $start, DateTimeImmutable $after): string {
    $start = new DateTimeImmutable($start, choreTimezone());

    if ($every === 'month') {
        // Ayın 31'i gibi günler kısa aylarda ayın son gününe düşer, sonraki
        // aylarda yine başlangıç gününe döner
        $day = (int) $start->format('j');
        $firstOfMonth = $start->modify('first day of this month');
        for ($n = 1; ; $n++) {
            $month = $firstOfMonth->modify("+$n month");
            $candidate = $month->setDate((int) $month->format('Y'), (int) $month->format('n'), min($day, (int) $month->format('t')));
            if ($candidate > $after) {
                return $candidate->format('Y-m-d');
            }
        }
    }

    $step = $every === 'day' ? 1 : 7;
    $daysSinceStart = max(0, (int) $start->diff($after)->format('%r%a'));
    $periods = intdiv($daysSinceStart, $step) + 1;
    return $start->modify('+' . ($periods * $step) . ' days')->format('Y-m-d');
}

/** Görev bugün tamamlandıysa yeniden açılacağı gün; tekrarlı değilse null. */
function choreNextDue(?string $every, ?string $start): ?string {
    if (!$every) {
        return null;
    }
    $today = choreToday();
    return nextChoreDate($every, $start ?: $today->format('Y-m-d'), $today);
}

/** Üyeler eklenme sırasına dizildiğinde $currentId'den sonra gelen kişi (sondakinden sonra baştaki). */
function nextMemberId(PDO $conn, int $houseId, int $currentId): ?int {
    $stmt = $conn->prepare("SELECT id FROM home_members WHERE house_id = ? AND id != ? ORDER BY id > ? DESC, id ASC LIMIT 1");
    $stmt->execute([$houseId, $currentId, $currentId]);
    $id = $stmt->fetchColumn();
    return $id === false ? null : (int) $id;
}

/**
 * Günü gelen tekrarlı görevleri yeniden açar ve sorumlusuna haber verir;
 * açılan görev sayısını döner. $houseId verilmezse bütün evler (cron),
 * verilirse sadece o ev: uygulama listeyi çekerken cron'u beklemeden güncel görünsün.
 */
function reopenDueChores(PDO $conn, ?int $houseId = null): int {
    $now = new DateTimeImmutable('now', choreTimezone());
    // Gece yarısı bildirim gitmesin: günü gelen görevler sabah açılır
    $lastDue = (int) $now->format('G') >= CHORE_REOPEN_HOUR ? $now : $now->modify('-1 day');

    $sql = "SELECT id, creator_id, assigned_to_id, task_name, rotate FROM house_chores
            WHERE is_done = 1 AND repeat_every IS NOT NULL AND next_due <= ?";
    $params = [$lastDue->format('Y-m-d')];
    if ($houseId !== null) {
        $sql .= " AND creator_id = ?";
        $params[] = $houseId;
    }
    $stmt = $conn->prepare($sql);
    $stmt->execute($params);

    $reopened = 0;
    foreach ($stmt->fetchAll(PDO::FETCH_ASSOC) as $chore) {
        $assignee = (int) $chore['assigned_to_id'];
        if ($chore['rotate']) {
            $assignee = nextMemberId($conn, (int) $chore['creator_id'], $assignee) ?? $assignee;
        }

        // Cron ve uygulama aynı anda açmaya çalışırsa sadece biri açar, tek bildirim gider
        $update = $conn->prepare("UPDATE house_chores SET is_done = 0, next_due = NULL, assigned_to_id = ? WHERE id = ? AND is_done = 1");
        $update->execute([$assignee, $chore['id']]);
        if ($update->rowCount() === 0) {
            continue;
        }
        $reopened++;

        $tokenStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE id = ?");
        $tokenStmt->execute([$assignee]);
        notifyMembers(
            $conn,
            [$tokenStmt->fetchColumn()],
            $chore['rotate'] ? "Sıra sende!" : "Görev zamanı",
            "\"" . $chore['task_name'] . "\" görevi seni bekliyor.",
            "chores"
        );
    }
    return $reopened;
}
