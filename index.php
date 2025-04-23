<?php
include 'navbar.php';
require 'config.php';

// Get search input
$searchName = $_GET['name'] ?? '';
$searchType = $_GET['type'] ?? '';

// Build query
$sql = "SELECT rid, name, description, type, image FROM recipes WHERE 1";
$params = [];

if (!empty($searchName)) {
    $sql .= " AND name LIKE ?";
    $params[] = "%" . $searchName . "%";
}

if (!empty($searchType)) {
    $sql .= " AND type = ?";
    $params[] = $searchType;
}

$sql .= " ORDER BY rid DESC LIMIT 20";

$stmt = $pdo->prepare($sql);
$stmt->execute($params);
$recipes = $stmt->fetchAll();
?>

<!DOCTYPE html>
<html>
<head>
    <title>Virtual Kitchen - Home</title>
    <style>
        body {
            font-family: sans-serif;
        }
        .recipe-container {
            display: flex;
            flex-wrap: wrap;
            gap: 20px;
        }
        .recipe-card {
            background: #f9f9f9;
            border: 1px solid #ccc;
            border-radius: 10px;
            padding: 15px;
            width: 300px;
        }
        .recipe-card img {
            width: 100%;
            height: auto;
            border-radius: 8px;
        }
        .view-button {
            display: inline-block;
            margin-top: 10px;
            padding: 6px 12px;
            background-color: #0077cc;
            color: #fff;
            text-decoration: none;
            border-radius: 4px;
        }
        .search-form {
            margin-bottom: 20px;
            padding: 10px;
            background: #f0f0f0;
            border-radius: 10px;
            max-width: 600px;
        }
    </style>
</head>
<body>

    <h1>Welcome to Virtual Kitchen! 🍽️</h1>

    <form class="search-form" method="GET" action="index.php">
        <label>Search by name:</label>
        <input type="text" name="name" value="<?php echo htmlspecialchars($searchName); ?>">

        <label>Type:</label>
        <select name="type">
            <option value="">-- Any --</option>
            <?php
            $types = ['French', 'Italian', 'Chinese', 'Indian', 'Mexican', 'Others'];
            foreach ($types as $t):
            ?>
                <option value="<?php echo $t; ?>" <?php if ($searchType === $t) echo 'selected'; ?>>
                    <?php echo $t; ?>
                </option>
            <?php endforeach; ?>
        </select>

        <input type="submit" value="Search">
    </form>

    <div class="recipe-container">
        <?php if (count($recipes) === 0): ?>
            <p>No recipes found.</p>
        <?php else: ?>
            <?php foreach ($recipes as $r): ?>
                <div class="recipe-card">
                    <?php if (!empty($r['image'])): ?>
                        <img src="<?php echo htmlspecialchars($r['image']); ?>" alt="Recipe image">
                    <?php endif; ?>
                    <h3><?php echo htmlspecialchars($r['name']); ?></h3>
                    <small><em><?php echo htmlspecialchars($r['type']); ?></em></small>
                    <p><?php echo nl2br(htmlspecialchars(substr($r['description'], 0, 100))) . "..."; ?></p>
                    <a class="view-button" href="view_recipe.php?id=<?php echo $r['rid']; ?>">View Recipe</a>
                </div>
            <?php endforeach; ?>
        <?php endif; ?>
    </div>

</body>
</html>
