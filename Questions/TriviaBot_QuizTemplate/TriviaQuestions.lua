local _,TriviaBot_Questions = ...
-- Initialize arrays
TriviaBot_Questions[1] = {['Categories'] = {}, ['Question']= {}, ['Answers']= {}, ['Category']= {}, ['Points']= {}, ['Hints']= {}};
-- -------------------------------------------------- --
 --[[ DO NOT EDIT OR REMOVE ANYTHING ABOVE THIS LINE ]]
-- -------------------------------------------------- --

-- Quiz general information
TriviaBot_Questions[1]['Title'] = "Title of the List"; -- Title of the quiz
TriviaBot_Questions[1]['Description'] = "Description of the List"; -- Little description of the quiz
TriviaBot_Questions[1]['Author'] = "Author of the List"; -- Author of the quiz

-- Add categories (optional)
TriviaBot_Questions[1]['Categories'][1] = "Category 1"; -- Just add your own categories and as many as you like
TriviaBot_Questions[1]['Categories'][2] = "Category 2";
TriviaBot_Questions[1]['Categories'][3] = "Category 3";
TriviaBot_Questions[1]['Categories'][4] = "Category 4";

-- Points: Difficulty 1: 5-9 - Difficulty 2: 10-15 - Difficulty 3: 16-20
-- Add questions
TriviaBot_Questions[1]['Question'][1] = "What category is this question in?"; -- required
TriviaBot_Questions[1]['Answers'][1] = {"1", "One"}; -- required
TriviaBot_Questions[1]['Category'][1] = 1; -- First category (optional)
TriviaBot_Questions[1]['Points'][1] = 5; -- Amount of points this question should grant (optional)
TriviaBot_Questions[1]['Hints'][1] = {"Rhymes with fun", "Comes before two"}; -- (optional)

TriviaBot_Questions[1]['Question'][2] = "What category is this question in?";
TriviaBot_Questions[1]['Answers'][2] = {"2", "Two"};
TriviaBot_Questions[1]['Category'][2] = 2; -- Second category
TriviaBot_Questions[1]['Points'][2] = 5;
TriviaBot_Questions[1]['Hints'][2] = {"Rhymes with boo", "Comes before three"};

TriviaBot_Questions[1]['Question'][3] = "What category is this question in?";
TriviaBot_Questions[1]['Answers'][3] = {"3", "Three"};
TriviaBot_Questions[1]['Category'][3] = 3; -- Third category
TriviaBot_Questions[1]['Points'][3] = 5;
TriviaBot_Questions[1]['Hints'][3] = {"Rhymes with bee", "Comes before four"};

TriviaBot_Questions[1]['Question'][4] = "What category is this question in?";
TriviaBot_Questions[1]['Answers'][4] = {"4", "Four"};
TriviaBot_Questions[1]['Category'][4] = 4; -- Fourth category
TriviaBot_Questions[1]['Points'][4] = 5;
TriviaBot_Questions[1]['Hints'][4] = {"Rhymes with more", "Comes before five"};

-- You decide how many hints each question should have if any
-- The amount of points is your decision, as long as it's over 0 