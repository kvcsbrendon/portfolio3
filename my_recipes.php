<?php
include 'navbar.php';
require 'config.php';

if (!isset($_SESSION['uid'])) {
    header("Location: login.php");
    exit();
}

$uid = $_SESSION['uid'];

$stmt = $pdo->prepare("SELECT rid, name, type, description FROM recipes WHERE uid = ? ORDER BY rid DESC");
$stmt->execute([$uid]);
$recipes = $stmt->fetchAll();
?>

<!DOCTYPE html>
<html>
<head>
    <title>My Recipes</title>
    <style>
        body {
            font-family: sans-serif;
            max-width: 900px;
            margin: auto;
            padding: 20px;
        }
        .recipe-box {
            border: 1px solid #ccc;
            border-radius: 10px;
            margin-bottom: 15px;
            padding: 15px;
            background: #f9f9f9;
        }
        .recipe-box h3 {
            margin: 0;
        }
        .recipe-box small {
            color: #666;
        }
        .view-link {
            margin-top: 8px;
            display: inline-block;
            color: #0077cc;
        }
    </style>
</head>
<body>

<h2>My Recipes</h2>

<?php if (count($recipes) === 0): ?>
    <p>You haven't added any recipes yet.</p>
<?php else: ?>
    <?php foreach ($recipes as $r): ?>
        <div class="recipe-box">
            <h3><?php echo htmlspecialchars($r['name']); ?></h3>
            <small><em><?php echo htmlspecialchars($r['type']); ?></em></small>
            <p><?php echo nl2br(htmlspecialchars(substr($r['description'], 0, 100))) . "..."; ?></p>
            <a class="view-link" href="view_recipe.php?id=<?php echo $r['rid']; ?>">View Recipe</a> |
            <a class="view-link" href="edit_recipe.php?id=<?php echo $r['rid']; ?>">Edit</a>
        </div>
    <?php endforeach; ?>
<?php endif; ?>

</body>
</html>
