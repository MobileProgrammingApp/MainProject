<?php
include 'db.php';
require_once __DIR__ . '/auth.php';

// 1.0.2 ve öncesinde aynı evdeki tüm cihazlar tek bir token'ı paylaşıyordu
// (2026-10-23 migration'ı ile api_tokens'a tek satır olarak taşındı). Yeni
// sürüm ilk açılışta bunu kendi cihazına özel bir token'la değiştirir; böylece
// bu cihazdan çıkış yapmak, eski sürümü kullanan diğer aile üyelerinin
// oturumunu kapatmaz. Paylaşılan token burada silinmez: eski sürümler onu
// kullanmaya devam eder, kullanılmazsa cleanup_polls.php 180 gün sonra temizler.
$user = authenticateRequest($conn);

try {
    if (isRateLimited($conn, 'renew_token', (string)$user['id'], 20, 3600)) {
        jsonError("Çok fazla istek, lütfen daha sonra tekrar deneyin.");
    }
    recordAttempt($conn, 'renew_token', (string)$user['id']);

    echo json_encode(["status" => "success", "api_token" => issueApiToken($conn, (int)$user['id'])]);
} catch (Exception $e) {
    serverError($e);
}
