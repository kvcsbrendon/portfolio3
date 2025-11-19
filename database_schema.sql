DROP DATABASE IF EXISTS RecipeDB;

CREATE DATABASE IF NOT EXISTS RecipeDB
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE RecipeDB;

CREATE TABLE LoginDetails (
    UserID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    Username VARCHAR(32) UNIQUE NOT NULL,
    EmailAddress VARCHAR(100) NOT NULL UNIQUE CHECK (EmailAddress REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'),
    PasswordHash VARCHAR(32) NOT NULL,
    PasswordSalt VARCHAR(8) NOT NULL,
    AccountCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE Table ContributorProfile (
    UserID INT NOT NULL PRIMARY KEY,
    UserFirstName VARCHAR(50) NOT NULL,
    UserLastName VARCHAR(100) NOT NULL,
    UserPronouns ENUM('He/Him', 'She/Her', 'They/Them', 'Prefer not to say') NOT NULL,
    UserDoB DATE NOT NULL,
    UserBio TEXT,
    EmailVerified BOOLEAN NOT NULL DEFAULT FALSE,
    CanPostRecipe BOOLEAN NOT NULL DEFAULT FALSE,
    ContributorAvgRating DECIMAL(3,2) DEFAULT NULL,

    FOREIGN KEY (UserID) REFERENCES LoginDetails(UserID) ON DELETE CASCADE
);

CREATE TABLE Cuisine (
    CuisineID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    CuisineName VARCHAR(50) NOT NULL
);

CREATE TABLE Recipe (
    RecipeID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    RecipeTitle VARCHAR(100) NOT NULL,
    RecipeDescription TEXT NOT NULL,
    RecipePrepTime INT NOT NULL,
    RecipeCookTime INT NOT NULL,
	RecipeTotalTime INT NOT NULL,
    RecipeDifficulty ENUM('Easy', 'Medium', 'Hard') NOT NULL,
    RecipeCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    LikesCount INT DEFAULT 0,
	AvgRating DECIMAL(3,2) DEFAULT 0.00,
    CuisineID INT NOT NULL,
    UserID INT NULL,
    
    FOREIGN KEY (CuisineID) REFERENCES Cuisine(CuisineID) ON DELETE NO ACTION,
    FOREIGN KEY (UserID) REFERENCES ContributorProfile(UserID) ON DELETE SET NULL
);


CREATE TABLE RecipeUpdateRequest (
    RequestID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ProposedChange TEXT NOT NULL,
    RequestStatus ENUM('Pending', 'Approved', 'Rejected') DEFAULT 'Pending',
    RequestSubmittedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    RecipeID INT NOT NULL,
    UserID INT NULL,


    FOREIGN KEY (RecipeID) REFERENCES Recipe(RecipeID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES ContributorProfile(UserID) ON DELETE SET NULL
);

CREATE TABLE UserInteractions (
    RatingID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    Rating DECIMAL(2,1) NOT NULL CHECK (Rating BETWEEN 1.0 AND 5.0),
    IsItLiked BOOLEAN DEFAULT FALSE,
    InteractedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    RecipeID INT NOT NULL,
    UserID INT NOT NULL,


    FOREIGN KEY (RecipeID) REFERENCES Recipe(RecipeID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES ContributorProfile(UserID) ON DELETE CASCADE,
    UNIQUE(UserID, RecipeID)
);

CREATE TABLE Measurements (
    MeasurementID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    MeasurementName VARCHAR(50) NOT NULL,
    MeasurementNameAlternative VARCHAR(75) UNIQUE,
    MeasurementCategory ENUM('Volume', 'Mass', 'Length', 'CountBased') NOT NULL
);

CREATE TABLE Ingredients (
    IngredientID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    IngredientName VARCHAR(50) NOT NULL,
    IngredientNameAlternative VARCHAR(75) UNIQUE
);

CREATE TABLE RecipeIngredients (
    Amount DECIMAL(6,2) NOT NULL,
    MeasurementID INT NOT NULL,
    IngredientID INT NOT NULL,
    RecipeID INT NOT NULL,

    FOREIGN KEY (MeasurementID) REFERENCES Measurements(MeasurementID) ON DELETE NO ACTION,
    FOREIGN KEY (IngredientID) REFERENCES Ingredients(IngredientID) ON DELETE NO ACTION,
    FOREIGN KEY (RecipeID) REFERENCES Recipe(RecipeID) ON DELETE CASCADE
);

CREATE TABLE RecipeSteps (
    StepID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    RecipeID INT NOT NULL,
    StepNumber INT NOT NULL,
    StepDescription TEXT NOT NULL,
    
    FOREIGN KEY (RecipeID) REFERENCES Recipe(RecipeID) ON DELETE CASCADE,
    UNIQUE(RecipeID, StepNumber)
);

CREATE TABLE RecipeImages (
    ImageID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    ImageURL VARCHAR(255) NOT NULL,
    ImageDescription VARCHAR(255) NOT NULL,
    RecipeID INT NOT NULL,

    FOREIGN KEY (RecipeID) REFERENCES Recipe(RecipeID) ON DELETE CASCADE
);

CREATE TABLE RecipeTags (
    TagID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    TagName VARCHAR(50) NOT NULL
);

CREATE TABLE TagMap (
    TagMapID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    TagID INT NOT NULL,
    RecipeID INT NOT NULL,

    FOREIGN KEY (TagID) REFERENCES RecipeTags(TagID) ON DELETE NO ACTION,
    FOREIGN KEY (RecipeID) REFERENCES Recipe(RecipeID) ON DELETE CASCADE
); 

CREATE TABLE RecipeComments (
    CommentID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    CommentText TEXT NOT NULL,
    CommentCreated TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UserID INT NOT NULL,
    RecipeID INT NOT NULL,

    FOREIGN KEY (UserID) REFERENCES ContributorProfile(UserID) ON DELETE CASCADE,
    FOREIGN KEY (RecipeID) REFERENCES Recipe(RecipeID) ON DELETE CASCADE
);
CREATE TABLE RecipeFavourites (
    FavouriteID INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    UserID INT NOT NULL,
    RecipeID INT NOT NULL,

    FOREIGN KEY (UserID) REFERENCES ContributorProfile(UserID) ON DELETE CASCADE,
    FOREIGN KEY (RecipeID) REFERENCES Recipe(RecipeID) ON DELETE CASCADE,
    UNIQUE(UserID, RecipeID)
);

CREATE INDEX idx_recipe_title ON Recipe(RecipeTitle);
CREATE INDEX idx_ingredient_name ON Ingredients(IngredientName);
CREATE INDEX idx_recipe_tags ON RecipeTags(TagName);
CREATE INDEX idx_email_address ON LoginDetails(EmailAddress);


CREATE OR REPLACE VIEW ContributorRatings AS
SELECT UserID, ROUND(AVG(Rating), 2) AS AvgRating
FROM UserInteractions
GROUP BY UserID;


DELIMITER $$

CREATE TRIGGER afterRatingInsert
AFTER INSERT ON UserInteractions
FOR EACH ROW
BEGIN
    UPDATE ContributorProfile
    SET ContributorAvgRating = (
        SELECT AVG(Rating)
        FROM UserInteractions
        WHERE UserID = NEW.UserID
    )
    WHERE UserID = NEW.UserID;
END$$

CREATE TRIGGER checkContributorPermissions
BEFORE INSERT ON Recipe
FOR EACH ROW
BEGIN
    DECLARE emailVerifiedStatus BOOLEAN;
    DECLARE canPostRecipeStatus BOOLEAN;

    SELECT EmailVerified, CanPostRecipe INTO emailVerifiedStatus, canPostRecipeStatus
    FROM ContributorProfile
    WHERE UserID = NEW.UserID;

    IF emailVerifiedStatus = FALSE OR canPostRecipeStatus = FALSE THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'User does not have permission to post recipes.';
    END IF;
END$$

-- The following trigger is used to enforce email format validation
-- In MySQL versions before 8.0.16 and MariaDB versions before 10.2.1
-- As those versions just either threw an error for constraints or straight up ignored it.

-- Also provides a more user friendly error message!

CREATE TRIGGER checkEmailBeforeInsert
BEFORE INSERT ON LoginDetails
FOR EACH ROW
BEGIN
    IF NEW.EmailAddress NOT REGEXP '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Invalid email format: Must be in user@example.com format';
    END IF;
END $$

CREATE TRIGGER calculateTotalTime
BEFORE INSERT ON Recipe
FOR EACH ROW
BEGIN
    SET NEW.RecipeTotalTime = NEW.RecipePrepTime + NEW.RecipeCookTime;
END $$

CREATE TRIGGER after_insert_interaction
AFTER INSERT ON UserInteractions
FOR EACH ROW
BEGIN
    IF NEW.IsItLiked = TRUE THEN
        UPDATE Recipe 
        SET LikesCount = LikesCount + 1 
        WHERE RecipeID = NEW.RecipeID;
    END IF;
END$$

CREATE TRIGGER after_insert_rating
AFTER INSERT ON UserInteractions
FOR EACH ROW
BEGIN
    UPDATE Recipe 
    SET AvgRating = (
        SELECT ROUND(AVG(Rating), 2) 
        FROM UserInteractions 
        WHERE RecipeID = NEW.RecipeID
    )
    WHERE RecipeID = NEW.RecipeID;
END$$


DELIMITER ;

/* ======================================== */
/*         INSERT Statements Section        */
/* ======================================== */

/* ============================= */
/*      LoginDetails Table       */
/* ============================= */
INSERT INTO LoginDetails (Username, EmailAddress, PasswordHash, PasswordSalt)
VALUES
    ('kevinharvey45', 'kevin.harvey@yahoo.co.uk', '$2a$04$WHVzsxmMmZQoZ5n/5irBdOOio', '1d13511f'),
    ('karlbarker24', 'karl.barker@yahoo.com', '$2a$04$O/fAL3AYb4QAVmmNzz/jzOqbY', 'ec92f29c'),
    ('mauriceross61', 'maurice.ross@hotmail.co.uk', '$2a$04$mSGXpJalu3doZJuuprjB4eiRu', '3861048b'),
    ('maxnicholls64', 'max.nicholls@gmail.com', '$2a$04$CFGEaEcRAjlLYq0px99kse3y2', 'a2531d0f'),
    ('kevinthomas52', 'kevin.thomas@gmail.com', '$2a$04$zX0U7pUpEpnJQ3hwx/bqbOotj', 'f25ea948'),
    ('tracyholmes92', 'tracy.holmes@gmail.com', '$2a$04$TNTPJrru2pZYjp64z28L.e8Kv', 'bf6be780'),
    ('carlwillis27', 'carl.willis@hotmail.com', '$2a$04$egQD1WWEngeszTQYnv.eOu6qt', 'ee69a9a7'),
    ('juliaali79', 'julia.ali@gmail.com', '$$2a$04$nIPipT2glyIAR1capZrloOfxS', '1774e91c'),
    ('charlottechapman55', 'charlotte.chapman@gmail.com', '$2a$04$e9dTNHm/1w0z3BTzkFqdUe4KR', '3994a46a'),
    ('dannyfoster83', 'danny.foster@yahoo.co.uk', '$2a$04$DVu/a8ar1TMRpsRdbW5z9t0pc', '9bf80522');

/* ============================= */
/*   ContributorProfile Table    */
/* ============================= */
INSERT INTO ContributorProfile (UserID, UserFirstName, UserLastName, UserPronouns, UserDoB, UserBio, EmailVerified, CanPostRecipe)
VALUES
    (1, 'Kevin', 'Harvey', 'They/Them', '1977-04-03', 'My favorite cuisine is Greek, and I\'m always trying new dishes.', TRUE, TRUE),
    (2, 'Karl', 'Barker', 'He/Him', '1994-11-25', 'I love cooking and exploring different recipes. My favorite cuisine is Mexican', TRUE, TRUE),
    (3, 'Maurice', 'Ross', 'He/Him', '1976-10-2', 'Hi, I\'m Maurice!  and I\'m always trying new dishes.', FALSE, TRUE),
    (4, 'Max', 'Nicholls', 'They/Them', '1976-01-22', 'My favorite cuisine is Japanese', TRUE, TRUE),
    (5, 'Kevin', 'Thomas', 'Prefer not to say', '1991-01-19', 'Hi, I\'m Kevin! I love cooking and exploring different recipes. My favorite cuisine is Indian, and I\'m always trying new dishes.', TRUE, TRUE),
    (6, 'Tracy', 'Holmes', 'She/Her', '1983-04-22', 'Hi, I\'m Tracy!', FALSE, TRUE),
    (7, 'Carl', 'Willis', 'Prefer not to say', '1994-02-23', 'Love Spanish Food', TRUE, TRUE),
    (8, 'Julia', 'Ali', 'She/Her', '1995-06-19', 'Chinese takeaway rules!', TRUE, TRUE),
    (9, 'Charlotte', 'Chapman', 'She/Her', '1958-04-16', 'My favorite cuisine is French', TRUE, FALSE),
    (10, 'Danny', 'Foster', 'They/Them', '1964-02-27', 'My favorite cuisine is British, and I\'m always trying new dishes.', TRUE, FALSE);

/* ============================= */
/*        Cuisine Table          */
/* ============================= */
INSERT INTO Cuisine (CuisineName) 
VALUES 
    ('Italian'),
    ('Greek'),
    ('Mexican'),
    ('Japanese'),
    ('Indian'),
    ('Spanish'),
    ('Chinese'),
    ('French'),
    ('British'),
    ('Arabic'),
    ('Thai');

/* ============================= */
/*      Measurements Table       */
/* ============================= */
INSERT INTO Measurements (MeasurementName, MeasurementNameAlternative, MeasurementCategory) 
VALUES
    ('Milliliter', 'mL', 'Volume'),
    ('Liter', 'L', 'Volume'),
    ('Teaspoon', 'tsp', 'Volume'),
    ('Tablespoon', 'tbsp', 'Volume'),
    ('Fluid Ounce', 'fl oz', 'Volume'),
    ('Cup', NULL, 'Volume'),
    ('Pint', 'pt', 'Volume'),
    ('Gallon', 'gal', 'Volume'),
    ('Gram', 'g', 'Mass'),
    ('Kilogram', 'kg', 'Mass'),
    ('Ounce', 'oz', 'Mass'),
    ('Centimeter', 'cm', 'Length'),
    ('Inch', 'in', 'Length'),
    ('Piece', NULL, 'CountBased'),
    ('Whole', NULL, 'CountBased'),
    ('Slice', NULL, 'CountBased'),
    ('Clove', NULL, 'CountBased'),
    ('Pinch', NULL, 'CountBased'),
    ('Dash', NULL, 'CountBased');

/* ============================= */
/*      Ingredients Table        */
/* ============================= */
INSERT INTO Ingredients (IngredientName, IngredientNameAlternative) 
VALUES
    -- Spaghetti Bolognese ingredients
    ('Spaghetti', NULL),
    ('Ground Beef', 'Minced Beef'),
    ('Onion', NULL),
    ('Garlic', NULL),
    ('Tomato Paste', 'Tomato Puree'),
    ('Canned Tomatoes', 'Tinned Tomatoes'),
    ('Oregano', NULL),
    ('Basil', NULL),
    ('Olive Oil', NULL),
    
    -- Greek Moussaka ingredients
    ('Eggplant', 'Aubergine'),
    ('Ground Lamb', 'Minced Lamb'),
    ('All-Purpose Flour', 'Plain Flour'),
    ('Milk', NULL),
    ('Butter', NULL),
    ('Nutmeg', NULL),
    ('Parmesan Cheese', 'Parmigiano Reggiano'),
    ('Cinnamon', NULL),
    
    -- Chicken Tikka Masala ingredients
    ('Chicken Breast', 'Chicken Fillets'),
    ('Plain Yogurt', 'Natural Yoghurt'),
    ('Heavy Cream', 'Double Cream'),
    ('Garam Masala', NULL),
    ('Turmeric', 'Haldi'),
    ('Ground Cumin', 'Jeera Powder'),
    ('Ground Coriander', 'Dhania Powder'),
    ('Fresh Ginger', NULL),
    
    -- Beef Tacos ingredients
    ('Corn Tortillas', NULL),
    ('Chili Powder', NULL),
    ('Lettuce', NULL),
    ('Cheddar Cheese', NULL),
    ('Sour Cream', NULL),
    
    -- Sushi Rolls ingredients
    ('Sushi Rice', 'Japanese Rice'),
    ('Nori', 'Seaweed Sheet'),
    ('Rice Vinegar', NULL),
    ('Imitation Crab', 'Crab Stick'),
    ('Wasabi', 'Horseradish'),
    ('Soy Sauce', 'Shoyu'),
    
    -- Ingredients not used anywhere
    ('Tofu', NULL),
    ('Sweet Potato', 'Kumara'),
    ('Coconut Milk', NULL),
    ('Lemongrass', NULL),
    ('Tahini', 'Sesame Paste');

/* ============================= */
/*        Recipe Table           */
/* ============================= */
INSERT INTO Recipe (RecipeTitle, RecipeDescription, RecipePrepTime, RecipeCookTime, RecipeDifficulty, CuisineID, UserID) 
VALUES
    -- User 1's Recipes (Kevin Harvey)
    ('Spaghetti Bolognese', 'A classic Italian dish made with spaghetti, meat sauce, and aromatic herbs.', 30, 45, 'Medium', 1, 1),
    ('Greek Moussaka', 'Layered eggplant, spiced ground meat, and béchamel sauce.', 60, 45, 'Hard', 2, 1),
    
    -- User 2's Recipes (Karl Barker)
    ('Chicken Tikka Masala', 'Tender chicken pieces in a rich, creamy curry sauce.', 45, 35, 'Medium', 5, 2),
    ('Beef Tacos', 'Crispy corn tortillas filled with seasoned ground beef and toppings.', 20, 25, 'Easy', 3, 2),
    
    -- One recipe from User 4 (Max Nicholls)
    ('Sushi Rolls', 'Fresh California rolls with crab, avocado, and cucumber.', 45, 15, 'Hard', 4, 4);



/* ============================= */
/*       RecipeSteps Table       */
/* ============================= */
INSERT INTO RecipeSteps (RecipeID, StepNumber, StepDescription)
VALUES
    (1, 1, "Boil water in a large pot and cook spaghetti until al dente."),
    (1, 2, "Heat olive oil in a pan and sauté onions and garlic until fragrant."),
    (1, 3, "Add ground beef and cook until browned."),
    (1, 4, "Stir in tomato paste, canned tomatoes, oregano, and basil. Simmer for 30 minutes."),
    (1, 5, "Drain spaghetti and mix with the sauce. Serve hot."),

    (2, 1, "Preheat oven to 375°F (190°C)."),
    (2, 2, "Slice eggplants, salt them, and let sit for 20 minutes. Rinse and pat dry."),
    (2, 3, "Brown ground lamb in a pan and add spices."),
    (2, 4, "Prepare béchamel sauce with butter, flour, and milk."),
    (2, 5, "Layer eggplants, meat sauce, and béchamel in a baking dish."),
    (2, 6, "Bake for 45 minutes until golden brown. Let cool before serving."),

    (3, 1, "Marinate chicken in yogurt, spices, and lemon juice for at least 1 hour."),
    (3, 2, "Heat oil in a pan and cook marinated chicken until browned."),
    (3, 3, "Prepare the sauce by sautéing onions, garlic, and ginger."),
    (3, 4, "Add tomatoes, heavy cream, and garam masala. Simmer for 20 minutes."),
    (3, 5, "Stir in cooked chicken and let simmer for 10 more minutes. Serve hot."),

    (4, 1, "Heat oil in a pan and cook ground beef with chili powder and cumin."),
    (4, 2, "Warm up corn tortillas in a dry skillet."),
    (4, 3, "Assemble tacos by filling tortillas with beef, lettuce, cheese, and sour cream."),
    (4, 4, "Serve immediately with lime wedges."),

    (5, 1, "Cook sushi rice and season with rice vinegar."),
    (5, 2, "Lay a sheet of nori on a bamboo mat and spread a thin layer of rice over it."),
    (5, 3, "Place imitation crab, avocado, and cucumber along the center."),
    (5, 4, "Roll tightly using the bamboo mat and slice into pieces."),
    (5, 5, "Serve with soy sauce, wasabi, and pickled ginger.");


/* ============================= */
/*   RecipeIngredients Table     */
/* ============================= */
INSERT INTO RecipeIngredients (Amount, MeasurementID, IngredientID, RecipeID)
VALUES
    -- Spaghetti Bolognese (RecipeID: 1)
    (500, 9, 1, 1),   -- 500g Spaghetti
    (400, 9, 2, 1),   -- 400g Ground Beef
    (1, 14, 3, 1),    -- 1 Piece Onion
    (3, 17, 4, 1),    -- 3 Cloves Garlic
    (2, 4, 5, 1),     -- 2 Tablespoons Tomato Paste
    (400, 9, 6, 1),   -- 400g Canned Tomatoes
    (1, 3, 7, 1),     -- 1 Teaspoon Oregano
    (2, 4, 9, 1),     -- 2 Tablespoons Olive Oil
    (200, 9, 29, 1),  -- 200g Cheddar Cheese

    -- Greek Moussaka (RecipeID: 2)
    (2, 14, 10, 2),   -- 2 Pieces Eggplant
    (500, 9, 11, 2),  -- 500g Ground Lamb
    (4, 4, 12, 2),    -- 4 Tablespoons All-Purpose Flour
    (500, 1, 13, 2),  -- 500ml Milk
    (100, 9, 14, 2),  -- 100g Butter
    (1, 3, 15, 2),    -- 1 Teaspoon Nutmeg
    (100, 9, 16, 2),  -- 100g Parmesan Cheese
    (1, 3, 17, 2),    -- 1 Teaspoon Cinnamon

    -- Chicken Tikka Masala (RecipeID: 3)
    (750, 9, 18, 3),  -- 750g Chicken Breast
    (200, 1, 19, 3),  -- 200ml Plain Yogurt
    (200, 1, 20, 3),  -- 200ml Heavy Cream
    (2, 3, 21, 3),    -- 2 Teaspoons Garam Masala
    (1, 3, 22, 3),    -- 1 Teaspoon Turmeric
    (3, 17, 4, 3),    -- 3 Cloves Garlic
    (2, 3, 23, 3),    -- 2 Teaspoons Ground Cumin
    (1, 3, 24, 3),    -- 1 Teaspoon Ground Coriander
    (2, 4, 25, 3),    -- 2 Tablespoons Fresh Ginger

    -- Beef Tacos (RecipeID: 4)
    (8, 14, 26, 4),   -- 8 Pieces Corn Tortillas
    (2, 3, 27, 4),    -- 2 Teaspoons Chili Powder
    (200, 1, 19, 4),  -- 200ml Plain Yogurt
    (2, 14, 28, 4),   -- 2 Pieces Lettuce
    (3, 17, 4, 4),    -- 3 Cloves Garlic
    (200, 9, 29, 4),  -- 200g Cheddar Cheese
    (4, 4, 30, 4),    -- 4 Tablespoons Sour Cream

    -- Sushi Rolls (RecipeID: 5)
    (300, 9, 31, 5),  -- 300g Sushi Rice
    (4, 14, 32, 5),   -- 4 Pieces Nori
    (3, 4, 33, 5),    -- 3 Tablespoons Rice Vinegar
    (200, 9, 34, 5),  -- 200g Imitation Crab
    (1, 3, 35, 5),    -- 1 Teaspoon Wasabi
    (4, 4, 36, 5);    -- 4 Tablespoons Soy Sauce


/* ============================= */
/*       RecipeImages Table      */
/* ============================= */
INSERT INTO RecipeImages (ImageURL, ImageDescription, RecipeID) 
VALUES
    ('https://example.com/Spaghetti_Bolognese.jpg', 'Spaghetti Bolognese', 1),
    ('https://example.com/Greek_Moussaka.jpg', 'Greek Moussaka', 2),
    ('https://example.com/Chicken_Tikka_Masala.jpg', 'Chicken Tikka Masala', 3),
    ('https://example.com/Beef_Tacos', 'Beef Tacos', 4),
    ('https://example.com/Sushi_Rolls', 'Sushi Rolls', 5);

/* ============================= */
/*        RecipeTags Table       */
/* ============================= */
INSERT INTO RecipeTags (TagName) 
VALUES
    ('Pasta'),
    ('Curry'),
    ('Spicy'),
    ('Healthy'),
    ('Quick & Easy'),
    ('Dinner'),
    ('Comfort Food'),
    ('Authentic'),
    ('Traditional'),
    ('Seafood'),
    ('Homemade'),
    ('Cheesy'),
    ('Grilled');

/* ============================= */
/*         TagMap Table          */
/* ============================= */
INSERT INTO TagMap (TagID, RecipeID)
VALUES
    (1, 1),  -- Pasta
    (6, 1),  -- Dinner
    (7, 1),  -- Comfort Food
    (11, 1), -- Homemade

    (8, 2),  -- Authentic
    (9, 2),  -- Traditional
    (6, 2),  -- Dinner
    (12, 2), -- Cheesy

    (2, 3),  -- Curry
    (3, 3),  -- Spicy
    (8, 3),  -- Authentic
    (6, 3),  -- Dinner

    (5, 4),  -- Quick & Easy
    (6, 4),  -- Dinner
    (13, 4), -- Grilled

    (4, 5),  -- Healthy
    (10, 5), -- Seafood
    (11, 5); -- Homemade

/* ============================= */
/*    UserInteractions Table     */
/* ============================= */
INSERT INTO UserInteractions (Rating, IsItLiked, RecipeID, UserID)
VALUES
    (3.2, 1, 1, 1),
    (3.2, 1, 1, 2),
    (5.0, 1, 2, 2),
    (4.4, 1, 2, 4),
    (3.4, 1, 5, 1),
    (1.9, 0, 5, 2);

/* ============================= */
/*     RecipeComments Table      */
/* ============================= */
INSERT INTO RecipeComments (CommentText, UserID, RecipeID)
VALUES
    ('A classic comfort meal, will definitely make again.', 1, 1),
    ('The spaghetti was cooked perfectly, and the sauce was rich and flavorful!', 2, 1),

    ('The bechamel sauce was creamy and delicious!', 1, 2),

    ('I would add a bit more cream next time for extra richness.', 1, 3),
    ('The spice level was perfect, and the chicken was so tender.', 2, 3);

/* ============================= */
/*  RecipeUpdateRequest Table    */
/* ============================= */
INSERT INTO RecipeUpdateRequest (ProposedChange, RequestStatus, RecipeID, UserID)
VALUES
    ('Increase the wasabi from 1 tsp to 2 tsp for better taste.', 'Pending', 2, 1),
    ('Change cooking time from 35 minutes to 40 minutes for better texture.', 'Pending', 3, 2),
    ('Add an optional spicy version by including chili flakes.', 'Pending', 4, 2);


/* ============================= */
/*    RecipeFavourites Table     */
/* ============================= */

INSERT INTO RecipeFavourites (UserID, RecipeID)
VALUES
    (4, 1),
    (2, 2),
    (4, 2),
    (2, 3),
    (4, 4),
    (1, 5),
    (2, 5);