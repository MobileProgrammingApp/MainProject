<?php
include 'db.php';
require_once __DIR__ . '/auth.php';
require_once __DIR__ . '/polls_helper.php';

// Evin bütün anketleri (1.3.0+): açık olanlar ve son POLL_RESULT_HOURS içinde bitenler,
// sonuçlarıyla. Eski sürümler tek anket gösterir (get_active_poll.php).
$user = authenticateRequest($conn);
$house_id = (int) $user['id'];

// Profil ("Ben kimim?") henüz seçilmediyse uygulama 0 gönderir: anketler yine
// gösterilir, sadece oy bilgisi boş döner (oy vermek için profil gerekir).
$member_id = (int)($_GET['member_id'] ?? 0) > 0 ? requireInt($_GET, 'member_id') : null;

if ($member_id && !memberBelongsToHouse($conn, $member_id, $house_id)) {
    jsonError("Geçersiz üye");
}

try {
    echo json_encode([
        "status" => "success",
        "polls" => housePolls($conn, $house_id, $member_id, true),
        "member_count" => houseMemberCount($conn, $house_id),
    ]);
} catch (Exception $e) {
    serverError($e);
}
