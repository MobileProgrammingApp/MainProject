-- Anket iyileştirmeleri (2026-10-27): süre seçimi, erken bitirme, oy değiştirme
-- Kod ile birlikte, git pull'dan HEMEN SONRA çalıştırılır:
--   sudo mysql homepal_db < backend/migrations/2026-10-27_poll_improvements.sql
-- Tekrar çalıştırmak zararsızdır.
--
-- ends_at: anketin kapandığı an (oluştururken seçilen süre, erken bitirilince şimdi).
--   Açık anketler bugüne kadar 24 saat sürüyordu; mevcut anketler aynı sürede kapanır.
-- created_by: anketi açan üye (silinirse NULL kalır, "kim sordu" gösterilmez).
-- is_active ve vote_count artık kullanılmıyor: kapanış ends_at'ten, oy sayıları
--   poll_votes'tan hesaplanıyor (oy değiştirme ve üye silme sonrası sayılar tutarlı kalsın).

ALTER TABLE `polls`
  ADD COLUMN IF NOT EXISTS `ends_at` datetime DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `created_by` int DEFAULT NULL;

UPDATE `polls` SET `ends_at` = `created_at` + INTERVAL 24 HOUR WHERE `ends_at` IS NULL;

ALTER TABLE `polls` DROP COLUMN IF EXISTS `is_active`;
ALTER TABLE `poll_options` DROP COLUMN IF EXISTS `vote_count`;
