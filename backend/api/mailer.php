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
        $mail->addReplyTo($_ENV['MAIL_USERNAME'], 'Homepal Destek');
        $mail->addAddress($toEmail, $toName);

        $verifyUrl = rtrim($_ENV['APP_URL'], '/') . '/verify_email.php?token=' . urlencode($token);

        $mail->isHTML(true);
        $mail->Subject = 'Homepal hesap doğrulaması';
        $mail->Body = "<p>Merhaba " . htmlspecialchars($toName) . ",</p>"
            . "<p>Homepal uygulamasında bir hesap oluşturdunuz. Hesabınızı aktifleştirmek için aşağıdaki bağlantıya tıklayın:</p>"
            . "<p><a href=\"$verifyUrl\">$verifyUrl</a></p>"
            . "<p>Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz, hesabınız aktifleşmeyecektir.</p>"
            . "<p>İyi günler,<br>Homepal Ekibi</p>";
        $mail->AltBody = "Merhaba " . $toName . ",\n\n"
            . "Homepal hesabınızı aktifleştirmek için şu bağlantıya gidin:\n$verifyUrl\n\n"
            . "Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz.\n\nİyi günler,\nHomepal Ekibi";

        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("Doğrulama maili gönderilemedi: " . $mail->ErrorInfo);
        return false;
    }
}

function sendPasswordResetEmail(string $toEmail, string $toName, string $token): bool {
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
        $mail->addReplyTo($_ENV['MAIL_USERNAME'], 'Homepal Destek');
        $mail->addAddress($toEmail, $toName);

        $resetUrl = rtrim($_ENV['APP_URL'], '/') . '/reset_password.php?token=' . urlencode($token);

        $mail->isHTML(true);
        $mail->Subject = 'Homepal şifre sıfırlama';
        $mail->Body = "<p>Merhaba " . htmlspecialchars($toName) . ",</p>"
            . "<p>Homepal hesabınız için bir şifre sıfırlama talebi aldık. Yeni şifre belirlemek için aşağıdaki bağlantıya tıklayın:</p>"
            . "<p><a href=\"$resetUrl\">$resetUrl</a></p>"
            . "<p>Bu bağlantı 1 saat boyunca geçerlidir. Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz, şifreniz değişmeyecektir.</p>"
            . "<p>İyi günler,<br>Homepal Ekibi</p>";
        $mail->AltBody = "Merhaba " . $toName . ",\n\n"
            . "Homepal hesabınız için yeni şifre belirlemek üzere şu bağlantıya gidin (1 saat geçerli):\n$resetUrl\n\n"
            . "Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz.\n\nİyi günler,\nHomepal Ekibi";

        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("Şifre sıfırlama maili gönderilemedi: " . $mail->ErrorInfo);
        return false;
    }
}
