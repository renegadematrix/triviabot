-- Default (enUS)

do
	TriviaBotLocalization = setmetatable( {
			-- Zones --
			TB_ZONE_AB = "Arathi Basin",
			TB_ZONE_WSG = "Warsong Gulch",
			TB_ZONE_AV = "Alterac Valley",
			TB_ZONE_EOTS = "Eye of the Storm",
			TB_ZONE_SOTA = "Strand of the Ancients",
			TB_ZONE_IOC = "Isle of Conquest",
			TB_ZONE_TBFG = "The Battle for Gilneas",
			TB_ZONE_TP = "Twin Peaks",
			-- GUI --
			TB_GUI_WIDTH = "350", -- v2.8.0.1
			TB_GUI_PRINT_WIDTH = "45", -- v2.8.0.1
			TB_GUI_UPDATE_WIDTH = "70", -- v2.8.0.1
			TB_GUI_QUESTIONLIST = "Quiz List:", -- 2.8.5
			TB_GUI_PRINT = "Print",
			TB_GUI_CATEGORYLIST = "Category List:",
			TB_GUI_CHATTYPE = "Chat Type:",
			TB_GUI_UPDATE = "Update",
			TB_GUI_CUSTOMCHANNEL = "Custom Channel:",
			TB_GUI_ROUNDSIZE = "Round Size:",
			TB_GUI_QUESTIONINTERVAL = "Question Interval:",
			TB_GUI_QUESTIONTIMEOUT = "Question Timeout:",
			TB_GUI_TIMEOUTWARNING = "Timeout Warning:",
			TB_GUI_TOPSCORECOUNT = "Top Score Count:",
			TB_GUI_TOPSCOREINTERVAL = "Top Score Interval:",
			TB_GUI_ANSWERSSHOWN = "Answers Shown:",
			TB_GUI_SHOWANSWERS = "Show Answers",
			TB_GUI_SHOWREPORTS = "Show Reports",
			TB_GUI_SHOWHINTS = "Show Hints",
			TB_GUI_SHOWWHISPERS = "Show Whispers",
			TB_GUI_REPORTWINSTREAK = "Report Win Streak",
			TB_GUI_REPORTPERSONAL = "Report Personal",
			TB_GUI_POINTMODE = "Point Mode",
			TB_GUI_SHORTCHANNEL = "Short Channel Tag",
			TB_GUI_STARTTRIVIA = "Start TriviaBot",
			TB_GUI_STOPTRIVIA = "Stop TriviaBot",
			TB_GUI_SKIPQUESTION = "Skip Question",
			TB_GUI_GAMESCORES = "Game Scores",
			TB_GUI_QUESTIONMAKER = "Quiz Maker",
			TB_GUI_RELOAD = "Reload",
			TB_GUI_ALLTIMESCORES = "All-Time Scores",
			TB_GUI_CHANNELCHANGE = "Changing...",
			TB_GUI_LOD = "Load on Demand", -- v2.8
			TB_GUI_NOPACKS = "No Quiz Found!", -- v2.8
			TB_GUI_ALL = "All", -- v2.8
			TB_GUI_ANSWERSSHOWN_TIP = "If \'Show Answers\' is selected\nchoose how many answers to display.\nDefault = 0 (\'all\').", -- 2.84
			TB_GUI_PANELCONTROL_TIP = "Click and Drag to move.\nDouble-click to minimize and maximize.", -- 2.84
			TB_GUI_CLOSE_TIP = "Closes the TriviaBot control panel.\nWill not interrupt a quiz in progress!\nUse /trivia to bring it up again.", -- 2.84
			-- Print --
			TB_PRINT_OUTOFQUESTIONS = "Out of questions - Restarting",
			TB_PRINT_CHANNELCHANGE = "Channel changed to: ",
			TB_PRINT_SCORESCLEARED = "Game scores cleared.",
			TB_PRINT_ALLSCORESCLEARED = "All-Time scores cleared.",
			TB_PRINT_HELP = "---TriviaBot Help---",
			TB_PRINT_CMDCLEAR = "/trivia clear - Clear current game data",
			TB_PRINT_CMDCLEARALL = "/trivia clearall - Clear current all-time score data",
			TB_PRINT_CMDHELP = "/trivia help - Help on TriviaBot commands",
			TB_PRINT_CMDRESET = "/trivia reset - Reset configuration to defaults",
			TB_PRINT_QUESTIONCOUNT = "Questions loaded successfully. Question count: ",
			TB_PRINT_DATABASENAME = "Database Name: ",
			TB_PRINT_HYPHENDESCRIPTION = " - Description: ",
			TB_PRINT_HYPHENAUTHORS = " - Author(s): ",
			TB_PRINT_HYPHENCATEGORY = " - Category: ",
			TB_PRINT_BLANKLOADED = " loaded.",
			TB_PRINT_NOQUESTIONLOAD = " had no questions to load.",
			TB_PRINT_SWITCHDATABASE = "Switching trivia database to: ",
			TB_PRINT_DOTDESCRIPTION = ". Description: ",
			TB_PRINT_DOTAUTHOR = ". Author: ",
			TB_PRINT_CATEGORYID = "Category ID: ",
			TB_PRINT_NOTEXIST = " does not exist",
			TB_PRINT_AVAILABLECATEGORIES = "Available categories of trivia:",
			TB_PRINT_ID0 = "ID: 0 - all",
			TB_PRINT_QUESTIONSETID = "Question-Set ID: ",
			TB_PRINT_LIBRARIES = "Available Libraries of trivia:",
			TB_PRINT_RESETCONFIG = "Resetting configuration to default values",
			TB_PRINT_NEWCONFIG = "Creating new configuation.",
			TB_PRINT_OLDDETECTUPGRADE = "Old version detected, upgrading to new version.",
			TB_PRINT_OLD = "Old: ",
			TB_PRINT_NEW = " New: ",
			TB_PRINT_VERSION = "Version ",
			TB_PRINT_CHANNELLEAVE = "Leave another channel before setting a new custom channel",
			TB_PRINT_NOCHATEVENTS = "No chat events registered",
			TB_PRINT_QUESTIONSKIP = "Question skipped",
			TB_PRINT_FIRSTQUESTION = "First question coming up!",
			TB_PRINT_TRIVIASTOPPED = "Trivia stopped.",
			TB_PRINT_NOCHATEVENTSUNREG = "No chat events unregistered",
			TB_PRINT_ALREADYJOINED = "You've already joined the chosen channel.",
			TB_PRINT_WARNINGCAPS = "WARNING: ",
			TB_PRINT_PUBLICCHANNEL = "Public channel Selected",
			TB_PRINT_PUBLICANNOYING = "Outputting questions to public channels can be very annoying in busy areas.",
			TB_PRINT_REPORTBAN = "If people report you, your account may be suspended for spamming!",
			TB_PRINT_RESPONSIBILITY = "Using TriviaBot in public channels is your own responsibility.",
			TB_PRINT_THROTTLEHELP = "Increase the question interval and try in a while. Preferably switch to a custom channel.", -- 2.8.8
			-- Error --
			TB_ERROR_NOGAME = "No game running!",
			TB_ERROR_NOVALIDCHANNEL = "No valid channel set!",
			TB_ERROR_ANSWERSHOWN = "Answers Shown must be higher or equal to 0.",
			TB_ERROR_INVALIDCHANNELCHOOSE = "Invalid channel! Please choose another.",
			TB_ERROR_FMTQUESTIONINTERVAL = "Question Interval must be between %d and %d.",
			TB_ERROR_FMTQUESTIONTIMEOUT = "Question Timeout must be between %d and %d.",
			TB_ERROR_FMTROUNDSIZE = "Round Size must be between %d and %d or %d as unlimited.",
			TB_ERROR_FMTTIMEOUTWARN = "Timeout Warning must be between %d and %d and maximum half of Question Timeout.",
			TB_ERROR_FMTTOPSCORECOUNT = "Top Score Count must be between %d and %d.",
			TB_ERROR_FMTTOPSCOREINTERVAL = "Top Score Interval must be between %d and %d.",
			TB_ERROR_NOLOADED = "Select or Load a Quiz first.", -- v2.8
			TB_ERROR_NOTINIT = "TriviaBot hasn't finished initializing. Try in a few seconds.", -- v2.8.1
			TB_ERROR_CHANNELTHROTTLED = "Stopping due to Server Throttling Chat.", -- 2.8.8
			-- Send -- 
			TB_SEND_OUTOFQUESTIONS = "Out of questions... Reshuffled and restarted.",
			TB_SEND_CORRECTANSWERQUOTE = "' is the correct answer, ",
			TB_SEND_BLANKIN = " in ",
			TB_SEND_BLANKSECONDS = " seconds.",
			TB_SEND_NEWGAMESPEED = "--New Game Speed Record--",
			TB_SEND_ALLTIMESPEED = "--New All-Time Speed Record--",
			TB_SEND_BLANKBEAT = " beat ",
			TB_SEND_BLANKOWNSTREAK = " own win-streak by ",
			TB_SEND_BLANKINAROW = " in a row.",
			TB_SEND_HASSTREAK = " has a win-streak of ",
			TB_SEND_BLANKOWNSPEED = " own speed record with ",
			TB_SEND_HINT = "Hint: ",
			TB_SEND_SECONDSLEFT = " seconds left!",
			TB_SEND_CORRECTANSWER = "The correct answer was: ",
			TB_SEND_CORRECTANSWERS = "The correct answers were:",
			TB_SEND_TITLE = "Title: ",
			TB_SEND_DESCRIPTION = "Description: ",
			TB_SEND_AUTHOR = "Author: ",
			TB_SEND_CATEGORIESQUESTIONCOUNT = "Categories (question count):",
			TB_SEND_0ALL = "#0: All (",
			TB_SEND_QUESTIONSETQUESTIONCOUNT = "Question-sets (question count):",
			TB_SEND_TIMEUPNOANSWERS = "Time is up! No correct answers were given.",
			TB_SEND_ALLTIMESTANDINGS = "All-Time standings:",
			TB_SEND_BLANKPOINT = " point",
			TB_SEND_BLANKAND = " and ",
			TB_SEND_BLANKANSWER = " answer",
			TB_SEND_BLANKWITH = " with ",
			TB_SEND_SPEEDRECORD = "Speed record: ",
			TB_SEND_WINSTREAK = "Win-streak record: ",
			TB_SEND_NOALLTIMESCORE = "No All-Time scores found.",
			TB_SEND_STANDINGS = "Game standings:",
			TB_SEND_MIDSTANDINGS = "Standings so far:",
			TB_SEND_FINALSTANDINGS = "GAME OVER! Final standings:",
			TB_SEND_NOSCOREFOUND = "No Game scores found.",
			TB_SEND_NOPOINTSEARNED = "No points earned so far.",
			TB_SEND_FINALNOSCORE = "GAME OVER! Nobody scored!",
			TB_SEND_QUESTIONSKIPPED = "Question was skipped.",
			TB_SEND_POWEREDBY = "--World of Warcraft Trivia powered by TriviaBot--",
			TB_SEND_USINGDATABASE = "Using Trivia from database: ",
			TB_SEND_CATEGORYSELECTED = "Category selected: ",
			TB_SEND_STARTROUND = "Starting a round of ",
			TB_SEND_BLANKQUESTIONS = " questions.",
			TB_SEND_SWITCHDATABASE = "Switching trivia database to: ",
	}, {
		__index = function ( self, Key )
			if ( Key ~= nil ) then
				rawset( self, Key, Key );
				return Key;
			end
		end;
	} );
end