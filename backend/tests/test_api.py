"""HomePal backend uçtan uca testleri.

Doğrudan çalıştırmayın; ortamı run_tests.py kurar (izole MariaDB + PHP sunucusu)
ve aşağıdaki ortam değişkenlerini verir.
"""
import datetime, json, os, re, subprocess, sys, urllib.parse, urllib.request

BASE = os.environ.get("HOMEPAL_TEST_BASE", "http://127.0.0.1:8099")
MAILS = os.environ["HOMEPAL_TEST_MAILS"]
PHP_ERRORS = os.environ["HOMEPAL_TEST_PHP_ERRORS"]
PHP = os.environ.get("HOMEPAL_TEST_PHP", "php")
API_DIR = os.environ["HOMEPAL_TEST_API_DIR"]
MYSQL = [os.environ["HOMEPAL_TEST_MYSQL"], "-h127.0.0.1", "-P" + os.environ.get("HOMEPAL_TEST_DB_PORT", "3307"),
         "-uroot", "homepal_test", "-N", "-e"]
OLD_TOKEN = "a" * 64  # seed.sql: eski sürümden kalan ortak token

passed = failed = 0
def check(name, cond, detail=""):
    global passed, failed
    if cond:
        passed += 1; print(f"  ✓ {name}")
    else:
        failed += 1; print(f"  ✗ {name}  {detail}")

def req(path, data=None, get=None, token=None, json_body=None, raw=False):
    url = BASE + "/" + path + ("?" + urllib.parse.urlencode(get) if get else "")
    headers = {}
    body = None
    if json_body is not None:
        body = json.dumps(json_body).encode(); headers["Content-Type"] = "application/json"
    elif data is not None:
        body = urllib.parse.urlencode(data, doseq=True).encode()
    if token:
        headers["Authorization"] = "Bearer " + token
    r = urllib.request.Request(url, data=body, headers=headers)
    try:
        resp = urllib.request.urlopen(r); code = resp.status; text = resp.read().decode(); ctype = resp.headers.get("Content-Type", "")
    except urllib.error.HTTPError as e:
        code = e.code; text = e.read().decode(); ctype = e.headers.get("Content-Type", "")
    if raw:
        return code, text, ctype
    try:
        return code, json.loads(text)
    except ValueError:
        return code, {"_raw": text}

def sql(q):
    return subprocess.run(MYSQL + [q], capture_output=True, text=True).stdout.strip()

def devices(member_id):
    return sql(f"SELECT IFNULL(GROUP_CONCAT(fcm_token ORDER BY fcm_token), '-') FROM member_devices WHERE member_id = {member_id}")

def fcm_log():
    # fcm_helper.php testte bildirim göndermez, alıcıları buraya yazar
    path = os.environ["HOMEPAL_TEST_FCM"]
    return [json.loads(l) for l in open(path, encoding="utf-8")] if os.path.exists(path) else []

def last_mail_link(to, kind):
    lines = [json.loads(l) for l in open(MAILS, encoding="utf-8")] if os.path.exists(MAILS) else []
    for m in reversed(lines):
        if m["to"] == to:
            found = re.search(kind + r"\.php\?token=([a-f0-9]{64})", m["text"])
            return (found.group(1) if found else None), m["subject"]
    return None, None

if os.path.exists(MAILS):
    os.remove(MAILS)
php_hash = subprocess.run([PHP, "-r", "echo password_hash('EskiSifre123', PASSWORD_BCRYPT);"], capture_output=True, text=True).stdout
sql(f"UPDATE users SET password = '{php_hash}' WHERE id = 1")

print("1) Oturum token'ı sadece Authorization başlığında (eski sürümden kalan ortak token ile)")
c, j = req("get_profile.php", token=OLD_TOKEN)
check("Authorization: Bearer başlığı çalışıyor", j.get("status") == "success", j)
c, j = req("get_profile.php", get={"api_token": OLD_TOKEN})
check("URL'deki token (1.0.2 yöntemi) kabul edilmiyor", c == 401, (c, j))
c, j = req("get_items.php", data={"api_token": OLD_TOKEN})
check("form gövdesindeki token kabul edilmiyor", c == 401, (c, j))
c, j = req("create_poll.php", json_body={"api_token": OLD_TOKEN, "question": "x", "options": ["a", "b"]})
check("JSON gövdesindeki token kabul edilmiyor", c == 401 and sql("SELECT COUNT(*) FROM polls") == "0", (c, j))
c, j = req("get_profile.php", token="yanlis")
check("geçersiz token -> 401", c == 401, c)
c, text, ctype = req("get_profile.php", token=OLD_TOKEN, raw=True)
check("yanıt Content-Type JSON", "application/json" in ctype, ctype)

print("2) Giriş: çoklu cihaz + deneme sınırı")
c, j = req("login.php", data={"email": "eski@example.com", "password": "EskiSifre123"})
check("doğru şifreyle giriş", j.get("status") == "success" and len(j.get("api_token", "")) == 64, j)
tokB = j.get("api_token")
check("yeni cihaz token'ı eski token'dan farklı", tokB != OLD_TOKEN)
c, j = req("get_profile.php", token=OLD_TOKEN)
check("ikinci girişten sonra ilk cihaz hâlâ açık", j.get("status") == "success", j)
check("veritabanında düz token yok", sql(f"SELECT COUNT(*) FROM api_tokens WHERE token_hash = '{tokB}'") == "0")
c, j = req("login.php", data={"email": "yok@example.com", "password": "x"})
check("kayıtsız e-posta -> aynı genel mesaj", j.get("message") == "Mail veya şifre hatalı", j)
for i in range(10):
    req("login.php", data={"email": "eski@example.com", "password": f"yanlis{i}"})
c, j = req("login.php", data={"email": "eski@example.com", "password": "EskiSifre123"})
check("10 hatalı denemeden sonra doğru şifre bile engelli", "Çok fazla" in j.get("message", ""), j)
check("engel cevabı HTTP 200 (eski uygulama mesajı gösterebilsin)", c == 200, c)
sql("DELETE FROM auth_attempts")

