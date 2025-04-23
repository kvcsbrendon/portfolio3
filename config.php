<?php
$host = 'localhost';
$db = 'u_240210111_db';
$user = 'u-240210111';
$pass = 'AqAaUZ3LTUoy9qu';

try {
    $pdo = new PDO("mysql:host=$host;dbname=$db", $user, $pass);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
} catch (PDOException $e) {
    die("Connection failed: " . $e->getMessage());
}
?>
