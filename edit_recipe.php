<?php
include 'navbar.php';
require 'config.php';

if (!isset($_SESSION['uid'])) {
    header("Location: login.php");
    exit();
}

$uid = $_SESSION['uid'];

if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    echo "<p>Invalid recipe ID.</p>";
    exit();
}

$rid = intval($_GET['id']);

$stmt = $pdo->prepare("SELECT * FROM recipes WHERE rid = ? AND uid = ?");
$stmt->execute([$rid, $uid]);
$recipe = $stmt->fetch();

if (!$recipe) {
    echo "<p>Recipe not found or you do not have permission to edit it.</p>";
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
    $imagePath = $recipe['image']; 

    if (isset($_FILES['image']) && $_FILES['image']['error'] === UPLOAD_ERR_OK) {
        $fileTmp = $_FILES['image']['tmp_name'];
        $fileName = basename($_FILES['image']['name']);
        $targetPath = "uploads/" . time() . "_" . $fileName;

        if (move_uploaded_file($fileTmp, $targetPath)) {
            $imagePath = $targetPath;
        }
    }

    try {
        $stmt = $pdo->prepare("UPDATE recipes SET name = ?, description = ?, type = ?, cookingtime = ?, ingredients = ?, instructions = ?, image = ? WHERE rid = ? AND uid = ?");
        $stmt->execute([$name, $description, $type, $cookingtime, $ingredients, $instructions, $imagePath, $rid, $uid]);
        $message = "Recipe updated successfully!";
    } catch (PDOException $e) {
        $message = "Error: " . $e->getMessage();
    }
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>Edit Recipe</title>
</head>
<body>

<h2>Edit Recipe: <?php echo htmlspecialchars($recipe['name']); ?></h2>
<?php if ($message) echo "<p style='color:green;'>$message</p>"; ?>

<form method="POST" action="edit_recipe.php?id=<?php echo $rid; ?>" enctype="multipart/form-data">
    <label>Recipe Name:</label><br>
    <input type="text" name="name" value="<?php echo htmlspecialchars($recipe['name']); ?>" required><br>

    <label>Description:</label><br>
    <textarea name="description" required><?php echo htmlspecialchars($recipe['description']); ?></textarea><br>

    <label>Cuisine Type:</label><br>
    <select name="type" required>
        <?php
        $types = ['French', 'Italian', 'Chinese', 'Indian', 'Mexican', 'Others'];
        foreach ($types as $typeOption):
            ?>
            <option value="<?php echo $typeOption; ?>" <?php if ($recipe['type'] === $typeOption) echo 'selected'; ?>>
                <?php echo $typeOption; ?>
            </option>
        <?php endforeach; ?>
    </select><br>

    <label>Cooking Time (minutes):</label><br>
    <input type="number" name="cookingtime" value="<?php echo htmlspecialchars($recipe['cookingtime']); ?>" required><br>

    <label>Ingredients:</label><br>
    <textarea name="ingredients" required><?php echo htmlspecialchars($recipe['ingredients']); ?></textarea><br>

    <label>Instructions:</label><br>
    <textarea name="instructions" required><?php echo htmlspecialchars($recipe['instructions']); ?></textarea><br>

    <label>Replace Image (optional):</label><br>
    <input type="file" name="image" accept="image/*"><br><br>

    <?php if (!empty($recipe['image'])): ?>
        <p>Current Image:</p>
        <img src="<?php echo htmlspecialchars($recipe['image']); ?>" style="max-width: 300px; border-radius: 10px;"><br><br>
    <?php endif; ?>

    <input type="submit" value="Update Recipe">
</form>

</body>
</html>
