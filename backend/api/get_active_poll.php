<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/polls_helper.php';

// 1.2.0 ve öncesi için: tek anket döner. 1.3.0+ bütün anketleri get_polls.php'den alır.
$user = authenticateRequest($conn);
$house_id = (int) $user['id'];

// Profil ("Ben kimim?") henüz seçilmediyse uygulama 0 gönderir: anket yine
// gösterilir, sadece oy bilgisi boş döner (oy vermek için profil gerekir).
$member_id = (int)($_GET['member_id'] ?? 0) > 0 ? requireInt($_GET, 'member_id') : null;

if ($member_id && !memberBelongsToHouse($conn, $member_id, $house_id)) {
    jsonError("Geçersiz üye");
}

// 1.2.0 biten anketi de (sonuçlarıyla, POLL_RESULT_HOURS boyunca) ister. Daha eski sürümler
// bunu bilmediği için onlara sadece açık anket döner: bitmiş ankete oy vermeye çalışmasınlar.
$include_closed = ($_GET['include_closed'] ?? '') === '1';

try {
    // Evde birden fazla anket olabilir: en son açılan açık anket, açık yoksa en son biten
    $polls = housePolls($conn, $house_id, $member_id, $include_closed);
    $open = array_filter($polls, fn($p) => $p['is_open']);
    $poll = $open
        ? array_reduce($open, fn($newest, $p) => $newest === null || (int) $p['poll_id'] > (int) $newest['poll_id'] ? $p : $newest)
        : ($polls[0] ?? null);

    if ($poll) {
        echo json_encode(["status" => "success"] + $poll + ["member_count" => houseMemberCount($conn, $house_id)]);
    } else {
        echo json_encode(["status" => "empty", "message" => "Aktif anket yok"]);
    }
} catch (Exception $e) {
    serverError($e);
}