print("3) Kayıt + e-posta doğrulama")
c, j = req("register.php", data={"house_name": "Test Evi", "email": "kayit@example.com", "password": "kisa"})
check("8 karakterden kısa şifre reddedildi", "en az 8" in j.get("message", ""), j)
c, j = req("register.php", data={"house_name": "Test Evi", "email": "kayit@example.com", "password": "GuzelSifre1"})
check("kayıt başarılı", j.get("status") == "success", j)
tok, subj = last_mail_link("kayit@example.com", "verify_email")
check("doğrulama maili gitti", tok is not None, subj)
check("DB'de doğrulama token'ı hash'li", sql(f"SELECT verification_token = SHA2('{tok}',256) FROM users WHERE email='kayit@example.com'") == "1")
c, j = req("login.php", data={"email": "kayit@example.com", "password": "GuzelSifre1"})
check("doğrulamadan giriş engelli", "doğrulamanız" in j.get("message", ""), j)
c, text, ctype = req("verify_email.php", get={"token": tok}, raw=True)
check("doğrulama linki çalışıyor", "doğrulandı" in text, text[:120])
c, text, _ = req("verify_email.php", get={"token": tok}, raw=True)
check("doğrulama linki tek kullanımlık", "geçersiz" in text, text[:120])
c, j = req("login.php", data={"email": "kayit@example.com", "password": "GuzelSifre1"})
check("doğrulandıktan sonra giriş", j.get("status") == "success", j)
tokC = j.get("api_token")
c, j = req("register.php", data={"house_name": "Saldirgan", "email": "kayit@example.com", "password": "BaskaSifre1"})
check("kayıtlı e-posta: 'zaten kayıtlı' demiyor (enumeration yok)", j.get("status") == "success", j)
_, subj = last_mail_link("kayit@example.com", "x")
check("gerçek sahibine 'hesabınız zaten var' maili", subj == "Homepal hesabınız zaten var", subj)
c, j = req("login.php", data={"email": "kayit@example.com", "password": "GuzelSifre1"})
check("tekrar kayıt denemesi şifreyi değiştirmedi", j.get("status") == "success", j)
c, j = req("register.php", data={"house_name": "Yeni Ad", "email": "yeni@example.com", "password": "SonSifre123"})
tok2, _ = last_mail_link("yeni@example.com", "verify_email")
req("verify_email.php", get={"token": tok2}, raw=True)
c, j = req("login.php", data={"email": "yeni@example.com", "password": "SonSifre123"})
check("doğrulanmamış hesaba tekrar kayıt: son şifre geçerli (ön-ele geçirme yok)", j.get("status") == "success", j)
sql("DELETE FROM auth_attempts")

print("4) Şifremi unuttum + sıfırlama")
c, j = req("forgot_password.php", data={"email": "kayit@example.com"})
check("genel cevap", j.get("status") == "success", j)
rtok, _ = last_mail_link("kayit@example.com", "reset_password")
check("sıfırlama maili gitti, DB'de hash'li", rtok and sql(f"SELECT reset_token = SHA2('{rtok}',256) FROM users WHERE email='kayit@example.com'") == "1")
c, text, ctype = req("reset_password.php", get={"token": rtok}, raw=True)
check("sıfırlama formu açılıyor", "Yeni Şifre Belirle" in text and "text/html" in ctype)
c, text, _ = req("reset_password.php?token=" + rtok, data={"token": rtok, "new_password": "YeniSifre99", "confirm_password": "Farkli999"}, raw=True)
check("şifreler eşleşmiyor hatası", "eşleşmiyor" in text)
c, text, _ = req("reset_password.php?token=" + rtok, data={"token": rtok, "new_password": "<script>alert(1)</script>", "confirm_password": "farkli12345"}, raw=True)
check("form XSS'e kapalı (girdi sayfaya basılmıyor)", "<script>" not in text and "eşleşmiyor" in text)
c, text, _ = req("reset_password.php?token=" + rtok, data={"token": rtok, "new_password": "YeniSifre99", "confirm_password": "YeniSifre99"}, raw=True)
check("şifre güncellendi", "başarıyla güncellendi" in text, text[-200:])
c, j = req("get_profile.php", token=tokC)
check("sıfırlamadan sonra eski oturumlar kapandı", c == 401, (c, j))
c, text, _ = req("reset_password.php", get={"token": rtok}, raw=True)
check("sıfırlama linki tek kullanımlık", "geçersiz" in text)
c, j = req("login.php", data={"email": "kayit@example.com", "password": "YeniSifre99"})
check("yeni şifreyle giriş", j.get("status") == "success", j)
tokC = j.get("api_token")
assert tokC, "yeni şifreyle giriş başarısız, sonraki testler anlamsız"
for i in range(4):
    req("forgot_password.php", data={"email": "kayit@example.com"})
n = sum(1 for l in open(MAILS, encoding="utf-8") if "reset_password" in l and "kayit@" in l)
check("şifremi unuttum: saatte en fazla 3 mail", n == 3, n)
sql("DELETE FROM auth_attempts")

print("5) Şifre değiştirme")
c, j = req("login.php", data={"email": "kayit@example.com", "password": "YeniSifre99"})
tokC2 = j.get("api_token")
c, j = req("change_password.php", data={"current_password": "yanlis", "new_password": "DahaYeni123"}, token=tokC)
check("yanlış mevcut şifre reddedildi", j.get("message") == "Mevcut şifre hatalı", j)
c, j = req("change_password.php", data={"current_password": "YeniSifre99", "new_password": "DahaYeni123"}, token=tokC)
check("şifre değişti", j.get("status") == "success", j)
c, _ = req("get_profile.php", token=tokC)
check("bu cihaz açık kaldı", c == 200)
c, _ = req("get_profile.php", token=tokC2)
check("diğer cihazın oturumu kapandı", c == 401)

print("6) Başka evin verisine erişim (IDOR)")
req("add_item.php", data={"item_name": "Süt"}, token=OLD_TOKEN)
item_id = sql("SELECT id FROM shopping_list WHERE user_id = 1 ORDER BY id DESC LIMIT 1")
for ep in ["delete_item.php", "update_item.php"]:
    c, j = req(ep, data={"id": item_id, "is_bought": "1"}, token=tokC)
    check(f"{ep}: başka evin ürünü değiştirilemiyor", j.get("message") == "Ürün bulunamadı", j)
check("ürün yerinde ve değişmemiş", sql(f"SELECT is_bought FROM shopping_list WHERE id = {item_id}") == "0")
c, j = req("delete_member.php", data={"id": "1"}, token=tokC)
check("başka evin üyesi silinemiyor", j.get("message") == "Üye bulunamadı", j)
c, j = req("add_chore.php", data={"assigned_to_id": "1", "task_name": "x"}, token=tokC)
check("başka evin üyesine görev atanamıyor", j.get("message") == "Geçersiz üye", j)
c, j = req("update_item.php", data={"id": item_id, "is_bought": "1"}, token=OLD_TOKEN)
check("kendi ürününü işaretleyebiliyor", j.get("status") == "success" and sql(f"SELECT is_bought FROM shopping_list WHERE id = {item_id}") == "1", j)
c, j = req("update_item.php", data={"id": item_id, "is_bought": "1"}, token=OLD_TOKEN)
check("aynı değeri tekrar göndermek hata vermiyor", j.get("status") == "success", j)
c, j = req("delete_item.php", data={"id": item_id}, token=OLD_TOKEN)
check("kendi ürününü silebiliyor", j.get("status") == "success", j)

