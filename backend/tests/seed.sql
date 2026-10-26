-- Test verisi: schema.sql'den sonra yüklenir (bkz. run_tests.py).
-- Ev 1: doğrulanmış, eski sürümden kalma ortak token'ı olan hesap
--       (token = 'a' x 64; testlerdeki OLD_TOKEN). Şifresi test başında atanır.
-- Ev 2: doğrulanmamış hesap (bekleyen doğrulama token'ı = 'c' x 64)
INSERT INTO users (id, house_name, email, password, email_verified, verification_token) VALUES
  (1, 'Eski Ev', 'eski@example.com', 'x', 1, NULL),
  (2, 'Dogrulanmamis', 'yeni@example.com', 'x', 0, SHA2(REPEAT('c', 64), 256));

INSERT INTO api_tokens (user_id, token_hash, last_used_at) VALUES
  (1, SHA2(REPEAT('a', 64), 256), NOW());

-- Aynı cihaz token'ı iki üyede (profil değiştirme senaryosu)
INSERT INTO home_members (id, house_id, name, fcm_token) VALUES
  (1, 1, 'Ahmet', 'tokA'),
  (2, 1, 'Ayse', 'tokA'),
  (3, 2, 'Baska', NULL);
