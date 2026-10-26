# Backend testleri

Uçtan uca API testleri (giriş, oturumlar, deneme sınırı, kayıt/doğrulama,
şifre sıfırlama, sahiplik kontrolleri, girdi doğrulama, anket, bildirim token'ı,
hesap silme). Gerçek sunucuya ve gerçek veritabanına dokunmaz.

```bash
python backend/tests/run_tests.py
```

`run_tests.py` geçici bir klasörde backend kopyası, ayrı portta (3307) boş bir
MariaDB ve PHP yerleşik sunucusu (8099) kurar; `schema.sql` + `seed.sql`
yükler, `test_api.py`'yi çalıştırır ve sonunda her şeyi siler.

- Gerekenler: Python 3, PHP 8+ (`pdo_mysql`), MariaDB/MySQL. Windows'ta XAMPP
  yolları otomatik bulunur; değilse `PHP_BIN` ve `MYSQL_BIN_DIR` verin.
- Composer gerekmez: `stubs/autoload.php` gerçek `.env` okuyucu ve PHPMailer
  yerine geçer; gönderilen mailler bir dosyaya yazılır, testler doğrulama ve
  sıfırlama bağlantılarını oradan okur.
- Firebase bildirimleri test ortamında kapalıdır (`PROJECT_ID` boş).
- Backend'de bir şey değiştirince deploy etmeden önce çalıştırın.
