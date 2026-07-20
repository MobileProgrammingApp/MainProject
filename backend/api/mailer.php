<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

function sendVerificationEmail(string $toEmail, string $toName, string $token): bool {
    $mail = new PHPMailer(true);
    try {
        $mail->isSMTP();
        $mail->Host = 'smtp.gmail.com';
        $mail->SMTPAuth = true;
        $mail->Username = $_ENV['MAIL_USERNAME'];
        $mail->Password = $_ENV['MAIL_PASSWORD'];
        $mail->SMTPSecure = PHPMailer::ENCRYPTION_STARTTLS;
        $mail->Port = 587;
        $mail->CharSet = 'UTF-8';

        $mail->setFrom($_ENV['MAIL_USERNAME'], 'Homepal');
        $mail->addAddress($toEmail, $toName);

        $verifyUrl = rtrim($_ENV['APP_URL'], '/') . '/verify_email.php?token=' . urlencode($token);

        $mail->isHTML(true);
        $mail->Subject = 'Homepal - E-posta Adresinizi Doğrulayın';
        $mail->Body = "Merhaba " . htmlspecialchars($toName) . ",<br><br>"
            . "Homepal hesabınızı doğrulamak için <a href=\"$verifyUrl\">buraya tıklayın</a>.<br><br>"
            . "Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz.";
        $mail->AltBody = "Homepal hesabınızı doğrulamak için şu bağlantıya gidin: $verifyUrl";

        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("Doğrulama maili gönderilemedi: " . $mail->ErrorInfo);
        return false;
    }
}
