<?php
// Periyodik temizlik ve tekrarlı görevlerin yeniden açılması. Her istekte değil,
// cron ile SAATTE BİR çalıştırılmak üzere tasarlandı (görevler sabah açılsın diye)
// (bkz. crontab). Dosya adı crontab'da kayıtlı olduğu için değiştirilmedi.
// Örnek: 0 * * * * php /var/www/homepal.swordarchitecture.com/backend/api/cleanup_polls.php

if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    exit("Bu script sadece komut satırından çalıştırılabilir.\n");
}

include __DIR__ . '/db.php';
require_once __DIR__ . '/chores_helper.php';
require_once __DIR__ . '/polls_helper.php';

// Günü gelen tekrarlı görevler (sabah 08:00'den sonraki ilk çalışmada açılır)
$chores = reopenDueChores($conn);
echo "Yeniden açılan görev: $chores\n";

// Biteli 24 saati geçen anketler (bitince sonuçları bu süre boyunca görünür)
$deleted = $conn->exec("DELETE FROM polls WHERE ends_at < (NOW() - INTERVAL " . POLL_RESULT_HOURS . " HOUR)");
echo "Silinen anket sayısı: $deleted\n";

// Deneme sınırı kayıtları (en uzun pencere 1 saat)
$attempts = $conn->exec("DELETE FROM auth_attempts WHERE created_at < (NOW() - INTERVAL 1 DAY)");
echo "Silinen deneme kaydı: $attempts\n";

// 180 gündür kullanılmayan cihaz oturumları
$tokens = $conn->exec("DELETE FROM api_tokens WHERE COALESCE(last_used_at, created_at) < (NOW() - INTERVAL 180 DAY)");
echo "Silinen eski oturum: $tokens\n";

// Süresi dolmuş şifre sıfırlama token'ları
$conn->exec("UPDATE users SET reset_token = NULL, reset_token_expires = NULL WHERE reset_token_expires < NOW()");
