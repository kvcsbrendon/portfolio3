<?php
session_start();
?>

<nav style="background:#eee;padding:10px;">
    <a href="index.php">Home</a> |
    <?php if (isset($_SESSION['uid'])): ?>
        <a href="add_recipe.php">Add Recipe</a> |
        <a href="my_recipes.php">My Recipes</a> |
        <a href="logout.php">Logout</a>
        <span style="float:right;">Hello, <?php echo htmlspecialchars($_SESSION['username']); ?>!</span>
    <?php else: ?>
        <a href="start.php">Login / Register</a> |
    <?php endif; ?>
</nav>
<hr>
