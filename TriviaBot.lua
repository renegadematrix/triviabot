-- GLOBALS: TriviaBot_Config,TriviaBot_Scores,SLASH_TRIVIABOT1,SLASH_TRIVIABOT2
--[[
TriviaBot Version 2.8.7 for World of Warcraft 5.4.1
TriviaBot Version 2.8.5a for World of Warcraft 5.0.4/Mists of Pandaria
TriviaBot Version 2.8.4 for World of Warcraft 4.0.x
Originally written by Guri of Trollbane
Based on work created by Psy of Frostwolf
Code blocks written by ReZeftY and StrangeWill modified
Rewritten by KeeZ (Araina of EU-Agamaggan)
Updated for 3.2.0, 3.3.5 and rewritten for 4.0.x by Dridzt (Driizt of EU-Bronzebeard)
Update for 5.0.4 by Dridzt (Driizt of EU-Bronzebeard)
--]]

-- Local vars declared with TB_
-- TriviaBot version
local addonName, private = ...
private.api = {}
local API = private.api
local TB_VERSION = GetAddOnMetadata(addonName,"Version")

local L = TriviaBotLocalization
-- Declared colour codes for console messages
local TB_RED = "|cffff0000";
local TB_MAGENTA = "|cffff00ff";
local TB_WHITE = "|cffffffff";

-- Control flags
local TB_Running = false; -- To check if TriviaBot is started
local TB_Accept_Answers = false; -- Whether or not answers are accepted
local TB_Loaded = false; -- Set to true when TriviaBot is fully loaded
local TB_Player_Entered = false;

-- Control counters
local TB_Active_Question = 0; -- The currently active question
local TB_Report_Counter = 0; -- Count for how many questions have been asked
local TB_Round_Counter = 0; -- Count for which question we're on in a round
local TB_Hint_Counter = 0; -- What hint was sent before
local TB_Question_Starttime = 0; -- When the question was asked
local TB_Question_Hinttime = 0; -- When hints can be sent
local TB_Min_Interval = 2;
local TB_Max_Interval = 600;
local TB_Min_Timeout = 10;
local TB_Max_Timeout = 120;
local TB_Min_Round = 5;
local TB_Max_Round = 100;
local TB_Infinite_Round = 0;
local TB_Min_Timeout_Warning = 5;
local TB_Max_Timeout_Warning = 60;
local TB_Min_Topscore = 3;
local TB_Max_Topscore = 10;
local TB_Min_Topscore_Interval = 5;
local TB_Max_Topscore_Interval = 50;
local TB_Update_Interval = 0.5;
local TB_limit_out -- extra sparse output when in public channel

-- Control arrays
local TB_Question_Order = {}; -- The order in which the questions will be asked
local TB_Question_List = {}; -- Current list of questions to use
local TB_Game_Scores = {}; -- Round scores
TB_Game_Scores['Best_Win_Streak'] = {};
TB_Game_Scores['Temp_Win_Streak'] = {};
TB_Game_Scores['Speed'] = {};
TB_Game_Scores['Player_Scores'] = {};
local TB_Genders = {"its", "his", "her"}; -- Gender selection
local TB_Question_Sets = {}; -- Faster listing of question-sets and categories
local TB_Questions = {}; -- Pointer to the active question set
local TB_Schedule = {}; -- The array used for scheduling events
local TB_Caps_Restricted = {"a", "and", "as", "at", "in", "of", "on", "the", "to", "vs"}; -- Words that won't be capitalized

local TriviaBot_Questions = {}; -- All question-sets
local TriviaBot_QuestionPacks = {}; -- Populated with load on demand question lists available

-- Global vars declared with TriviaBot_
TriviaBot_Config = {}; -- Configuration array
TriviaBot_Scores = {}; -- Player scores
TriviaBot_Scores['Win_Streak'] = {};
TriviaBot_Scores['Speed'] = {};
TriviaBot_Scores['Player_Scores'] = {};

-- Channel usage
local TB_NewChannel; -- Used for changing custom channel
local TB_Zone; -- Used to store the current zone
local TB_Message_Prefix = "!tb"; -- Incoming whispers prefix
local TB_Short_Prefix = "[TB]"; -- Short tag prefix
local TB_Long_Prefix = "[TriviaBot]"; -- Long tag prefix
local TB_Channel_Prefix = TB_Long_Prefix; -- Channel/Console prefix
local TB_ServerChannels = {}; -- globalName = {id=id,fullName=channelName}
local TB_Chat_Restricted = {}; -- globalName = fullName --
local CUSTOM_IID,GENERAL_IID,TRADE_IID,LD_IID,WD_IID,LFG_IID = 0,1,2,22,23,26
local SERVER_CHANNEL_INTERNAL_ID = {[GENERAL_IID]="General",[TRADE_IID]="Trade",[LD_IID]="LocalDefense",[WD_IID]="WorldDefense",[LFG_IID]="LookingForGroup"}
local SERVER_CHANNEL_ORDER_ID_CITY = {[1]="General",[2]="Trade",[3]="LocalDefense",[4]="WorldDefense",[5]="LookingForGroup"}
local SERVER_CHANNEL_ORDER_ID_WORLD = {[1]="General",[2]="LocalDefense",[3]="WorldDefense"}
local SERVER_CHANNEL_INTERNAL_TO_ORDER = {
	["SERVER_CHANNEL_ORDER_ID_CITY"] = {[GENERAL_IID]=1,[TRADE_IID]=2,[LD_IID]=3,[WD_IID]=4,[LFG_IID]=5},
	["SERVER_CHANNEL_ORDER_ID_WORLD"] = {[GENERAL_IID]=1,[LD_IID]=2,[WD_IID]=3},
}
local CHANNEL_ACTIONS = {["YOU_JOINED"]=true,["YOU_LEFT"]=true,["YOU_CHANGED"]=true,["SUSPENDED"]=true,["THROTTLED"]=true}

----------------------------------------------------------------------------
-- Utility Functions
----------------------------------------------------------------------------
local function findSide(frame)
	local side = "left";
	local rightDist = 0;
	local leftPos = frame:GetLeft();
	local rightPos = frame:GetRight();
	if ( not rightPos ) then
		rightPos = 0;
	end
	if ( not leftPos ) then
		leftPos = 0;
	end
	rightDist = GetScreenWidth() - rightPos;
	if (leftPos and (rightDist < leftPos)) then
		side = "left";
	else
		side = "right";
	end
	return side
end
local function tCount(t)
	local count=0
  for _,_ in pairs(t) do
    count = count+1
  end
  return count
end
local function deepcopy(object)
	local lookup_table = {}
	local function _copy(object)
		if type(object) ~= "table" then
			return object
		elseif lookup_table[object] then
			return lookup_table[object]
		end
		local new_table = {}
		lookup_table[object] = new_table
		for index, value in pairs(object) do
			new_table[_copy(index)] = _copy(value)
		end
		return setmetatable(new_table, _copy(getmetatable(object)))
	end
	return _copy(object)
end
local prevClick
local function IsDoubleClick(thisClick)
	local isDouble = nil
	if prevClick and (thisClick-prevClick) < 0.3 then
		isDouble = true
	end
	prevClick = thisClick
	return isDouble
end
local SERVER_CHANNEL_NUM_TO_LOC = {[tCount(SERVER_CHANNEL_ORDER_ID_CITY)]="SERVER_CHANNEL_ORDER_ID_CITY",[tCount(SERVER_CHANNEL_ORDER_ID_WORLD)]="SERVER_CHANNEL_ORDER_ID_WORLD"}

