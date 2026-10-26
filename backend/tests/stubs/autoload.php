<?php
// TEST STUB: gerçek vlucas/phpdotenv ve PHPMailer yerine. Mailler mails.log'a yazılır.
namespace Dotenv {
    class Dotenv {
        private $dir;
        static function createImmutable($dir) { $d = new self; $d->dir = $dir; return $d; }
        function load() {
            foreach (file($this->dir . '/.env', FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $l) {
                [$k, $v] = explode('=', $l, 2); $_ENV[$k] = $v;
            }
        }
    }
}
namespace PHPMailer\PHPMailer {
    class Exception extends \Exception {}
    class PHPMailer {
        const ENCRYPTION_STARTTLS = 'tls';
        public $Host, $SMTPAuth, $Username, $Password, $SMTPSecure, $Port, $CharSet, $Timeout, $Subject, $Body, $AltBody, $ErrorInfo = '';
        private $to;
        function __construct($e = false) {}
        function isSMTP() {} function isHTML($b) {} function setFrom($a, $n = '') {} function addReplyTo($a, $n = '') {}
        function addAddress($a, $n = '') { $this->to = $a; }
        function send() {
            file_put_contents(dirname(__DIR__) . '/mails.log', json_encode(['to' => $this->to, 'subject' => $this->Subject, 'text' => $this->AltBody], JSON_UNESCAPED_UNICODE) . "\n", FILE_APPEND);
            return true;
        }
    }
}
