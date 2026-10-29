-- 1.3.0: anket bitiş bildirimi ve üye başına birden fazla cihaz (2026-10-29)
-- Kod ile birlikte, git pull'dan HEMEN SONRA çalıştırılır:
--   sudo mysql homepal_db < backend/migrations/2026-10-29_polls_and_devices.sql
-- Tekrar çalıştırmak zararsızdır.

-- Biten anketin sonucu evdekilere bir kez bildirilir (cron / end_poll.php)
SET @had_end_notified = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'polls' AND column_name = 'end_notified');
ALTER TABLE `polls`
  ADD COLUMN IF NOT EXISTS `end_notified` tinyint(1) NOT NULL DEFAULT '0';
-- Bu sürümden önce açılmış anketler (açık ya da bitmiş) için bitiş bildirimi gitmez:
-- açanlar böyle bir bildirim beklemiyordu. Sadece kolon ilk eklendiğinde yapılır;
-- tekrar çalıştırmak sonradan açılan anketlerin bildirimini engellemez.
SET @mark_old_polls = IF(@had_end_notified = 0, 'UPDATE polls SET end_notified = 1', 'DO 0');
PREPARE mark_old_polls FROM @mark_old_polls;
EXECUTE mark_old_polls;
DEALLOCATE PREPARE mark_old_polls;

-- Bildirim token'ları artık cihaz başına: aynı kişi birden fazla cihazda bildirim alır.
-- Token benzersiz, yani bir cihaz tek üyeye bağlı ("Ben kimim?" değişince taşınır).
CREATE TABLE IF NOT EXISTS `member_devices` (
  `id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `fcm_token` varchar(1024) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `fcm_token` (`fcm_token`),
  KEY `member_id` (`member_id`),
  CONSTRAINT `member_devices_ibfk_1` FOREIGN KEY (`member_id`) REFERENCES `home_members` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Üyelerdeki mevcut tek token cihaz tablosuna taşınır, sonra eski kolon kaldırılır.
-- Kolon yoksa (migration daha önce çalıştıysa) taşıma atlanır.
SET @has_old_column = (SELECT COUNT(*) FROM information_schema.columns
  WHERE table_schema = DATABASE() AND table_name = 'home_members' AND column_name = 'fcm_token');
SET @copy_tokens = IF(@has_old_column > 0,
  'INSERT IGNORE INTO member_devices (member_id, fcm_token)
     SELECT id, fcm_token FROM home_members
     WHERE fcm_token REGEXP ''^[!-~]{1,1024}$'' ORDER BY id',
  'DO 0');
PREPARE copy_tokens FROM @copy_tokens;
EXECUTE copy_tokens;
DEALLOCATE PREPARE copy_tokens;

ALTER TABLE `home_members` DROP COLUMN IF EXISTS `fcm_token`;
