<?php
// IONOS Sunucu Bilgileri
header("Access-Control-Allow-Origin: *"); 
header("Access-Control-Allow-Methods: POST, GET, OPTIONS, DELETE, PUT");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
$host = "db5019343528.hosting-data.io"; 
$db_name = "dbs15146355";               
$username = "dbu2102079"; 
$password = "UsyiQ3fH@MG@R9PQWER"; 

try {
    $conn = new PDO("mysql:host=$host;dbname=$db_name;charset=utf8", $username, $password);
   
    $conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch(PDOException $e) {
  
    die(json_encode(["status" => "error", "message" => "Bağlantı hatası: " . $e->getMessage()]));
}
?>