<?php

function sendFCMNotificationV1($projectId, $keyFilePath, $targetToken, $title, $body) {
    $accessToken = getGoogleAccessToken($keyFilePath);

    $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    $payload = [
        "message" => [
            "token" => $targetToken,
            "notification" => [
                "title" => $title,
                "body" => $body
            ],
            "android" => [
                "priority" => "high",
                "notification" => [
                    "sound" => "default",
                    "click_action" => "FLUTTER_NOTIFICATION_CLICK"
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
    curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));

    $response = curl_exec($ch);
    curl_close($ch);

    return $response;
}

/**
 * Bir liste FCM token'ına aynı bildirimi gönderir; tek tek hatalar
 * diğer alıcılara gönderimi engellemesin diye burada yutulur.
 */
function sendFCMToMembers($projectId, $keyFilePath, array $tokens, $title, $body) {
    foreach ($tokens as $token) {
        if (empty($token)) {
            continue;
        }
        try {
            sendFCMNotificationV1($projectId, $keyFilePath, $token, $title, $body);
        } catch (Exception $e) {
            // Bir alıcıya gönderim başarısız olsa da diğerlerine devam et
        }
    }
}

function getGoogleAccessToken($keyFilePath) {
    if (!file_exists($keyFilePath)) {
        throw new Exception("JSON anahtar dosyası bulunamadı: " . $keyFilePath);
    }

    $key = json_decode(file_get_contents($keyFilePath), true);
    $privKey = $key['private_key'];

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
    openssl_sign($base64UrlHeader . "." . $base64UrlPayload, $signature, $privKey, OPENSSL_ALGO_SHA256);
    $base64UrlSignature = $encode($signature);

    $jwt = $base64UrlHeader . "." . $base64UrlPayload . "." . $base64UrlSignature;

    $ch = curl_init();
    curl_setopt($ch, CURLOPT_URL, 'https://oauth2.googleapis.com/token');
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, http_build_query([
        'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        'assertion' => $jwt
    ]));

    $result = curl_exec($ch);
    curl_close($ch);

    $response = json_decode($result, true);
    return $response['access_token'];
}
