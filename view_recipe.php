<?php
include 'navbar.php';
require 'config.php';

if (!isset($_GET['id']) || !is_numeric($_GET['id'])) {
    echo "<p>Invalid recipe ID.</p>";
    exit();
}

$rid = intval($_GET['id']);

$stmt = $pdo->prepare("
    SELECT r.*, u.username 
    FROM recipes r
    JOIN users u ON r.uid = u.uid
    WHERE r.rid = ?
");
$stmt->execute([$rid]);
$recipe = $stmt->fetch();

if (!$recipe) {
    echo "<p>Recipe not found.</p>";
    exit();
}
?>

<!DOCTYPE html>
<html>
<head>
    <title><?php echo htmlspecialchars($recipe['name']); ?> - Virtual Kitchen</title>
    <style>
        body {
            font-family: sans-serif;
            max-width: 800px;
            margin: auto;
            padding: 20px;
        }
        .recipe-image {
            width: 100%;
            max-height: 400px;
            object-fit: cover;
            border-radius: 10px;
        }
        h2 {
            margin-bottom: 10px;
        }
        .meta {
            font-size: 14px;
            color: #666;
            margin-bottom: 15px;
        }
    </style>
</head>
<body>

<h2><?php echo htmlspecialchars($recipe['name']); ?></h2>

<?php if (!empty($recipe['image'])): ?>
    <img src="<?php echo htmlspecialchars($recipe['image']); ?>" class="recipe-image" alt="Recipe Image">
<?php endif; ?>

<p class="meta">
    <strong>Cuisine Type:</strong> <?php echo htmlspecialchars($recipe['type']); ?> |
    <strong>Cooking Time:</strong> <?php echo htmlspecialchars($recipe['cookingtime']); ?> min<br>
    <strong>Posted by:</strong> <?php echo htmlspecialchars($recipe['username']); ?>
</p>

<h3>Description</h3>
<p><?php echo nl2br(htmlspecialchars($recipe['description'])); ?></p>

<h3>Ingredients</h3>
<p><?php echo nl2br(htmlspecialchars($recipe['ingredients'])); ?></p>

<h3>Instructions</h3>
<p><?php echo nl2br(htmlspecialchars($recipe['instructions'])); ?></p>

</body>
</html>
