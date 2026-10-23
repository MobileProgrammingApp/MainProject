<?php
require_once __DIR__ . '/../vendor/autoload.php';
require_once __DIR__ . '/security.php';

use Dotenv\Dotenv;

// PHP uyarıları (dosya yolları vb.) yanıta değil sadece sunucu loguna yazılsın
ini_set('display_errors', '0');
ini_set('log_errors', '1');

// .env dosyasını yükle
$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

// IONOS Sunucu Bilgileri
$host = $_ENV['DB_HOST'];
$db   = $_ENV['DB_NAME'];
$user = $_ENV['DB_USER'];
$pass = $_ENV['DB_PASS'];

// Varsayılan yanıt tipi; HTML sayfa döndüren endpoint'ler bunu kendisi ezer.
// CORS başlığı yok: API'yi sadece mobil uygulama kullanıyor, tarayıcıdan
// başka sitelerin çağırmasına izin vermeye gerek yok.
header('Content-Type: application/json; charset=utf-8');

try {
    $conn = new PDO("mysql:host=$host;dbname=$db;charset=utf8mb4", $user, $pass);

    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
    error_log("[homepal] DB bağlantı hatası: " . $e->getMessage());
    jsonError("Sunucuya şu an ulaşılamıyor, lütfen daha sonra tekrar deneyin.", 503);
}
?>