print("7) Girdi doğrulama")
c, j = req("add_chore.php", data={"assigned_to_id": "1", "task_name": "x" * 256}, token=OLD_TOKEN)
check("256 karakterlik görev reddedildi", "en fazla 255" in j.get("message", ""), j)
c, j = req("add_chore.php", data={"assigned_to_id": "1", "task_name": "ğ" * 255}, token=OLD_TOKEN)
check("255 Türkçe karakter kabul (bayt değil karakter sayılıyor)", j.get("status") == "success", j)
c, j = req("add_item.php", data={"item_name[]": "x"}, token=OLD_TOKEN)
check("dizi parametre reddedildi", j.get("status") == "error", j)
c, j = req("delete_item.php", data={"id": "1 OR 1=1"}, token=OLD_TOKEN)
check("sayısal olmayan id reddedildi", j.get("status") == "error", j)
c, j = req("add_info.php", data={"title": "Wi-Fi 🔑", "value": "şifre"}, token=OLD_TOKEN)
c, d = req("get_home_details.php", token=OLD_TOKEN)
check("emoji kaydediliyor (utf8mb4)", any(i["title"] == "Wi-Fi 🔑" for i in d.get("infos", [])), d)

print("8) Anket")
c, j = req("create_poll.php", json_body={"question": "Ne yiyelim?", "options": [str(i) for i in range(11)]}, token=OLD_TOKEN)
check("11 seçenek reddedildi", "en fazla 10" in j.get("message", "").lower(), j)
c, j = req("create_poll.php", json_body={"question": "Ne yiyelim?", "options": ["Pizza", ""]}, token=OLD_TOKEN)
check("boş seçenek reddedildi", j.get("status") == "error", j)
c, j = req("create_poll.php", json_body={"question": "Ne yiyelim?", "options": ["Pizza", "Döner"]}, token=OLD_TOKEN)
check("anket oluştu (açanı göndermeyen eski sürüm)", j.get("status") == "success", j)
c, j = req("get_active_poll.php", get={"member_id": "1"}, token=OLD_TOKEN)
check("aktif anket okunuyor", j.get("question") == "Ne yiyelim?", j)
poll_id, opt_id = j.get("poll_id"), j["options"][0]["id"]
c, j = req("vote_poll.php", data={"poll_id": poll_id, "option_id": opt_id, "member_id": "1"}, token=OLD_TOKEN)
check("oy verildi", j.get("status") == "success", j)
c, j = req("vote_poll.php", data={"poll_id": poll_id, "option_id": opt_id, "member_id": "1"}, token=OLD_TOKEN)
check("aynı seçeneğe ikinci oy hata vermiyor", j.get("status") == "success", j)
c, j = req("get_active_poll.php", get={"member_id": "1"}, token=OLD_TOKEN)
check("ikinci oy sayılmadı (sayaç 1'de kaldı)", int(j["options"][0]["vote_count"]) == 1, j)

print("9) Bildirim token'ı (cihaz başına)")
c, j = req("update_member_token.php", data={"member_id": "1", "fcm_token": "tokB"}, token=OLD_TOKEN)
check("aynı kişinin ikinci cihazı eklendi, ilki duruyor", j.get("status") == "success" and devices(1) == "tokA,tokB", (j, devices(1)))
c, j = req("update_member_token.php", data={"member_id": "1", "fcm_token": "tokB"}, token=OLD_TOKEN)
check("aynı token'ı tekrar kaydetmek çift kayıt açmıyor", j.get("status") == "success" and devices(1) == "tokA,tokB", devices(1))
req("update_member_token.php", data={"member_id": "2", "fcm_token": "tokA"}, token=OLD_TOKEN)
check("profil değişince cihaz yeni üyeye taşındı", devices(1) == "tokB" and devices(2) == "tokA", (devices(1), devices(2)))
c, j = req("get_members.php", token=OLD_TOKEN)
check("üye listesinde fcm_token dönmüyor", isinstance(j, list) and j and "fcm_token" not in j[0], j)
c, j = req("update_member_token.php", data={"member_id": "1", "fcm_token": "tokB", "enabled": "0"}, token=OLD_TOKEN)
check("bildirimi kapatan cihaz silindi, diğer üyeninki duruyor", j.get("status") == "success" and devices(1) == "-" and devices(2) == "tokA", (j, devices(2)))
c, j = req("update_member_token.php", data={"member_id": "2", "fcm_token": ""}, token=OLD_TOKEN)
check("eski sürümün boş token'ı üyenin cihazlarını siliyor", j.get("status") == "success" and devices(2) == "-", devices(2))
for bad in ("şifre", "x" * 1025, "a b"):
    c, j = req("update_member_token.php", data={"member_id": "1", "fcm_token": bad}, token=OLD_TOKEN)
    check(f"geçersiz token reddedildi ({bad[:8]})", j.get("message") == "Geçersiz token", j)

print("10) Çıkış")
c, j = req("logout.php", token=tokC)
check("logout başarılı", j.get("status") == "success", j)
c, _ = req("get_profile.php", token=tokC)
check("logout sonrası token geçersiz", c == 401)

print("11) Ortak token'ın cihaza özel token'la değiştirilmesi (renew_token)")
c, j = req("renew_token.php", token=OLD_TOKEN); dev = j.get("api_token")
check("ortak token ile yenileme -> yeni cihaz token'ı", j.get("status") == "success" and dev and dev != OLD_TOKEN, j)
c, _ = req("get_profile.php", token=dev); check("yeni cihaz token'ı çalışıyor", c == 200)
c, _ = req("get_profile.php", token=OLD_TOKEN); check("ortak token henüz yenilemeyen cihazlarda hâlâ çalışıyor", c == 200)
c, j = req("logout.php", token=dev); check("cihaz token'ı ile çıkış", j.get("status") == "success", j)
c, _ = req("get_profile.php", token=OLD_TOKEN); check("çıkış ortak token kullanan diğer cihazları etkilemedi", c == 200)
c, _ = req("renew_token.php"); check("token'sız yenileme -> 401", c == 401, c)
sql("DELETE FROM auth_attempts")

print("12) Doğrulama mailini tekrar gönderme")
req("register.php", data={"house_name": "Dogrula Evi", "email": "dogrula@example.com", "password": "DogrulaSifre1"})
first, _ = last_mail_link("dogrula@example.com", "verify_email")
c, j = req("login.php", data={"email": "dogrula@example.com", "password": "DogrulaSifre1"})
check("doğrulanmamış girişte makine kodu: email_not_verified", j.get("code") == "email_not_verified", j)
c, j = req("resend_verification.php", data={"email": "dogrula@example.com"})
second, subj = last_mail_link("dogrula@example.com", "verify_email")
check("yeni doğrulama maili gönderildi", j.get("status") == "success" and second and second != first, (j, subj))
c, text, _ = req("verify_email.php", get={"token": first}, raw=True)
check("eski doğrulama linki artık geçersiz", "geçersiz" in text)
c, text, _ = req("verify_email.php", get={"token": second}, raw=True)
check("yeni doğrulama linki çalışıyor", "doğrulandı" in text)
before = sum(1 for _ in open(MAILS, encoding="utf-8"))
c, j1 = req("resend_verification.php", data={"email": "dogrula@example.com"})
c, j2 = req("resend_verification.php", data={"email": "hic-yok@example.com"})
after = sum(1 for _ in open(MAILS, encoding="utf-8"))
check("doğrulanmış/kayıtsız adrese mail gitmiyor", after == before, (before, after))
check("kayıtlı/kayıtsız ayırt edilemiyor (aynı cevap)", j1 == j2, (j1, j2))
sql("DELETE FROM auth_attempts")

