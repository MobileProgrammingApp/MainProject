# Homepal

Flutter mobil uygulaması (ev/ev arkadaşları için görev, market listesi, ev bilgisi/envanter, anket paylaşımı) + PHP backend.

## Yapı
- `flutter_app/` — Flutter uygulaması. Paket adı: `com.swordarchitecture.homepal`.
- `backend/api/` — PHP backend (PDO/MySQL, prepared statement'lar ile). Bu klasör sunucuda doğrudan web kökü.
- `backend/schema.sql` — Veri içermeyen, güncel veritabanı şeması (fresh kurulum için).
- `backend/tests/` — Uçtan uca API testleri: `python backend/tests/run_tests.py` (izole MariaDB + PHP kurar, gerçek veritabanına dokunmaz). Backend değişikliğinden sonra deploy öncesi çalıştırın; yeni endpoint'e test ekleyin.
- Hesap silme uygulama içinden (`delete_account.php`, şifre onaylı; bağlı tablolar `ON DELETE CASCADE` ile silinir) ve web'den (`delete-account.html`) yapılabilir; Google Play bunu şart koşuyor.
- Açık ve koyu tema var (1.3.0+): Ayarlar > Görünüm'den "Telefonun ayarına uy / Açık / Koyu" seçilir, SharedPreferences `theme_mode`'da durur ve çıkış yapınca silinmez. Temaya göre değişen renk/stiller `lib/core/app_theme.dart`'taki `AppStyles.light`/`AppStyles.dark` içinde, ekranlarda `context.styles.textColor` gibi okunur. İki temada aynı kalanlar statik: `AppStyles.accentColor`, `successColor`, amblem için `brandBlue`/`brandNavy`. Ekrana sabit renk (`Colors.white`, `Color(0x…)`) yazmayın; koyu temada okunmaz. Telefon gece modundayken yerel açılış ekranı da koyudur (`res/values-night/colors.xml`); rengi `AppStyles.dark.backgroundColor` ile aynı tutun. Seçim `MainActivity.kt`'deki `homepal/theme` kanalıyla `UiModeManager.setApplicationNightMode`'a da verilir; Android 12+'da açılış ekranı telefondan farklı seçilen temayla açılır (Android 11 ve öncesinde telefonun temasıyla).

## Sunucu / Deploy
- Sunucu: IONOS VPS (Ubuntu), Nginx + PHP-FPM + MariaDB.
- API adresi: `https://homepal.swordarchitecture.com` (Let's Encrypt SSL, certbot ile otomatik yenileniyor).
- Sunucudaki proje yolu: `/var/www/homepal.swordarchitecture.com` (bu repo git clone edilmiş hali).
- Deploy: sunucuda `cd /var/www/homepal.swordarchitecture.com && sudo git pull origin main && sudo chown -R www-data:www-data backend`.
- DB şema değişikliklerinde: otomatik migration sistemi yok. Değişiklik `backend/migrations/YYYY-MM-DD_ad.sql` olarak eklenir (`.gitignore`'daki `*.sql` kuralından muaf), deploy'dan hemen sonra sunucuda bir kez `sudo mysql homepal_db < backend/migrations/...sql` ile çalıştırılır; `backend/schema.sql` de güncellenir.
- Nginx (`/etc/nginx/sites-enabled/homepal.swordarchitecture.com`): web kökü `backend/api/` olduğu için `.env`, `keys/`, `*.json|sql|lock|env|md|log|bak` dışarı verilmiyor; HSTS ve güvenlik başlıkları burada. Web köküne asla gizli dosya koymayın.
- Cron: `cleanup_polls.php` (sadece CLI, **10 dakikada bir** çalışmalı: `*/10 * * * *`) günü gelen tekrarlı görevleri açar, süresi dolan anketlerin sonuç bildirimini gönderir; eski anketleri, deneme sınırı kayıtlarını, 180 gün kullanılmayan oturumları ve 270 gün güncellenmeyen cihaz kayıtlarını temizler. Saatte bir çalışsa da doğru işler, sadece anket bildirimi geç gider.
- Tekrarlayan görevler (`chores_helper.php`): `house_chores.repeat_every` (day/week/month), `repeat_start`, `rotate`, `next_due`. Tamamlanınca `next_due` takvime göre (başlangıç gününden, geç tamamlansa da kaymadan) kurulur. Görev o gün Türkiye saatiyle 08:00'den sonra yeniden açılır ve sorumlusuna bildirim gider: cron'da ya da uygulama listeyi çekerken (`get_chores`/`get_home_stats`), hangisi önce olursa. `rotate`'te görev açılırken üyeler id sırasıyla dolaşılır. Sırası gelen kişi silinirse görev sıradakine geçer. 1.2.0 ve öncesi `repeat` göndermez; o durumda ayar korunur.
- Anketler (`polls_helper.php`): 1.3.0'dan beri evde aynı anda en fazla 10 açık anket olabilir; yenisi açılınca diğerleri kalır. `polls.ends_at` kapanış anıdır: oluştururken seçilen süre (1 saat–1 hafta, gönderilmezse 24 saat) ya da `end_poll.php` ile erken bitirilince o an. Açıkken oy değiştirilebilir (`poll_votes` üye başına tek satır). Oy sayıları her istekte `poll_votes`'tan hesaplanır. Biten anket 24 saat daha sonuçlarıyla görünür, sonra cron siler; `delete_poll.php` ile daha önce de silinebilir. Bitince evdekilere sonuç bildirimi gider: erken bitirilince hemen (bitirene gitmez), süresi dolunca cron'la; `polls.end_notified` her ankete tek bildirim garantiler. `created_by` anketi açan üyedir; yeni anket bildirimi ona gitmez. Anketi sadece açan kişi bitirebilir ve silebilir (üye kimliği cihazdaki "Ben kimim?" seçimidir); açan belli değilse ya da silinmişse herkes. 1.3.0+ `get_polls.php` ile bütün anketleri alır; panelde biri öne çıkar (oyunu bekleyen), hepsi Anketler ekranındadır. 1.2.0 ve öncesi `get_active_poll.php` ile tek anket görür (en son açılan açık anket; `include_closed=1` gönderen 1.2.0 açık yoksa en son biteni).
- Yedek: `/usr/local/sbin/homepal-backup.sh` her gece 03:30 UTC'de (`/etc/cron.d/homepal-backup`) `homepal_db`'yi gzip'li olarak `/var/backups/homepal/` altına döker, 14 günden eskileri siler; log `/var/log/homepal_backup.log`. Yedekler aynı sunucuda duruyor, ara ara bilgisayara (OneDrive dışına, gerçek kullanıcı verisi) indirin.
- SSH: sadece anahtarla giriş (`/etc/ssh/sshd_config.d/01-homepal.conf`; `50-cloud-init.conf` şifreyi açtığı için ondan önce okunan bir dosyada). `authorized_keys`'te web sitesinin `github-actions` deploy anahtarı da var, silmeyin. Erişim kaybolursa IONOS panelindeki web konsolu SSH'den bağımsız çalışır.
- Aynı sunucuda geliştiricinin web sitesi de var (`swordarchitecture.com`, Nginx → Node :3000, pm2'de `sword-app`, açılışta `pm2-root` servisiyle başlar; 3000 portu dışarıya IONOS güvenlik duvarıyla kapalı). Sunucu yeniden başlatma onu da etkiler.
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
- `backend/api/fcm_helper.php` — FCM v1 API ile bildirim gönderme (görev atama/tamamlama, yeni anket, anket sonucu, market listesine ürün ekleme). Endpoint'ler `notifyMembers()` ile, alıcıları `memberTokens()`/`houseTokens()` ile bulur; Google `NOT_FOUND`/`UNREGISTERED` derse token DB'den silinir, hatalar `error_log`'a yazılır. Testlerde `.env`'deki `FCM_TEST_LOG` bildirimi göndermek yerine alıcıları dosyaya yazar.
- Cihazlar `member_devices` tablosunda (1.3.0+): bir üyenin birden fazla cihazı olabilir, bildirim hepsine gider; token benzersiz olduğu için bir cihaz tek üyeye bağlıdır ("Ben kimim?" değişince `update_member_token.php` onu yeni üyeye taşır). Bildirimi kapatan ya da çıkış yapan cihaz `enabled=0` ile sadece kendi kaydını siler; 1.2.0 ve öncesi boş token gönderir, o zaman üyenin bütün cihazları silinir (açık olanlar uygulama açılınca kendini yeniden kaydeder).
- Uygulama hâlâ `getToken()`/`onTokenRefresh` kullanıyor (firebase_messaging 17'de eskidi). Önerilen `register()`/`onRegistered` FCM token'ı yerine Firebase Installation ID verir; ona geçmek için sunucunun gönderimi de değişmeli.
- Firebase servis hesabı JSON anahtarı sunucuda **web kökünün dışında**: `/etc/homepal/fcm-service-account.json` (`root:www-data`, `640`), `.env`'de `KEY_FILEPATH`. Eskiden `backend/api/keys/` altındaydı ve web'den indirilebiliyordu; 2026-10-23'te o anahtar iptal edilip yenisi oluşturuldu.

## Çökme raporları (Crashlytics)
- 1.2.1'den itibaren Firebase Crashlytics açık (`flutter_app/lib/core/crash_reporting.dart`, açılışta `SplashScreen` Firebase'den hemen sonra başlatır). Yakalanmamış Flutter/Dart hataları ve yerel çökmeler aynı Firebase projesinin Crashlytics panosuna düşer.
- Rapor yalnızca release derlemeden gider (`kReleaseMode`); debug/profile derlemeler göndermez. Kodun içinde yakalanan ağ hataları (ApiService) rapor edilmez.
- Gradle: `com.google.firebase.crashlytics` eklentisi google-services 4.4.1+ ister. Release derlemede R8 mapping dosyası otomatik yüklenir, yani `flutter build appbundle` sırasında internet gerekir.
- Raporlara kullanıcı kimliği/e-posta eklenmiyor; bu yüzden gizlilik politikası ve Play veri güvenliği formunda sadece "çökme günlükleri, tanılama, cihaz kimliği" beyan ediliyor. Kimlik eklenecekse ikisi de güncellenmeli.

## Android derleme
- Gradle 9.3.1, AGP 9.1.0, Kotlin 2.4.0, Java 17. Bunlar Flutter 3.47'nin yeni proje şablonuyla aynı. `gradle.properties`'te `android.builtInKotlin=false` ve `android.newDsl=false`, eklentiler AGP 9'un yeni yollarına geçene kadar kalmalı. Kotlin eklentisini app modülüne Flutter eklentisi uygular; `app/build.gradle.kts`'e `kotlin-android` eklemeyin.
- FlutterFire: firebase_core 5, firebase_crashlytics 6, firebase_messaging 17 (Firebase Android BoM 35, minSdk 24). Derlemede "plugins that apply KGP" uyarısı (firebase_core, firebase_crashlytics) bu en son sürümlerde de çıkıyor; şimdilik derlemeye engel değil, eklentiler güncellenince gider.

## Play Store
- Paket adı: `com.swordarchitecture.homepal` (değiştirilemez, kalıcı).
- **KRİTİK — asla kaybetmeyin**: Release imzalama anahtarı `flutter_app/android/homepal-release-key.jks` ve `flutter_app/android/key.properties` — **gitignore'da, repo'da yoklar**. Bu dosyaları kaybederseniz Play Store'daki uygulamayı bir daha güncelleyemezsiniz (yeni bir uygulama gibi yayınlamanız gerekir). Bilgisayar formatlanmadan/değişmeden önce bu iki dosyayı ayrıca yedekleyin (USB, bulut depolama vb.).
- Uygulama içi versiyon: `flutter_app/pubspec.yaml` → `version: X.Y.Z+N`. Play Console'a her yüklemede `N` (versionCode) daha önce kullanılmamış olmalı.
- Gizlilik politikası: `https://homepal.swordarchitecture.com/privacy.html`, hesap silme: `https://homepal.swordarchitecture.com/delete-account.html` (kaynak: `backend/api/`).

## Bilinen açık konular
- Doğrulama maili bazen spam'e düşüyor (Gmail SMTP kullanılıyor, yeni/düşük itibarlı hesap). İçerik iyileştirildi ama kalıcı çözüm için Brevo/SendGrid gibi bir transactional email servisine geçiş değerlendirilebilir.
- `shopping_list.added_by_member_id` yeni eklendi, eski kayıtlarda `NULL` (geriye dönük atanmadı, sorun değil).
