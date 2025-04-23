<?php
include 'navbar.php';
require 'config.php';

$message = '';
$email = $_SESSION['email'] ?? '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $username = trim($_POST['username']);
    $email = trim($_POST['email']);
    $password = $_POST['password'];
    $hash = password_hash($password, PASSWORD_DEFAULT);

    $check = $pdo->prepare("SELECT * FROM users WHERE username = ? OR email = ?");
    $check->execute([$username, $email]);
    if ($check->fetch()) {
        $message = "Username or email already exists.";
    } else {
        $stmt = $pdo->prepare("INSERT INTO users (username, email, password) VALUES (?, ?, ?)");
        $stmt->execute([$username, $email, $hash]);

        $_SESSION['uid'] = $pdo->lastInsertId();
        $_SESSION['username'] = $username;
        header("Location: index.php");
        exit();
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Register - Virtual Kitchen</title>
</head>
<body>
<h2>Register</h2>
<?php if ($message) echo "<p style='color:red;'>$message</p>"; ?>
<form method="POST" action="register.php">
    <label>Username:</label><br>
    <input type="text" name="username" required><br>

    <label>Email:</label><br>
    <input type="email" name="email" value="<?php echo htmlspecialchars($email); ?>" required><br>

    <label>Password:</label><br>
    <input type="password" name="password" required><br><br>

    <input type="submit" value="Register">
</form>
</body>
</html>
