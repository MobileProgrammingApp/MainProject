"""HomePal backend uçtan uca testleri.

Doğrudan çalıştırmayın; ortamı run_tests.py kurar (izole MariaDB + PHP sunucusu)
ve aşağıdaki ortam değişkenlerini verir.
"""
import json, os, re, subprocess, sys, urllib.parse, urllib.request

BASE = os.environ.get("HOMEPAL_TEST_BASE", "http://127.0.0.1:8099")
MAILS = os.environ["HOMEPAL_TEST_MAILS"]
PHP_ERRORS = os.environ["HOMEPAL_TEST_PHP_ERRORS"]
PHP = os.environ.get("HOMEPAL_TEST_PHP", "php")
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

print("1) Eski uygulama uyumluluğu (eski sürümden kalan ortak token)")
c, j = req("get_profile.php", get={"api_token": OLD_TOKEN})
check("eski token GET query ile çalışıyor", j.get("status") == "success", j)
c, j = req("get_items.php", data={"api_token": OLD_TOKEN})
check("eski token POST body ile çalışıyor", isinstance(j, list), j)
c, j = req("get_profile.php", token=OLD_TOKEN)
check("Authorization: Bearer başlığı çalışıyor", j.get("status") == "success", j)
c, j = req("get_profile.php", get={"api_token": "yanlis"})
check("geçersiz token -> 401", c == 401, c)
c, j = req("get_profile.php", data={"api_token[]": "x"})
check("dizi olarak gelen token -> 401 (uyarı/sızıntı yok)", c == 401, (c, j))
c, text, ctype = req("get_profile.php", get={"api_token": OLD_TOKEN}, raw=True)
check("yanıt Content-Type JSON", "application/json" in ctype, ctype)

print("2) Giriş: çoklu cihaz + deneme sınırı")
c, j = req("login.php", data={"email": "eski@example.com", "password": "EskiSifre123"})
check("doğru şifreyle giriş", j.get("status") == "success" and len(j.get("api_token", "")) == 64, j)
tokB = j.get("api_token")
check("yeni cihaz token'ı eski token'dan farklı", tokB != OLD_TOKEN)
c, j = req("get_profile.php", get={"api_token": OLD_TOKEN})
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
c, j = req("create_poll.php", json_body={"api_token": OLD_TOKEN, "question": "Ne yiyelim?", "options": [str(i) for i in range(11)]})
check("11 seçenek reddedildi", "en fazla 10" in j.get("message", "").lower(), j)
c, j = req("create_poll.php", json_body={"api_token": OLD_TOKEN, "question": "Ne yiyelim?", "options": ["Pizza", ""]})
check("boş seçenek reddedildi", j.get("status") == "error", j)
c, j = req("create_poll.php", json_body={"api_token": OLD_TOKEN, "question": "Ne yiyelim?", "options": ["Pizza", "Döner"]})
check("anket oluştu (eski uygulamanın JSON biçimi)", j.get("status") == "success", j)
c, j = req("get_active_poll.php", get={"api_token": OLD_TOKEN, "member_id": "1"})
check("aktif anket okunuyor", j.get("question") == "Ne yiyelim?", j)
poll_id, opt_id = j.get("poll_id"), j["options"][0]["id"]
c, j = req("vote_poll.php", data={"api_token": OLD_TOKEN, "poll_id": poll_id, "option_id": opt_id, "member_id": "1"})
check("oy verildi", j.get("status") == "success", j)
c, j = req("vote_poll.php", data={"api_token": OLD_TOKEN, "poll_id": poll_id, "option_id": opt_id, "member_id": "1"})
check("ikinci oy reddedildi", j.get("message") == "Zaten oy kullandınız", j)
check("sayaç 1'de kaldı", sql(f"SELECT vote_count FROM poll_options WHERE id = {opt_id}") == "1")

print("9) Bildirim token'ı")
c, j = req("update_member_token.php", data={"member_id": "1", "fcm_token": "tokA"}, token=OLD_TOKEN)
check("token kaydedildi", j.get("status") == "success", j)
check("aynı cihaz token'ı diğer üyeden temizlendi", sql("SELECT fcm_token IS NULL FROM home_members WHERE id = 2") == "1")
c, j = req("get_members.php", token=OLD_TOKEN)
check("üye listesinde fcm_token dönmüyor", isinstance(j, list) and j and "fcm_token" not in j[0], j)
c, j = req("update_member_token.php", data={"member_id": "1", "fcm_token": ""}, token=OLD_TOKEN)
check("bildirim kapatma: token NULL", sql("SELECT fcm_token IS NULL FROM home_members WHERE id = 1") == "1")

print("10) Çıkış")
c, j = req("logout.php", token=tokC)
check("logout başarılı", j.get("status") == "success", j)
c, _ = req("get_profile.php", token=tokC)
check("logout sonrası token geçersiz", c == 401)

print("11) Ortak token'ın cihaza özel token'la değiştirilmesi (renew_token)")
c, j = req("renew_token.php", token=OLD_TOKEN); dev = j.get("api_token")
check("ortak token ile yenileme -> yeni cihaz token'ı", j.get("status") == "success" and dev and dev != OLD_TOKEN, j)
c, _ = req("get_profile.php", token=dev); check("yeni cihaz token'ı çalışıyor", c == 200)
c, _ = req("get_profile.php", data={"api_token": OLD_TOKEN}); check("ortak token (eski sürümdeki aile üyeleri) hâlâ çalışıyor", c == 200)
c, j = req("logout.php", token=dev); check("cihaz token'ı ile çıkış", j.get("status") == "success", j)
c, _ = req("get_profile.php", data={"api_token": OLD_TOKEN}); check("çıkış diğer aile üyelerini etkilemedi", c == 200)
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
req("create_poll.php", json_body={"api_token": OLD_TOKEN, "question": "Hafta sonu?", "options": ["Sinema", "Piknik"]})
c, j = req("get_active_poll.php", get={"api_token": OLD_TOKEN, "member_id": "0"})
check("profil seçmeden anket görünüyor", j.get("question") == "Hafta sonu?" and j.get("has_voted") is False, j)
check("kalan süre ~24 saat", 1430 <= int(j.get("minutes_left", 0)) <= 1440, j.get("minutes_left"))
poll_id, opt_id = j.get("poll_id"), j["options"][0]["id"]
sql(f"UPDATE polls SET created_at = NOW() - INTERVAL 25 HOUR WHERE id = {poll_id}")
c, j = req("get_active_poll.php", get={"api_token": OLD_TOKEN, "member_id": "1"})
check("süresi dolan anket gösterilmiyor (temizlik çalışmamış olsa da)", j.get("status") == "empty", j)
c, j = req("vote_poll.php", data={"api_token": OLD_TOKEN, "poll_id": poll_id, "option_id": opt_id, "member_id": "1"})
check("süresi dolan ankete oy verilemiyor", j.get("message") == "Anket bulunamadı", j)

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

print("15) PHP hata logu")
errs = open(PHP_ERRORS, encoding="utf-8", errors="replace").read() if os.path.exists(PHP_ERRORS) else ""
bad = [l for l in errs.splitlines() if re.search(r"PHP (Warning|Fatal|Notice|Deprecated)", l)]
check("PHP uyarı/hata logu temiz", not bad, "\n" + "\n".join(bad[:8]))

print(f"\nSONUÇ: {passed} geçti, {failed} başarısız")
sys.exit(1 if failed else 0)
