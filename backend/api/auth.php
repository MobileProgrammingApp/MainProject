<?php

/**
 * İstekteki oturum token'ını okur. Yeni sürümler "Authorization: Bearer"
 * başlığını kullanır (URL'de ve sunucu loglarında görünmez); Play Store'daki
 * eski sürümler için api_token form/query/JSON alanı da kabul edilir.
 */
function getRequestToken(): string {
    $header = $_SERVER['HTTP_AUTHORIZATION'] ?? '';
    if (stripos($header, 'Bearer ') === 0) {
        return trim(substr($header, 7));
    }

    $token = $_POST['api_token'] ?? $_GET['api_token'] ?? null;

    // Bazı endpoint'ler form-data yerine ham JSON body kullanıyor
    // (create_poll.php gibi); orada da api_token alanını kabul et.
    if (!$token && stripos($_SERVER['CONTENT_TYPE'] ?? '', 'application/json') !== false) {
        $jsonBody = json_decode(file_get_contents('php://input'), true);
        $token = $jsonBody['api_token'] ?? null;
    }

    return is_string($token) ? $token : '';
}

/**
 * Giriş yapmış ev hesabını doğrular. Token geçerli değilse 401 döner ve
 * script'i sonlandırır. Geçerliyse ['token_id', 'id', 'house_name', 'email'] döner.
 *
 * Token'lar cihaz başınadır (api_tokens tablosu): aynı ev hesabına birden
 * fazla aile üyesi/cihaz giriş yapabilir, her girişte yeni bir token üretilir
 * ve diğer cihazların oturumu düşmez. Şifre değişince/sıfırlanınca iptal edilirler.
 */
function authenticateRequest(PDO $conn): array {
    $token = getRequestToken();

    if ($token === '') {
        jsonError("Giriş yapmanız gerekiyor", 401);
    }

    $stmt = $conn->prepare(
        "SELECT t.id AS token_id, u.id, u.house_name, u.email
         FROM api_tokens t JOIN users u ON u.id = t.user_id
         WHERE t.token_hash = ?"
    );
    $stmt->execute([hashToken($token)]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user) {
        jsonError("Geçersiz oturum, lütfen tekrar giriş yapın", 401);
    }

    // Uzun süre kullanılmayan token'ları temizleyebilmek için (cleanup_polls.php);
    // her istekte yazmamak adına günde en fazla bir kez güncellenir.
    $conn->prepare("UPDATE api_tokens SET last_used_at = NOW() WHERE id = ? AND (last_used_at IS NULL OR last_used_at < NOW() - INTERVAL 1 DAY)")
        ->execute([$user['token_id']]);

    return $user;
}

/** Yeni bir cihaz oturumu açar; düz token sadece istemciye döner, veritabanında hash'i durur. */
function issueApiToken(PDO $conn, int $userId): string {
    $token = bin2hex(random_bytes(32));
    $conn->prepare("INSERT INTO api_tokens (user_id, token_hash, last_used_at) VALUES (?, ?, NOW())")
        ->execute([$userId, hashToken($token)]);
    return $token;
}

/** Hesabın tüm oturumlarını (istenirse mevcut cihaz hariç) kapatır. */
function revokeUserTokens(PDO $conn, int $userId, ?int $exceptTokenId = null): void {
    $conn->prepare("DELETE FROM api_tokens WHERE user_id = ? AND id != ?")
        ->execute([$userId, $exceptTokenId ?? 0]);
}

/**
 * Verilen home_members.id gerçekten bu eve mi ait, kontrol eder.
 */
function memberBelongsToHouse(PDO $conn, $memberId, $houseId): bool {
    $stmt = $conn->prepare("SELECT id FROM home_members WHERE id = ? AND house_id = ?");
    $stmt->execute([$memberId, $houseId]);
    return (bool) $stmt->fetch(PDO::FETCH_ASSOC);
}
