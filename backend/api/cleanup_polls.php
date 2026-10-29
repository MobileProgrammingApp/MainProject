<?php
// Periyodik temizlik, tekrarlı görevlerin yeniden açılması ve süresi dolan anketlerin
// sonuç bildirimi. Her istekte değil, cron ile 10 dakikada bir çalıştırılır (bkz. crontab);
// saatte bir çalışsa da doğru işler, sadece anket bildirimi geç gider.
// Dosya adı crontab'da kayıtlı olduğu için değiştirilmedi.
// Örnek: */10 * * * * php /var/www/homepal.swordarchitecture.com/backend/api/cleanup_polls.php

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

// Süresi dolan anketlerin sonucu (erken bitirilenlerinki end_poll.php'de gitti)
$notified = 0;
foreach ($conn->query("SELECT id FROM polls WHERE end_notified = 0 AND ends_at <= NOW()")->fetchAll(PDO::FETCH_COLUMN) as $pollId) {
    $notified += notifyPollEnded($conn, (int) $pollId) ? 1 : 0;
}
echo "Bitiş bildirimi giden anket: $notified\n";

// Biteli 24 saati geçen anketler (bitince sonuçları bu süre boyunca görünür)
$deleted = $conn->exec("DELETE FROM polls WHERE ends_at < (NOW() - INTERVAL " . POLL_RESULT_HOURS . " HOUR)");
echo "Silinen anket sayısı: $deleted\n";

// Deneme sınırı kayıtları (en uzun pencere 1 saat)
$attempts = $conn->exec("DELETE FROM auth_attempts WHERE created_at < (NOW() - INTERVAL 1 DAY)");
echo "Silinen deneme kaydı: $attempts\n";

// 270 gündür uygulama açılmayan cihazların bildirim kaydı (FCM de bu kadar süre
// kullanılmayan token'ı geçersiz sayar; açılınca cihaz kendini yeniden kaydeder)
$devices = $conn->exec("DELETE FROM member_devices WHERE updated_at < (NOW() - INTERVAL 270 DAY)");
echo "Silinen eski cihaz kaydı: $devices\n";

// 180 gündür kullanılmayan cihaz oturumları
$tokens = $conn->exec("DELETE FROM api_tokens WHERE COALESCE(last_used_at, created_at) < (NOW() - INTERVAL 180 DAY)");
echo "Silinen eski oturum: $tokens\n";

// Süresi dolmuş şifre sıfırlama token'ları
$conn->exec("UPDATE users SET reset_token = NULL, reset_token_expires = NULL WHERE reset_token_expires < NOW()");
