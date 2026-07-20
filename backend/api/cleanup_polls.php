<?php
// 24 saatten eski anketleri temizler. Her istekte değil, cron ile
// periyodik çalıştırılmak üzere tasarlandı (bkz. crontab).
// Örnek: 0 * * * * php /var/www/homepal.swordarchitecture.com/backend/api/cleanup_polls.php

if (php_sapi_name() !== 'cli') {
    http_response_code(403);
    exit("Bu script sadece komut satırından çalıştırılabilir.\n");
}

include __DIR__ . '/db.php';

$deleted = $conn->exec("DELETE FROM polls WHERE created_at < (NOW() - INTERVAL 24 HOUR)");
echo "Silinen anket sayısı: $deleted\n";
