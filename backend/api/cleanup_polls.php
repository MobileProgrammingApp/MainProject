<?php
// Periyodik temizlik. Her istekte değil, cron ile çalıştırılmak üzere tasarlandı
// (bkz. crontab). Dosya adı crontab'da kayıtlı olduğu için değiştirilmedi.
// Örnek: 0 * * * * php /var/www/homepal.swordarchitecture.com/backend/api/cleanup_polls.php

if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    exit("Bu script sadece komut satırından çalıştırılabilir.\n");
}

include __DIR__ . '/db.php';

// 24 saatten eski anketler
$deleted = $conn->exec("DELETE FROM polls WHERE created_at < (NOW() - INTERVAL 24 HOUR)");
echo "Silinen anket sayısı: $deleted\n";

// Deneme sınırı kayıtları (en uzun pencere 1 saat)
$attempts = $conn->exec("DELETE FROM auth_attempts WHERE created_at < (NOW() - INTERVAL 1 DAY)");
echo "Silinen deneme kaydı: $attempts\n";

// 180 gündür kullanılmayan cihaz oturumları
$tokens = $conn->exec("DELETE FROM api_tokens WHERE COALESCE(last_used_at, created_at) < (NOW() - INTERVAL 180 DAY)");
echo "Silinen eski oturum: $tokens\n";

// Süresi dolmuş şifre sıfırlama token'ları
$conn->exec("UPDATE users SET reset_token = NULL, reset_token_expires = NULL WHERE reset_token_expires < NOW()");
