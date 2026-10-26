"""HomePal backend testlerini izole bir ortamda çalıştırır.

Ne yapar:
  1. Geçici bir klasöre backend/api'nin kopyasını ve sahte vendor kütüphanelerini
     (stubs/autoload.php: .env okuyucu + mailleri dosyaya yazan PHPMailer) koyar.
  2. Ayrı veri klasörü ve ayrı portta (3307) boş bir MariaDB başlatır; schema.sql
     ve seed.sql'i yükler. Bilgisayardaki diğer veritabanlarına dokunmaz.
  3. PHP'nin yerleşik sunucusunu (8099) başlatır, test_api.py'yi çalıştırır.
  4. Her şeyi kapatıp geçici klasörü siler.

Kullanım:  python backend/tests/run_tests.py
Gerekenler: PHP 8+ (pdo_mysql) ve MariaDB/MySQL. Windows'ta XAMPP varsayılan
yollarından bulunur; başka yerdeyse PHP_BIN ve MYSQL_BIN_DIR ortam
değişkenleriyle verin.
"""
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import time

HERE = os.path.dirname(os.path.abspath(__file__))
BACKEND = os.path.dirname(HERE)
DB_PORT, WEB_PORT = 3307, 8099
EXE = ".exe" if os.name == "nt" else ""


def find_php():
    for candidate in (os.environ.get("PHP_BIN"), "C:/xampp/php/php.exe", shutil.which("php")):
        if candidate and os.path.exists(candidate):
            return candidate
    sys.exit("PHP bulunamadı (PHP_BIN ortam değişkeniyle verin)")


def find_mysql_dir():
    for candidate in (os.environ.get("MYSQL_BIN_DIR"), "C:/xampp/mysql/bin"):
        if candidate and os.path.exists(os.path.join(candidate, "mysqld" + EXE)):
            return candidate
    mysqld = shutil.which("mysqld") or shutil.which("mariadbd")
    if mysqld:
        return os.path.dirname(mysqld)
    sys.exit("MariaDB/MySQL bulunamadı (MYSQL_BIN_DIR ortam değişkeniyle verin)")


def wait_for_port(port, timeout=30):
    deadline = time.time() + timeout
    while time.time() < deadline:
        with socket.socket() as s:
            if s.connect_ex(("127.0.0.1", port)) == 0:
                return
        time.sleep(0.3)
    sys.exit(f"Port {port} {timeout} saniyede açılmadı")


def main():
    php = find_php()
    mysql_dir = find_mysql_dir()
    mysql = os.path.join(mysql_dir, "mysql" + EXE)
    for port in (DB_PORT, WEB_PORT):
        with socket.socket() as s:
            if s.connect_ex(("127.0.0.1", port)) == 0:
                sys.exit(f"Port {port} kullanımda; önceki bir test çalışıyor olabilir")

    tmp = tempfile.mkdtemp(prefix="homepal-test-")
    app = os.path.join(tmp, "app")
    processes = []
    try:
        # 1) Backend kopyası (gerçek .env ve anahtarlar hariç) + sahte vendor
        shutil.copytree(os.path.join(BACKEND, "api"), os.path.join(app, "api"),
                        ignore=shutil.ignore_patterns(".env", "keys"))
        os.makedirs(os.path.join(app, "vendor"))
        shutil.copy(os.path.join(HERE, "stubs", "autoload.php"), os.path.join(app, "vendor", "autoload.php"))
        with open(os.path.join(app, "api", ".env"), "w", encoding="utf-8") as f:
            f.write(f"DB_HOST=127.0.0.1;port={DB_PORT}\nDB_NAME=homepal_test\nDB_USER=root\nDB_PASS=\n"
                    "PROJECT_ID=\nKEY_FILEPATH=\nMAIL_USERNAME=test@example.com\nMAIL_PASSWORD=x\n"
                    f"APP_URL=http://127.0.0.1:{WEB_PORT}\n")

        # 2) İzole MariaDB
        datadir = os.path.join(tmp, "db")
        install = os.path.join(mysql_dir, ("mysql_install_db" if os.name == "nt" else "mariadb-install-db") + EXE)
        install_args = [install, f"--datadir={datadir}"]
        install_args += [f"--port={DB_PORT}"] if os.name == "nt" else ["--auth-root-authentication-method=normal"]
        subprocess.run(install_args, check=True, capture_output=True)
        processes.append(subprocess.Popen(
            [os.path.join(mysql_dir, "mysqld" + EXE), "--no-defaults", f"--datadir={datadir}", f"--port={DB_PORT}",
             "--bind-address=127.0.0.1", f"--socket={os.path.join(tmp, 'mysql.sock')}"],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
        wait_for_port(DB_PORT)
        base = [mysql, "-h127.0.0.1", f"-P{DB_PORT}", "-uroot"]
        subprocess.run(base + ["-e", "CREATE DATABASE homepal_test CHARACTER SET utf8mb4"], check=True)
        for sql_file in (os.path.join(BACKEND, "schema.sql"), os.path.join(HERE, "seed.sql")):
            with open(sql_file, "rb") as f:
                subprocess.run(base + ["homepal_test"], stdin=f, check=True)

        # 3) PHP sunucusu
        errors_log = os.path.join(app, "php_errors.log")
        processes.append(subprocess.Popen(
            [php, "-d", "display_errors=0", "-d", "log_errors=1", "-d", f"error_log={errors_log}",
             "-S", f"127.0.0.1:{WEB_PORT}", "-t", os.path.join(app, "api")],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL))
        wait_for_port(WEB_PORT)

        # 4) Testler
        env = dict(os.environ, PYTHONIOENCODING="utf-8",
                   HOMEPAL_TEST_BASE=f"http://127.0.0.1:{WEB_PORT}",
                   HOMEPAL_TEST_MAILS=os.path.join(app, "mails.log"),
                   HOMEPAL_TEST_PHP_ERRORS=errors_log,
                   HOMEPAL_TEST_PHP=php,
                   HOMEPAL_TEST_MYSQL=mysql,
                   HOMEPAL_TEST_DB_PORT=str(DB_PORT))
        return subprocess.run([sys.executable, os.path.join(HERE, "test_api.py")], env=env).returncode
    finally:
        for p in processes:
            p.terminate()
        for p in processes:
            try:
                p.wait(timeout=10)
            except subprocess.TimeoutExpired:
                p.kill()
        shutil.rmtree(tmp, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