print("13) Anket: profil seçilmeden görüntüleme ve 24 saatlik süre")
sql("DELETE FROM polls")  # 8. bölümün anketi açık kalıyor (yeni anket eskisini artık silmiyor)
req("create_poll.php", json_body={"question": "Hafta sonu?", "options": ["Sinema", "Piknik"]}, token=OLD_TOKEN)
c, j = req("get_active_poll.php", get={"member_id": "0"}, token=OLD_TOKEN)
check("profil seçmeden anket görünüyor", j.get("question") == "Hafta sonu?" and j.get("has_voted") is False, j)
check("kalan süre ~24 saat", 1430 <= int(j.get("minutes_left", 0)) <= 1440, j.get("minutes_left"))
poll_id, opt_id = j.get("poll_id"), j["options"][0]["id"]
sql(f"UPDATE polls SET created_at = NOW() - INTERVAL 25 HOUR, ends_at = NOW() - INTERVAL 1 HOUR WHERE id = {poll_id}")
c, j = req("get_active_poll.php", get={"member_id": "1"}, token=OLD_TOKEN)
check("süresi dolan anket gösterilmiyor (temizlik çalışmamış olsa da)", j.get("status") == "empty", j)
c, j = req("vote_poll.php", data={"poll_id": poll_id, "option_id": opt_id, "member_id": "1"}, token=OLD_TOKEN)
check("süresi dolan ankete oy verilemiyor", j.get("message") == "Anket sona erdi", j)

print("14) Uygulama içinden hesap silme")
req("register.php", data={"house_name": "Silinecek Ev", "email": "silinecek@example.com", "password": "SilSifre123"})
vt, _ = last_mail_link("silinecek@example.com", "verify_email"); req("verify_email.php", get={"token": vt}, raw=True)
c, j = req("login.php", data={"email": "silinecek@example.com", "password": "SilSifre123"}); tokD = j.get("api_token")
req("add_member.php", data={"name": "Zeynep"}, token=tokD)
req("add_item.php", data={"item_name": "Peynir"}, token=tokD)
hid = sql("SELECT id FROM users WHERE email = 'silinecek@example.com'")
c, j = req("delete_account.php", data={"password": "yanlis-sifre"}, token=tokD)
check("yanlış şifreyle silinmiyor", j.get("message") == "Şifre hatalı" and sql(f"SELECT COUNT(*) FROM users WHERE id = {hid}") == "1", j)
c, j = req("delete_account.php", data={"password": "SilSifre123"}, token=tokD)
check("doğru şifreyle hesap silindi", j.get("status") == "success", j)
check("kullanıcı kaydı yok", sql(f"SELECT COUNT(*) FROM users WHERE id = {hid}") == "0")
check("bağlı veriler de silindi (üye, liste, oturum)",
      sql(f"SELECT (SELECT COUNT(*) FROM home_members WHERE house_id = {hid}) + (SELECT COUNT(*) FROM shopping_list WHERE user_id = {hid}) + (SELECT COUNT(*) FROM api_tokens WHERE user_id = {hid})") == "0")
c, _ = req("get_profile.php", token=tokD); check("silinen hesabın token'ı geçersiz", c == 401, c)
_, subj = last_mail_link("silinecek@example.com", "x"); check("hesap silindi bilgilendirme maili", subj == "Homepal hesabınız silindi", subj)
check("diğer hesaplar etkilenmedi", sql("SELECT COUNT(*) FROM users WHERE id = 1") == "1")

print("15) Görev ve ürün düzenleme")
req("add_chore.php", data={"assigned_to_id": "1", "task_name": "Bulasik"}, token=OLD_TOKEN)
chore_id = sql("SELECT id FROM house_chores WHERE creator_id = 1 ORDER BY id DESC LIMIT 1")
c, j = req("edit_chore.php", data={"id": chore_id, "task_name": "Bulasik makinesi", "assigned_to_id": "2"}, token=OLD_TOKEN)
check("görevin adı ve sorumlusu değişti", j.get("status") == "success" and sql(f"SELECT CONCAT(task_name, '|', assigned_to_id) FROM house_chores WHERE id = {chore_id}") == "Bulasik makinesi|2", j)
c, j = req("edit_chore.php", data={"id": chore_id, "task_name": "x", "assigned_to_id": "3"}, token=OLD_TOKEN)
check("görev başka evin üyesine aktarılamıyor", j.get("message") == "Geçersiz üye", j)
c, j = req("edit_chore.php", data={"id": chore_id, "task_name": "", "assigned_to_id": "2"}, token=OLD_TOKEN)
check("boş görev adı reddedildi", j.get("message") == "Görev adı gerekli", j)
sql("DELETE FROM auth_attempts")
c, j = req("login.php", data={"email": "kayit@example.com", "password": "DahaYeni123"}); tokE = j.get("api_token")
req("add_member.php", data={"name": "Ece"}, token=tokE)
own_member = sql("SELECT m.id FROM home_members m JOIN users u ON u.id = m.house_id WHERE u.email = 'kayit@example.com' ORDER BY m.id DESC LIMIT 1")
c, j = req("edit_chore.php", data={"id": chore_id, "task_name": "Hack", "assigned_to_id": own_member}, token=tokE)
check("başka evin görevi düzenlenemiyor", j.get("message") == "Görev bulunamadı" and sql(f"SELECT task_name FROM house_chores WHERE id = {chore_id}") == "Bulasik makinesi", j)
req("add_item.php", data={"item_name": "Sut"}, token=OLD_TOKEN)
item_id = sql("SELECT id FROM shopping_list WHERE user_id = 1 ORDER BY id DESC LIMIT 1")
c, j = req("edit_item.php", data={"id": item_id, "item_name": "Sut 2 litre"}, token=OLD_TOKEN)
check("ürün adı değişti", j.get("status") == "success" and sql(f"SELECT item_name FROM shopping_list WHERE id = {item_id}") == "Sut 2 litre", j)
c, j = req("edit_item.php", data={"id": item_id, "item_name": "Sut 2 litre"}, token=OLD_TOKEN)
check("aynı adı tekrar kaydetmek hata vermiyor", j.get("status") == "success", j)
c, j = req("edit_item.php", data={"id": item_id, "item_name": "Hack"}, token=tokE)
check("başka evin ürünü düzenlenemiyor", j.get("message") == "Ürün bulunamadı" and sql(f"SELECT item_name FROM shopping_list WHERE id = {item_id}") == "Sut 2 litre", j)
c, j = req("edit_item.php", data={"id": item_id, "item_name": "x" * 256}, token=OLD_TOKEN)
check("256 karakterlik ürün adı reddedildi", "en fazla 255" in j.get("message", ""), j)

