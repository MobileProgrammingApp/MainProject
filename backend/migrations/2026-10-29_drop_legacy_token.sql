-- 1.0.2'nin ortak oturum token'ı kolonu kaldırılır (2026-10-29)
-- 2026-10-23'ten beri token'lar api_tokens tablosunda (hash'li) duruyor; bu kolon
-- o gün boşaltıldı ve bir daha kullanılmadı. Kod ile birlikte, git pull'dan sonra:
--   sudo mysql homepal_db < backend/migrations/2026-10-29_drop_legacy_token.sql
-- Tekrar çalıştırmak zararsızdır. (2026-10-23_security.sql bundan sonra tekrar
-- çalıştırılamaz; zaten çalıştırıldı, yeni kurulumlar schema.sql kullanır.)

ALTER TABLE `users` DROP COLUMN IF EXISTS `api_token`;
