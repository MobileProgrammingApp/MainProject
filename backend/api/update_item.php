<?php
include 'db.php';

if(isset($_POST['id']) && isset($_POST['is_bought'])){
    $id = $_POST['id'];
    $is_bought = $_POST['is_bought']; 
    
    try {
        $stmt = $conn->prepare("UPDATE shopping_list SET is_bought = ? WHERE id = ?");
        $stmt->execute([$is_bought, $id]);
        echo json_encode(["status" => "success"]);
    } catch(Exception $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
}
?>