print("16) Tekrarlayan görevler")
migration = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "migrations", "2026-10-27_recurring_chores.sql")
with open(migration, "rb") as f:
    rc = subprocess.run(MYSQL[:-2], stdin=f, capture_output=True).returncode
check("migration hazır tabloda tekrar çalıştırılabiliyor", rc == 0, rc)
# Sunucu günleri Türkiye saatiyle hesaplıyor (UTC+3, yaz saati yok)
today = datetime.datetime.now(datetime.timezone(datetime.timedelta(hours=3))).date()
yesterday = (today - datetime.timedelta(days=1)).isoformat()
def chore_row(cid):
    return sql(f"SELECT CONCAT_WS('|', is_done, assigned_to_id, IFNULL(next_due, '-')) FROM house_chores WHERE id = {cid}")
def run_cron():
    return subprocess.run([PHP, "-d", "display_errors=0", os.path.join(API_DIR, "cleanup_polls.php")], capture_output=True, text=True, encoding="utf-8").stdout
def next_date(every, start, after):
    helper = os.path.join(API_DIR, "chores_helper.php").replace("\\", "/")
    code = f"require '{helper}'; echo nextChoreDate('{every}', '{start}', new DateTimeImmutable('{after}', choreTimezone()));"
    return subprocess.run([PHP, "-r", code], capture_output=True, text=True).stdout

c, j = req("add_chore.php", data={"assigned_to_id": "1", "task_name": "Cop", "repeat": "yearly"}, token=OLD_TOKEN)
check("geçersiz tekrar seçeneği reddedildi", j.get("message") == "Geçersiz tekrar seçeneği", j)
c, j = req("add_chore.php", data={"assigned_to_id": "1", "task_name": "Cop", "repeat": "week", "rotate": "1"}, token=OLD_TOKEN)
rid = sql("SELECT id FROM house_chores WHERE creator_id = 1 ORDER BY id DESC LIMIT 1")
check("haftalık, sırayla dönen görev eklendi",
      j.get("status") == "success" and sql(f"SELECT CONCAT_WS('|', repeat_every, repeat_start, rotate) FROM house_chores WHERE id = {rid}") == f"week|{today}|1", j)
req("add_chore.php", data={"assigned_to_id": "1", "task_name": "Tek seferlik"}, token=OLD_TOKEN)
oid = sql("SELECT id FROM house_chores WHERE creator_id = 1 ORDER BY id DESC LIMIT 1")
check("tekrar seçmeyen (eski) istemcinin görevi tek seferlik", sql(f"SELECT CONCAT_WS('|', IFNULL(repeat_every, '-'), rotate) FROM house_chores WHERE id = {oid}") == "-|0")

req("update_chore.php", data={"id": rid}, token=OLD_TOKEN)
check("tamamlanınca bir hafta sonrasına kuruldu", chore_row(rid) == f"1|1|{today + datetime.timedelta(days=7)}", chore_row(rid))
req("update_chore.php", data={"id": oid}, token=OLD_TOKEN)
check("tek seferlik görevin tekrar günü yok", chore_row(oid) == "1|1|-", chore_row(oid))
req("get_chores.php", token=OLD_TOKEN)
check("günü gelmeden yeniden açılmıyor", chore_row(rid).startswith("1|"), chore_row(rid))

sql(f"UPDATE house_chores SET next_due = '{yesterday}' WHERE id = {rid}")
c, j = req("get_chores.php", token=OLD_TOKEN)
check("günü gelince liste çekilirken açıldı ve sıradakine (Ayse) geçti", chore_row(rid) == "0|2|-", chore_row(rid))
check("listede tekrar bilgisi dönüyor", any(str(x.get("id")) == rid and x.get("repeat_every") == "week" for x in j), j)
req("update_chore.php", data={"id": rid}, token=OLD_TOKEN)
sql(f"UPDATE house_chores SET next_due = '{yesterday}' WHERE id = {rid}")
out = run_cron()
check("cron açtı, sıra başa (Ahmet) döndü", chore_row(rid) == "0|1|-" and "Yeniden açılan görev: 1" in out, (chore_row(rid), out))
check("tek seferlik görev cron'da açılmadı", chore_row(oid).startswith("1|"), chore_row(oid))

c, j = req("edit_chore.php", data={"id": rid, "task_name": "Copu cikar", "assigned_to_id": "1"}, token=OLD_TOKEN)
check("tekrar göndermeyen (1.2.0) düzenleme ayarı bozmuyor",
      sql(f"SELECT CONCAT_WS('|', task_name, repeat_every, repeat_start, rotate) FROM house_chores WHERE id = {rid}") == f"Copu cikar|week|{today}|1")
req("edit_chore.php", data={"id": oid, "task_name": "Tek seferlik", "assigned_to_id": "1", "repeat": "day"}, token=OLD_TOKEN)
check("tamamlanmış görev günlüğe çevrilince yarın açılacak",
      sql(f"SELECT CONCAT_WS('|', repeat_every, rotate, next_due) FROM house_chores WHERE id = {oid}") == f"day|0|{today + datetime.timedelta(days=1)}")
req("edit_chore.php", data={"id": oid, "task_name": "Tek seferlik", "assigned_to_id": "1", "repeat": "none", "rotate": "1"}, token=OLD_TOKEN)
check("tekrar kapatılınca görev tek seferliğe döndü",
      sql(f"SELECT CONCAT_WS('|', IFNULL(repeat_every, '-'), IFNULL(repeat_start, '-'), rotate, IFNULL(next_due, '-')) FROM house_chores WHERE id = {oid}") == "-|-|0|-")

req("add_member.php", data={"name": "Cem"}, token=OLD_TOKEN)
cem = sql("SELECT id FROM home_members WHERE house_id = 1 ORDER BY id DESC LIMIT 1")
req("edit_chore.php", data={"id": rid, "task_name": "Copu cikar", "assigned_to_id": cem, "repeat": "week", "rotate": "1"}, token=OLD_TOKEN)
req("delete_member.php", data={"id": cem}, token=OLD_TOKEN)
check("sırası gelen kişi silinince görev sıradakine geçti", chore_row(rid) == "0|1|-", chore_row(rid))

check("aylık: ayın 31'i şubatta son güne düşer", next_date("month", "2026-01-31", "2026-01-31") == "2026-02-28")
check("aylık: sonra yine 31'ine döner", next_date("month", "2026-01-31", "2026-02-28") == "2026-03-31")
check("haftalık: geç tamamlansa da aynı gün açılır", next_date("week", "2026-10-05", "2026-10-20") == "2026-10-26")
check("günlük: yarın açılır", next_date("day", "2026-10-27", "2026-10-27") == "2026-10-28")
sql(f"DELETE FROM house_chores WHERE id IN ({rid}, {oid})")

