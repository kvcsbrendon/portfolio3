<?php
session_start();
require 'config.php';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $email = trim($_POST['email']);

    // Save email in session for pre-filling
    $_SESSION['email'] = $email;

    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        die("Invalid email format.");
    }

    try {
        $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
        $stmt->execute([$email]);
        $user = $stmt->fetch();

        if ($user) {
            // Email exists → go to login
            header("Location: login.php");
            exit();
        } else {
            // Email not found → go to register
            header("Location: register.php");
            exit();
        }
    } catch (PDOException $e) {
        die("Database error: " . $e->getMessage());
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Start - Virtual Kitchen</title>
</head>
<body>
    <h2>Welcome to Virtual Kitchen</h2>
    <p>Enter your email to continue:</p>
    <form method="POST" action="start.php">
        <label>Email:</label><br>
        <input type="email" name="email" required><br><br>
        <input type="submit" value="Continue">
    </form>
</body>
</html>
