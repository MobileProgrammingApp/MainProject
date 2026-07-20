<?php

/**
 * Giriş yapmış ev hesabını doğrular. Token geçerli değilse 401 döner ve
 * script'i sonlandırır. Geçerliyse ['id' => ..., 'house_name' => ...] döner.
 *
 * Not: Bu uygulamada aynı ev hesabına birden fazla aile üyesi/cihaz aynı
 * anda giriş yapabildiği için token, oturum bazlı değil hesap bazlı ve
 * sabit tutulur (login'de yeniden üretilmez) — böylece bir cihaz giriş
 * yapınca diğer cihazların oturumu düşmez.
 */
function authenticateRequest(PDO $conn): array {
    $token = $_POST['api_token'] ?? $_GET['api_token'] ?? null;

    // Bazı endpoint'ler form-data yerine ham JSON body kullanıyor
    // (create_poll.php gibi); orada da api_token alanını kabul et.
    if (!$token && stripos($_SERVER['CONTENT_TYPE'] ?? '', 'application/json') !== false) {
        $jsonBody = json_decode(file_get_contents('php://input'), true);
        $token = $jsonBody['api_token'] ?? null;
    }

    if (!$token) {
        http_response_code(401);
        echo json_encode(["status" => "error", "message" => "Giriş yapmanız gerekiyor"]);
        exit;
    }

    $stmt = $conn->prepare("SELECT id, house_name, email FROM users WHERE api_token = ?");
    $stmt->execute([$token]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        http_response_code(401);
        echo json_encode(["status" => "error", "message" => "Geçersiz oturum, lütfen tekrar giriş yapın"]);
        exit;
    }

    return $user;
}

/**
 * Verilen home_members.id gerçekten bu eve mi ait, kontrol eder.
 */
function memberBelongsToHouse(PDO $conn, $memberId, $houseId): bool {
    $stmt = $conn->prepare("SELECT id FROM home_members WHERE id = ? AND house_id = ?");
    $stmt->execute([$memberId, $houseId]);
    return (bool) $stmt->fetch(PDO::FETCH_ASSOC);
}