print("17) Anket: süre seçimi, erken bitirme, oy değiştirme")
# Migration'ı eski biçimdeki bir tabloda (is_active/vote_count, ends_at yok) dene
sql("DELETE FROM polls")
sql("ALTER TABLE polls DROP COLUMN ends_at, DROP COLUMN created_by, ADD COLUMN is_active tinyint(1) DEFAULT '1'")
sql("ALTER TABLE poll_options ADD COLUMN vote_count int DEFAULT '0'")
sql("INSERT INTO polls (house_id, question, created_at) VALUES (1, 'Eski anket', NOW() - INTERVAL 2 HOUR)")
migration = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "migrations", "2026-10-27_poll_improvements.sql")
for attempt in ("ilk", "ikinci"):
    with open(migration, "rb") as f:
        rc = subprocess.run(MYSQL[:-2], stdin=f, capture_output=True).returncode
    check(f"migration {attempt} çalıştırmada hatasız", rc == 0, rc)
check("mevcut anketin bitişi açılıştan 24 saat sonraya kuruldu",
      sql("SELECT TIMESTAMPDIFF(HOUR, created_at, ends_at) FROM polls WHERE question = 'Eski anket'") == "24")
check("kullanılmayan kolonlar kaldırıldı", sql(
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'homepal_test' AND "
    "((table_name = 'polls' AND column_name = 'is_active') OR (table_name = 'poll_options' AND column_name = 'vote_count'))") == "0")
c, j = req("get_active_poll.php", get={"member_id": "1"}, token=OLD_TOKEN)
check("migration öncesi açılan anket kalan süresiyle görünüyor", j.get("question") == "Eski anket" and 1315 <= int(j.get("minutes_left", 0)) <= 1320, j)

for bad in (0, 169, "abc"):
    c, j = req("create_poll.php", json_body={"question": "Film?", "options": ["A", "B"], "duration_hours": bad}, token=OLD_TOKEN)
    check(f"geçersiz süre ({bad}) reddedildi", j.get("message") == "Geçersiz anket süresi", j)
c, j = req("create_poll.php", json_body={"question": "Film?", "options": ["A", "B"], "member_id": 3}, token=OLD_TOKEN)
check("başka evin üyesi anket açan olarak verilemiyor", j.get("message") == "Geçersiz üye", j)
c, j = req("create_poll.php", json_body={"question": "Film?", "options": ["Komedi", "Korku", "Dram"], "duration_hours": 1, "member_id": 1}, token=OLD_TOKEN)
check("1 saatlik anket açıldı, eski anket de yerinde", j.get("status") == "success" and sql("SELECT COUNT(*) FROM polls WHERE house_id = 1") == "2", j)
pid = j.get("poll_id")
check("yeni anketin numarası dönüyor", isinstance(pid, int), j)
c, j = req("get_active_poll.php", get={"member_id": "2", "include_closed": "1"}, token=OLD_TOKEN)
check("eski sürüme en son açılan açık anket gidiyor", str(j.get("poll_id")) == str(pid), j)
sql("DELETE FROM polls WHERE question = 'Eski anket'")
c, j = req("get_active_poll.php", get={"member_id": "2", "include_closed": "1"}, token=OLD_TOKEN)
members = int(sql("SELECT COUNT(*) FROM home_members WHERE house_id = 1"))
check("açık, ~1 saat kaldı; açan kişi ve üye sayısı dönüyor",
      j.get("is_open") is True and 59 <= j.get("minutes_left", 0) <= 60 and j.get("created_by") == 1
      and j.get("created_by_name") == "Ahmet" and j.get("member_count") == members, j)
opts = [o["id"] for o in j["options"]]
def poll_counts(poll=None):
    # 1.3.0'ın gördüğü hâli (get_polls.php); anket listede yoksa {}
    c, j = req("get_polls.php", get={"member_id": "2"}, token=OLD_TOKEN)
    p = next((p for p in j.get("polls", []) if str(p["poll_id"]) == str(poll or pid)), {})
    return p, [int(o["vote_count"]) for o in p.get("options", [])]

req("vote_poll.php", data={"poll_id": pid, "option_id": opts[0], "member_id": "1"}, token=OLD_TOKEN)
req("vote_poll.php", data={"poll_id": pid, "option_id": opts[0], "member_id": "2"}, token=OLD_TOKEN)
c, j = req("vote_poll.php", data={"poll_id": pid, "option_id": opts[1], "member_id": "2"}, token=OLD_TOKEN)
j2, counts = poll_counts()
check("oy değiştirildi, sayılar tutarlı", j.get("status") == "success" and counts == [1, 1, 0]
      and str(j2.get("voted_option_id")) == str(opts[1]), (j, j2))

c, j = req("end_poll.php", data={"poll_id": pid, "member_id": "1"}, token=tokE)
check("başka evin anketi bitirilemiyor", j.get("status") == "error" and poll_counts()[0].get("is_open") is True, j)
c, j = req("end_poll.php", data={"poll_id": pid, "member_id": "2"}, token=OLD_TOKEN)
check("açan kişi dışındaki üye bitiremiyor", j.get("message") == "Anketi sadece açan kişi bitirebilir", j)
c, j = req("end_poll.php", data={"poll_id": pid}, token=OLD_TOKEN)
check("üye seçilmeden bitirilemiyor", j.get("message") == "Anketi sadece açan kişi bitirebilir", j)
c, j = req("create_poll.php", json_body={"question": "Baska?", "options": ["X", "Y"], "member_id": 2}, token=OLD_TOKEN)
check("başka üye de anket açabiliyor, açık anket yerinde", j.get("status") == "success" and poll_counts()[0].get("is_open") is True, j)
c, j = req("create_poll.php", json_body={"question": "Baska?", "options": ["X", "Y"]}, token=OLD_TOKEN)
check("eski sürümün açtığı anket de açık anketi silmiyor", j.get("status") == "success" and poll_counts()[0].get("is_open") is True, j)
c, j = req("end_poll.php", data={"poll_id": pid, "member_id": "1"}, token=OLD_TOKEN)
check("açan kişi erken bitirdi", j.get("status") == "success", j)
c, j = req("end_poll.php", data={"poll_id": pid, "member_id": "2"}, token=OLD_TOKEN)
check("bitmiş anketi tekrar bitirmek hata vermiyor", j.get("status") == "success", j)
c, j = req("vote_poll.php", data={"poll_id": pid, "option_id": opts[2], "member_id": "1"}, token=OLD_TOKEN)
check("biten ankete oy verilemiyor", j.get("message") == "Anket sona erdi", j)
j2, counts = poll_counts()
check("biten anket sonuçlarıyla görünüyor (1.3.0+)", j2.get("is_open") is False and j2.get("minutes_left") == 0 and counts == [1, 1, 0], j2)
check("biten anketin silinmesine ~24 saat var", 1435 <= j2.get("result_minutes_left", 0) <= 1440, j2.get("result_minutes_left"))
c, j = req("get_active_poll.php", get={"member_id": "1"}, token=OLD_TOKEN)
check("eski sürüme biten anket gösterilmiyor", j.get("status") == "success" and str(j.get("poll_id")) != str(pid), j)

