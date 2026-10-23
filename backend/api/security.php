<?php

/**
 * Ortak güvenlik yardımcıları: hata yanıtı, girdi doğrulama, token hash'leme
 * ve deneme sınırı (rate limiting). db.php tarafından her endpoint'e yüklenir.
 *
 * Not: Hata yanıtları kasıtlı olarak HTTP 200 + {"status":"error"} döner.
 * Play Store'daki eski sürümler 200 dışındaki her cevapta mesajı göstermeden
 * "Sunucu hatası" yazıyor; kullanıcı asıl mesajı görsün diye bu biçimi koruyoruz.
 */

function jsonError(string $message, int $httpCode = 200): void {
    http_response_code($httpCode);
    echo json_encode(["status" => "error", "message" => $message]);
    exit;
}

/**
 * Beklenmeyen hatanın detayını sadece sunucu loguna yazar; istemciye
 * veritabanı/dosya yolu gibi iç bilgileri sızdırmayan genel bir mesaj döner.
 */
function serverError(Throwable $e): void {
    error_log("[homepal] " . basename($_SERVER['SCRIPT_NAME'] ?? '') . ": " . $e->getMessage());
    jsonError("Bir hata oluştu, lütfen daha sonra tekrar deneyin.");
}

/** Dizi (ör. name[]=x) gibi beklenmeyen tipleri boş string sayar. */
function inputString(array $source, string $field): string {
    $value = $source[$field] ?? '';
    return is_string($value) ? trim($value) : '';
}

/** UTF-8 karakter sayısı (mbstring kurulu olmasa da çalışır). Geçersiz UTF-8 için -1. */
function textLength(string $value): int {
    $count = preg_match_all('/./us', $value);
    return $count === false ? -1 : $count;
}

/** Zorunlu metin alanı: boşsa, geçersiz UTF-8 ise veya $max karakteri aşıyorsa hata döner. */
function requireText(array $source, string $field, int $max, string $label): string {
    $value = inputString($source, $field);
    if ($value === '') {
        jsonError("$label gerekli");
    }
    $length = textLength($value);
    if ($length < 0 || $length > $max) {
        jsonError("$label en fazla $max karakter olabilir");
    }
    return $value;
}

/** Zorunlu pozitif tam sayı (id) alanı. */
function requireInt(array $source, string $field): int {
    $value = filter_var($source[$field] ?? null, FILTER_VALIDATE_INT, ["options" => ["min_range" => 1]]);
    if ($value === false) {
        jsonError("Eksik veya geçersiz veri gönderildi");
    }
    return $value;
}

/** Yeni şifre kuralı. bcrypt 72 bayttan sonrasını yok saydığı için üst sınır var. */
function passwordError(string $password): ?string {
    if (strlen($password) < 8) {
        return "Şifre en az 8 karakter olmalı";
    }
    if (strlen($password) > 72) {
        return "Şifre en fazla 72 karakter olabilir";
    }
    return null;
}

/**
 * Token'lar veritabanında sha256 olarak saklanır; veritabanı sızsa bile
 * içindeki değerlerle giriş yapılamaz. Token'lar 256 bit rastgele olduğu
 * için (şifrelerin aksine) yavaş bir hash'e gerek yoktur.
 */
function hashToken(string $token): string {
    return hash('sha256', $token);
}

function clientIp(): string {
    return $_SERVER['REMOTE_ADDR'] ?? 'unknown';
}

/**
 * $action için $subject (IP, e-posta vb.) son $windowSeconds saniyede $max
 * veya daha fazla deneme yapmış mı? Subject hash'lenerek saklanır, ham
 * IP/e-posta tutulmaz.
 */
function isRateLimited(PDO $conn, string $action, string $subject, int $max, int $windowSeconds): bool {
    $stmt = $conn->prepare("SELECT COUNT(*) FROM auth_attempts WHERE action = ? AND subject = ? AND created_at > (NOW() - INTERVAL ? SECOND)");
    $stmt->execute([$action, hashToken(strtolower($subject)), $windowSeconds]);
    return (int) $stmt->fetchColumn() >= $max;
}

function recordAttempt(PDO $conn, string $action, string $subject): void {
    $conn->prepare("INSERT INTO auth_attempts (action, subject) VALUES (?, ?)")
        ->execute([$action, hashToken(strtolower($subject))]);
}
