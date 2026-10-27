-- Tekrarlayan görevler (2026-10-27)
-- Kod ile birlikte, git pull'dan HEMEN SONRA çalıştırılır:
--   sudo mysql homepal_db < backend/migrations/2026-10-27_recurring_chores.sql
-- Tekrar çalıştırmak zararsızdır. Mevcut görevler ve eski uygulamalar
-- etkilenmez: yeni kolonlar boş/0 başlar, yani görevler tek seferlik kalır.

ALTER TABLE `house_chores`
  ADD COLUMN IF NOT EXISTS `repeat_every` enum('day','week','month') COLLATE utf8mb4_general_ci DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `repeat_start` date DEFAULT NULL,
  ADD COLUMN IF NOT EXISTS `rotate` tinyint(1) NOT NULL DEFAULT '0',
  ADD COLUMN IF NOT EXISTS `next_due` date DEFAULT NULL;
