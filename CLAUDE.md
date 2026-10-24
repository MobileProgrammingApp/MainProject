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
- DB şema değişikliklerinde: otomatik migration sistemi yok. Değişiklik `backend/migrations/YYYY-MM-DD_ad.sql` olarak eklenir (`.gitignore`'daki `*.sql` kuralından muaf), deploy'dan hemen sonra sunucuda bir kez `sudo mysql homepal_db < backend/migrations/...sql` ile çalıştırılır; `backend/schema.sql` de güncellenir.
- Nginx (`/etc/nginx/sites-enabled/homepal.swordarchitecture.com`): web kökü `backend/api/` olduğu için `.env`, `keys/`, `*.json|sql|lock|env|md|log|bak` dışarı verilmiyor; HSTS ve güvenlik başlıkları burada. Web köküne asla gizli dosya koymayın.
- Cron: `cleanup_polls.php` (sadece CLI) eski anketleri, deneme sınırı kayıtlarını ve 180 gün kullanılmayan oturumları temizler.
- `.env` dosyası sunucuda `backend/api/.env` — DB bilgileri, `PROJECT_ID`/`KEY_FILEPATH` (Firebase), `MAIL_USERNAME`/`MAIL_PASSWORD` (Gmail SMTP), `APP_URL` içeriyor. Repo'da yok (gitignore), sadece sunucuda.

## Auth
- Cihaz başına token: her `login.php` çağrısı `api_tokens` tablosuna yeni bir token açar (aynı ev hesabına birden fazla cihaz/üye aynı anda giriş yapabilir). Veritabanında token'ın sadece sha256 hash'i durur (`users.api_token` kolonu artık kullanılmıyor). Doğrulama ve şifre sıfırlama token'ları da hash'li.
- Token şifre sıfırlanınca tüm cihazlarda, şifre değişince diğer cihazlarda iptal edilir; `logout.php` mevcut cihazınkini iptal eder.
- 1.0.2 ve öncesinde evdeki tüm cihazlar tek bir token paylaşıyordu (migration onu tek satır olarak taşıdı). 1.0.3+ ilk açılışta `renew_token.php` ile kendine özel token alır; ortak token hâlâ ortaksa uygulama çıkışta onu sunucuda iptal etmez (eski sürümdeki aile üyeleri düşmesin).
- Uygulamada token `flutter_secure_storage`'da (`lib/core/session.dart`); tüm istekler `lib/core/api_service.dart`'tan geçer (Bearer başlığı, 15 sn zaman aşımı, 401'de otomatik giriş ekranına dönüş). Ekranlarda doğrudan `http` kullanmayın.
- Her endpoint `backend/api/auth.php`'deki `authenticateRequest()` ile token'ı doğruluyor, `house_id`'yi client'tan değil token'dan alıyor (sahiplik kontrolü sorgunun `WHERE`'inde). Token `Authorization: Bearer` başlığından okunur; Play Store'daki 1.0.2 ve öncesi için `api_token` form/query/JSON alanı da kabul ediliyor (eski sürümler güncellenince kaldırılabilir).
- Ortak yardımcılar `backend/api/security.php`'de (db.php yükler): `jsonError`/`serverError` (iç hata detayı sadece `error_log`'a), `requireText`/`requireInt` girdi doğrulama, `isRateLimited`/`recordAttempt` (giriş, kayıt, şifremi unuttum, şifre değiştirme; `auth_attempts` tablosu).
- Hata yanıtları kasıtlı olarak HTTP 200 + `{"status":"error"}`: eski sürümler 200 dışında mesajı göstermiyor. İstisna: geçersiz oturumda 401.
- Şifreler bcrypt (8–72 karakter). Kayıt sırasında e-posta doğrulama zorunlu (`verify_email.php`). Kayıtlı bir e-postayla tekrar kayıt olunursa uygulama aynı cevabı verir, sahibine "hesabınız zaten var" maili gider (e-posta tahmini engellensin diye).

## Push Notification
- Firebase projesi: `homepal-app-d0cb6` (geliştiricinin kendi hesabında, önceki bir arkadaşının projesinden bağımsız).
- `backend/api/fcm_helper.php` — FCM v1 API ile bildirim gönderme (görev atama/tamamlama, yeni anket, market listesine ürün ekleme). Endpoint'ler `notifyMembers()` kullanır; Google `NOT_FOUND`/`UNREGISTERED` derse token DB'den silinir, hatalar `error_log`'a yazılır. Bir cihaz token'ı aynı anda tek üyede tutulur (`update_member_token.php`).
- Firebase servis hesabı JSON anahtarı sunucuda **web kökünün dışında**: `/etc/homepal/fcm-service-account.json` (`root:www-data`, `640`), `.env`'de `KEY_FILEPATH`. Eskiden `backend/api/keys/` altındaydı ve web'den indirilebiliyordu; 2026-10-23'te o anahtar iptal edilip yenisi oluşturuldu.

## Play Store
- Paket adı: `com.swordarchitecture.homepal` (değiştirilemez, kalıcı).
- **KRİTİK — asla kaybetmeyin**: Release imzalama anahtarı `flutter_app/android/homepal-release-key.jks` ve `flutter_app/android/key.properties` — **gitignore'da, repo'da yoklar**. Bu dosyaları kaybederseniz Play Store'daki uygulamayı bir daha güncelleyemezsiniz (yeni bir uygulama gibi yayınlamanız gerekir). Bilgisayar formatlanmadan/değişmeden önce bu iki dosyayı ayrıca yedekleyin (USB, bulut depolama vb.).
- Uygulama içi versiyon: `flutter_app/pubspec.yaml` → `version: X.Y.Z+N`. Play Console'a her yüklemede `N` (versionCode) daha önce kullanılmamış olmalı.
- Gizlilik politikası: `https://homepal.swordarchitecture.com/privacy.html`, hesap silme: `https://homepal.swordarchitecture.com/delete-account.html` (kaynak: `backend/api/`).

## Bilinen açık konular
- Doğrulama maili bazen spam'e düşüyor (Gmail SMTP kullanılıyor, yeni/düşük itibarlı hesap). İçerik iyileştirildi ama kalıcı çözüm için Brevo/SendGrid gibi bir transactional email servisine geçiş değerlendirilebilir.
- `shopping_list.added_by_member_id` yeni eklendi, eski kayıtlarda `NULL` (geriye dönük atanmadı, sorun değil).
