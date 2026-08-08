# Homepal

Flutter mobil uygulaması (ev/ev arkadaşları için görev, market listesi, ev bilgisi/envanter, anket paylaşımı) + PHP backend.

## Yapı
- `flutter_app/` — Flutter uygulaması. Paket adı: `com.swordarchitecture.homepal`.
- `backend/api/` — PHP backend (PDO/MySQL, prepared statement'lar ile). Bu klasör sunucuda doğrudan web kökü.
- `backend/schema.sql` — Veri içermeyen, güncel veritabanı şeması (fresh kurulum için).

## Sunucu / Deploy
- Sunucu: IONOS VPS (Ubuntu), Nginx + PHP-FPM + MariaDB.
- API adresi: `https://homepal.swordarchitecture.com` (Let's Encrypt SSL, certbot ile otomatik yenileniyor).
- Sunucudaki proje yolu: `/var/www/homepal.swordarchitecture.com` (bu repo git clone edilmiş hali).
- Deploy: sunucuda `cd /var/www/homepal.swordarchitecture.com && sudo git pull origin main && sudo chown -R www-data:www-data backend`.
- DB şema değişikliklerinde: ilgili `ALTER TABLE` komutunu manuel çalıştırmak gerekiyor (otomatik migration sistemi yok).
- `.env` dosyası sunucuda `backend/api/.env` — DB bilgileri, `PROJECT_ID`/`KEY_FILEPATH` (Firebase), `MAIL_USERNAME`/`MAIL_PASSWORD` (Gmail SMTP), `APP_URL` içeriyor. Repo'da yok (gitignore), sadece sunucuda.

## Auth
- Basit token tabanlı auth: `login.php` hesap bazlı sabit bir `api_token` üretir (JWT değil, session de değil — aynı ev hesabına birden fazla cihaz/üye aynı anda giriş yapabildiği için login'de yeniden üretilmiyor).
- Her endpoint `backend/api/auth.php`'deki `authenticateRequest()` ile bu token'ı doğruluyor, `house_id`'yi client'tan değil token'dan alıyor (sahiplik kontrolü var).
- Şifreler `password_hash`/`password_verify` ile hash'li.
- Kayıt sırasında e-posta doğrulama zorunlu (`verify_email.php`), doğrulanmadan giriş engelleniyor.

## Push Notification
- Firebase projesi: `homepal-app-d0cb6` (geliştiricinin kendi hesabında, önceki bir arkadaşının projesinden bağımsız).
- `backend/api/fcm_helper.php` — FCM v1 API ile bildirim gönderme (görev atama/tamamlama, yeni anket, market listesine ürün ekleme).
- Firebase servis hesabı JSON anahtarı sunucuda `backend/api/keys/fcm-service-account.json` (gitignore'da, repo'da yok).

## Play Store
- Paket adı: `com.swordarchitecture.homepal` (değiştirilemez, kalıcı).
- **KRİTİK — asla kaybetmeyin**: Release imzalama anahtarı `flutter_app/android/homepal-release-key.jks` ve `flutter_app/android/key.properties` — **gitignore'da, repo'da yoklar**. Bu dosyaları kaybederseniz Play Store'daki uygulamayı bir daha güncelleyemezsiniz (yeni bir uygulama gibi yayınlamanız gerekir). Bilgisayar formatlanmadan/değişmeden önce bu iki dosyayı ayrıca yedekleyin (USB, bulut depolama vb.).
- Uygulama içi versiyon: `flutter_app/pubspec.yaml` → `version: X.Y.Z+N`. Play Console'a her yüklemede `N` (versionCode) daha önce kullanılmamış olmalı.
- Gizlilik politikası: `https://homepal.swordarchitecture.com/privacy.html`, hesap silme: `https://homepal.swordarchitecture.com/delete-account.html` (kaynak: `backend/api/`).

## Bilinen açık konular
- Doğrulama maili bazen spam'e düşüyor (Gmail SMTP kullanılıyor, yeni/düşük itibarlı hesap). İçerik iyileştirildi ama kalıcı çözüm için Brevo/SendGrid gibi bir transactional email servisine geçiş değerlendirilebilir.
- `shopping_list.added_by_member_id` yeni eklendi, eski kayıtlarda `NULL` (geriye dönük atanmadı, sorun değil).
