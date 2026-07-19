<?php
require_once __DIR__ . '/vendor/autoload.php';

use Dotenv\Dotenv;

// .env dosyasını yükle
$dotenv = Dotenv::createImmutable(__DIR__);
$dotenv->load();

// IONOS Sunucu Bilgileri
$host = $_ENV['DB_HOST'];
$db   = $_ENV['DB_NAME'];
$user = $_ENV['DB_USER'];
$pass = $_ENV['DB_PASS'];
header("Access-Control-Allow-Origin: *"); 
header("Access-Control-Allow-Methods: POST, GET, OPTIONS, DELETE, PUT");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");


try {
    $conn = new PDO("mysql:host=$host;dbname=$db;charset=utf8", $user, $pass);
   
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
  
    die(json_encode(["status" => "error", "message" => "Bağlantı hatası: " . $e->getMessage()]));
}
?>