sql(f"UPDATE polls SET ends_at = NOW() - INTERVAL 25 HOUR WHERE id = {pid}")
check("bitişinden 24 saat sonra sonuç da kalkıyor", poll_counts()[0] == {})
req("create_poll.php", json_body={"question": "Kalsin mi?", "options": ["Evet", "Hayir"]}, token=tokE)
out = run_cron()
check("cron eski sonucu sildi, açık ankete dokunmadı",
      "Silinen anket sayısı: 1" in out and sql(f"SELECT COUNT(*) FROM polls WHERE id = {pid}") == "0"
      and sql("SELECT COUNT(*) FROM polls WHERE question = 'Kalsin mi?'") == "1", out)
c, j = req("create_poll.php", json_body={"question": "Sahipsiz", "options": ["X", "Y"]}, token=OLD_TOKEN)
pid = j.get("poll_id")
c, j = req("end_poll.php", data={"poll_id": pid}, token=OLD_TOKEN)
check("açanı belli olmayan (eski sürüm) anketi herkes bitirebiliyor", j.get("status") == "success" and poll_counts()[0].get("is_open") is False, j)

print("18) Birden fazla anket, silme, bitiş bildirimi ve çoklu cihaz")
# Önce migration: eski biçimde (üyede tek fcm_token, end_notified yok) iki kez
sql("DELETE FROM polls"); sql("DELETE FROM member_devices")
sql("ALTER TABLE polls DROP COLUMN end_notified")
sql("ALTER TABLE home_members ADD COLUMN fcm_token text")
sql("UPDATE home_members SET fcm_token = CASE id WHEN 1 THEN 'eskiTok1' WHEN 2 THEN 'eskiTok2' END WHERE id IN (1, 2)")
sql("INSERT INTO polls (house_id, question, ends_at) VALUES (1, 'Bitmis', NOW() - INTERVAL 1 HOUR), (1, 'Acik', NOW() + INTERVAL 1 HOUR)")
migration = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "migrations", "2026-10-29_polls_and_devices.sql")
def run_migration():
    with open(migration, "rb") as f:
        return subprocess.run(MYSQL[:-2], stdin=f, capture_output=True)
