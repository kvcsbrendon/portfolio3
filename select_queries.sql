
--  1: Print out a whole recipe based on recipe ID(1), The RecipeID has to be changed 3 place
SET @recipe_id = 1;
SELECT 
    r.RecipeID,
    r.RecipeTitle,
    r.RecipeDescription,
    r.RecipePrepTime,
    r.RecipeCookTime,
    (r.RecipePrepTime + r.RecipeCookTime) AS TotalTime,
    c.CuisineName
FROM Recipe r
JOIN Cuisine c ON r.CuisineID = c.CuisineID
WHERE r.RecipeID = @recipe_id;

SELECT 
    ri.Amount,
    m.MeasurementName,
    i.IngredientName
FROM RecipeIngredients ri
JOIN Ingredients i ON ri.IngredientID = i.IngredientID
JOIN Measurements m ON ri.MeasurementID = m.MeasurementID
WHERE ri.RecipeID = @recipe_id
ORDER BY i.IngredientName;

SELECT 
    rs.StepNumber,
    rs.StepDescription
FROM RecipeSteps rs
WHERE rs.RecipeID = @recipe_id
ORDER BY  rs.StepNumber;

-- Query 2: Most used Ingredients(2)
SELECT 
    i.IngredientName,
    COUNT(ri.IngredientID) AS UsageCount
FROM RecipeIngredients ri
JOIN Ingredients i ON ri.IngredientID = i.IngredientID
GROUP BY i.IngredientName
ORDER BY UsageCount DESC
LIMIT 2;


-- Query 3: Longest recipes to make(3)
SELECT 
    RecipeID, 
    RecipeTitle, 
    (RecipePrepTime + RecipeCookTime) AS TotalTime
FROM Recipe
ORDER BY TotalTime DESC
LIMIT 3;

-- Query 4: Recipes with specific ingredient(Tomate Paste)
SELECT DISTINCT r.RecipeTitle
FROM Recipe r
JOIN RecipeIngredients ri ON r.RecipeID = ri.RecipeID
JOIN Ingredients i ON ri.IngredientID = i.IngredientID
WHERE i.IngredientName IN ('Tomato Paste')
GROUP BY r.RecipeID;

-- Query 5: Recipes with specific tags(Healthy)
SELECT DISTINCT r.RecipeTitle
FROM Recipe r
JOIN TagMap tm ON r.RecipeID = tm.RecipeID
JOIN RecipeTags rt ON tm.TagID = rt.TagID
WHERE rt.TagName IN ('Healthy')
GROUP BY r.RecipeID;

-- Query 6: Top Contributors
SELECT 
    cp.UserID, 
    cp.UserFirstName, 
    cp.UserLastName, 
    cp.ContributorAvgRating, 
    COUNT(r.RecipeID) AS NumberOfRecipes
FROM  ContributorProfile cp
LEFT JOIN  Recipe r ON cp.UserID = r.UserID
GROUP BY  cp.UserID
ORDER BY 
    cp.ContributorAvgRating DESC, 
    NumberOfRecipes DESC
LIMIT 3;

-- Query 7: Most popular recipes
SELECT 
    r.RecipeID, 
    r.RecipeTitle, 
    AVG(ui.Rating) AS AvgRating, 
    COUNT(ui.IsItLiked) AS LikeCount
FROM Recipe r
JOIN  UserInteractions ui ON r.RecipeID = ui.RecipeID
WHERE  ui.IsItLiked = TRUE
GROUP BY  r.RecipeID
ORDER BY 
    AvgRating DESC, 
    LikeCount DESC
LIMIT 3;

-- Query 8: Shortest Time to make + Most ingredients
SELECT 
    r.RecipeID, 
    r.RecipeTitle, 
    (r.RecipePrepTime + r.RecipeCookTime) AS TotalTime, 
    COUNT(ri.IngredientID) AS IngredientCount
FROM  Recipe r
JOIN  RecipeIngredients ri ON r.RecipeID = ri.RecipeID
GROUP BY  r.RecipeID
ORDER BY 
    TotalTime ASC, 
    IngredientCount DESC
LIMIT 3;


-- Query 9: Recipe title with a specific words(Chicken or Beef)
SELECT 
    RecipeID, 
    RecipeTitle
FROM  Recipe
WHERE 
    RecipeTitle LIKE '%Chicken%' 
    OR RecipeTitle LIKE '%Beef%';

-- Query 10: Recipe with specific title(chicken) and specific ingredient(yoghurt)
SELECT 
    r.RecipeID, 
    r.RecipeTitle
FROM Recipe r
JOIN  RecipeIngredients ri ON r.RecipeID = ri.RecipeID
JOIN Ingredients i ON ri.IngredientID = i.IngredientID
WHERE 
    r.RecipeTitle LIKE '%Chicken%' 
    AND i.IngredientName LIKE '%Yogurt%';