----------------------------------------------------------------------------
-- Addon frame, and frame scripts
----------------------------------------------------------------------------
local TriviaBot = CreateFrame("Frame")
--local TriviaBotGUI_Header = CreateFrame("Frame", "TriviaBotGUI_Header", UIParent);
--local TriviaBotGUI = CreateFrame("Frame", nil, TriviaBotGUI_Header)
local TriviaBotGUI_Header = CreateFrame("Frame", "TriviaBotGUI_Header", UIParent, "BackdropTemplate");
local TriviaBotGUI = CreateFrame("Frame", nil, TriviaBotGUI_Header, "BackdropTemplate")
TriviaBot.TimeSinceLastUpdate = 0
TriviaBot:RegisterEvent("ADDON_LOADED")
TriviaBot.OnEvent = function(self,event,...)
	local arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9 = ...;
	if (event == "ADDON_LOADED" and arg1 == addonName) then
		-- Register Slash Command
		SLASH_TRIVIABOT1 = "/trivia";
		SLASH_TRIVIABOT2 = "/triviabot";
		SlashCmdList['TRIVIABOT'] = TriviaBot.Command;
		if (not TB_Loaded) then
			-- Load the saved variables
			if (not TriviaBot_Config.Version) then
				TriviaBot.Print(L.TB_PRINT_NEWCONFIG);
				TriviaBot.NewConfig();
			end
			if (TriviaBot_Config.Version ~= TB_VERSION) then
				TriviaBot.Print(L.TB_PRINT_OLDDETECTUPGRADE);
				TriviaBot.Print(L.TB_PRINT_OLD .. TriviaBot_Config.Version .. L.TB_PRINT_NEW .. TB_VERSION);
				TriviaBot.NewConfig();
			end
			-- Start in the 'off' state
			TB_Accept_Answers = false;
			-- Send a message
			TriviaBot.Print(L.TB_PRINT_VERSION .. TB_VERSION .. L.TB_PRINT_BLANKLOADED);
			-- Discover LoD Question Lists and create stubs
			TriviaBot.QuestionPackRegistry()
			-- Load question-sets and categories
			TriviaBot.LoadQuestionSets();
			-- Load the questions
			TriviaBot.LoadTrivia(TriviaBot_Config['Question_Set'], TriviaBot_Config['Question_Category']);
			-- Check to see if general was the last selected chat and change it
			if (TriviaBot_Config['Chat_Type'] == "general") then
				TriviaBot_Config['Chat_Type'] = "channel";
			end
			-- delegate rest of initialization
			self:RegisterEvent("PLAYER_ENTERING_WORLD"); -- reload
			TB_Loaded = true;
		end
	elseif (event == "CHAT_MSG_CHANNEL" and TB_Accept_Answers) then
		local msg = arg1;
		local player = arg2;
		local channel = string.lower(arg9);
		if (msg and player and channel) then
			local generalCh = TB_ServerChannels[SERVER_CHANNEL_INTERNAL_ID[GENERAL_IID]] and TB_ServerChannels[SERVER_CHANNEL_INTERNAL_ID[GENERAL_IID]].fullName
			if (channel == string.lower(TriviaBot_Config['Channel']) or (generalCh and channel == string.lower(generalCh)) ) then
				if (string.lower(msg) ~= "!hint") then
					TriviaBot.CheckAnswer(player, msg);
				else
					TriviaBot.CheckHints();
				end
			end
		end
	elseif (event == "CHAT_MSG_WHISPER") then
		local msg = string.lower(arg1);
		local player = arg2;

		if (msg and player) then
			TriviaBot.WhisperControl(player, msg);
		end
	elseif ((event == "CHAT_MSG_SAY" or
	event == "CHAT_MSG_GUILD" or
	event == "CHAT_MSG_RAID" or
	event == "CHAT_MSG_RAID_LEADER" or
	event == "CHAT_MSG_PARTY" or
	event == "CHAT_MSG_PARTY_LEADER" or
	event == "CHAT_MSG_INSTANCE_CHAT" or
	event == "CHAT_MSG_INSTANCE_CHAT_LEADER") and TB_Accept_Answers) then
		-- Something was said, and the bot is on
		local msg = arg1;
		local player = arg2;
		if (msg and player) then
			if (string.lower(msg) ~= "!hint") then
				TriviaBot.CheckAnswer(player, msg);
			else
				TriviaBot.CheckHints();
			end
		end
	elseif (event == "CHAT_MSG_SYSTEM" and arg1 == ERR_TOO_MANY_CHAT_CHANNELS) then
		TriviaBot.UnSchedule("all");
		TriviaBot.Print(L.TB_PRINT_CHANNELLEAVE);
	elseif (event == "CHAT_MSG_CHANNEL_NOTICE") then
		local action,channelServerID,channelIndex,channelName = arg1,arg7,arg8,arg9
		if not action or not CHANNEL_ACTIONS[action] then return end
		if not channelServerID or (channelServerID ~= CUSTOM_IID and not SERVER_CHANNEL_INTERNAL_ID[channelServerID]) then
			TriviaBot.PrintError(format("Channel (%d) %q has an unknown internal id: %s",channelIndex,channelName,(channelServerID or "nil")))
			return
		end
	elseif (event == "NEXT_QUESTION") then TriviaBot.AskQuestion();
	elseif (event == "QUESTION_TIMEOUT") then TriviaBot.QuestionTimeout();
	elseif (event == "TIMEOUT_WARNING") and not TB_limit_out then TriviaBot.Send(TriviaBot_Config['Timeout_Warning'] .. L.TB_SEND_SECONDSLEFT);
	elseif (event == "REPORT_SCORES") then TriviaBot.Report("midreport");
	elseif (event == "END_REPORT") then TriviaBot.Report("endreport");
	elseif (event == "STOP_GAME") then TriviaBot.Stop();
	elseif (event == "SHOW_ANSWER") then TriviaBot.PrintAnswers();
	elseif (event == "SHOW_HINT") then TriviaBot.CheckHints();
	elseif (event == "RETRY_CHANNEL_CHANGE") then TriviaBot.ChangeCustomChannel();
	elseif (event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "GUILD_ROSTER_UPDATE" or event == "GROUP_ROSTER_UPDATE") then
		if ((event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA") and not TB_Player_Entered) then
			TB_Zone = GetRealZoneText();
			if TB_Zone and TB_Zone ~= "" then
				TriviaBot.InitEnd(self)
			else
				self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
			end
		end
		if TB_Loaded and TB_Player_Entered then
			TB_Zone = GetRealZoneText();
			TriviaBot.CheckChannel(event);
		end
	end
end
TriviaBot.OnUpdate = function(self,elapsed)
	self.TimeSinceLastUpdate = self.TimeSinceLastUpdate + elapsed;
	if (self.TimeSinceLastUpdate > TriviaBot_Config['Update_Interval']) then
		TriviaBot.DoSchedule(self);
		self.TimeSinceLastUpdate = 0;
	end
end
TriviaBot:SetScript("OnEvent",TriviaBot.OnEvent)
TriviaBot:SetScript("OnUpdate",TriviaBot.OnUpdate)

----------------------------------------------------------------------------
-- ChatFrame message filter
----------------------------------------------------------------------------
function TriviaBot.MessageFilter(self, event, messg, ...)
	if TriviaBot.Starts(string.lower(messg), string.lower(TB_Message_Prefix)) then
		return true
	else
		return false, messg, ...
	end
end

----------------------------------------------------------------------------
-- Core functions
----------------------------------------------------------------------------
----------------------------------------------------------------------------
-- Discover load on demand Question Packs
----------------------------------------------------------------------------
function TriviaBot.QuestionPackRegistry()
	for i = 1, GetNumAddOns() do
		local questionPack = GetAddOnInfo(i)
		--if GetAddOnEnableState(character,i) > 0 and not IsAddOnLoaded(i) and IsAddOnLoadOnDemand(i) then
		local playerName = UnitName("player")
		if GetAddOnEnableState(playerName,i) > 0 and not IsAddOnLoaded(i) and IsAddOnLoadOnDemand(i) then
			local valid = GetAddOnMetadata(i, "X-TriviaBot-Questions")
			if valid then
				TriviaBot_QuestionPacks[#TriviaBot_QuestionPacks+1] = questionPack
			end
		end
	end
	-- create stub sets
	if next(TriviaBot_QuestionPacks) then
		for i, v in pairs(TriviaBot_QuestionPacks) do
			if not TriviaBot_Questions[i] then
				TriviaBot_Questions[i] = {}
			end
			if not TriviaBot_Questions[i]['Categories'] then
				TriviaBot_Questions[i]['Categories']={}
			end
			if not TriviaBot_Questions[i]['Question'] then
				TriviaBot_Questions[i]['Question']={}
			end
			if not TriviaBot_Questions[i]['Answers'] then
				TriviaBot_Questions[i]['Answers']={}
			end
			if not TriviaBot_Questions[i]['Category'] then
				TriviaBot_Questions[i]['Category']={}
			end
			if not TriviaBot_Questions[i]['Points'] then
				TriviaBot_Questions[i]['Points']={}
			end
			if not TriviaBot_Questions[i]['Hints'] then
				TriviaBot_Questions[i]['Hints']={}
			end
			TriviaBot_Questions[i]['Title'] = GRAY_FONT_COLOR_CODE..GetAddOnMetadata(v, "Notes")..FONT_COLOR_CODE_CLOSE
			TriviaBot_Questions[i]['Description'] = L.TB_GUI_LOD
			TriviaBot_Questions[i]['Author'] = GetAddOnMetadata(v, "Author")
			TriviaBot_Questions[i]['Categories'][1] = GRAY_FONT_COLOR_CODE..L.TB_GUI_LOD..FONT_COLOR_CODE_CLOSE
			TriviaBot_Questions[i]['Question'][1] = L.TB_GUI_LOD
			TriviaBot_Questions[i]['Answers'][1] = {L.TB_GUI_LOD}
			TriviaBot_Questions[i]['Category'][1] = 1
			TriviaBot_Questions[i]['Points'][1] = 1
			TriviaBot_Questions[i]['Hints'][1] = {}
			TriviaBot_Questions[i]['Stub'] = true
		end
		local setid = TriviaBot_Config['Question_Set']
		if setid and not TriviaBot_QuestionPacks[setid] then
			TriviaBot_Config['Question_Set'] = 1
			-- 			TriviaBot_Config['Question_Category'] = 0 -- all
		end
	else -- no question packs found
		if not TriviaBot_Questions[1] then
			TriviaBot_Questions[1] = {}
		end
		if not TriviaBot_Questions[1]['Categories'] then
			TriviaBot_Questions[1]['Categories']={}
		end
		if not TriviaBot_Questions[1]['Question'] then
			TriviaBot_Questions[1]['Question']={}
		end
		if not TriviaBot_Questions[1]['Answers'] then
			TriviaBot_Questions[1]['Answers']={}
		end
		if not TriviaBot_Questions[1]['Category'] then
			TriviaBot_Questions[1]['Category']={}
		end
		if not TriviaBot_Questions[1]['Points'] then
			TriviaBot_Questions[1]['Points']={}
		end
		if not TriviaBot_Questions[1]['Hints'] then
			TriviaBot_Questions[1]['Hints']={}
		end
		TriviaBot_Questions[1]['Title'] = RED_FONT_COLOR_CODE..L.TB_GUI_NOPACKS..FONT_COLOR_CODE_CLOSE
		TriviaBot_Questions[1]['Description'] = L.TB_GUI_NOPACKS
		TriviaBot_Questions[1]['Author'] = L.TB_GUI_NOPACKS
		TriviaBot_Questions[1]['Categories'][1] = GRAY_FONT_COLOR_CODE..L.TB_GUI_NOPACKS..FONT_COLOR_CODE_CLOSE
		TriviaBot_Questions[1]['Question'][1] = L.TB_GUI_NOPACKS
		TriviaBot_Questions[1]['Answers'][1] = {L.TB_GUI_NOPACKS}
		TriviaBot_Questions[1]['Category'][1] = 1
		TriviaBot_Questions[1]['Points'][1] = 1
		TriviaBot_Questions[1]['Hints'][1] = {}
		TriviaBot_Questions[1]['Stub'] = true
		TriviaBot_Config['Question_Set'] = 1
	end
end

----------------------------------------------------------------------------
-- Abort current question
----------------------------------------------------------------------------
function TriviaBot.AbortQuestion()
	if (TB_Running) then
		TriviaBot.UnSchedule("all");
		TB_Accept_Answers = false;
	else
		TriviaBot.PrintError(L.TB_ERROR_NOGAME);
	end
end

----------------------------------------------------------------------------
-- Ask a question
----------------------------------------------------------------------------
function TriviaBot.AskQuestion(announce)
	TB_Active_Question = TB_Active_Question + 1;

	-- Check if there is questions left
	if (TB_Active_Question == #TB_Questions['Question'] + 1) then
		-- Reshuffle the order
		TriviaBot.Randomize();
		TB_Active_Question = 1;
		if not TB_limit_out then TriviaBot.Send(L.TB_SEND_OUTOFQUESTIONS); end
		TriviaBot.Print(L.TB_PRINT_OUTOFQUESTIONS);
	end

	local questionNumber = 0;
	if (TriviaBot_Config['Round_Size'] ~= TB_Infinite_Round) then
		questionNumber = TB_Round_Counter + 1;
	end

	local setid = TriviaBot_Config['Question_Set'];
	local qid = TB_Question_List[TB_Question_Order[TB_Active_Question]];
	if (questionNumber ~= 0) then
		if (announce and not TB_limit_out) then TriviaBot.Send("C: " .. TriviaBot.Capitalize(TB_Question_Sets[setid]['Title']) .. " - " .. TB_Question_Sets[setid]['Categories'][TB_Questions['Category'][qid]]); end -- config this
		TriviaBot.Send("Q" .. questionNumber .. ": " .. TB_Questions['Question'][qid]);
	else
		if (announce and not TB_limit_out) then TriviaBot.Send("C: " .. TriviaBot.Capitalize(TB_Question_Sets[setid]['Title']) .. " - " .. TB_Question_Sets[setid]['Categories'][TB_Questions['Category'][qid]]); end
		TriviaBot.Send("Q: " .. TB_Questions['Question'][qid]);
	end

	TB_Question_Starttime = GetTime();
	TB_Question_Hinttime = TB_Question_Starttime + (TriviaBot_Config['Question_Timeout']/2);
	TB_Hint_Counter = 0;
	TB_Accept_Answers = true;
	TriviaBotGUI.SkipButton:Enable();
	if TriviaBot_Config['Show_Hints'] and #TB_Questions['Hints'][qid] > 0 then
		TriviaBot.Schedule("SHOW_HINT", (TriviaBot_Config['Question_Timeout']/2));
	end
	TriviaBot.Schedule("QUESTION_TIMEOUT", TriviaBot_Config['Question_Timeout']);
	TriviaBot.Schedule("TIMEOUT_WARNING", TriviaBot_Config['Question_Timeout'] - TriviaBot_Config['Timeout_Warning']);
end

----------------------------------------------------------------------------
-- Capitalize string excluding restricted
----------------------------------------------------------------------------
function TriviaBot.Capitalize(str)
	-- str = str:lower(); -- Lowercase the string
	str = str:gsub("^%l", string.upper); -- Capitalize first letter
	local function tchelper(first, rest)
		if (TriviaBot.RestrictionCheck(first..rest, TB_Caps_Restricted)) then
			return first:upper()..rest:lower();
		else
			return first..rest;
		end
	end
	str = str:gsub("(%a)([%w_']*)", tchelper);
	return str;
end

----------------------------------------------------------------------------
-- Change custom channel
----------------------------------------------------------------------------
function TriviaBot.ChangeCustomChannel()
	-- Check if the old channel is still joined
	if (GetChannelName(TriviaBot_Config['Channel']) > 0) then
		-- It still exists, try to leave it and re-try this method.
		LeaveChannelByName(TriviaBot_Config['Channel']);
		TriviaBot.Schedule("RETRY_CHANNEL_CHANGE", 1);
	else
		-- Set and join the new channel
		JoinChannelByName(TB_NewChannel);
		ChatFrame_AddChannel(DEFAULT_CHAT_FRAME, TB_NewChannel);

		-- Check if the new channel is joined
		if (GetChannelName(TB_NewChannel) > 0) then
			-- Finalize the change
			TriviaBot_Config['Channel'] = TB_NewChannel;
			TriviaBot_Config['Chat_Type'] = "channel";
			TriviaBotGUI.Channel:SetText(TriviaBot_Config['Channel']);

			-- Announce the action
			TriviaBot.Print(L.TB_PRINT_CHANNELCHANGE .. TB_NewChannel);
		else
			-- If it doesn't exist yet, re-try this method again
			TriviaBot.Schedule("RETRY_CHANNEL_CHANGE", 1);
		end
	end
end

----------------------------------------------------------------------------
-- Change chat type
----------------------------------------------------------------------------
function TriviaBot.ChatSelect(type, channel)
	-- Unregister old chat type
	TriviaBot.UnregEvent(TriviaBot_Config['Chat_Type']);
	if (type ~= "channel") then
		-- Leave the custom channel if another chat type is selected
		if (GetChannelName(TriviaBot_Config['Channel']) > 0) then
			LeaveChannelByName(TriviaBot_Config['Channel']);
		end
		TriviaBot_Config['Chat_Type'] = type;
		TriviaBot.Print(L.TB_PRINT_CHANNELCHANGE .. TriviaBot.Capitalize(type));
		-- Disable custom channel stuff
		TriviaBotGUI.Channel:EnableMouse(false);
		TriviaBotGUI.Channel:ClearFocus();
		TriviaBotGUI.Channel:SetTextColor(1,0,0);
		TriviaBotGUI.ChannelButton:Disable();
	else
		-- Enable custom channel stuff
		if (type ~= TriviaBot_Config['Chat_Type']) then
			TriviaBotGUI.Channel:EnableMouse(true);
			TriviaBotGUI.Channel:SetTextColor(1,1,1);
			TriviaBotGUI.ChannelButton:Enable();
		end
		TB_NewChannel = channel;
		TriviaBot.ChangeCustomChannel();
	end
	-- Register new chat type
	TriviaBot.RegEvent(type);
end

----------------------------------------------------------------------------
-- Compares user's answer to question
----------------------------------------------------------------------------
function TriviaBot.CheckAnswer(player, msg)
	-- don't get the answer from the bot prints
	if string.find(msg,TB_Channel_Prefix,1,true) then return end
	-- Remove invalid chars from the message
	msg = TriviaBot.StringCorrection(msg);
	-- Current Question id
	local qid = TB_Question_List[TB_Question_Order[TB_Active_Question]];
	-- For every answer in the list of answers
	for i = 1, #TB_Questions['Answers'][qid], 1 do
		-- Check if answer is correct
		if string.find(string.lower(msg), string.lower(TB_Questions['Answers'][qid][i]), 1, true) then
			-- Unschedule warnings and timeout
			TriviaBot.UnSchedule("all");

			-- Time the answer
			local timeTaken = GetTime() - TB_Question_Starttime;
			timeTaken = math.floor(timeTaken * 100 + 0.5) / 100;

			-- Tell player they don't suck as badly as they think they do.
			if not TB_limit_out then TriviaBot.Send("'".. msg .. L.TB_SEND_CORRECTANSWERQUOTE .. player .. L.TB_SEND_BLANKIN .. timeTaken .. L.TB_SEND_BLANKSECONDS); end

			-- Generate personal arrays
			if (not TB_Game_Scores['Player_Scores'][player]) then
				TB_Game_Scores['Player_Scores'][player] = {['Win_Streak'] = 0, ['Speed'] = 120, ['Points'] = 0, ['Score'] = 0};
			end
			if (not TriviaBot_Scores['Player_Scores'][player]) then
				TriviaBot_Scores['Player_Scores'][player] = {['Win_Streak'] = 0, ['Speed'] = 120, ['Points'] = 0, ['Score'] = 0};
			end

			-- New game speed record
			if (not TB_Game_Scores['Speed']['Holder'] or timeTaken < TB_Game_Scores['Speed']['Time']) then
				TB_Game_Scores['Speed']['Holder'] = player;
				TB_Game_Scores['Speed']['Time'] = timeTaken;
				if not TB_limit_out then TriviaBot.Send(L.TB_SEND_NEWGAMESPEED); end
			end

			-- New all-time speed record
			if (not TriviaBot_Scores['Speed']['Holder'] or timeTaken < TriviaBot_Scores['Speed']['Time']) then
				TriviaBot_Scores['Speed']['Holder'] = player;
				TriviaBot_Scores['Speed']['Time'] = timeTaken;
				if not TB_limit_out then TriviaBot.Send(L.TB_SEND_ALLTIMESPEED); end
			end

			-- Check the temporary win streak
			if (TB_Game_Scores['Temp_Win_Streak']['Holder'] == player) then
				TB_Game_Scores['Temp_Win_Streak']['Count'] = TB_Game_Scores['Temp_Win_Streak']['Count'] + 1;
				-- Check personal game win streak
				if (TB_Game_Scores['Player_Scores'][player]['Win_Streak'] < TB_Game_Scores['Temp_Win_Streak']['Count']) then
					TB_Game_Scores['Player_Scores'][player]['Win_Streak'] = TB_Game_Scores['Temp_Win_Streak']['Count'];
				end
				-- Check personal all-time win streak
				if (TriviaBot_Scores['Player_Scores'][player]['Win_Streak'] < TB_Game_Scores['Temp_Win_Streak']['Count']) then
					TriviaBot_Scores['Player_Scores'][player]['Win_Streak'] = TB_Game_Scores['Temp_Win_Streak']['Count'];
					-- Announce the record if checked
					if (TriviaBot_Config['Report_Personal'] and not TB_limit_out) then
						TriviaBot.Send(player .. L.TB_SEND_BLANKBEAT .. "their" .. L.TB_SEND_BLANKOWNSTREAK .. TB_Game_Scores['Temp_Win_Streak']['Count'] .. L.TB_SEND_BLANKINAROW);
					end
				end
			else
				TB_Game_Scores['Temp_Win_Streak']['Holder'] = player;
				TB_Game_Scores['Temp_Win_Streak']['Count'] = 1;
			end

			-- New game win streak record
			if (not TB_Game_Scores['Best_Win_Streak']['Holder'] or TB_Game_Scores['Temp_Win_Streak']['Count'] > TB_Game_Scores['Best_Win_Streak']['Count']) then
				TB_Game_Scores['Best_Win_Streak']['Holder'] = player;
				TB_Game_Scores['Best_Win_Streak']['Count'] = TB_Game_Scores['Temp_Win_Streak']['Count'];
				if (TriviaBot_Config['Report_Win_Streak'] and TB_Game_Scores['Best_Win_Streak']['Count']%5 == 0 and not TB_limit_out) then
					TriviaBot.Send(player .. L.TB_SEND_HASSTREAK .. TB_Game_Scores['Best_Win_Streak']['Count'] .. L.TB_SEND_BLANKINAROW);
				end
			end

			-- New all-time win streak record
			if (not TriviaBot_Scores['Win_Streak']['Holder'] or TB_Game_Scores['Temp_Win_Streak']['Count'] > TriviaBot_Scores['Win_Streak']['Count']) then
				TriviaBot_Scores['Win_Streak']['Holder'] = player;
				TriviaBot_Scores['Win_Streak']['Count'] = TB_Game_Scores['Temp_Win_Streak']['Count'];
			end

			-- Check personal speed records
			if (timeTaken < TB_Game_Scores['Player_Scores'][player]['Speed']) then
				TB_Game_Scores['Player_Scores'][player]['Speed'] = timeTaken;
			end
			if (timeTaken < TriviaBot_Scores['Player_Scores'][player]['Speed']) then
				TriviaBot_Scores['Player_Scores'][player]['Speed'] = timeTaken;
				-- Announce the record if checked
				if (TriviaBot_Config['Report_Personal'] and not TB_limit_out) then
					TriviaBot.Send(player .. L.TB_SEND_BLANKBEAT .. "their" .. L.TB_SEND_BLANKOWNSPEED .. timeTaken .. L.TB_SEND_BLANKSECONDS);
				end
			end

			-- Add points if point mode is enabled
			if (TriviaBot_Config['Point_Mode']) then
				TriviaBot_Scores['Player_Scores'][player]['Points'] = TriviaBot_Scores['Player_Scores'][player]['Points'] + TB_Questions['Points'][qid];
				TB_Game_Scores['Player_Scores'][player]['Points'] = TB_Game_Scores['Player_Scores'][player]['Points'] + TB_Questions['Points'][qid];
			end

			-- Update the score
			TriviaBot_Scores['Player_Scores'][player]['Score'] = TriviaBot_Scores['Player_Scores'][player]['Score'] + 1;
			TB_Game_Scores['Player_Scores'][player]['Score'] = TB_Game_Scores['Player_Scores'][player]['Score'] + 1;

			TriviaBot.EndQuestion(false);
		end
	end
end

----------------------------------------------------------------------------
-- Check selected channel is available
----------------------------------------------------------------------------
function TriviaBot.CheckChannel(event)
	if (not TB_Loaded or not TB_Player_Entered) then
		-- Addon isn't loaded there's no reason to check the events
		return;
	end

	local chat = TriviaBot_Config['Chat_Type'];
	if (chat == "guild" and not IsInGuild()) or
	(chat == "party" and not IsInGroup(LE_PARTY_CATEGORY_HOME)) or
	(chat == "raid" and not IsInRaid(LE_PARTY_CATEGORY_HOME)) or
	(chat == "general" and not TB_ServerChannels[SERVER_CHANNEL_INTERNAL_ID[GENERAL_IID]]) or
	(chat == "instance_chat" and TB_Zone ~= L.TB_ZONE_AB and TB_Zone ~= L.TB_ZONE_WSG and TB_Zone ~= L.TB_ZONE_AV and TB_Zone ~= L.TB_ZONE_EOTS and TB_Zone ~= L.TB_ZONE_SOTA and TB_Zone ~= L.TB_ZONE_IOC and TB_Zone ~= L.TB_ZONE_TBFG and TB_Zone ~= L.TB_ZONE_TP) then
		if (TB_Running) then
			TriviaBot.Stop(); -- We can't broadcast so TriviaBot is stopped
		end
		TriviaBot.ChatSelect("channel", TriviaBot_Config['Channel']);
		TriviaBotGUI.Update();
	end
end

----------------------------------------------------------------------------
-- Checks if there're any hints to send
----------------------------------------------------------------------------
function TriviaBot.CheckHints()
	-- 	if (TB_Question_Hinttime <= GetTime()) then
	if (GetTime() >= TB_Question_Hinttime) then
		local qid = TB_Question_List[TB_Question_Order[TB_Active_Question]];
		if (TB_Hint_Counter < #TB_Questions['Hints'][qid]) then
			TriviaBot.Send(L.TB_SEND_HINT .. TB_Questions['Hints'][qid][TB_Hint_Counter + 1]);
			TB_Hint_Counter = TB_Hint_Counter + 1;
		-- todo: consider scheduling a new SHOW_HINT if more hints available
		end
		TB_Question_Hinttime = GetTime() + TB_Min_Interval;
	end
end

----------------------------------------------------------------------------
-- Command handler
----------------------------------------------------------------------------
function TriviaBot.Command(cmd)
	if (not TB_Player_Entered or not TB_Loaded) then
		-- Addon isn't finished loading, gui may be unavailable.
		TriviaBot.PrintError(L.TB_ERROR_NOTINIT)
		return
	end
	-- Create variables
	local msgArgs = {};

	-- Convert to lower case
	cmd = string.lower(cmd);

	-- Seperate our args
	for value in string.gmatch(cmd, "[^ ]+") do
		table.insert(msgArgs, value);
	end

	if (#msgArgs == 0) then
		-- Toggle the GUI
		if (TriviaBotGUI_Header:IsVisible()) then
			TriviaBotGUI_Header:Hide();
		else
			TriviaBotGUI_Header:Show();
			TriviaBotGUI.Update();
		end
	elseif (msgArgs[1] == "clear") then
		TB_Game_Scores = {};
		TB_Game_Scores['Best_Win_Streak'] = {};
		TB_Game_Scores['Temp_Win_Streak'] = {};
		TB_Game_Scores['Speed'] = {};
		TB_Game_Scores['Player_Scores'] = {};
		TriviaBot.Print(L.TB_PRINT_SCORESCLEARED);
	elseif (msgArgs[1] == "clearall") then
		TriviaBot_Scores = {};
		TriviaBot_Scores['Win_Streak'] = {};
		TriviaBot_Scores['Speed'] = {};
		TriviaBot_Scores['Player_Scores'] = {};
		TriviaBot.Print(L.TB_PRINT_ALLSCORESCLEARED);
	elseif (msgArgs[1] == "help") then
		TriviaBot.Print(L.TB_PRINT_HELP);
		TriviaBot.Print(L.TB_PRINT_CMDCLEAR);
		TriviaBot.Print(L.TB_PRINT_CMDCLEARALL);
		TriviaBot.Print(L.TB_PRINT_CMDHELP);
		TriviaBot.Print(L.TB_PRINT_CMDRESET);
	elseif (msgArgs[1] == "reset") then
		TriviaBot.NewConfig(true);
		TriviaBot.ChatSelect(TriviaBot_Config['Chat_Type'], TriviaBot_Config['Channel']);
		TriviaBotGUI.Update();
	end
end

----------------------------------------------------------------------------
-- Do scheduled events
----------------------------------------------------------------------------
function TriviaBot.DoSchedule(self)
	if (TB_Schedule) then
		for id, events in pairs(TB_Schedule) do
			-- Get the time of each event
			-- If it should be run (i.e. equal or less than current time)
			if (events['time'] <= GetTime()) then
				TriviaBot.OnEvent(self, events['name']);
				TriviaBot.UnSchedule(id);
			end
		end
	end
end

----------------------------------------------------------------------------
-- Called when a question is finished
----------------------------------------------------------------------------
function TriviaBot.EndQuestion(showAnswer)
	-- Prevent further answers
	TB_Accept_Answers = false;
	TriviaBotGUI.SkipButton:Disable();

	-- Increment the counters
	TB_Round_Counter = TB_Round_Counter + 1;

	local wait = 0;
	if (showAnswer) then
		wait = wait + TB_Min_Interval;
		TriviaBot.Schedule("SHOW_ANSWER", wait);
	end

	-- See if we've reached the end of the round
	if (TB_Round_Counter == TriviaBot_Config['Round_Size']) then
		TriviaBot.Schedule("END_REPORT", wait + 4);
		TriviaBot.Schedule("STOP_GAME", wait + 8);
	else
		-- Count how long it's been since a question report
		if (TriviaBot_Config['Show_Reports']) then
			TB_Report_Counter = TB_Report_Counter + 1;
			if (TB_Report_Counter == TriviaBot_Config['Top_Score_Interval']) then
				wait = wait + 4;
				TriviaBot.Schedule("REPORT_SCORES", wait);
				TB_Report_Counter = 0;
			end
		end
		TriviaBot.Schedule("NEXT_QUESTION", TriviaBot_Config['Question_Interval'] + wait);
	end
end

----------------------------------------------------------------------------
-- Index trivia questions
----------------------------------------------------------------------------
function TriviaBot.IndexTrivia(setid)
	if (TriviaBot_Questions[setid]) then
		if (not TB_Question_Sets[setid]['CatIdx']) then
			TB_Question_Sets[setid]['CatIdx'] = {[0] = {}};
			for id,_ in pairs(TB_Question_Sets[setid]['Categories']) do
				TB_Question_Sets[setid]['CatIdx'][id] = {};
			end
			for id,_ in pairs(TriviaBot_Questions[setid]['Question']) do
				table.insert(TB_Question_Sets[setid]['CatIdx'][0], id);
				local catid = TriviaBot_Questions[setid]['Category'][id];
				if (TB_Question_Sets[setid]['CatIdx'][catid]) then
					table.insert(TB_Question_Sets[setid]['CatIdx'][catid], id);
				end
			end
		end
	end
end

----------------------------------------------------------------------------
-- Load question-sets info and categories
----------------------------------------------------------------------------
function TriviaBot.LoadQuestionSets()
	for id,_ in pairs(TriviaBot_Questions) do
		TB_Question_Sets[id] = {};
		TB_Question_Sets[id]['Title'] = TriviaBot_Questions[id]['Title'];
		TB_Question_Sets[id]['Description'] = TriviaBot_Questions[id]['Description'];
		TB_Question_Sets[id]['Author'] = TriviaBot_Questions[id]['Author'];
		TB_Question_Sets[id]['Categories'] = TriviaBot_Questions[id]['Categories'];
		TriviaBot.IndexTrivia(id);
	end
end

----------------------------------------------------------------------------
-- Load trivia into trivia memory
----------------------------------------------------------------------------
function TriviaBot.LoadTrivia(setid, catid)
	-- If we're running we need to skip the current question before hopping databases.
	if (TB_Running) then
		TriviaBot.AbortQuestion();
	end

	-- See if question-set and category exists
	if (TB_Question_Sets[setid]) then
		TB_Questions = TriviaBot_Questions[setid];
		if (TB_Question_Sets[setid]['Categories'][catid] or catid == 0) then
			TB_Question_List = TB_Question_Sets[setid]['CatIdx'][catid];
			local category = L.TB_GUI_ALL;
			if (catid ~= 0) then -- Single categories
				category = TB_Question_Sets[setid]['Categories'][catid];
			end
			if (#TB_Questions['Question'] > 0) then
				TriviaBot.Print(L.TB_PRINT_QUESTIONCOUNT .. #TB_Question_Sets[setid]['CatIdx'][catid]);--#TB_Questions['Question']);
				if (TriviaBot_Config['Question_Set'] ~= setid) then
					TriviaBot.Print(L.TB_PRINT_DATABASENAME .. TriviaBot.Capitalize(TB_Question_Sets[setid]['Title']) .. L.TB_PRINT_HYPHENDESCRIPTION .. TB_Question_Sets[setid]['Description'].. L.TB_PRINT_HYPHENAUTHORS .. TB_Question_Sets[setid]['Author'] .. ".");
				else
					TriviaBot.Print(L.TB_PRINT_DATABASENAME .. TriviaBot.Capitalize(TB_Question_Sets[setid]['Title']) .. L.TB_PRINT_HYPHENCATEGORY .. category .. L.TB_PRINT_BLANKLOADED);
				end
			else
				TriviaBot.Print(L.TB_PRINT_DATABASENAME .. TriviaBot.Capitalize(TB_Question_Sets[setid]['Title']) .. L.TB_PRINT_HYPHENCATEGORY .. category .. L.TB_PRINT_NOQUESTIONLOAD);
			end

			-- Always randomize the question order
			TriviaBot.Randomize();
			if (TB_Running)then
				-- If we're switching databases mid-game, we should alert our players that the questions has changed
				if not TB_limit_out then TriviaBot.Send(L.TB_PRINT_SWITCHDATABASE .. TriviaBot.Capitalize(TB_Question_Sets[setid]['Title']) .. L.TB_PRINT_DOTDESCRIPTION .. TB_Question_Sets[setid]['Description'].. L.TB_PRINT_DOTAUTHOR .. TB_Question_Sets[setid]['Author'] .. "."); end
				TriviaBot.Schedule("NEXT_QUESTION", TriviaBot_Config['Question_Interval']);
			end
			collectgarbage("collect") -- Do a cleanup
		else
			TriviaBot.Print(L.TB_PRINT_CATEGORYID..catid..L.TB_PRINT_NOTEXIST);
			TriviaBot.Print(L.TB_PRINT_AVAILABLECATEGORIES);
			TriviaBot.Print(L.TB_PRINT_ID0);
			for id, cat in pairs(TB_Question_Sets[setid]['Categories']) do
				TriviaBot.Print("ID: " .. id .. " - " .. cat);
			end
		end
	else
		TriviaBot.Print(L.TB_PRINT_QUESTIONSETID..setid..L.TB_PRINT_NOTEXIST);
		TriviaBot.Print(L.TB_PRINT_LIBRARIES);
		for id, set in pairs(TB_Question_Sets) do
			TriviaBot.Print("ID: " .. id .. " - " .. set['Title']);
		end
	end
end

----------------------------------------------------------------------------
-- Create new configuation
----------------------------------------------------------------------------
function TriviaBot.NewConfig(reset)
	if (reset) then
		TriviaBot_Config = {};
		TriviaBot.Print(L.TB_PRINT_RESETCONFIG);
	end

	-- Default amount of answers shown (0 = all)
	if (not TriviaBot_Config['Answers_Shown']) then TriviaBot_Config['Answers_Shown'] = 0; end

	-- Default private channel (Trivia)
	if (not TriviaBot_Config['Channel']) then TriviaBot_Config['Channel'] = "Trivia"; end

	-- Default chat type (channel)
	if (not TriviaBot_Config['Chat_Type']) then TriviaBot_Config['Chat_Type'] = "channel"; end

	-- Using point-mode (true)
	if (not TriviaBot_Config['Point_Mode']) then TriviaBot_Config['Point_Mode'] = true; end

	-- Default question category (0 = all)
	if (not TriviaBot_Config['Question_Category']) then TriviaBot_Config['Question_Category'] = 0; end

	-- Default question interval (10 seconds)
	if (not TriviaBot_Config['Question_Interval']) then TriviaBot_Config['Question_Interval'] = 10; end

	-- Default question-set (1)
	if (not TriviaBot_Config['Question_Set']) then TriviaBot_Config['Question_Set'] = 1; end

	-- Default question timeout (45 seconds)
	if (not TriviaBot_Config['Question_Timeout']) then TriviaBot_Config['Question_Timeout'] = 45; end

	-- Report personal records (true)
	if (not TriviaBot_Config['Report_Personal']) then TriviaBot_Config['Report_Personal'] = true; end

	-- Report win streak updates (true)
	if (not TriviaBot_Config['Report_Win_Streak']) then TriviaBot_Config['Report_Win_Streak'] = true; end

	-- Defaults questions per round (0 = unlimited)
	if (not TriviaBot_Config['Round_Size']) then TriviaBot_Config['Round_Size'] = TB_Infinite_Round; end

	-- Use Short Channel Tag (false)
	if (not TriviaBot_Config['Short_Tag']) then TriviaBot_Config['Short_Tag'] = false; end

	-- Show answers (true)
	if (not TriviaBot_Config['Show_Answers']) then TriviaBot_Config['Show_Answers'] = true; end

	-- Show hints (true)
	if (not TriviaBot_Config['Show_Hints']) then TriviaBot_Config['Show_Hints'] = true; end

	-- Show reports (true)
	if (not TriviaBot_Config['Show_Reports']) then TriviaBot_Config['Show_Reports'] = true; end

	-- Show whispers (false)
	if (not TriviaBot_Config['Show_Whispers']) then TriviaBot_Config['Show_Whispers'] = false; end

	-- Default timeout warning (20 seconds)
	if (not TriviaBot_Config['Timeout_Warning']) then TriviaBot_Config['Timeout_Warning'] = 20; end

	-- Top score count (5)
	if (not TriviaBot_Config['Top_Score_Count']) then TriviaBot_Config['Top_Score_Count'] = 5; end

	-- Default top score interval (5 answers)
	if (not TriviaBot_Config['Top_Score_Interval']) then TriviaBot_Config['Top_Score_Interval'] = TB_Min_Topscore_Interval; end

	-- Default Update interval. Tweaking may increase performance.
	if (not TriviaBot_Config['Update_Interval']) then TriviaBot_Config['Update_Interval'] = TB_Update_Interval; end

	-- Store the version
	TriviaBot_Config.Version = TB_VERSION;
end

function TriviaBot.InitEnd(self)
	-- Initialize the GUI
	TriviaBot.GUIInitialize();
	TriviaBot.ChatSelect(TriviaBot_Config['Chat_Type'], TriviaBot_Config['Channel']);
	-- Register Events
	self:RegisterEvent("CHAT_MSG_CHANNEL_NOTICE"); -- channel join/leave/suspend etc
	self:RegisterEvent("CHAT_MSG_SYSTEM"); -- Should the server report something important
	self:RegisterEvent("CHAT_MSG_WHISPER"); -- Enables whisper commands
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA"); -- Battleground check
	self:RegisterEvent("GUILD_ROSTER_UPDATE"); -- Guild check
	self:RegisterEvent("GROUP_ROSTER_UPDATE"); -- Party/Raid check

	if not (TriviaBot_Config['Show_Whispers']) then
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER",TriviaBot.MessageFilter)
		ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM",TriviaBot.MessageFilter)
	else
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM",TriviaBot.MessageFilter)
		ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER",TriviaBot.MessageFilter)
	end
	-- Set loaded state
	TB_Player_Entered = true;
end

----------------------------------------------------------------------------
-- Print message in console
----------------------------------------------------------------------------
function TriviaBot.Print(msg)
	-- Check if the default frame exists
	if (DEFAULT_CHAT_FRAME) then
		-- Format the message
		msg = TB_MAGENTA .. TB_Channel_Prefix .. ": " .. TB_WHITE .. msg;
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end

----------------------------------------------------------------------------
-- Print answers to the channel
----------------------------------------------------------------------------
function TriviaBot.PrintAnswers()
	if (TriviaBot_Config['Answers_Shown'] == 1 or #TB_Questions['Answers'][TB_Question_List[TB_Question_Order[TB_Active_Question]]] == 1) then
		TriviaBot.Send(L.TB_SEND_CORRECTANSWER .. TB_Questions['Answers'][TB_Question_List[TB_Question_Order[TB_Active_Question]]][1]);
	else
		if not TB_limit_out then TriviaBot.Send(L.TB_SEND_CORRECTANSWERS); end
		if (TriviaBot_Config['Answers_Shown'] == 0) then
			for _,answer in pairs(TB_Questions['Answers'][TB_Question_List[TB_Question_Order[TB_Active_Question]]]) do
				TriviaBot.Send(answer);
				if TB_limit_out then break end
			end
		else
			local count = TriviaBot_Config['Answers_Shown'];
			if (#TB_Questions['Answers'][TB_Question_List[TB_Question_Order[TB_Active_Question]]] < count) then
				count = #TB_Questions['Answers'][TB_Question_List[TB_Question_Order[TB_Active_Question]]];
			end
			for i = 1, count, 1 do
				TriviaBot.Send(TB_Questions['Answers'][TB_Question_List[TB_Question_Order[TB_Active_Question]]][i]);
				if TB_limit_out then break end
			end
		end
	end
end

----------------------------------------------------------------------------
-- Print Category List to the channel
----------------------------------------------------------------------------
function TriviaBot.PrintCategoryList()
	if TB_limit_out then return end
	local setid = TriviaBot_Config['Question_Set'];
	if not TriviaBot_Questions[setid]['Stub'] then
		TriviaBot.Send(L.TB_SEND_TITLE .. TriviaBot.Capitalize(TB_Question_Sets[setid]['Title']));
	end
	TriviaBot.Send(L.TB_SEND_DESCRIPTION .. TB_Question_Sets[setid]['Description']);
	TriviaBot.Send(L.TB_SEND_AUTHOR .. TB_Question_Sets[setid]['Author']);
	TriviaBot.Send(L.TB_SEND_CATEGORIESQUESTIONCOUNT);
	TriviaBot.Send(L.TB_SEND_0ALL .. #TriviaBot_Questions[setid]['Question'] .. ")");
	for id,_ in pairs(TB_Question_Sets[setid]['Categories']) do
		TriviaBot.Send("#" .. id .. ": " .. TB_Question_Sets[setid]['Categories'][id] .. " (" .. #TB_Question_Sets[setid]['CatIdx'][id] .. ")");
	end
end

----------------------------------------------------------------------------
-- Print error message in console
----------------------------------------------------------------------------
function TriviaBot.PrintError(msg)
	-- Check if the default frame exists
	if (DEFAULT_CHAT_FRAME) then
		-- Format the message
		msg = TB_RED .. "[ERROR]" .. TB_Channel_Prefix .. ": " .. TB_WHITE .. msg;
		DEFAULT_CHAT_FRAME:AddMessage(msg);
	end
end

----------------------------------------------------------------------------
-- Print Question List to the channel
----------------------------------------------------------------------------
function TriviaBot.PrintQuestionList()
	if TB_limit_out then return end
	TriviaBot.Send(L.TB_SEND_QUESTIONSETQUESTIONCOUNT);
	for id,_ in pairs(TB_Question_Sets) do
		if not TriviaBot_Questions[id]['Stub'] then
			TriviaBot.Send(L.TB_SEND_TITLE .. TriviaBot.Capitalize(TB_Question_Sets[id]['Title']) .. " (" .. #TriviaBot_Questions[id]['Question'] .. ")");
		end
	end
end

----------------------------------------------------------------------------
-- Answers question and prepares next one
----------------------------------------------------------------------------
function TriviaBot.QuestionTimeout()
	if not TB_limit_out then TriviaBot.Send(L.TB_SEND_TIMEUPNOANSWERS); end
	TriviaBot.EndQuestion(TriviaBot_Config['Show_Answers']);
end

----------------------------------------------------------------------------
-- Randomize the trivia questions
----------------------------------------------------------------------------
function TriviaBot.Randomize()
	-- Initialise the table
	TB_Question_Order = {};

	-- Number of questions
	local noq = #TB_Question_List;

	-- Fill the order array
	for i = 1, noq, 1 do
		TB_Question_Order[i] = i;
	end

	local temp, rand; -- Temporary value holders
	for j = 1, 5, 1 do -- Do the switch 5 times
		-- Swap each element with a random element
		for k = 1, noq, 1 do
			rand = math.random(noq);
			temp = TB_Question_Order[k];
			TB_Question_Order[k] = TB_Question_Order[rand]
			TB_Question_Order[rand] = temp;
		end
	end
end

----------------------------------------------------------------------------
-- Register Chat Event
----------------------------------------------------------------------------
function TriviaBot.RegEvent(chat_type)
	if (chat_type == "channel") then
		TriviaBot:RegisterEvent("CHAT_MSG_CHANNEL");
	elseif (chat_type == "say") then
		TriviaBot:RegisterEvent("CHAT_MSG_SAY");
	elseif (chat_type == "general") then
		TriviaBot:RegisterEvent("CHAT_MSG_CHANNEL");
	elseif (chat_type == "guild") then
		TriviaBot:RegisterEvent("CHAT_MSG_GUILD");
	elseif (chat_type == "party") then
		TriviaBot:RegisterEvent("CHAT_MSG_PARTY");
		TriviaBot:RegisterEvent("CHAT_MSG_PARTY_LEADER");
	elseif (chat_type == "raid") then
		TriviaBot:RegisterEvent("CHAT_MSG_RAID");
		TriviaBot:RegisterEvent("CHAT_MSG_RAID_LEADER");
	elseif (chat_type == "instance_chat") then
		TriviaBot:RegisterEvent("CHAT_MSG_INSTANCE_CHAT");
		TriviaBot:RegisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER");
	else
		TriviaBot.Print(L.TB_PRINT_NOCHATEVENTS);
	end
end

----------------------------------------------------------------------------
-- Print report to the channel
----------------------------------------------------------------------------
function TriviaBot.Report(type)
	if TB_limit_out and type ~= "endreport" then return end
	local Sorted_Scores = {};
	local exists;
	local limit = TriviaBot_Config['Top_Score_Count']
	if (type == "alltimereport") then
		for player, scores in pairs(TriviaBot_Scores['Player_Scores']) do
			exists = true;
			table.insert(Sorted_Scores, {['Player'] = player, ['Points'] = scores['Points'], ['Score'] = scores['Score']});
		end

		if (exists) then
			if (TriviaBot_Config['Point_Mode']) then
				table.sort(Sorted_Scores, function(v1, v2)
					if (v1['Points'] == v2['Points']) then
						return v1['Score'] > v2['Score'];
					else
						return v1['Points'] > v2['Points'];
					end
				end);
			else
				table.sort(Sorted_Scores, function(v1, v2)
					if (v1['Score'] == v2['Score']) then
						return v1['Points'] > v2['Points'];
					else
						return v1['Score'] > v2['Score'];
					end
				end)
			end
			if (limit > #Sorted_Scores) then
				limit = #Sorted_Scores;
			end
			TriviaBot.Send(L.TB_SEND_ALLTIMESTANDINGS);
			for i = 1, limit, 1 do
				local pess = "s";
				local sess = "s";
				if (Sorted_Scores[i]['Points'] == 1) then
					pess = "";
				end
				if (Sorted_Scores[i]['Score'] == 1) then
					sess = "";
				end
				TriviaBot.Send("#" .. i .. ": " .. Sorted_Scores[i]['Player'] .. L.TB_SEND_BLANKWITH .. Sorted_Scores[i]['Points'] .. L.TB_SEND_BLANKPOINT .. pess .. L.TB_SEND_BLANKAND .. Sorted_Scores[i]['Score'] .. L.TB_SEND_BLANKANSWER .. sess .. ".");
			end
			if (TriviaBot_Scores['Speed']['Holder']) then
				TriviaBot.Send(L.TB_SEND_SPEEDRECORD .. TriviaBot_Scores['Speed']['Holder'] .. L.TB_SEND_BLANKIN .. TriviaBot_Scores['Speed']['Time'] .. L.TB_SEND_BLANKSECONDS);
			end
			if (TriviaBot_Scores['Win_Streak']['Holder']) then
				TriviaBot.Send(L.TB_SEND_WINSTREAK .. TriviaBot_Scores['Win_Streak']['Holder'] .. L.TB_SEND_BLANKWITH .. TriviaBot_Scores['Win_Streak']['Count'] .. L.TB_SEND_BLANKINAROW);
			end
		else
			TriviaBot.Send(L.TB_SEND_NOALLTIMESCORE);
		end
	else
		for player, scores in pairs(TB_Game_Scores['Player_Scores']) do
			exists = true;
			table.insert(Sorted_Scores, {['Player'] = player, ['Points'] = scores['Points'], ['Score'] = scores['Score']});
		end

		if (exists) then
			if (TriviaBot_Config['Point_Mode']) then
				table.sort(Sorted_Scores, function(v1, v2)
					if (v1['Points'] == v2['Points']) then
						return v1['Score'] > v2['Score'];
					else
						return v1['Points'] > v2['Points'];
					end
				end);
			else
				table.sort(Sorted_Scores, function(v1, v2)
					if (v1['Score'] == v2['Score']) then
						return v1['Points'] > v2['Points'];
					else
						return v1['Score'] > v2['Score'];
					end
				end)
			end
			if (type == "gamereport") then
				TriviaBot.Send(L.TB_SEND_STANDINGS);
			elseif (type == "midreport") then
				TriviaBot.Send(L.TB_SEND_MIDSTANDINGS);
				limit = 3;
			elseif (type == "endreport") then
				TriviaBot.Send(L.TB_SEND_FINALSTANDINGS);
				if TB_limit_out then limit = 1 end
			end
			if (limit > #Sorted_Scores) then
				limit = #Sorted_Scores;
			end
			for i = 1, limit, 1 do
				local pess = "s";
				local sess = "s";
				if (Sorted_Scores[i]['Points'] == 1) then
					pess = "";
				end
				if (Sorted_Scores[i]['Score'] == 1) then
					sess = "";
				end
				if (TriviaBot_Config['Point_Mode']) then
					TriviaBot.Send("#" .. i .. ": " .. Sorted_Scores[i]['Player'] .. L.TB_SEND_BLANKWITH .. Sorted_Scores[i]['Points'] .. " (" .. Sorted_Scores[i]['Score'] .. ")"..L.TB_SEND_BLANKPOINT .. pess .. ".");
				else
					TriviaBot.Send("#" .. i .. ": " .. Sorted_Scores[i]['Player'] .. L.TB_SEND_BLANKWITH .. Sorted_Scores[i]['Score'] .. L.TB_SEND_BLANKPOINT .. sess .. ".");
				end
			end
			if (TB_Game_Scores['Speed']['Holder']) then
				TriviaBot.Send(L.TB_SEND_SPEEDRECORD .. TB_Game_Scores['Speed']['Holder'] .. L.TB_SEND_BLANKIN .. TB_Game_Scores['Speed']['Time'] .. L.TB_SEND_BLANKSECONDS);
			end
			if (TB_Game_Scores['Best_Win_Streak']['Holder']) then
				TriviaBot.Send(L.TB_SEND_WINSTREAK .. TB_Game_Scores['Best_Win_Streak']['Holder'] .. L.TB_SEND_BLANKWITH .. TB_Game_Scores['Best_Win_Streak']['Count'] .. L.TB_SEND_BLANKINAROW);
			end
		else
			if (type == "gamereport") then
				TriviaBot.Send(L.TB_SEND_NOSCOREFOUND);
			elseif (type == "midreport") then
				TriviaBot.Send(L.TB_SEND_NOPOINTSEARNED);
			elseif (type == "endreport") then
				TriviaBot.Send(L.TB_SEND_FINALNOSCORE);
			end
		end
	end
end

----------------------------------------------------------------------------
-- Check if string is restricted
----------------------------------------------------------------------------
function TriviaBot.RestrictionCheck(str, list)
	for _, word in ipairs(list) do
		if (str == word) then
			return false;
		end
	end
	return true;
end

----------------------------------------------------------------------------
-- Schedule an event
----------------------------------------------------------------------------
function TriviaBot.Schedule(name, time)
	local thisEvent = {['name'] = name, ['time'] = GetTime() + time};
	table.insert(TB_Schedule, thisEvent);
end

----------------------------------------------------------------------------
-- Send a TriviaBot message to the channel
----------------------------------------------------------------------------
function TriviaBot.Send(msg)
	-- Send a message to the trivia channel
	msg = TB_Channel_Prefix .. ": " .. msg; -- Add the trivia tag to each message
	local cid = GetChannelName(TriviaBot_Config['Channel']); -- Custom channel id
	local gdata = TB_ServerChannels[SERVER_CHANNEL_INTERNAL_ID[GENERAL_IID]]
	local gid = gdata and gdata["id"] or 0; -- General channel id
	if (TriviaBot_Config['Chat_Type'] ~= "channel" and TriviaBot_Config['Chat_Type'] ~= "general") then
		SendChatMessage(msg, string.upper(TriviaBot_Config['Chat_Type']));
	elseif (TriviaBot_Config['Chat_Type'] == "channel" and cid > 0) then
		SendChatMessage(msg, "CHANNEL", nil, cid);
	elseif (TriviaBot_Config['Chat_Type'] == "general" and gid > 0) then
		SendChatMessage(msg, "CHANNEL", nil, gid);
	else
		-- Print error if no valid channels were found
		TriviaBot.PrintError(L.TB_ERROR_NOVALIDCHANNEL);
	end
end

----------------------------------------------------------------------------
-- Send a whisper message back to the player
----------------------------------------------------------------------------
function TriviaBot.SendWhisper(player, msg)
	msg = TB_Short_Prefix .. ": " .. msg; -- Add a more diskrete trivia tag to the message
	SendChatMessage(msg, "WHISPER", nil, player);
end

----------------------------------------------------------------------------
-- Skip current question
----------------------------------------------------------------------------
function TriviaBot.SkipQuestion()
	TriviaBotGUI.SkipButton:Disable();
	if (TB_Running) then
		if not TB_limit_out then TriviaBot.Send(L.TB_SEND_QUESTIONSKIPPED); end
		TriviaBot.UnSchedule("all");
		TB_Accept_Answers = false;

		-- Show the answer anyway (for those that wanted to know)
		if (TriviaBot_Config['Show_Answers']) then
			TriviaBot.Schedule("SHOW_ANSWER", TB_Min_Interval);
		end

		-- Schedule the next question
		TriviaBot.Schedule("NEXT_QUESTION", TriviaBot_Config['Question_Interval']);
		TriviaBot.Print(L.TB_PRINT_QUESTIONSKIP);
	else
		TriviaBot.PrintError(L.TB_ERROR_NOGAME);
	end
end

----------------------------------------------------------------------------
-- Start trivia session
----------------------------------------------------------------------------
function TriviaBot.Start(announce)
	local id = TriviaBot_Config['Question_Set'];
	if TriviaBot_Questions[id]['Stub'] and not TriviaBot.questionmaker then
		TriviaBot.PrintError(L.TB_ERROR_NOLOADED)
		return
	end -- not yet loaded set
	-- Set Running
	TB_Running = true;

	-- Check if the channel is present
	TriviaBot.CheckChannel();

	TB_limit_out = TriviaBot_Config['Chat_Type']
	TB_limit_out = strlower(TB_limit_out)=="general" and true or false
	-- Announce the start
	if not TB_limit_out then TriviaBot.Send(L.TB_SEND_POWEREDBY); end
	local category;
	if (TriviaBot_Config['Question_Category'] ~= 0) then
		category = TB_Question_Sets[id]['Categories'][TriviaBot_Config['Question_Category']];
	else
		category = L.TB_GUI_ALL;
	end
	if not TB_limit_out then TriviaBot.Send(L.TB_SEND_USINGDATABASE .. TB_Question_Sets[id]['Title']); end
	if (announce and not TB_limit_out) then -- todo: config this
		TriviaBot.Send(L.TB_SEND_DESCRIPTION .. TB_Question_Sets[id]['Description']);
		TriviaBot.Send(L.TB_SEND_AUTHOR .. TB_Question_Sets[id]['Author']);
		TriviaBot.Send(L.TB_SEND_CATEGORYSELECTED .. category);
	end
	if (TriviaBot_Config['Round_Size'] ~= TB_Infinite_Round) then
		if not TB_limit_out then TriviaBot.Send(L.TB_SEND_STARTROUND .. TriviaBot_Config['Round_Size'] .. L.TB_SEND_BLANKQUESTIONS); end
	end
	if (announce) then -- todo: config this
		TriviaBot.Print(L.TB_PRINT_FIRSTQUESTION);
	end

	-- Schedule start
	TriviaBot.Schedule("NEXT_QUESTION", TB_Min_Interval);

	-- Clear game scores
	TB_Game_Scores = {};
	TB_Game_Scores['Best_Win_Streak'] = {};
	TB_Game_Scores['Temp_Win_Streak'] = {};
	TB_Game_Scores['Speed'] = {};
	TB_Game_Scores['Player_Scores'] = {};

	if (not TriviaBot_Scores) then
		TriviaBot_Scores = {};
	end
	if (not TriviaBot_Scores['Win_Streak']) then
		TriviaBot_Scores['Win_Streak'] = {};
	end
	if (not TriviaBot_Scores['Speed']) then
		TriviaBot_Scores['Speed'] = {};
	end
	if (not TriviaBot_Scores['Player_Scores']) then
		TriviaBot_Scores['Player_Scores'] = {};
	end

	-- Reset Round and Report Counters
	TB_Report_Counter = 0;
	TB_Round_Counter = 0;

	-- GUI Update
	TriviaBotGUI.StartStopToggle();
end

----------------------------------------------------------------------------
-- Check if str starts with start
----------------------------------------------------------------------------
function TriviaBot.Starts(str, start)
	return string.sub(str,1,string.len(start)) == start;
end

----------------------------------------------------------------------------
-- Start/Stop Toggle
----------------------------------------------------------------------------
function TriviaBot.StartStopToggle()
	if(TB_Running) then
		TriviaBot.Stop(true);
	else
		TriviaBot.Start();
	end
end

----------------------------------------------------------------------------
-- QuestionMaker Toggle (if the optional addon is loaded)
----------------------------------------------------------------------------
function TriviaBot.QuestionMakerToggle(self,button)
	if TriviaBot_QuestionMakerGUI:IsShown() then
		TriviaBot_QuestionMakerGUI:Hide()
	else
		TriviaBot_QuestionMakerGUI:ClearAllPoints()
		local side = findSide(TriviaBotGUI_Header)
		TriviaBotGUI_Header:ClearAllPoints()
		if side == "left" then
			TriviaBot_QuestionMakerGUI:SetPoint("TOPRIGHT",TriviaBotGUI_Header,"TOPLEFT",0,-32)
		else
			TriviaBot_QuestionMakerGUI:SetPoint("TOPLEFT",TriviaBotGUI_Header,"TOPRIGHT",0,-32)
		end
		TriviaBot_QuestionMakerGUI:Show()
	end
end

function TriviaBot.ReloadQuestionsOnClick(self,button)
	TB_Question_Sets = {}
	TriviaBot.LoadQuestionSets()
	TriviaBot.LoadTrivia(TriviaBot_Config['Question_Set'], TriviaBot_Config['Question_Category'])
	self:Hide()
	TriviaBot.questionmaker = nil
	TriviaBotGUI.Update();
end

function API.GUIUpdate()
	-- wrapper function for use by quizmaker
	TriviaBotGUI.Update()
end

function API.LoadQuestionMakerSet()
	if next(_G["TriviaBotQuestionMakerExports"]["ActiveSet"]) then
		TB_Question_Sets = {}
		TB_Question_Sets = deepcopy(_G["TriviaBotQuestionMakerExports"]["ActiveSet"])
		TB_Questions = TB_Question_Sets[1];
		TB_Questions['Title'] = "QMaker:"..TB_Question_Sets[1]['Title'];
		if (not TB_Questions['CatIdx']) then
			TB_Questions['CatIdx'] = {[0] = {}};
			for id,_ in pairs(TB_Questions['Categories']) do
				TB_Questions['CatIdx'][id] = {};
			end
			for id,_ in pairs(TB_Questions['Question']) do
				table.insert(TB_Questions['CatIdx'][0], id);
				local catid = TB_Questions['Category'][id];
				if (TB_Questions['CatIdx'][catid]) then
					table.insert(TB_Questions['CatIdx'][catid], id);
				end
			end
		end
		TriviaBot_Config['Question_Set'] = 1;
		TriviaBot_Config['Question_Category'] = 0;
		TB_Question_List = TB_Questions['CatIdx'][0]
		local category = L.TB_GUI_ALL;
		if (#TB_Questions['Question'] > 0) then
			TriviaBot.Print(L.TB_PRINT_QUESTIONCOUNT .. #TB_Questions['Question'])
			TriviaBot.Print(L.TB_PRINT_DATABASENAME .. TriviaBot.Capitalize(TB_Questions['Title']) .. L.TB_PRINT_HYPHENCATEGORY .. category .. L.TB_PRINT_BLANKLOADED);
		else
			TriviaBot.Print(L.TB_PRINT_DATABASENAME .. TriviaBot.Capitalize(TB_Questions['Title']) .. L.TB_PRINT_HYPHENCATEGORY .. category .. L.TB_PRINT_NOQUESTIONLOAD);
		end
		-- Always randomize the question order
		TriviaBot.Randomize();
		if (TB_Running)then
			-- If we're switching databases mid-game, we should alert our players that the questions has changed
			TriviaBot.Send(L.TB_SEND_SWITCHDATABASE .. TriviaBot.Capitalize(TB_Questions['Title']) .. L.TB_PRINT_DOTDESCRIPTION .. TB_Questions['Description'].. L.TB_PRINT_DOTAUTHOR .. TB_Questions['Author'] .. ".");
			TriviaBot.Schedule("NEXT_QUESTION", TriviaBot_Config['Question_Interval']);
		end
		collectgarbage("collect") -- Do a cleanup
		TriviaBotGUI.ReloadQuestionsButton:Show();
		TriviaBot.questionmaker = true
	end
end

----------------------------------------------------------------------------
-- Stop trivia session
----------------------------------------------------------------------------
function TriviaBot.Stop(announce)
	-- Clear all scheduled events
	TriviaBot.UnSchedule("all");
	TB_Accept_Answers = false;
	TB_Running = false;

	if (announce) then
		TriviaBot.Send(L.TB_PRINT_TRIVIASTOPPED);
	end
	TriviaBot.Print(L.TB_PRINT_TRIVIASTOPPED)

	-- GUI Update
	TriviaBotGUI.StartStopToggle();
end

----------------------------------------------------------------------------
-- Extracts name from links
-- Removes leading/trailing spaces and punctuation chars from the string
----------------------------------------------------------------------------
function TriviaBot.StringCorrection(str)
	-- Strip name out of links
	str = strmatch(str,"|h%[(.-)%]|h|r") or str
	-- Remove whitespaces
	str = str:gsub("^%s*(.-)%s*$", "%1");
	-- Remove punctuation
	str = str:gsub("^%p*(.-)%p*$", "%1");
	return str;
end

----------------------------------------------------------------------------
-- Unregister Chat Event
----------------------------------------------------------------------------
function TriviaBot.UnregEvent(chat_type)
	if (chat_type == "channel") then
		TriviaBot:UnregisterEvent("CHAT_MSG_CHANNEL");
	elseif (chat_type == "say") then
		TriviaBot:UnregisterEvent("CHAT_MSG_SAY");
	elseif (chat_type == "general") then
		TriviaBot:UnregisterEvent("CHAT_MSG_CHANNEL");
	elseif (chat_type == "guild") then
		TriviaBot:UnregisterEvent("CHAT_MSG_GUILD");
	elseif (chat_type == "party") then
		TriviaBot:UnregisterEvent("CHAT_MSG_PARTY");
		TriviaBot:UnregisterEvent("CHAT_MSG_PARTY_LEADER");
	elseif (chat_type == "raid") then
		TriviaBot:UnregisterEvent("CHAT_MSG_RAID");
		TriviaBot:UnregisterEvent("CHAT_MSG_RAID_LEADER");
	elseif (chat_type == "instance_chat") then
		TriviaBot:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT");
		TriviaBot:UnregisterEvent("CHAT_MSG_INSTANCE_CHAT_LEADER");
	else
		TriviaBot.Print(L.TB_PRINT_NOCHATEVENTSUNREG);
	end
end

----------------------------------------------------------------------------
-- Removes an event from the schedule
----------------------------------------------------------------------------
function TriviaBot.UnSchedule(id)
	-- Unschedule an event
	if (id == "all") then
		TB_Schedule = {};
	else
		table.remove(TB_Schedule, id);
	end
end

----------------------------------------------------------------------------
-- Whisper command handler
----------------------------------------------------------------------------
function TriviaBot.WhisperControl(player, msg)
	-- Create variables
	local msgArgs = {};

	-- Seperate our args
	for value in string.gmatch(msg, "[^ ]+") do
		table.insert(msgArgs, value);
	end

	if TriviaBot.Starts(msg, string.lower(TB_Message_Prefix)) then
		if (msgArgs[2] == "help") then
			TriviaBot.SendWhisper(player, "Help Menu:");
			TriviaBot.SendWhisper(player, "!tb help - For this help menu.");
			TriviaBot.SendWhisper(player, "!tb info - Info about the current game.");
			TriviaBot.SendWhisper(player, "!tb score - Score help menu.");
		elseif (msgArgs[2] == "info") then
			TriviaBot.SendWhisper(player, "Title: " .. TB_Question_Sets[TriviaBot_Config['Question_Set']]['Title']);
			if (TriviaBot_Config['Question_Category'] == 0) then
				TriviaBot.SendWhisper(player, "Category: All");
			else
				TriviaBot.SendWhisper(player, "Category: " .. TB_Question_Sets[TriviaBot_Config['Question_Set']]['Categories'][TriviaBot_Config['Question_Category']]);
			end
			if (TB_Running) then
				if (TriviaBot_Config['Round_Size'] ~= TB_Infinite_Round) then
					TriviaBot.SendWhisper(player, "Round Size: " .. TriviaBot_Config['Round_Size']);
					TriviaBot.SendWhisper(player, "Current Round: " .. TB_Round_Counter + 1);
				else
					TriviaBot.SendWhisper(player, "Round Size: Unlimited");
				end
			else
				TriviaBot.SendWhisper(player, "No games currently running");
			end
		elseif (msgArgs[2] == "score") then
			if (msgArgs[3] == "game") then
				if (TB_Game_Scores['Player_Scores'][player]) then
					TriviaBot.SendWhisper(player, "Speed Record: " .. TB_Game_Scores['Player_Scores'][player]['Speed']);
					TriviaBot.SendWhisper(player, "Win Streak Record: " .. TB_Game_Scores['Player_Scores'][player]['Win_Streak']);
					TriviaBot.SendWhisper(player, "Points: " .. TB_Game_Scores['Player_Scores'][player]['Points']);
					TriviaBot.SendWhisper(player, "Score: " .. TB_Game_Scores['Player_Scores'][player]['Score']);
				else
					TriviaBot.SendWhisper(player, "No current game scores found.");
				end
			elseif (msgArgs[3] == "alltime") then
				if (TriviaBot_Scores['Player_Scores'][player]) then
					TriviaBot.SendWhisper(player, "Speed Record: " .. TriviaBot_Scores['Player_Scores'][player]['Speed']);
					TriviaBot.SendWhisper(player, "Win Streak Record: " .. TriviaBot_Scores['Player_Scores'][player]['Win_Streak']);
					TriviaBot.SendWhisper(player, "Points: " .. TriviaBot_Scores['Player_Scores'][player]['Points']);
					TriviaBot.SendWhisper(player, "Score: " .. TriviaBot_Scores['Player_Scores'][player]['Score']);
				else
					TriviaBot.SendWhisper(player, "No all-time scores found.");
				end
			else
				TriviaBot.SendWhisper(player, "Score Help Menu:");
				TriviaBot.SendWhisper(player, "!tb score game - For your current (or previous) game scores:");
				TriviaBot.SendWhisper(player, "!tb score alltime - For your all-time scores");
			end
		else
			TriviaBot.SendWhisper(player, "Help Menu:");
			TriviaBot.SendWhisper(player, "!tb help - For this help menu.");
			TriviaBot.SendWhisper(player, "!tb info - Info about the current game.");
			TriviaBot.SendWhisper(player, "!tb score - Score help menu.");
		end
	end
end

----------------------------------------------------------------------------
-- GUI functions
----------------------------------------------------------------------------

----------------------------------------------------------------------------
-- Initialize all GUI objects
----------------------------------------------------------------------------
-- If you want a control to have a help tooltip add a .toolTip key
-- to the frame and set the string you want to appear there and
-- OnEnter/OnLeave scripts.
-- Example:
-- myEditbox.toolTip = "My localized help string";
-- myEditbox:SetScript("OnEnter", TriviaBotGUI.OnMouseEnter);
-- myEditbox:SetScript("OnLeave", GameTooltip_Hide);
function TriviaBot.GUIInitialize()
	local editboxspace = 8;
	local checkboxspace = 5;

	TriviaBotGUI.OnMouseEnter = function(self)
		if self.toolTip then
			GameTooltip:SetOwner(self, "ANCHOR_TOP")
			GameTooltip:SetText(self.toolTip, nil, nil, nil, 1.0)
		end
	end
	TriviaBotGUI.EditBox_Highlight = function(self)
		self:HighlightText(0,0); -- We don't want any highlighting
	end
	-- Header Frame for dragging and minimizing
	TriviaBotGUI_Header:SetWidth(tonumber(L.TB_GUI_WIDTH));
	TriviaBotGUI_Header:SetHeight(31);
	TriviaBotGUI_Header:SetBackdrop(
	{
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 16, edgeSize = 16,
		insets = {left = 5, right = 5, top = 5, bottom = 5}
	});
	TriviaBotGUI_Header:SetBackdropColor(0,0,0,1);
	TriviaBotGUI_Header:SetFrameStrata("BACKGROUND");
	TriviaBotGUI_Header:SetClampedToScreen(true);
	TriviaBotGUI_Header:SetClampRectInsets(-5,5,5,-50);
	TriviaBotGUI_Header:SetPoint("TOP", 0, -200);
	TriviaBotGUI_Header:EnableMouse(true);
	TriviaBotGUI_Header:SetMovable(true);
	TriviaBotGUI_Header:RegisterForDrag("LeftButton");
	TriviaBotGUI_Header.toolTip = L.TB_GUI_PANELCONTROL_TIP;
	TriviaBotGUI_Header:SetScript("OnDragStart", TriviaBotGUI_Header.StartMoving);
	TriviaBotGUI_Header:SetScript("OnDragStop", TriviaBotGUI_Header.StopMovingOrSizing);
	TriviaBotGUI_Header:SetScript("OnHide", TriviaBotGUI_Header.StopMovingOrSizing);
	TriviaBotGUI_Header:SetScript("OnShow", TriviaBotGUI.Show);
	TriviaBotGUI_Header:SetScript("OnMouseDown",
	function(_,button)
		if button == "LeftButton" then
			if IsDoubleClick(GetTime()) then
				if TriviaBotGUI:IsShown() then TriviaBotGUI:Hide() else TriviaBotGUI:Show() end
			end
		end
	end)
	TriviaBotGUI_Header:SetScript("OnEnter", TriviaBotGUI.OnMouseEnter);
	TriviaBotGUI_Header:SetScript("OnLeave", GameTooltip_Hide);
	tinsert(UISpecialFrames, "TriviaBotGUI_Header");
	TriviaBotGUI_Header:Hide();

	TriviaBotGUI.HeaderLabel = TriviaBotGUI_Header:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.HeaderLabel:ClearAllPoints();
	TriviaBotGUI.HeaderLabel:SetPoint("TOP", TriviaBotGUI_Header, "TOP", 0, -8);

	-- Close Button
	TriviaBotGUI.CloseButton = CreateFrame("Button", nil, TriviaBotGUI_Header, "UIPanelCloseButton");
	TriviaBotGUI.CloseButton:ClearAllPoints();
	TriviaBotGUI.CloseButton:SetPoint("TOPRIGHT", TriviaBotGUI_Header, "TOPRIGHT", 0, 0);
	TriviaBotGUI.CloseButton:SetScript("OnClick", function() TriviaBotGUI_Header:Hide() end);
	TriviaBotGUI.CloseButton.toolTip = L.TB_GUI_CLOSE_TIP;
	TriviaBotGUI.CloseButton:SetScript("OnEnter", TriviaBotGUI.OnMouseEnter);
	TriviaBotGUI.CloseButton:SetScript("OnLeave", GameTooltip_Hide);

	-- Set the main GUI screen
	TriviaBotGUI:ClearAllPoints();
	TriviaBotGUI:SetWidth(tonumber(L.TB_GUI_WIDTH));
	TriviaBotGUI:SetHeight(445);
	TriviaBotGUI:SetBackdrop(
	{
		bgFile = "Interface/Tooltips/UI-Tooltip-Background",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true, tileSize = 32, edgeSize = 16,
		insets = {left = 5, right = 5, top = 5, bottom = 5}
	});
	TriviaBotGUI:SetBackdropColor(0,0,0,1);
	TriviaBotGUI:SetFrameLevel(TriviaBotGUI_Header:GetFrameLevel()-1);
	TriviaBotGUI:SetPoint("TOPLEFT", TriviaBotGUI_Header, "BOTTOMLEFT");

	-- Question List
	TriviaBotGUI.QuestionList = CreateFrame("Frame", "TriviaBotGUI_QuestionList", TriviaBotGUI, "Lib_UIDropDownMenuTemplate");
	TriviaBotGUI.QuestionList.OnClick = function(self)
		local set = self.value;
		if TriviaBot_Questions[set]['Stub'] then
			local questionPack = TriviaBot_QuestionPacks[set]
			if questionPack then
				local loaded, reason = LoadAddOn(questionPack)
				if not loaded then
					TriviaBot.PrintError(questionPack..":".._G["ADDON_"..reason])
				else
					TriviaBot_Questions[set]['Stub'] = nil;
					TriviaBot_Questions[set]={};
					TriviaBot_Questions[set]=_G[questionPack]["QuestionList"]
					TriviaBot.LoadQuestionSets();
				end
			end
		end
		if (TB_Question_Sets[set]) then
			if not TriviaBot.questionmaker then
				TriviaBot.LoadTrivia(set, 0); -- 'All' category
			end
			TriviaBot_Config['Question_Set'] = set;
			TriviaBot_Config['Question_Category'] = 0;
		end

		Lib_UIDropDownMenu_SetSelectedValue(TriviaBotGUI.QuestionList, TriviaBot_Config['Question_Set']);
		Lib_UIDropDownMenu_SetText(TriviaBotGUI.QuestionList, TriviaBot.Capitalize(TB_Question_Sets[TriviaBot_Config['Question_Set']]['Title']))
		Lib_UIDropDownMenu_SetSelectedValue(TriviaBotGUI.CategoryList, 0);
		Lib_UIDropDownMenu_SetText(TriviaBotGUI.CategoryList, L.TB_GUI_ALL)
	end
	TriviaBotGUI.QuestionList.Initialize = function()
		local info;

		for id,_ in pairs(TB_Question_Sets) do
			info = Lib_UIDropDownMenu_CreateInfo();
			info.value = id;
			info.text = TriviaBot.Capitalize(TB_Question_Sets[id]['Title']);
			info.func = TriviaBotGUI.QuestionList.OnClick;
			Lib_UIDropDownMenu_AddButton(info);
		end

		Lib_UIDropDownMenu_SetSelectedValue(TriviaBotGUI.QuestionList, TriviaBot_Config['Question_Set']);
		Lib_UIDropDownMenu_SetText(TriviaBotGUI.QuestionList, TriviaBot.Capitalize(TB_Question_Sets[TriviaBot_Config['Question_Set']]['Title']))
	end
	TriviaBotGUI.QuestionList:ClearAllPoints();
	Lib_UIDropDownMenu_SetWidth(TriviaBotGUI.QuestionList, 150);
	Lib_UIDropDownMenu_SetButtonWidth(TriviaBotGUI.QuestionList, 20);
	TriviaBotGUI.QuestionList:SetPoint("TOPLEFT", TriviaBotGUI, "TOP", -35, -20);
	Lib_UIDropDownMenu_Initialize(TriviaBotGUI.QuestionList, TriviaBotGUI.QuestionList.Initialize);
	-- Question List Label
	TriviaBotGUI.QuestionList.Label = TriviaBotGUI.QuestionList:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.QuestionList.Label:ClearAllPoints();
	TriviaBotGUI.QuestionList.Label:SetText(L.TB_GUI_QUESTIONLIST);
	TriviaBotGUI.QuestionList.Label:SetPoint("RIGHT", TriviaBotGUI.QuestionList, "LEFT", 10, 2);
	-- Question List Print Button
	TriviaBotGUI.QuestionList.PrintButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
	TriviaBotGUI.QuestionList.PrintButton:ClearAllPoints();
	TriviaBotGUI.QuestionList.PrintButton:SetWidth(tonumber(L.TB_GUI_PRINT_WIDTH));
	TriviaBotGUI.QuestionList.PrintButton:SetText(L.TB_GUI_PRINT);
	TriviaBotGUI.QuestionList.PrintButton:SetPoint("TOPLEFT", TriviaBotGUI, "TOPLEFT", 15, -25);
	TriviaBotGUI.QuestionList.PrintButton:SetScript("OnClick", TriviaBot.PrintQuestionList);

	-- Category List
	TriviaBotGUI.CategoryList = CreateFrame("Frame", "TriviaBotGUI_CategoryList", TriviaBotGUI, "Lib_UIDropDownMenuTemplate");
	TriviaBotGUI.CategoryList.OnClick = function(self)
		local cat = self.value;
		local set = TriviaBot_Config['Question_Set'];

		if ((TB_Question_Sets[set]['Categories'][cat] or cat == 0) and cat ~= TriviaBot_Config['Question_Category']) then
			if not TriviaBot.questionmaker then
				TriviaBot.LoadTrivia(set, cat);
			end
			TriviaBot_Config['Question_Category'] = cat;
		end

		Lib_UIDropDownMenu_SetSelectedValue(TriviaBotGUI.CategoryList, TriviaBot_Config['Question_Category']);
	end
	TriviaBotGUI.CategoryList.Initialize = function()
		local info;
		local set = TriviaBot_Config['Question_Set'];

		if (#TB_Question_Sets > 0 and TB_Question_Sets[set]) then
			-- Add 'All' option
			info = Lib_UIDropDownMenu_CreateInfo();
			info.value = 0;
			info.text = L.TB_GUI_ALL;
			info.func = TriviaBotGUI.CategoryList.OnClick;
			Lib_UIDropDownMenu_AddButton(info);

			for id,_ in pairs(TB_Question_Sets[set]['Categories']) do
				info = Lib_UIDropDownMenu_CreateInfo();
				info.value = id;
				info.text = TB_Question_Sets[set]['Categories'][id];
				info.func = TriviaBotGUI.CategoryList.OnClick;
				Lib_UIDropDownMenu_AddButton(info);
			end
			local cat = TriviaBot_Config['Question_Category']
			Lib_UIDropDownMenu_SetSelectedValue(TriviaBotGUI.CategoryList, cat);
			if tonumber(cat) == 0 then
				Lib_UIDropDownMenu_SetText(TriviaBotGUI.CategoryList, L.TB_GUI_ALL)
			else
				Lib_UIDropDownMenu_SetText(TriviaBotGUI.CategoryList, TB_Question_Sets[set]['Categories'][TriviaBot_Config['Question_Category']])
			end
		end
	end
	TriviaBotGUI.CategoryList:ClearAllPoints();
	Lib_UIDropDownMenu_SetWidth(TriviaBotGUI.CategoryList, 150);
	Lib_UIDropDownMenu_SetButtonWidth(TriviaBotGUI.CategoryList, 20);
	TriviaBotGUI.CategoryList:SetPoint("TOPLEFT", TriviaBotGUI.QuestionList, "BOTTOMLEFT", 0, 0);
	Lib_UIDropDownMenu_Initialize(TriviaBotGUI.CategoryList, TriviaBotGUI.CategoryList.Initialize);
	-- Category List Label
	TriviaBotGUI.CategoryList.Label = TriviaBotGUI.CategoryList:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.CategoryList.Label:ClearAllPoints();
	TriviaBotGUI.CategoryList.Label:SetText(L.TB_GUI_CATEGORYLIST);
	TriviaBotGUI.CategoryList.Label:SetPoint("RIGHT", TriviaBotGUI.CategoryList, "LEFT", 10, 2);
	-- Category List Print Button
	TriviaBotGUI.CategoryList.PrintButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
	TriviaBotGUI.CategoryList.PrintButton:ClearAllPoints();
	TriviaBotGUI.CategoryList.PrintButton:SetWidth(tonumber(L.TB_GUI_PRINT_WIDTH));
	TriviaBotGUI.CategoryList.PrintButton:SetText(L.TB_GUI_PRINT);
	TriviaBotGUI.CategoryList.PrintButton:SetPoint("TOPLEFT", TriviaBotGUI, "TOPLEFT", 15, -55);
	TriviaBotGUI.CategoryList.PrintButton:SetScript("OnClick", TriviaBot.PrintCategoryList);

	-- Chat Type List
	TriviaBotGUI.ChatType = CreateFrame("Frame", "TriviaBotGUI_ChatType", TriviaBotGUI, "Lib_UIDropDownMenuTemplate");
	TriviaBotGUI.ChatType.OnClick = function(self)
		-- Get the chat type value
		local type = self.value;
		-- No reason to change if the selected chat is the same as previous
		if (type == TriviaBot_Config['Chat_Type']) then
			return;
		end
		if (type == "channel") then
			TriviaBot.ChatSelect(type, TriviaBot_Config['Channel']);
		else
			TriviaBot.ChatSelect(type);
		end
		-- Warn for public channels
		if (type == "say" or type == "instance_chat" or type == "general") then
			TriviaBot.Print(TB_RED .. L.TB_PRINT_WARNINGCAPS .. TB_WHITE .. L.TB_PRINT_PUBLICCHANNEL);
			TriviaBot.Print(L.TB_PRINT_PUBLICANNOYING);
			TriviaBot.Print(L.TB_PRINT_REPORTBAN);
			TriviaBot.Print(L.TB_PRINT_RESPONSIBILITY);
		end
		Lib_UIDropDownMenu_SetSelectedValue(TriviaBotGUI.ChatType, TriviaBot_Config['Chat_Type']);
	end
	TriviaBotGUI.ChatType.Initialize = function()
		local info;
		-- Say channel
		info = Lib_UIDropDownMenu_CreateInfo();
		info.value = "say";
		info.text = "Say";
		info.func = TriviaBotGUI.ChatType.OnClick;
		Lib_UIDropDownMenu_AddButton(info);
		-- General channel
		if (TB_ServerChannels[SERVER_CHANNEL_INTERNAL_ID[GENERAL_IID]]) then
			info = Lib_UIDropDownMenu_CreateInfo();
			info.value = "general";
			info.text = "General";
			info.func = TriviaBotGUI.ChatType.OnClick;
			Lib_UIDropDownMenu_AddButton(info);
		end
		-- Guild channel
		if (IsInGuild()) then
			info = Lib_UIDropDownMenu_CreateInfo();
			info.value = "guild";
			info.text = "Guild";
			info.func = TriviaBotGUI.ChatType.OnClick;
			Lib_UIDropDownMenu_AddButton(info);
		end
		-- Party channel
		if (IsInGroup(LE_PARTY_CATEGORY_HOME)) then
			info = Lib_UIDropDownMenu_CreateInfo();
			info.value = "party";
			info.text = "Party";
			info.func = TriviaBotGUI.ChatType.OnClick;
			Lib_UIDropDownMenu_AddButton(info);
		end
		-- Raid channel
		if (IsInRaid(LE_PARTY_CATEGORY_HOME)) then
			info = Lib_UIDropDownMenu_CreateInfo();
			info.value = "raid";
			info.text = "Raid";
			info.func = TriviaBotGUI.ChatType.OnClick;
			Lib_UIDropDownMenu_AddButton(info);
		end
		-- Battleground channel
		if (TB_Zone == L.TB_ZONE_AB or TB_Zone == L.TB_ZONE_WSG or TB_Zone == L.TB_ZONE_AV or TB_Zone == L.TB_ZONE_EOTS or TB_Zone == L.TB_ZONE_IOC or TB_Zone == L.TB_ZONE_TBFG or TB_Zone == L.TB_ZONE_TP) then
			info = Lib_UIDropDownMenu_CreateInfo();
			info.value = "instance_chat";
			info.text = "Instance";
			info.func = TriviaBotGUI.ChatType.OnClick;
			Lib_UIDropDownMenu_AddButton(info);
		end
		-- Custom channel
		info = Lib_UIDropDownMenu_CreateInfo();
		info.value = "channel";
		info.text = "Custom Channel";
		info.func = TriviaBotGUI.ChatType.OnClick;
		Lib_UIDropDownMenu_AddButton(info);

		Lib_UIDropDownMenu_SetSelectedValue(TriviaBotGUI.ChatType, TriviaBot_Config['Chat_Type']);
	end
	TriviaBotGUI.ChatType:ClearAllPoints();
	Lib_UIDropDownMenu_SetWidth(TriviaBotGUI.ChatType, 150);
	Lib_UIDropDownMenu_SetButtonWidth(TriviaBotGUI.ChatType, 20);
	TriviaBotGUI.ChatType:SetPoint("TOPLEFT", TriviaBotGUI.CategoryList, "BOTTOMLEFT", 0, 0);
	Lib_UIDropDownMenu_Initialize(TriviaBotGUI.ChatType, TriviaBotGUI.ChatType.Initialize);
	-- Chat Type List Label
	TriviaBotGUI.ChatType.Label = TriviaBotGUI.ChatType:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.ChatType.Label:ClearAllPoints();
	TriviaBotGUI.ChatType.Label:SetText(L.TB_GUI_CHATTYPE);
	TriviaBotGUI.ChatType.Label:SetPoint("RIGHT", TriviaBotGUI.ChatType, "LEFT", 10, 2);

	-- Channel Update Button
	TriviaBotGUI.ChannelButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
	TriviaBotGUI.ChannelButton:ClearAllPoints();
	TriviaBotGUI.ChannelButton:SetWidth(tonumber(L.TB_GUI_UPDATE_WIDTH));
	TriviaBotGUI.ChannelButton:SetText(L.TB_GUI_UPDATE);
	TriviaBotGUI.ChannelButton:SetPoint("TOPLEFT", TriviaBotGUI.ChatType, "BOTTOM", 15, -5);

	-- Channel TextBox
	TriviaBotGUI.Channel = CreateFrame("EditBox", nil, TriviaBotGUI, "InputBoxTemplate");
	TriviaBotGUI.Channel.OnEditFocusLost = function(self)
		if (self:GetText():len() == 0) then
			self:SetText(TriviaBot_Config['Channel']);
		end
	end
	TriviaBotGUI.Channel.OnEscapePressed = function(self)
		self:SetText(TriviaBot_Config['Channel']);
		self:ClearFocus();
	end
	TriviaBotGUI.Channel.Update = function()
		local channel = TriviaBotGUI.Channel:GetText();
		if(channel == "") then
			-- Someone forgot to put text here so we simply put it back
			TriviaBotGUI.Channel:SetText(TriviaBot_Config['Channel']);
			return;
		end
		-- Let's check if the channel is valid
		local lchannel, invalid = strlower(channel)
		for gcn,fcn in pairs(TB_Chat_Restricted) do
			if lchannel == gcn or lchannel == fcn then
				invalid = true
				break
			end
		end
		if not invalid then
			TriviaBotGUI.Channel:SetText(L.TB_GUI_CHANNELCHANGE);
			TriviaBot.ChatSelect("channel", channel);
		else
			TriviaBot.PrintError(L.TB_ERROR_INVALIDCHANNELCHOOSE);
			TriviaBotGUI.Channel:SetText(TriviaBot_Config['Channel']);
			return;
		end
		if (GetChannelName(channel) > 0) then
			if (TriviaBot_Config['Channel'] == channel) then
				TriviaBot.Print(L.TB_PRINT_ALREADYJOINED);
			else
				TriviaBot_Config['Channel'] = channel;
				TriviaBot.Print(L.TB_PRINT_CHANNELCHANGE .. channel);
			end
			return;
		end
		TriviaBotGUI.Channel:ClearFocus();
	end
	TriviaBotGUI.Channel:ClearAllPoints();
	TriviaBotGUI.Channel:SetWidth(100);
	TriviaBotGUI.Channel:SetHeight(36);
	TriviaBotGUI.Channel:SetMaxLetters(20);
	TriviaBotGUI.Channel:SetAutoFocus(false);
	TriviaBotGUI.Channel:SetPoint("RIGHT", TriviaBotGUI.ChannelButton, "LEFT", -10, 1);
	TriviaBotGUI.Channel:SetScript("OnEnterPressed", TriviaBotGUI.Channel.Update);
	TriviaBotGUI.Channel:SetScript("OnEscapePressed", TriviaBotGUI.Channel.OnEscapePressed);
	TriviaBotGUI.Channel:SetScript("OnEditFocusLost", TriviaBotGUI.Channel.OnEditFocusLost);
	TriviaBotGUI.Channel:SetScript("OnEditFocusGained", TriviaBotGUI.EditBox_Highlight);
	TriviaBotGUI.ChannelButton:SetScript("OnClick", TriviaBotGUI.Channel.Update);
	-- Channel TextBox Label
	TriviaBotGUI.Channel.Label = TriviaBotGUI.Channel:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.Channel.Label:ClearAllPoints();
	TriviaBotGUI.Channel.Label:SetText(L.TB_GUI_CUSTOMCHANNEL);
	TriviaBotGUI.Channel.Label:SetPoint("RIGHT", TriviaBotGUI.Channel, "LEFT", -15, 0);

	-- Round Size TextBox
	TriviaBotGUI.RoundSize = CreateFrame("EditBox", nil, TriviaBotGUI, "InputBoxTemplate");
	TriviaBotGUI.RoundSize.OnEditFocusLost = function(self)
		local value = tonumber(self:GetText());
		if (not value or (value ~= TB_Infinite_Round and value < TB_Min_Round) or value > TB_Max_Round) then
			TriviaBot.PrintError(string.format(L.TB_ERROR_FMTROUNDSIZE,TB_Min_Round,TB_Max_Round,TB_Infinite_Round));
			self:SetText(TriviaBot_Config['Round_Size']);
		end
	end
	TriviaBotGUI.RoundSize.OnEscapePressed = function(self)
		self:SetText(TriviaBot_Config['Round_Size']);
		self:ClearFocus();
	end
	TriviaBotGUI.RoundSize.Update = function(self)
		if(self:GetText() == "") then
			-- Field is blanked out so we do nothing
			return;
		end
		local num = self:GetNumber();
		if (num == TB_Infinite_Round or (num >= TB_Min_Round and num <= TB_Max_Round)) then
			TriviaBot_Config['Round_Size'] = num;
		end
	end
	TriviaBotGUI.RoundSize:ClearAllPoints();
	TriviaBotGUI.RoundSize:SetWidth(40);
	TriviaBotGUI.RoundSize:SetHeight(36);
	TriviaBotGUI.RoundSize:SetMaxLetters(3);
	TriviaBotGUI.RoundSize:SetAutoFocus(false);
	TriviaBotGUI.RoundSize:SetNumeric(true);
	TriviaBotGUI.RoundSize:SetJustifyH("CENTER");
	TriviaBotGUI.RoundSize:SetTextInsets(0,6,0,0);
	TriviaBotGUI.RoundSize:SetPoint("TOPLEFT", TriviaBotGUI.Channel, "BOTTOMLEFT", 0, editboxspace);
	TriviaBotGUI.RoundSize:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
	TriviaBotGUI.RoundSize:SetScript("OnTextChanged", TriviaBotGUI.RoundSize.Update);
	TriviaBotGUI.RoundSize:SetScript("OnEscapePressed", TriviaBotGUI.RoundSize.OnEscapePressed);
	TriviaBotGUI.RoundSize:SetScript("OnEditFocusLost", TriviaBotGUI.RoundSize.OnEditFocusLost);
	TriviaBotGUI.RoundSize:SetScript("OnEditFocusGained", TriviaBotGUI.EditBox_Highlight);
	-- Round Size TextBox Label
	TriviaBotGUI.RoundSize.Label = TriviaBotGUI.RoundSize:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.RoundSize.Label:ClearAllPoints();
	TriviaBotGUI.RoundSize.Label:SetText(L.TB_GUI_ROUNDSIZE);
	TriviaBotGUI.RoundSize.Label:SetPoint("RIGHT", TriviaBotGUI.RoundSize, "LEFT", -15, 0);

	-- Question Interval TextBox
	TriviaBotGUI.QuestionInterval = CreateFrame("EditBox", nil, TriviaBotGUI, "InputBoxTemplate");
	TriviaBotGUI.QuestionInterval.OnEditFocusLost = function(self)
		local value = tonumber(self:GetText());
		if (not value or value < TB_Min_Interval or value > TB_Max_Interval) then
			TriviaBot.PrintError(string.format(L.TB_ERROR_FMTQUESTIONINTERVAL,TB_Min_Interval,TB_Max_Interval));
			self:SetText(TriviaBot_Config['Question_Interval']);
		end
	end
	TriviaBotGUI.QuestionInterval.OnEscapePressed = function(self)
		self:SetText(TriviaBot_Config['Question_Interval']);
		self:ClearFocus();
	end
	TriviaBotGUI.QuestionInterval.Update = function(self)
		if(self:GetText() == "") then
			-- Field is blanked out so we do nothing
			return;
		end
		local num = self:GetNumber();
		if (num >= TB_Min_Interval and num <= TB_Max_Interval) then
			TriviaBot_Config['Question_Interval'] = num;
		end
	end
	TriviaBotGUI.QuestionInterval:ClearAllPoints();
	TriviaBotGUI.QuestionInterval:SetWidth(40);
	TriviaBotGUI.QuestionInterval:SetHeight(36);
	TriviaBotGUI.QuestionInterval:SetMaxLetters(3);
	TriviaBotGUI.QuestionInterval:SetAutoFocus(false);
	TriviaBotGUI.QuestionInterval:SetNumeric(true);
	TriviaBotGUI.QuestionInterval:SetJustifyH("CENTER");
	TriviaBotGUI.QuestionInterval:SetTextInsets(0,6,0,0);
	TriviaBotGUI.QuestionInterval:SetPoint("TOPLEFT", TriviaBotGUI.RoundSize, "BOTTOMLEFT", 0, editboxspace);
	TriviaBotGUI.QuestionInterval:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
	TriviaBotGUI.QuestionInterval:SetScript("OnTextChanged", TriviaBotGUI.QuestionInterval.Update);
	TriviaBotGUI.QuestionInterval:SetScript("OnEscapePressed", TriviaBotGUI.QuestionInterval.OnEscapePressed);
	TriviaBotGUI.QuestionInterval:SetScript("OnEditFocusLost", TriviaBotGUI.QuestionInterval.OnEditFocusLost);
	TriviaBotGUI.QuestionInterval:SetScript("OnEditFocusGained", TriviaBotGUI.EditBox_Highlight);
	-- Question Interval TextBox Label
	TriviaBotGUI.QuestionInterval.Label = TriviaBotGUI.QuestionInterval:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.QuestionInterval.Label:ClearAllPoints();
	TriviaBotGUI.QuestionInterval.Label:SetText(L.TB_GUI_QUESTIONINTERVAL);
	TriviaBotGUI.QuestionInterval.Label:SetPoint("RIGHT", TriviaBotGUI.QuestionInterval, "LEFT", -15, 0);

	-- Question Timeout TextBox
	TriviaBotGUI.QuestionTimeout = CreateFrame("EditBox", nil, TriviaBotGUI, "InputBoxTemplate");
	TriviaBotGUI.QuestionTimeout.OnEditFocusLost = function(self)
		local value = tonumber(self:GetText());
		if (not value or value < TB_Min_Timeout or value > TB_Max_Timeout) then
			TriviaBot.PrintError(string.format(L.TB_ERROR_FMTQUESTIONTIMEOUT,TB_Min_Timeout,TB_Max_Timeout));
			self:SetText(TriviaBot_Config['Question_Timeout']);
		end
	end
	TriviaBotGUI.QuestionTimeout:ClearAllPoints();
	TriviaBotGUI.QuestionTimeout.OnEscapePressed = function(self)
		self:SetText(TriviaBot_Config['Question_Timeout']);
		self:ClearFocus();
	end
	TriviaBotGUI.QuestionTimeout.Update = function(self)
		if(self:GetText() == "") then
			-- Field is blanked out so we do nothing
			return;
		end
		local num = self:GetNumber();
		if (num >= TB_Min_Timeout and num <= TB_Max_Timeout) then
			TriviaBot_Config['Question_Timeout'] = num;
			if (TriviaBot_Config['Timeout_Warning']*2 > num) then
				TriviaBot_Config['Timeout_Warning'] = math.floor(num/2);
				TriviaBotGUI.TimeoutWarning:SetText(TriviaBot_Config['Timeout_Warning']);
			end
		end
	end
	TriviaBotGUI.QuestionTimeout:SetWidth(40);
	TriviaBotGUI.QuestionTimeout:SetHeight(36);
	TriviaBotGUI.QuestionTimeout:SetMaxLetters(3);
	TriviaBotGUI.QuestionTimeout:SetAutoFocus(false);
	TriviaBotGUI.QuestionTimeout:SetNumeric(true);
	TriviaBotGUI.QuestionTimeout:SetJustifyH("CENTER");
	TriviaBotGUI.QuestionTimeout:SetTextInsets(0,6,0,0);
	TriviaBotGUI.QuestionTimeout:SetPoint("TOPLEFT", TriviaBotGUI.QuestionInterval, "BOTTOMLEFT", 0, editboxspace);
	TriviaBotGUI.QuestionTimeout:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
	TriviaBotGUI.QuestionTimeout:SetScript("OnTextChanged", TriviaBotGUI.QuestionTimeout.Update);
	TriviaBotGUI.QuestionTimeout:SetScript("OnEscapePressed", TriviaBotGUI.QuestionTimeout.OnEscapePressed);
	TriviaBotGUI.QuestionTimeout:SetScript("OnEditFocusLost", TriviaBotGUI.QuestionTimeout.OnEditFocusLost);
	TriviaBotGUI.QuestionTimeout:SetScript("OnEditFocusGained", TriviaBotGUI.EditBox_Highlight);
	-- Question Timeout TextBox Label
	TriviaBotGUI.QuestionTimeout.Label = TriviaBotGUI.QuestionTimeout:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.QuestionTimeout.Label:ClearAllPoints();
	TriviaBotGUI.QuestionTimeout.Label:SetText(L.TB_GUI_QUESTIONTIMEOUT);
	TriviaBotGUI.QuestionTimeout.Label:SetPoint("RIGHT", TriviaBotGUI.QuestionTimeout, "LEFT", -15, 0);

	-- Timeout Warning TextBox
	TriviaBotGUI.TimeoutWarning = CreateFrame("EditBox", nil, TriviaBotGUI, "InputBoxTemplate");
	TriviaBotGUI.TimeoutWarning.OnEditFocusLost = function(self)
		local value = tonumber(self:GetText());
		if (not value or value < TB_Min_Timeout_Warning or value > TB_Max_Timeout_Warning or value*2 > TriviaBot_Config['Question_Timeout']) then
			TriviaBot.PrintError(string.format(L.TB_ERROR_FMTTIMEOUTWARN,TB_Min_Timeout_Warning,TB_Max_Timeout_Warning));
			self:SetText(TriviaBot_Config['Timeout_Warning']);
		end
	end
	TriviaBotGUI.TimeoutWarning.OnEscapePressed = function(self)
		self:SetText(TriviaBot_Config['Timeout_Warning']);
		self:ClearFocus();
	end
	TriviaBotGUI.TimeoutWarning.Update = function(self)
		if(self:GetText() == "") then
			-- Field is blanked out so we do nothing
			return;
		end
		local num = self:GetNumber();
		if (num >= TB_Min_Timeout_Warning and num <= TB_Max_Timeout_Warning) then
			if (TriviaBot_Config['Question_Timeout'] < num*2) then
				TriviaBot_Config['Timeout_Warning'] = math.floor(TriviaBot_Config['Question_Timeout']/2);
				TriviaBotGUI.TimeoutWarning:SetText(TriviaBot_Config['Timeout_Warning']);
			else
				TriviaBot_Config['Timeout_Warning'] = num;
			end
		end
	end
	TriviaBotGUI.TimeoutWarning:ClearAllPoints();
	TriviaBotGUI.TimeoutWarning:SetWidth(40);
	TriviaBotGUI.TimeoutWarning:SetHeight(36);
	TriviaBotGUI.TimeoutWarning:SetMaxLetters(3);
	TriviaBotGUI.TimeoutWarning:SetAutoFocus(false);
	TriviaBotGUI.TimeoutWarning:SetNumeric(true);
	TriviaBotGUI.TimeoutWarning:SetJustifyH("CENTER");
	TriviaBotGUI.TimeoutWarning:SetTextInsets(0,6,0,0);
	TriviaBotGUI.TimeoutWarning:SetPoint("TOPLEFT", TriviaBotGUI.QuestionTimeout, "BOTTOMLEFT", 0, editboxspace);
	TriviaBotGUI.TimeoutWarning:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
	TriviaBotGUI.TimeoutWarning:SetScript("OnTextChanged", TriviaBotGUI.TimeoutWarning.Update);
	TriviaBotGUI.TimeoutWarning:SetScript("OnEscapePressed", TriviaBotGUI.TimeoutWarning.OnEscapePressed);
	TriviaBotGUI.TimeoutWarning:SetScript("OnEditFocusLost", TriviaBotGUI.TimeoutWarning.OnEditFocusLost);
	TriviaBotGUI.TimeoutWarning:SetScript("OnEditFocusGained", TriviaBotGUI.EditBox_Highlight);
	-- Timeout Warning TextBox Label
	TriviaBotGUI.TimeoutWarning.Label = TriviaBotGUI.TimeoutWarning:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.TimeoutWarning.Label:ClearAllPoints();
	TriviaBotGUI.TimeoutWarning.Label:SetText(L.TB_GUI_TIMEOUTWARNING);
	TriviaBotGUI.TimeoutWarning.Label:SetPoint("RIGHT", TriviaBotGUI.TimeoutWarning, "LEFT", -15, 0);

	-- Top Score Count TextBox
	TriviaBotGUI.TopScoreCount = CreateFrame("EditBox", nil, TriviaBotGUI, "InputBoxTemplate");
	TriviaBotGUI.TopScoreCount.OnEditFocusLost = function(self)
		local value = tonumber(self:GetText());
		if (not value or value < TB_Min_Topscore or value > TB_Max_Topscore) then
			TriviaBot.PrintError(string.format(L.TB_ERROR_FMTTOPSCORECOUNT,TB_Min_Topscore,TB_Max_Topscore));
			self:SetText(TriviaBot_Config['Top_Score_Count']);
		end
	end
	TriviaBotGUI.TopScoreCount.OnEscapePressed = function(self)
		self:SetText(TriviaBot_Config['Top_Score_Count']);
		self:ClearFocus();
	end
	TriviaBotGUI.TopScoreCount.Update = function(self)
		if(self:GetText() == "") then
			-- Field is blanked out so we do nothing
			return;
		end
		local num = self:GetNumber();
		if (num >= TB_Min_Topscore and num <= TB_Max_Topscore) then
			TriviaBot_Config['Top_Score_Count'] = num;
		end
	end
	TriviaBotGUI.TopScoreCount:ClearAllPoints();
	TriviaBotGUI.TopScoreCount:SetWidth(40);
	TriviaBotGUI.TopScoreCount:SetHeight(36);
	TriviaBotGUI.TopScoreCount:SetMaxLetters(3);
	TriviaBotGUI.TopScoreCount:SetAutoFocus(false);
	TriviaBotGUI.TopScoreCount:SetNumeric(true);
	TriviaBotGUI.TopScoreCount:SetJustifyH("CENTER");
	TriviaBotGUI.TopScoreCount:SetTextInsets(0,6,0,0);
	TriviaBotGUI.TopScoreCount:SetPoint("TOPLEFT", TriviaBotGUI.TimeoutWarning, "BOTTOMLEFT", 0, editboxspace);
	TriviaBotGUI.TopScoreCount:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
	TriviaBotGUI.TopScoreCount:SetScript("OnTextChanged", TriviaBotGUI.TopScoreCount.Update);
	TriviaBotGUI.TopScoreCount:SetScript("OnEscapePressed", TriviaBotGUI.TopScoreCount.OnEscapePressed);
	TriviaBotGUI.TopScoreCount:SetScript("OnEditFocusLost", TriviaBotGUI.TopScoreCount.OnEditFocusLost);
	TriviaBotGUI.TopScoreCount:SetScript("OnEditFocusGained", TriviaBotGUI.EditBox_Highlight);
	-- Top Score Count TextBox Label
	TriviaBotGUI.TopScoreCount.Label = TriviaBotGUI.TopScoreCount:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.TopScoreCount.Label:ClearAllPoints();
	TriviaBotGUI.TopScoreCount.Label:SetText(L.TB_GUI_TOPSCORECOUNT);
	TriviaBotGUI.TopScoreCount.Label:SetPoint("RIGHT", TriviaBotGUI.TopScoreCount, "LEFT", -15, 0);

	-- Top Score Interval TextBox
	TriviaBotGUI.TopScoreInterval = CreateFrame("EditBox", nil, TriviaBotGUI, "InputBoxTemplate");
	TriviaBotGUI.TopScoreInterval.OnEditFocusLost = function(self)
		local value = tonumber(self:GetText());
		if (not value or value < TB_Min_Topscore_Interval or value > TB_Max_Topscore_Interval) then
			TriviaBot.PrintError(string.format(L.TB_ERROR_FMTTOPSCOREINTERVAL,TB_Min_Topscore_Interval,TB_Max_Topscore_Interval));
			self:SetText(TriviaBot_Config['Top_Score_Interval']);
		end
	end
	TriviaBotGUI.TopScoreInterval.OnEscapePressed = function(self)
		self:SetText(TriviaBot_Config['Top_Score_Interval']);
		self:ClearFocus();
	end
	TriviaBotGUI.TopScoreInterval.Update = function(self)
		if(self:GetText() == "") then
			-- Field is blanked out so we do nothing
			return;
		end
		local num = self:GetNumber();
		if (num >= TB_Min_Topscore_Interval and num <= TB_Max_Topscore_Interval) then
			TriviaBot_Config['Top_Score_Interval'] = num;
		end
	end
	TriviaBotGUI.TopScoreInterval:ClearAllPoints();
	TriviaBotGUI.TopScoreInterval:SetWidth(40);
	TriviaBotGUI.TopScoreInterval:SetHeight(36);
	TriviaBotGUI.TopScoreInterval:SetMaxLetters(3);
	TriviaBotGUI.TopScoreInterval:SetAutoFocus(false);
	TriviaBotGUI.TopScoreInterval:SetNumeric(true);
	TriviaBotGUI.TopScoreInterval:SetJustifyH("CENTER");
	TriviaBotGUI.TopScoreInterval:SetTextInsets(0,6,0,0);
	TriviaBotGUI.TopScoreInterval:SetPoint("TOPLEFT", TriviaBotGUI.TopScoreCount, "BOTTOMLEFT", 0, editboxspace);
	TriviaBotGUI.TopScoreInterval:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
	TriviaBotGUI.TopScoreInterval:SetScript("OnTextChanged", TriviaBotGUI.TopScoreInterval.Update);
	TriviaBotGUI.TopScoreInterval:SetScript("OnEscapePressed", TriviaBotGUI.TopScoreInterval.OnEscapePressed);
	TriviaBotGUI.TopScoreInterval:SetScript("OnEditFocusLost", TriviaBotGUI.TopScoreInterval.OnEditFocusLost);
	TriviaBotGUI.TopScoreInterval:SetScript("OnEditFocusGained", TriviaBotGUI.EditBox_Highlight);
	-- Top Score Interval TextBox Label
	TriviaBotGUI.TopScoreInterval.Label = TriviaBotGUI.TopScoreInterval:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.TopScoreInterval.Label:ClearAllPoints();
	TriviaBotGUI.TopScoreInterval.Label:SetText(L.TB_GUI_TOPSCOREINTERVAL);
	TriviaBotGUI.TopScoreInterval.Label:SetPoint("RIGHT", TriviaBotGUI.TopScoreInterval, "LEFT", -15, 0);

	-- Answers Shown TextBox
	TriviaBotGUI.AnswersShown = CreateFrame("EditBox", nil, TriviaBotGUI, "InputBoxTemplate");
	TriviaBotGUI.AnswersShown.OnEditFocusLost = function(self)
		local value = tonumber(self:GetText());
		if (not value or value < 0) then
			TriviaBot.PrintError(L.TB_ERROR_ANSWERSHOWN);
			self:SetText(TriviaBot_Config['Answers_Shown']);
		end
	end
	TriviaBotGUI.AnswersShown.OnEscapePressed = function(self)
		self:SetText(TriviaBot_Config['Answers_Shown']);
		self:ClearFocus();
	end
	TriviaBotGUI.AnswersShown.Update = function(self)
		if(self:GetText() == "") then
			-- Field is blanked out so we do nothing
			return;
		end
		local num = self:GetNumber();
		if (num >= 0) then
			TriviaBot_Config['Answers_Shown'] = num;
		end
	end
	TriviaBotGUI.AnswersShown:ClearAllPoints();
	TriviaBotGUI.AnswersShown:SetWidth(40);
	TriviaBotGUI.AnswersShown:SetHeight(36);
	TriviaBotGUI.AnswersShown:SetMaxLetters(3);
	TriviaBotGUI.AnswersShown:SetAutoFocus(false);
	TriviaBotGUI.AnswersShown:SetNumeric(true);
	TriviaBotGUI.AnswersShown:SetJustifyH("CENTER");
	TriviaBotGUI.AnswersShown:SetTextInsets(0,6,0,0);
	TriviaBotGUI.AnswersShown:SetPoint("TOPLEFT", TriviaBotGUI.TopScoreInterval, "BOTTOMLEFT", 0, editboxspace);
	TriviaBotGUI.AnswersShown:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
	TriviaBotGUI.AnswersShown:SetScript("OnTextChanged", TriviaBotGUI.AnswersShown.Update);
	TriviaBotGUI.AnswersShown:SetScript("OnEscapePressed", TriviaBotGUI.AnswersShown.OnEscapePressed);
	TriviaBotGUI.AnswersShown:SetScript("OnEditFocusLost", TriviaBotGUI.AnswersShown.OnEditFocusLost);
	TriviaBotGUI.AnswersShown:SetScript("OnEditFocusGained", TriviaBotGUI.EditBox_Highlight);
	TriviaBotGUI.AnswersShown.toolTip = L.TB_GUI_ANSWERSSHOWN_TIP;
	TriviaBotGUI.AnswersShown:SetScript("OnEnter", TriviaBotGUI.OnMouseEnter);
	TriviaBotGUI.AnswersShown:SetScript("OnLeave", GameTooltip_Hide);
	-- Answers Shown TextBox Label
	TriviaBotGUI.AnswersShown.Label = TriviaBotGUI.AnswersShown:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.AnswersShown.Label:ClearAllPoints();
	TriviaBotGUI.AnswersShown.Label:SetText(L.TB_GUI_ANSWERSSHOWN);
	TriviaBotGUI.AnswersShown.Label:SetPoint("RIGHT", TriviaBotGUI.AnswersShown, "LEFT", -15, 0);

	-- Show Answers Checkbox
	TriviaBotGUI.ShowAnswersCheckBox = CreateFrame("CheckButton", nil, TriviaBotGUI, "OptionsCheckButtonTemplate");
	TriviaBotGUI.ShowAnswersCheckBox.OnClick = function(self)
		TriviaBot_Config['Show_Answers'] = self:GetChecked();
	end
	TriviaBotGUI.ShowAnswersCheckBox:ClearAllPoints();
	TriviaBotGUI.ShowAnswersCheckBox:SetPoint("LEFT", TriviaBotGUI.RoundSize, "RIGHT", 5, 0);
	TriviaBotGUI.ShowAnswersCheckBox:SetScript("OnClick", TriviaBotGUI.ShowAnswersCheckBox.OnClick);
	-- Show Answers Checkbox Label
	TriviaBotGUI.ShowAnswersCheckBox.Label = TriviaBotGUI.ShowAnswersCheckBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.ShowAnswersCheckBox.Label:ClearAllPoints();
	TriviaBotGUI.ShowAnswersCheckBox.Label:SetText(L.TB_GUI_SHOWANSWERS);
	TriviaBotGUI.ShowAnswersCheckBox.Label:SetPoint("LEFT", TriviaBotGUI.ShowAnswersCheckBox, "RIGHT", 5, 0);

	-- Show Reports Checkbox
	TriviaBotGUI.ShowReportsCheckBox = CreateFrame("CheckButton", nil, TriviaBotGUI, "OptionsCheckButtonTemplate");
	TriviaBotGUI.ShowReportsCheckBox.OnClick = function(self)
		TriviaBot_Config['Show_Reports'] = self:GetChecked();
	end
	TriviaBotGUI.ShowReportsCheckBox:ClearAllPoints();
	TriviaBotGUI.ShowReportsCheckBox:SetPoint("TOPLEFT", TriviaBotGUI.ShowAnswersCheckBox, "BOTTOMLEFT", 0, checkboxspace);
	TriviaBotGUI.ShowReportsCheckBox:SetScript("OnClick", TriviaBotGUI.ShowReportsCheckBox.OnClick);
	-- Show Reports Checkbox Label
	TriviaBotGUI.ShowReportsCheckBox.Label = TriviaBotGUI.ShowReportsCheckBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.ShowReportsCheckBox.Label:ClearAllPoints();
	TriviaBotGUI.ShowReportsCheckBox.Label:SetText(L.TB_GUI_SHOWREPORTS);
	TriviaBotGUI.ShowReportsCheckBox.Label:SetPoint("LEFT", TriviaBotGUI.ShowReportsCheckBox, "RIGHT", 5, 0);

	-- Show Hints Checkbox
	TriviaBotGUI.ShowHintsCheckBox = CreateFrame("CheckButton", nil, TriviaBotGUI, "OptionsCheckButtonTemplate");
	TriviaBotGUI.ShowHintsCheckBox.OnClick = function(self)
		TriviaBot_Config['Show_Hints'] = self:GetChecked();
	end
	TriviaBotGUI.ShowHintsCheckBox:ClearAllPoints();
	TriviaBotGUI.ShowHintsCheckBox:SetPoint("TOPLEFT", TriviaBotGUI.ShowReportsCheckBox, "BOTTOMLEFT", 0, checkboxspace);
	TriviaBotGUI.ShowHintsCheckBox:SetScript("OnClick", TriviaBotGUI.ShowHintsCheckBox.OnClick);
	-- Show Hints Checkbox Label
	TriviaBotGUI.ShowHintsCheckBox.Label = TriviaBotGUI.ShowHintsCheckBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.ShowHintsCheckBox.Label:ClearAllPoints();
	TriviaBotGUI.ShowHintsCheckBox.Label:SetText(L.TB_GUI_SHOWHINTS);
	TriviaBotGUI.ShowHintsCheckBox.Label:SetPoint("LEFT", TriviaBotGUI.ShowHintsCheckBox, "RIGHT", 5, 0);

	-- Show Whispers Checkbox
	TriviaBotGUI.ShowWhispersCheckBox = CreateFrame("CheckButton", nil, TriviaBotGUI, "OptionsCheckButtonTemplate");
	TriviaBotGUI.ShowWhispersCheckBox.OnClick = function(self)
		TriviaBot_Config['Show_Whispers'] = self:GetChecked();
		if not (TriviaBot_Config['Show_Whispers']) then
			ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER",TriviaBot.MessageFilter)
			ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM",TriviaBot.MessageFilter)
		else
			ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER_INFORM",TriviaBot.MessageFilter)
			ChatFrame_RemoveMessageEventFilter("CHAT_MSG_WHISPER",TriviaBot.MessageFilter)
		end
	end
	TriviaBotGUI.ShowWhispersCheckBox:ClearAllPoints();
	TriviaBotGUI.ShowWhispersCheckBox:SetPoint("TOPLEFT", TriviaBotGUI.ShowHintsCheckBox, "BOTTOMLEFT", 0, checkboxspace);
	TriviaBotGUI.ShowWhispersCheckBox:SetScript("OnClick", TriviaBotGUI.ShowWhispersCheckBox.OnClick);
	-- Show Whispers Checkbox Label
	TriviaBotGUI.ShowWhispersCheckBox.Label = TriviaBotGUI.ShowWhispersCheckBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.ShowWhispersCheckBox.Label:ClearAllPoints();
	TriviaBotGUI.ShowWhispersCheckBox.Label:SetText(L.TB_GUI_SHOWWHISPERS);
	TriviaBotGUI.ShowWhispersCheckBox.Label:SetPoint("LEFT", TriviaBotGUI.ShowWhispersCheckBox, "RIGHT", 5, 0);

	-- Report Win Streak Checkbox
	TriviaBotGUI.ReportWinStreakCheckBox = CreateFrame("CheckButton", nil, TriviaBotGUI, "OptionsCheckButtonTemplate");
	TriviaBotGUI.ReportWinStreakCheckBox.OnClick = function(self)
		TriviaBot_Config['Report_Win_Streak'] = self:GetChecked();
	end
	TriviaBotGUI.ReportWinStreakCheckBox:ClearAllPoints();
	TriviaBotGUI.ReportWinStreakCheckBox:SetPoint("TOPLEFT", TriviaBotGUI.ShowWhispersCheckBox, "BOTTOMLEFT", 0, checkboxspace);
	TriviaBotGUI.ReportWinStreakCheckBox:SetScript("OnClick", TriviaBotGUI.ReportWinStreakCheckBox.OnClick);
	-- Report Win Streak Checkbox Label
	TriviaBotGUI.ReportWinStreakCheckBox.Label = TriviaBotGUI.ReportWinStreakCheckBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.ReportWinStreakCheckBox.Label:ClearAllPoints();
	TriviaBotGUI.ReportWinStreakCheckBox.Label:SetText(L.TB_GUI_REPORTWINSTREAK);
	TriviaBotGUI.ReportWinStreakCheckBox.Label:SetPoint("LEFT", TriviaBotGUI.ReportWinStreakCheckBox, "RIGHT", 5, 0);

	-- Report Personal Checkbox
	TriviaBotGUI.ReportPersonalCheckBox = CreateFrame("CheckButton", nil, TriviaBotGUI, "OptionsCheckButtonTemplate");
	TriviaBotGUI.ReportPersonalCheckBox.OnClick = function(self)
		TriviaBot_Config['Report_Personal'] = self:GetChecked();
	end
	TriviaBotGUI.ReportPersonalCheckBox:ClearAllPoints();
	TriviaBotGUI.ReportPersonalCheckBox:SetPoint("TOPLEFT", TriviaBotGUI.ReportWinStreakCheckBox, "BOTTOMLEFT", 0, checkboxspace);
	TriviaBotGUI.ReportPersonalCheckBox:SetScript("OnClick", TriviaBotGUI.ReportPersonalCheckBox.OnClick);
	-- Report Personal Checkbox Label
	TriviaBotGUI.ReportPersonalCheckBox.Label = TriviaBotGUI.ReportPersonalCheckBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.ReportPersonalCheckBox.Label:ClearAllPoints();
	TriviaBotGUI.ReportPersonalCheckBox.Label:SetText(L.TB_GUI_REPORTPERSONAL);
	TriviaBotGUI.ReportPersonalCheckBox.Label:SetPoint("LEFT", TriviaBotGUI.ReportPersonalCheckBox, "RIGHT", 5, 0);

	-- Point Mode Checkbox
	TriviaBotGUI.PointModeCheckBox = CreateFrame("CheckButton", nil, TriviaBotGUI, "OptionsCheckButtonTemplate");
	TriviaBotGUI.PointModeCheckBox.OnClick = function(self)
		TriviaBot_Config['Point_Mode'] = self:GetChecked();
	end
	TriviaBotGUI.PointModeCheckBox:ClearAllPoints();
	TriviaBotGUI.PointModeCheckBox:SetPoint("TOPLEFT", TriviaBotGUI.ReportPersonalCheckBox, "BOTTOMLEFT", 0, checkboxspace);
	TriviaBotGUI.PointModeCheckBox:SetScript("OnClick", TriviaBotGUI.PointModeCheckBox.OnClick);
	-- Point Mode Checkbox Label
	TriviaBotGUI.PointModeCheckBox.Label = TriviaBotGUI.PointModeCheckBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.PointModeCheckBox.Label:ClearAllPoints();
	TriviaBotGUI.PointModeCheckBox.Label:SetText(L.TB_GUI_POINTMODE);
	TriviaBotGUI.PointModeCheckBox.Label:SetPoint("LEFT", TriviaBotGUI.PointModeCheckBox, "RIGHT", 5, 0);

	-- Short Channel Tag Checkbox
	TriviaBotGUI.ShortChannelTagCheckBox = CreateFrame("CheckButton", nil, TriviaBotGUI, "OptionsCheckButtonTemplate");
	TriviaBotGUI.ShortChannelTagCheckBox.OnClick = function(self)
		TriviaBot_Config['Short_Tag'] = self:GetChecked();
		if (self:GetChecked()) then
			TB_Channel_Prefix = TB_Short_Prefix;
		else
			TB_Channel_Prefix = TB_Long_Prefix;
		end
	end
	TriviaBotGUI.ShortChannelTagCheckBox:ClearAllPoints();
	TriviaBotGUI.ShortChannelTagCheckBox:SetPoint("TOPLEFT", TriviaBotGUI.PointModeCheckBox, "BOTTOMLEFT", 0, checkboxspace);
	TriviaBotGUI.ShortChannelTagCheckBox:SetScript("OnClick", TriviaBotGUI.ShortChannelTagCheckBox.OnClick);
	-- Short Channel Tag Checkbox Label
	TriviaBotGUI.ShortChannelTagCheckBox.Label = TriviaBotGUI.ShortChannelTagCheckBox:CreateFontString(nil, "ARTWORK", "GameFontNormal");
	TriviaBotGUI.ShortChannelTagCheckBox.Label:ClearAllPoints();
	TriviaBotGUI.ShortChannelTagCheckBox.Label:SetText(L.TB_GUI_SHORTCHANNEL);
	TriviaBotGUI.ShortChannelTagCheckBox.Label:SetPoint("LEFT", TriviaBotGUI.ShortChannelTagCheckBox, "RIGHT", 5, 0);

	-- Start/Stop Button
	TriviaBotGUI.StartStopButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
	TriviaBotGUI.StartStopButton:ClearAllPoints();
	TriviaBotGUI.StartStopButton:SetWidth(140);
	TriviaBotGUI.StartStopButton:SetText(L.TB_GUI_STARTTRIVIA);
	TriviaBotGUI.StartStopButton:SetPoint("BOTTOMRIGHT", TriviaBotGUI, "BOTTOM", -5, 45);
	TriviaBotGUI.StartStopButton:SetScript("OnClick", TriviaBot.StartStopToggle);

	-- Skip Button
	TriviaBotGUI.SkipButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
	TriviaBotGUI.SkipButton:ClearAllPoints();
	TriviaBotGUI.SkipButton:SetWidth(140);
	TriviaBotGUI.SkipButton:SetText(L.TB_GUI_SKIPQUESTION);
	TriviaBotGUI.SkipButton:SetPoint("TOPRIGHT", TriviaBotGUI.StartStopButton, "BOTTOMRIGHT", 0, -5);
	TriviaBotGUI.SkipButton:SetScript("OnClick", TriviaBot.SkipQuestion);
	TriviaBotGUI.SkipButton:Disable();

	-- Game Score Button
	TriviaBotGUI.GameScoresButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
	TriviaBotGUI.GameScoresButton:ClearAllPoints();
	TriviaBotGUI.GameScoresButton:SetWidth(140);
	TriviaBotGUI.GameScoresButton:SetText(L.TB_GUI_GAMESCORES);
	TriviaBotGUI.GameScoresButton:SetPoint("BOTTOMLEFT", TriviaBotGUI, "BOTTOM", 5, 45);
	TriviaBotGUI.GameScoresButton:SetScript("OnClick", function() TriviaBot.Report("gamereport"); end);

	-- Question Maker Button
	if IsAddOnLoaded("TriviaBot_QuestionMaker") then
		TriviaBotGUI.QuestionMakerButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
		TriviaBotGUI.QuestionMakerButton:ClearAllPoints();
		TriviaBotGUI.QuestionMakerButton:SetWidth(140);
		TriviaBotGUI.QuestionMakerButton:SetText(L.TB_GUI_QUESTIONMAKER);
		TriviaBotGUI.QuestionMakerButton:SetPoint("BOTTOMRIGHT", TriviaBotGUI.GameScoresButton, "TOPRIGHT", 0, 5);
		TriviaBotGUI.QuestionMakerButton:SetScript("OnClick", TriviaBot.QuestionMakerToggle)

		TriviaBotGUI.ReloadQuestionsButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
		TriviaBotGUI.ReloadQuestionsButton:ClearAllPoints();
		TriviaBotGUI.ReloadQuestionsButton:SetWidth(140);
		TriviaBotGUI.ReloadQuestionsButton:SetText(L.TB_GUI_RELOAD);
		TriviaBotGUI.ReloadQuestionsButton:SetPoint("BOTTOMRIGHT", TriviaBotGUI.StartStopButton, "TOPRIGHT", 0, 5);
		TriviaBotGUI.ReloadQuestionsButton:SetScript("OnClick", TriviaBot.ReloadQuestionsOnClick)
		TriviaBotGUI.ReloadQuestionsButton:Hide()
	end

	-- All-Time Score Button
	TriviaBotGUI.AllTimeScoresButton = CreateFrame("Button", nil, TriviaBotGUI, "OptionsButtonTemplate");
	TriviaBotGUI.AllTimeScoresButton:ClearAllPoints();
	TriviaBotGUI.AllTimeScoresButton:SetWidth(140);
	TriviaBotGUI.AllTimeScoresButton:SetText(L.TB_GUI_ALLTIMESCORES);
	TriviaBotGUI.AllTimeScoresButton:SetPoint("TOPLEFT", TriviaBotGUI.GameScoresButton, "BOTTOMLEFT", 0, -5);
	TriviaBotGUI.AllTimeScoresButton:SetScript("OnClick", function() TriviaBot.Report("alltimereport"); end);

	TriviaBotGUI.ClearFocus = function()
		TriviaBotGUI.Channel:ClearFocus();
		TriviaBotGUI.RoundSize:ClearFocus();
		TriviaBotGUI.QuestionInterval:ClearFocus();
		TriviaBotGUI.QuestionTimeout:ClearFocus();
		TriviaBotGUI.TimeoutWarning:ClearFocus();
		TriviaBotGUI.TopScoreCount:ClearFocus();
		TriviaBotGUI.TopScoreInterval:ClearFocus();
		TriviaBotGUI.AnswersShown:ClearFocus();
	end
	TriviaBotGUI:SetScript("OnMouseDown", TriviaBotGUI.ClearFocus);
	TriviaBotGUI.StartStopToggle = function()
		if (TB_Running) then
			TriviaBotGUI.StartStopButton:SetText(L.TB_GUI_STOPTRIVIA);
			Lib_UIDropDownMenu_DisableDropDown(TriviaBotGUI.ChatType);
			TriviaBotGUI.RoundSize:EnableMouse(false);
			TriviaBotGUI.RoundSize:ClearFocus();
			TriviaBotGUI.RoundSize:SetTextColor(1,0,0);
			TriviaBotGUI.PointModeCheckBox:Disable();
			if (TriviaBot_Config['Chat_Type'] == "channel") then
				TriviaBotGUI.Channel:EnableMouse(false);
				TriviaBotGUI.Channel:ClearFocus();
				TriviaBotGUI.Channel:SetTextColor(1,0,0);
				TriviaBotGUI.ChannelButton:Disable();
			end
		else
			TriviaBotGUI.StartStopButton:SetText(L.TB_GUI_STARTTRIVIA);
			TriviaBotGUI.SkipButton:Disable();
			Lib_UIDropDownMenu_EnableDropDown(TriviaBotGUI.ChatType);
			TriviaBotGUI.RoundSize:EnableMouse(true);
			TriviaBotGUI.RoundSize:SetTextColor(1,1,1);
			TriviaBotGUI.PointModeCheckBox:Enable();
			if (TriviaBot_Config['Chat_Type'] == "channel") then
				TriviaBotGUI.Channel:EnableMouse(true);
				TriviaBotGUI.Channel:SetTextColor(1,1,1);
				TriviaBotGUI.ChannelButton:Enable();
			end
		end
	end
	TriviaBotGUI.Update = function()
		-- Display Version
		TriviaBotGUI.HeaderLabel:SetText("TriviaBot " .. TB_VERSION);
		-- Load Channel
		TriviaBotGUI.Channel:SetText(TriviaBot_Config['Channel']);
		-- Load Round Size
		TriviaBotGUI.RoundSize:SetText(TriviaBot_Config['Round_Size']);
		-- Load Question Interval
		TriviaBotGUI.QuestionInterval:SetText(TriviaBot_Config['Question_Interval']);
		-- Load Question Timeout
		TriviaBotGUI.QuestionTimeout:SetText(TriviaBot_Config['Question_Timeout']);
		-- Load Timeout Warning
		TriviaBotGUI.TimeoutWarning:SetText(TriviaBot_Config['Timeout_Warning']);
		-- Load Top Score Count
		TriviaBotGUI.TopScoreCount:SetText(TriviaBot_Config['Top_Score_Count']);
		-- Load Top Score Interval
		TriviaBotGUI.TopScoreInterval:SetText(TriviaBot_Config['Top_Score_Interval']);
		-- Load Answers Shown
		TriviaBotGUI.AnswersShown:SetText(TriviaBot_Config['Answers_Shown']);
		-- Set Show Answers state
		TriviaBotGUI.ShowAnswersCheckBox:SetChecked(TriviaBot_Config['Show_Answers']);
		-- Set Show Reports state
		TriviaBotGUI.ShowReportsCheckBox:SetChecked(TriviaBot_Config['Show_Reports']);
		-- Set Show Hints state
		TriviaBotGUI.ShowHintsCheckBox:SetChecked(TriviaBot_Config['Show_Hints']);
		-- Set Show Whispers state
		TriviaBotGUI.ShowWhispersCheckBox:SetChecked(TriviaBot_Config['Show_Whispers']);
		-- Set Report Win Streak state
		TriviaBotGUI.ReportWinStreakCheckBox:SetChecked(TriviaBot_Config['Report_Win_Streak']);
		-- Set Report Personal state
		TriviaBotGUI.ReportPersonalCheckBox:SetChecked(TriviaBot_Config['Report_Personal']);
		-- Set Point Mode state
		TriviaBotGUI.PointModeCheckBox:SetChecked(TriviaBot_Config['Point_Mode']);
		-- Short Channel Tag state
		TriviaBotGUI.ShortChannelTagCheckBox:SetChecked(TriviaBot_Config['Short_Tag']);
		if (TriviaBot_Config['Short_Tag']) then
			TB_Channel_Prefix = TB_Short_Prefix;
		end
		-- Make sure QuestionList drop-down menu is initalized
		TriviaBotGUI.QuestionList.Initialize();
		-- Make sure CategoryList drop-down menu is initalized
		TriviaBotGUI.CategoryList.Initialize();
		-- Make sure ChatType drop-down menu is initalized
		TriviaBotGUI.ChatType.Initialize();
		-- Disable custom channel stuff
		if (TriviaBot_Config['Chat_Type'] ~= "channel") then
			TriviaBotGUI.Channel:EnableMouse(false);
			TriviaBotGUI.Channel:SetTextColor(1,0,0);
			TriviaBotGUI.ChannelButton:Disable();
		else
			TriviaBotGUI.Channel:EnableMouse(true);
			TriviaBotGUI.Channel:SetTextColor(1,1,1);
			TriviaBotGUI.ChannelButton:Enable();
		end
	end
end
_G[addonName] = API
