<?php

use PHPMailer\PHPMailer\PHPMailer;
use PHPMailer\PHPMailer\Exception;

/**
 * Gmail SMTP üzerinden Homepal maili gönderir. $htmlBody içine giren
 * kullanıcı verileri çağıran tarafta htmlspecialchars ile kaçırılmış olmalı.
 */
function sendHomepalMail(string $toEmail, string $toName, string $subject, string $htmlBody, string $textBody): bool {
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
        $mail->Timeout = 15;

        $mail->setFrom($_ENV['MAIL_USERNAME'], 'Homepal');
        $mail->addReplyTo($_ENV['MAIL_USERNAME'], 'Homepal Destek');
        $mail->addAddress($toEmail, $toName);

        $mail->isHTML(true);
        $mail->Subject = $subject;
        $mail->Body = $htmlBody;
        $mail->AltBody = $textBody;

        $mail->send();
        return true;
    } catch (Exception $e) {
        error_log("[homepal] Mail gönderilemedi ($subject): " . $mail->ErrorInfo);
        return false;
    }
}

function appUrl(string $path): string {
    return rtrim($_ENV['APP_URL'], '/') . '/' . $path;
}

function sendVerificationEmail(string $toEmail, string $toName, string $token): bool {
    $verifyUrl = appUrl('verify_email.php?token=' . urlencode($token));

    return sendHomepalMail(
        $toEmail,
        $toName,
        'Homepal hesap doğrulaması',
        "<p>Merhaba " . htmlspecialchars($toName) . ",</p>"
            . "<p>Homepal uygulamasında bir hesap oluşturdunuz. Hesabınızı aktifleştirmek için aşağıdaki bağlantıya tıklayın:</p>"
            . "<p><a href=\"$verifyUrl\">$verifyUrl</a></p>"
            . "<p>Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz, hesabınız aktifleşmeyecektir.</p>"
            . "<p>İyi günler,<br>Homepal Ekibi</p>",
        "Merhaba " . $toName . ",\n\n"
            . "Homepal hesabınızı aktifleştirmek için şu bağlantıya gidin:\n$verifyUrl\n\n"
            . "Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz.\n\nİyi günler,\nHomepal Ekibi"
    );
}

function sendPasswordResetEmail(string $toEmail, string $toName, string $token): bool {
    $resetUrl = appUrl('reset_password.php?token=' . urlencode($token));

    return sendHomepalMail(
        $toEmail,
        $toName,
        'Homepal şifre sıfırlama',
        "<p>Merhaba " . htmlspecialchars($toName) . ",</p>"
            . "<p>Homepal hesabınız için bir şifre sıfırlama talebi aldık. Yeni şifre belirlemek için aşağıdaki bağlantıya tıklayın:</p>"
            . "<p><a href=\"$resetUrl\">$resetUrl</a></p>"
            . "<p>Bu bağlantı 1 saat boyunca geçerlidir. Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz, şifreniz değişmeyecektir.</p>"
            . "<p>İyi günler,<br>Homepal Ekibi</p>",
        "Merhaba " . $toName . ",\n\n"
            . "Homepal hesabınız için yeni şifre belirlemek üzere şu bağlantıya gidin (1 saat geçerli):\n$resetUrl\n\n"
            . "Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz.\n\nİyi günler,\nHomepal Ekibi"
    );
}

function sendAccountDeletedEmail(string $toEmail, string $toName): bool {
    return sendHomepalMail(
        $toEmail,
        $toName,
        'Homepal hesabınız silindi',
        "<p>Merhaba " . htmlspecialchars($toName) . ",</p>"
            . "<p>Homepal ev hesabınız ve hesaba bağlı tüm veriler (ev üyeleri, görevler, market listesi, ev bilgileri ve anketler) uygulama içinden yapılan talep üzerine kalıcı olarak silindi.</p>"
            . "<p>Bu işlemi siz yapmadıysanız bize bu e-postayı yanıtlayarak ulaşın.</p>"
            . "<p>İyi günler,<br>Homepal Ekibi</p>",
        "Merhaba " . $toName . ",\n\n"
            . "Homepal ev hesabınız ve hesaba bağlı tüm veriler uygulama içinden yapılan talep üzerine kalıcı olarak silindi.\n"
            . "Bu işlemi siz yapmadıysanız bu e-postayı yanıtlayarak bize ulaşın.\n\nİyi günler,\nHomepal Ekibi"
    );
}

/**
 * Kayıtlı bir e-postayla tekrar kayıt olunmaya çalışıldığında gönderilir.
 * Uygulama "bu mail kayıtlı" demediği için (e-posta tahmini engellensin diye)
 * gerçek sahibi bilgiyi mailden öğrenir.
 */
function sendAccountExistsEmail(string $toEmail, string $toName): bool {
    return sendHomepalMail(
        $toEmail,
        $toName,
        'Homepal hesabınız zaten var',
        "<p>Merhaba " . htmlspecialchars($toName) . ",</p>"
            . "<p>Bu e-posta adresiyle yeni bir Homepal hesabı oluşturulmak istendi, ancak bu adrese ait bir hesabınız zaten var.</p>"
            . "<p>Uygulamadan bu e-posta ile giriş yapabilirsiniz. Şifrenizi hatırlamıyorsanız giriş ekranındaki <b>Şifremi Unuttum</b> seçeneğini kullanın.</p>"
            . "<p>Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz, hesabınızda bir değişiklik yapılmadı.</p>"
            . "<p>İyi günler,<br>Homepal Ekibi</p>",
        "Merhaba " . $toName . ",\n\n"
            . "Bu e-posta adresiyle yeni bir Homepal hesabı oluşturulmak istendi, ancak bu adrese ait bir hesabınız zaten var.\n"
            . "Uygulamadan giriş yapabilir, şifrenizi hatırlamıyorsanız 'Şifremi Unuttum' seçeneğini kullanabilirsiniz.\n\n"
            . "Bu isteği siz yapmadıysanız bu e-postayı yok sayabilirsiniz.\n\nİyi günler,\nHomepal Ekibi"
    );
}
