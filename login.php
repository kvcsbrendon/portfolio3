<?php
include 'navbar.php';
require 'config.php';

$message = '';
$email = $_SESSION['email'] ?? '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $emailInput = trim($_POST['email']);
    $passwordInput = $_POST['password'];

    $stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
    $stmt->execute([$emailInput]);
    $user = $stmt->fetch();

    if ($user && password_verify($passwordInput, $user['password'])) {
        $_SESSION['uid'] = $user['uid'];
        $_SESSION['username'] = $user['username'];
        header("Location: index.php");
        exit();
    } else {
        $message = "Invalid email or password.";
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Login - Virtual Kitchen</title>
</head>
<body>
<h2>Login</h2>
<?php if ($message) echo "<p style='color:red;'>$message</p>"; ?>
<form method="POST" action="login.php">
    <label>Email:</label><br>
    <input type="email" name="email" value="<?php echo htmlspecialchars($email); ?>" required><br>

    <label>Password:</label><br>
    <input type="password" name="password" required><br><br>

    <input type="submit" value="Login">
</form>
</body>
</html>
