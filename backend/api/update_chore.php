<?php
include 'db.php';

if(isset($_POST['id'])){
    $id = $_POST['id'];
    try {

        $stmt = $conn->prepare("UPDATE house_chores SET is_done = 1 WHERE id = ?");
        $stmt->execute([$id]);
        echo json_encode(["status" => "success"]);
    } catch(Exception $e) {
        echo json_encode(["status" => "error", "message" => $e->getMessage()]);
    }
}
?>