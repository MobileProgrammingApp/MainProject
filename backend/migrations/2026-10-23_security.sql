-- Güvenlik güncellemesi (2026-10-23)
-- Kod ile birlikte, git pull'dan HEMEN SONRA bir kez çalıştırılır:
--   sudo mysql homepal_db < backend/migrations/2026-10-23_security.sql
-- Mevcut telefonlardaki oturumlar korunur (token'lar hash'lenerek taşınır).

-- 1) Cihaz başına, hash'li oturum token'ları
CREATE TABLE IF NOT EXISTS `api_tokens` (
  `id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `token_hash` char(64) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_used_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `token_hash` (`token_hash`),
  KEY `user_id` (`user_id`),
  CONSTRAINT `api_tokens_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Eski hesap bazlı token'ları taşı; telefonlar aynı token'la çalışmaya devam eder
INSERT IGNORE INTO `api_tokens` (`user_id`, `token_hash`, `last_used_at`)
SELECT `id`, SHA2(`api_token`, 256), NOW() FROM `users`
WHERE `api_token` IS NOT NULL AND `api_token` <> '';

-- Düz token'lar artık tutulmuyor (kolon bir sonraki temizlikte kaldırılabilir)
UPDATE `users` SET `api_token` = NULL;

-- 2) Bekleyen doğrulama / şifre sıfırlama token'larını hash'le
--    (mailde giden linkler çalışmaya devam eder).
--    DİKKAT: Bu iki satır tekrar çalıştırılırsa token'lar iki kez hash'lenir
--    ve bekleyen linkler bozulur; dosyayı sadece BİR KEZ çalıştırın.
UPDATE `users` SET `verification_token` = SHA2(`verification_token`, 256)
WHERE `verification_token` IS NOT NULL;

UPDATE `users` SET `reset_token` = SHA2(`reset_token`, 256)
WHERE `reset_token` IS NOT NULL;

-- 3) Deneme sınırı (rate limiting) kayıtları; subject = sha256(IP veya e-posta)
CREATE TABLE IF NOT EXISTS `auth_attempts` (
  `id` int NOT NULL AUTO_INCREMENT,
  `action` varchar(32) COLLATE utf8mb4_general_ci NOT NULL,
  `subject` char(64) COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `lookup` (`action`, `subject`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
