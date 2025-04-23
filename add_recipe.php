<?php
include 'navbar.php';
require 'config.php';

if (!isset($_SESSION['uid'])) {
    header("Location: login.php");
    exit();
}

$message = '';

if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    $name = trim($_POST['name']);
    $description = trim($_POST['description']);
    $type = $_POST['type'];
    $cookingtime = intval($_POST['cookingtime']);
    $ingredients = trim($_POST['ingredients']);
    $instructions = trim($_POST['instructions']);
    $imagePath = '';

    // Image upload
    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $fileTmp = $_FILES['image']['tmp_name'];
        $fileName = basename($_FILES['image']['name']);
        $targetPath = "uploads/" . time() . "_" . $fileName;

        if (move_uploaded_file($fileTmp, $targetPath)) {
            $imagePath = $targetPath;
        } else {
            $message = "Image upload failed.";
        }
    }

    try {
        $stmt = $pdo->prepare("INSERT INTO recipes (name, description, type, cookingtime, ingredients, instructions, image, uid)
                               VALUES (?, ?, ?, ?, ?, ?, ?, ?)");
        $stmt->execute([$name, $description, $type, $cookingtime, $ingredients, $instructions, $imagePath, $_SESSION['uid']]);
        $message = "Recipe added successfully!";
    } catch (PDOException $e) {
        $message = "Error: " . $e->getMessage();
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Add Recipe</title>
</head>
<body>

<h2>Add a New Recipe</h2>
<?php if ($message) echo "<p style='color:green;'>$message</p>"; ?>

<form method="POST" action="add_recipe.php" enctype="multipart/form-data">
    <label>Recipe Name:</label><br>
    <input type="text" name="name" required><br>

    <label>Description:</label><br>
    <textarea name="description" required></textarea><br>

    <label>Cuisine Type:</label><br>
    <select name="type" required>
        <option value="French">French</option>
        <option value="Italian">Italian</option>
        <option value="Chinese">Chinese</option>
        <option value="Indian">Indian</option>
        <option value="Mexican">Mexican</option>
        <option value="Others">Others</option>
    </select><br>

    <label>Cooking Time (minutes):</label><br>
    <input type="number" name="cookingtime" min="1" required><br>

    <label>Ingredients:</label><br>
    <textarea name="ingredients" required></textarea><br>

    <label>Instructions:</label><br>
    <textarea name="instructions" required></textarea><br>

    <label>Upload Image:</label><br>
    <input type="file" name="image" accept="image/*"><br><br>

    <input type="submit" value="Add Recipe">
</form>

</body>
</html>
