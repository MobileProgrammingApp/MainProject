<?php
include 'db.php';

if(isset($_POST['member_id']) && isset($_POST['fcm_token'])) {
    $member_id = $_POST['member_id'];
    $fcm_token = $_POST['fcm_token'];

    try {
       
        $stmt = $conn->prepare("UPDATE home_members SET fcm_token = ? WHERE id = ?");
        $stmt->execute([$fcm_token, $member_id]);

        echo json_encode(["status" => "success", "message" => "Token güncellendi"]);
    } catch(Exception $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
} else {
    echo json_encode(["status" => "error", "message" => "Parametreler eksik"]);
}
?>