=================== INTRODUCTION ======================
	Starting with version 2.8.0 and later TriviaBot will 
no longer come with built-in Question Lists.
Instead the question lists come in the form of separate
"Load on Demand" Addons.
	
	This is so users can pick and choose question lists 
for their language or subjects that interest them without
having to wait for the whole addon to be repackaged.
It also allows the game to load faster as the Question Lists
are only loaded after the user selects them from TriviaBot
control panel in-game.

	If you are only going to use prepackaged Quizzes
from other users or the TriviaBot Team you can stop reading
now.

These are downloaded and installed like any other addon and
will appear on the TriviaBot Quiz dropdown in-game.
You just select one and host your quiz game.

If you are interested in creating a new Quiz with your
own questions keep reading :-)

------------ CREATING A QUESTION LIST ADDON -----------
	The <Questions> folder in TriviaBot now comes with an
example QuestionList addon.
This does not get loaded by TriviaBot.
To use it as a template for creating your own Question List,
the following steps are necessary:

	1. Copy the <TriviaBot_QuizTemplate> folder to your
	\World of Warcraft\Interface\AddOns\ folder.
	
	2. Rename it to whatever you want your question list to
	contain. Example: <TriviaBot_QuizWoW1English>
	
	3. Inside the folder you will find 3 files:
	a. TriviaBot_QuizTemplate.toc
	b. core.lua
	c. TriviaQuestions.lua
	
	3a. toc file
	You will need to rename the .toc file to have the exact
	same name as what you picked for the addon folder.
	In our example: TriviaBot_QuizWoW1English.toc
	After you renamed it, open it in a text editor.
	## Interface: 40300  
		- is the game version for which the addon is compatible.
	## Title: TriviaBot QuestionList 
		- is the name by which your question list will appear 
		in the addons list inside the game.
	## Notes: Title of the set
		- is the name by which your question list will appear 
		in the TriviaBot addon Question List dropdown.
		Edit this to whatever your question list containts;
		a good idea is to put the same as your TriviaQuestions.lua
		file contains in the 'Title' field.
	## Author: Author of the set
		- you can put your name, toon's name or nickname as creator
		of the quiz.
	Do not modify the section contained within the warning text :)
	
	3b. core.lua file
	Do not rename, edit or modify core.lua at all.
	
	3c. TriviaQuestions.lua file
	The TriviaQuestions.lua file is the one that will contain your 
	questions, answers, hints, points; the content of your quiz.
	------------- Creating your Quiz --------------------
	Manually:
		If you intend to create a quiz for a language other 
	than English make sure your text editor supports opening 
	and saving text files in UTF8 format so non-ascii characters 
	like 'ψ' 'æ' 'ñ' 'ć' 'ů' are properly handled.
		Open the file in the text editor of your choice and you will find
	inside it comments with instructions on how to create your own quiz.
	The first line must not be edited.	
	
	With the help of TriviaBot_QuestionMaker:
		Alternatively you can use another World of Warcraft addon
	to help you create the quiz in-game.
	You can get the addon at Curse Gaming:
	http://wow.curse.com/downloads/wow-addons/details/triviabot_questionmaker.aspx
	or WoWinterface:
	http://www.wowinterface.com/downloads/info18767
	
	Usage instructions are found on the TriviaBot_QuestionMaker adddon pages.
	
After your question list addon is ready you can start the game,
enable it at the addon selection screen and find it listed in the
TriviaBot Quiz dropdown.