r = run_migration()
check("migration ilk çalıştırmada hatasız", r.returncode == 0, r.stderr)
check("üyelerdeki token'lar cihaz tablosuna taşındı", devices(1) == "eskiTok1" and devices(2) == "eskiTok2", (devices(1), devices(2)))
check("üyedeki eski token kolonu kaldırıldı", sql(
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'homepal_test' AND table_name = 'home_members' AND column_name = 'fcm_token'") == "0")
check("bu sürümden önce açılmış anketler (açık olan da) bitiş bildirimi göndermeyecek",
      sql("SELECT GROUP_CONCAT(CONCAT(question, '=', end_notified) ORDER BY question) FROM polls") == "Acik=1,Bitmis=1")
sql("INSERT INTO polls (house_id, question, ends_at) VALUES (1, 'Sonradan', NOW() + INTERVAL 1 HOUR)")
r = run_migration()
check("migration ikinci çalıştırmada hatasız, sonradan açılan anketin bildirimi duruyor",
      r.returncode == 0 and sql("SELECT end_notified FROM polls WHERE question = 'Sonradan'") == "0", r.stderr)
sql("DELETE FROM polls"); sql("DELETE FROM member_devices")

# Kullanılmayan users.api_token kolonu (1.0.2'nin ortak token'ı) kaldırılıyor
sql("ALTER TABLE users ADD COLUMN api_token varchar(64) DEFAULT NULL, ADD UNIQUE KEY api_token (api_token)")
legacy = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "migrations", "2026-10-29_drop_legacy_token.sql")
for attempt in ("ilk", "ikinci"):
    with open(legacy, "rb") as f:
        r = subprocess.run(MYSQL[:-2], stdin=f, capture_output=True)
    check(f"eski token kolonu migration'ı {attempt} çalıştırmada hatasız", r.returncode == 0, r.stderr)
check("users.api_token kolonu kaldırıldı", sql(
    "SELECT COUNT(*) FROM information_schema.columns WHERE table_schema = 'homepal_test' AND table_name = 'users' AND column_name = 'api_token'") == "0")
c, _ = req("get_profile.php", token=OLD_TOKEN)
check("ortak token kolon kalkınca da çalışıyor (api_tokens'ta)", c == 200, c)

# Ahmet (1) telefon + tablet, Ayse (2) telefon
for m, t in (("1", "phoneA"), ("1", "tabletA"), ("2", "phoneB")):
    req("update_member_token.php", data={"member_id": m, "fcm_token": t}, token=OLD_TOKEN)
n = len(fcm_log())
c, j = req("create_poll.php", json_body={"question": "Pizza?", "options": ["Evet", "Hayir"], "member_id": 2}, token=OLD_TOKEN)
p1 = j.get("poll_id")
c, j = req("create_poll.php", json_body={"question": "Film?", "options": ["Evet", "Hayir"], "member_id": 1, "duration_hours": 1}, token=OLD_TOKEN)
p2 = j.get("poll_id")
sent = fcm_log()[n:]
check("yeni anket bildirimi açanın hiçbir cihazına gitmiyor, diğer kişinin bütün cihazlarına gidiyor",
      len(sent) == 2 and sorted(sent[0]["tokens"]) == ["phoneA", "tabletA"] and sent[1]["tokens"] == ["phoneB"], sent)
c, j = req("get_polls.php", get={"member_id": "1"}, token=OLD_TOKEN)
check("iki anket birlikte açık, en yakında kapanan başta",
      [str(p["poll_id"]) for p in j.get("polls", [])] == [str(p2), str(p1)] and j.get("member_count") == int(sql("SELECT COUNT(*) FROM home_members WHERE house_id = 1")), j)
c, j = req("get_polls.php", get={"member_id": "3"}, token=OLD_TOKEN)
check("get_polls: başka evin üyesi reddedildi", j.get("message") == "Geçersiz üye", j)
c, j = req("get_polls.php", token=tokE)
check("başka ev bu anketleri görmüyor", all(p["question"] not in ("Pizza?", "Film?") for p in j.get("polls", [])), j)

c, j = req("get_polls.php", get={"member_id": "1"}, token=OLD_TOKEN)
film = next(p for p in j["polls"] if str(p["poll_id"]) == str(p2))
for m in ("1", "2"):
    req("vote_poll.php", data={"poll_id": p2, "option_id": film["options"][0]["id"], "member_id": m}, token=OLD_TOKEN)
n = len(fcm_log())
req("end_poll.php", data={"poll_id": p2, "member_id": "1"}, token=OLD_TOKEN)
sent = fcm_log()[n:]
check("erken bitirince sonuç bildirimi bitirenin cihazlarına gitmiyor",
      len(sent) == 1 and sent[0]["tokens"] == ["phoneB"] and sent[0]["title"] == "Anket sona erdi"
      and sent[0]["body"] == "Film? • Kazanan: Evet (2 oy)" and sent[0]["screen"] == "home", sent)
n = len(fcm_log()); run_cron()
check("cron aynı anket için ikinci bildirim göndermiyor", fcm_log()[n:] == [], fcm_log()[n:])

sql(f"UPDATE polls SET ends_at = NOW() - INTERVAL 1 MINUTE WHERE id = {p1}")
n = len(fcm_log()); out = run_cron(); sent = fcm_log()[n:]
check("süresi dolan anketin sonucu cron'la herkesin cihazlarına gitti",
      len(sent) == 1 and sorted(sent[0]["tokens"]) == ["phoneA", "phoneB", "tabletA"]
      and sent[0]["body"] == "Pizza? • Kimse oy vermedi" and "Bitiş bildirimi giden anket: 1" in out, (sent, out))
check("sonraki cron tekrar göndermiyor", "Bitiş bildirimi giden anket: 0" in run_cron())

c, j = req("create_poll.php", json_body={"question": "Renk?", "options": ["Mavi", "Yesil", "Sari"], "member_id": 1}, token=OLD_TOKEN)
p3 = j.get("poll_id")
c, j = req("get_polls.php", get={"member_id": "1"}, token=OLD_TOKEN)
renk = next(p for p in j["polls"] if str(p["poll_id"]) == str(p3))
req("vote_poll.php", data={"poll_id": p3, "option_id": renk["options"][0]["id"], "member_id": "1"}, token=OLD_TOKEN)
req("vote_poll.php", data={"poll_id": p3, "option_id": renk["options"][1]["id"], "member_id": "2"}, token=OLD_TOKEN)
n = len(fcm_log())
req("end_poll.php", data={"poll_id": p3, "member_id": "1"}, token=OLD_TOKEN)
sent = fcm_log()[n:]
check("beraberlik bildirimde yazıyor", sent and sent[0]["body"] == "Renk? • Berabere: Mavi, Yesil", sent)

c, j = req("delete_poll.php", data={"poll_id": p1, "member_id": "1"}, token=OLD_TOKEN)
check("biten anketi açan dışındaki üye silemiyor", j.get("message") == "Anketi sadece açan kişi silebilir", j)
c, j = req("delete_poll.php", data={"poll_id": p1}, token=OLD_TOKEN)
check("üye seçilmeden silinemiyor", j.get("message") == "Anketi sadece açan kişi silebilir", j)
c, j = req("delete_poll.php", data={"poll_id": p2, "member_id": own_member}, token=tokE)
check("başka evin anketi silinemiyor", j.get("message") == "Anket bulunamadı" and poll_counts(p2)[0] != {}, j)
c, j = req("delete_poll.php", data={"poll_id": p2, "member_id": "1"}, token=OLD_TOKEN)
check("açan kişi biten anketi sildi; seçenek ve oyları da gitti",
      j.get("status") == "success" and poll_counts(p2)[0] == {}
      and sql(f"SELECT (SELECT COUNT(*) FROM poll_options WHERE poll_id = {p2}) + (SELECT COUNT(*) FROM poll_votes WHERE poll_id = {p2})") == "0", j)
c, j = req("create_poll.php", json_body={"question": "Acik sil", "options": ["X", "Y"], "member_id": 2}, token=OLD_TOKEN)
c, j = req("delete_poll.php", data={"poll_id": j.get("poll_id"), "member_id": "2"}, token=OLD_TOKEN)
check("açık anket de silinebiliyor", j.get("status") == "success" and sql("SELECT COUNT(*) FROM polls WHERE question = 'Acik sil'") == "0", j)
c, j = req("create_poll.php", json_body={"question": "Sahipsiz", "options": ["X", "Y"]}, token=OLD_TOKEN)
c, j = req("delete_poll.php", data={"poll_id": j.get("poll_id")}, token=OLD_TOKEN)
check("açanı belli olmayan anketi herkes silebiliyor", j.get("status") == "success", j)

sql("DELETE FROM polls")
for i in range(10):
    req("create_poll.php", json_body={"question": f"Soru {i}", "options": ["X", "Y"]}, token=OLD_TOKEN)
c, j = req("create_poll.php", json_body={"question": "Fazla", "options": ["X", "Y"]}, token=OLD_TOKEN)
check("aynı anda en fazla 10 açık anket", j.get("message") == "Aynı anda en fazla 10 anket açık olabilir", j)
sql("UPDATE polls SET ends_at = NOW() - INTERVAL 1 MINUTE, end_notified = 1 WHERE question = 'Soru 0'")
c, j = req("create_poll.php", json_body={"question": "Fazla", "options": ["X", "Y"]}, token=OLD_TOKEN)
check("biri bitince yenisi açılabiliyor", j.get("status") == "success", j)
sql("DELETE FROM polls")

req("update_member_token.php", data={"member_id": own_member, "fcm_token": "tabletA"}, token=tokE)
check("cihaz başka eve giriş yapınca eski evdeki kaydı taşındı", devices(1) == "phoneA" and devices(own_member) == "tabletA", (devices(1), devices(own_member)))
req("update_member_token.php", data={"member_id": "1", "fcm_token": "tabletA", "enabled": "0"}, token=OLD_TOKEN)
check("başka evin cihazı kapatılamıyor", devices(own_member) == "tabletA", devices(own_member))
req("add_member.php", data={"name": "Cem"}, token=OLD_TOKEN)
cem = sql("SELECT id FROM home_members WHERE house_id = 1 ORDER BY id DESC LIMIT 1")
req("update_member_token.php", data={"member_id": cem, "fcm_token": "phoneC"}, token=OLD_TOKEN)
req("delete_member.php", data={"id": cem}, token=OLD_TOKEN)
check("üye silinince cihaz kaydı da silindi", sql("SELECT COUNT(*) FROM member_devices WHERE fcm_token = 'phoneC'") == "0")
n = len(fcm_log())
req("add_chore.php", data={"assigned_to_id": "1", "task_name": "Cihaz testi"}, token=OLD_TOKEN)
check("görev bildirimi kişinin cihazına gidiyor", fcm_log()[n:] and fcm_log()[n:][0]["tokens"] == ["phoneA"], fcm_log()[n:])
sql("DELETE FROM house_chores WHERE task_name = 'Cihaz testi'")
sql("UPDATE member_devices SET updated_at = NOW() - INTERVAL 271 DAY WHERE fcm_token = 'phoneA'")
out = run_cron()
check("270 gündür açılmayan cihaz kaydı temizlendi", devices(1) == "-" and devices(2) == "phoneB" and "Silinen eski cihaz kaydı: 1" in out, (devices(1), out))

print("19) PHP hata logu")
errs = open(PHP_ERRORS, encoding="utf-8", errors="replace").read() if os.path.exists(PHP_ERRORS) else ""
bad = [l for l in errs.splitlines() if re.search(r"PHP (Warning|Fatal|Notice|Deprecated)", l)]
check("PHP uyarı/hata logu temiz", not bad, "\n" + "\n".join(bad[:8]))

print(f"\nSONUÇ: {passed} geçti, {failed} başarısız")
sys.exit(1 if failed else 0)
