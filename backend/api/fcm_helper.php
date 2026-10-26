<?php

/**
 * Tek bir cihaza FCM v1 bildirimi gönderir, başarılıysa true döner.
 * Google token'ın artık geçersiz olduğunu söylerse (uygulama silinmiş /
 * yeniden kurulmuş) ve $conn verilmişse token veritabanından temizlenir.
 */
function sendFCMNotificationV1($projectId, $keyFilePath, $targetToken, $title, $body, ?PDO $conn = null, string $screen = ''): bool {
    $accessToken = getGoogleAccessToken($keyFilePath);

    $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    $payload = [
        "message" => [
            "token" => $targetToken,
            "notification" => [
                "title" => $title,
                "body" => $body
            ],
            // Uygulama bildirime dokunulunca bu ekranı açar (chores / shopping / home)
            "data" => ["screen" => $screen],
            "android" => [
                "priority" => "high",
                "notification" => [
                    "sound" => "default",
                    // Uygulamanın kendi yüksek öncelikli kanalı (NotificationService
                    // oluşturur); yoksa Android varsayılan kanala düşer.
                    "channel_id" => "homepal_default_channel",
                    // click_action BİLEREK yok: firebase_messaging dokunmayı uygulamanın
                    // açılış ekranından bekler. Eskiden gönderilen
                    // "FLUTTER_NOTIFICATION_CLICK" hiçbir ekrana karşılık gelmediği için
                    // uygulama kapalı/arka plandayken bildirime dokunmak işe yaramıyordu.
                ]
            ]
        ]
    ];

    $headers = [
        'Authorization: Bearer ' . $accessToken,
        'Content-Type: application/json'
    ];

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, $url);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));

    $response = curl_exec($ch);
    $httpCode = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);

    if ($httpCode === 200) {
        return true;
    }

    $status = json_decode((string) $response, true)['error']['status'] ?? "HTTP $httpCode";

    // NOT_FOUND / UNREGISTERED: cihaz token'ı artık yok, bir daha denemeye gerek yok
    if ($conn && in_array($status, ['NOT_FOUND', 'UNREGISTERED'], true)) {
        $conn->prepare("UPDATE home_members SET fcm_token = NULL WHERE fcm_token = ?")->execute([$targetToken]);
    }

    error_log("[homepal] FCM gönderimi başarısız: $status");
    return false;
}

/**
 * Bir liste FCM token'ına aynı bildirimi gönderir. Firebase ayarlı değilse
 * sessizce atlar; tek tek hatalar diğer alıcılara gönderimi engellemesin diye
 * loglanıp geçilir. Aynı cihaz birden fazla üyede kayıtlıysa tek bildirim gider.
 */
function notifyMembers(PDO $conn, array $tokens, string $title, string $body, string $screen = ''): void {
    $projectId = $_ENV['PROJECT_ID'] ?? null;
    $keyFilePath = $_ENV['KEY_FILEPATH'] ?? null;
    if (!$projectId || !$keyFilePath) {
        return;
    }

    foreach (array_unique(array_filter($tokens)) as $token) {
        try {
            sendFCMNotificationV1($projectId, $keyFilePath, $token, $title, $body, $conn, $screen);
        } catch (Throwable $e) {
            // Asıl işlem (görev/ürün/anket) zaten kaydedildi; bildirim hatası onu bozmasın
            error_log("[homepal] FCM: " . $e->getMessage());
        }
    }
}

function getGoogleAccessToken($keyFilePath) {
    // Aynı istekte birden fazla bildirim gönderilirken her biri için
    // Google'dan yeniden token almamak için
    static $cache = [];
    if (isset($cache[$keyFilePath]) && $cache[$keyFilePath]['expires'] > time() + 60) {
        return $cache[$keyFilePath]['token'];
    }

    if (!is_readable($keyFilePath)) {
        throw new Exception("Firebase anahtar dosyası okunamadı");
    }

    $key = json_decode(file_get_contents($keyFilePath), true);
    if (empty($key['private_key']) || empty($key['client_email'])) {
        throw new Exception("Firebase anahtar dosyası geçersiz");
    }

    $header = json_encode(['alg' => 'RS256', 'typ' => 'JWT']);
    $now = time();
    $payload = json_encode([
        'iss' => $key['client_email'],
        'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
        'aud' => 'https://oauth2.googleapis.com/token',
        'iat' => $now,
        'exp' => $now + 3600
    ]);

    $encode = function($data) {
        return str_replace(['+', '/', '='], ['-', '_', ''], base64_encode($data));
    };

    $base64UrlHeader = $encode($header);
    $base64UrlPayload = $encode($payload);

    $signature = '';
    if (!openssl_sign($base64UrlHeader . "." . $base64UrlPayload, $signature, $key['private_key'], OPENSSL_ALGO_SHA256)) {
        throw new Exception("JWT imzalanamadı");
    }
    $base64UrlSignature = $encode($signature);

    $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_TIMEOUT, 10);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));

    $result = curl_exec($ch);
    curl_close($ch);

    $response = json_decode((string) $result, true);
    if (empty($response['access_token'])) {
        throw new Exception("Google erişim token'ı alınamadı: " . ($response['error'] ?? 'bağlantı hatası'));
    }

    $cache[$keyFilePath] = [
        'token' => $response['access_token'],
        'expires' => $now + (int) ($response['expires_in'] ?? 3600),
    ];
    return $response['access_token'];
}
