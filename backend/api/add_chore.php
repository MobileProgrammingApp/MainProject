<?php

include 'db.php';
require_once __DIR__ . '/vendor/autoload.php';

use Dotenv\Dotenv;

// .env dosyasını yükle
$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

$projectId = $_ENV['PROJECT_ID'];
$keyFilePath   = $_ENV['KEY_FILEPATH'];

$creator_id = $_POST['creator_id'] ?? null;
$assigned_to_id = $_POST['assigned_to_id'] ?? null;
$task_name = $_POST['task_name'] ?? null;

if (!$creator_id || !$assigned_to_id || !$task_name) {
    echo json_encode(["status" => "error", "message" => "Eksik veri gönderildi"]);
    exit;
}

try {

    $stmt = $conn->prepare("INSERT INTO house_chores (creator_id, assigned_to_id, task_name) VALUES (?, ?, ?)");
    $stmt->execute([$creator_id, $assigned_to_id, $task_name]);

    $tokenStmt = $conn->prepare("SELECT fcm_token FROM home_members WHERE id = ?");
    $tokenStmt->execute([$assigned_to_id]);
    $member = $tokenStmt->fetch(PDO::FETCH_ASSOC);

    if ($member && !empty($member['fcm_token'])) {
        $result = sendFCMNotificationV1($member['fcm_token'], "Yeni Görev!", "Sana bir görev atandı: " . $task_name);
        echo json_encode(["status" => "success", "fcm_response" => json_decode($result)]);
    } else {
        echo json_encode(["status" => "success", "message" => "Görev eklendi ancak hedef üyenin token'ı bulunamadı."]);
    }
  
} catch(Exception $e) {
    echo json_encode(["status" => "error", "message" => $e->getMessage()]);
}


function sendFCMNotificationV1($targetToken, $title, $body) {
    // 1. Google OAuth2 Access Token Al (Kütüphanesiz)
    $accessToken = getGoogleAccessToken($keyFilePath);
    
    // 2. FCM v1 URL
    $url = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    // 3. Mesaj Yapısı (V1 Formatı)
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
 * Service Account JSON kullanarak Access Token üreten yardımcı fonksiyon
 */
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
?>