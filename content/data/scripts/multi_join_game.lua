local rocket_utils = require("rocket_util")
local topics = require("ui_topics")
local class = require("class")
local async_util = require("async_util")
local utils = require("utils")
local dialogs = require("dialogs")

local JoinGameController = class(AbstractBriefingController)

function JoinGameController:init()
	self.gamesList = {} -- list of games names + ids only
	self.games = {} -- list of actual games
end

function JoinGameController:initialize(document)
	
	self.document = document
	
	---Load background choice
	self.document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)
	
	---Load the desired font size from the save file
	self.document:GetElementById("main_background"):SetClass(("p1-" .. ScpuiSystem:getFontSize()), true)
	
	self.games_list_el = self.document:GetElementById("games_list_ul")
	self.common_text_el = self.document:GetElementById("common_text")
	
	ScpuiSystem:ClearEntries(self.games_list_el)
	
	if not ScpuiSystem.MultiJoinReady then
		ui.MultiJoinGame.initMultiJoin()
	end
	
	ScpuiSystem.MultiJoinReady = true
	
	self:updateLists()
	
	--topics.multijoingame.initialize:send(self)

end

function JoinGameController:CreatePlayerEntry(entry)
	
	local li_el = self.document:CreateElement("li")

	li_el.inner_rml = "<span>" .. entry.Status .. entry.Server .. entry.Mission .. "</span>"
	li_el.id = entry.Server .. entry.InternalID
	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:SelectGame(entry)
	end)
	li_el:AddEventListener("dblclick", function(_, _, _)
		self:SelectGame(entry)
	end)
	entry.key = li_el.id
	
	table.insert(self.games, entry)

	return li_el
end

function JoinGameController:SelectGame(game)
	ui.MultiJoinGame.ActiveGames[game.Index]:setSelected()
end

function JoinGameController:addGame(game)
	self.games_list_el:AppendChild(self:CreatePlayerEntry(game))
	table.insert(self.gamesList, game.InternalID)
end

function JoinGameController:removeGame(idx)
	local game_idx = self:getGameIndexByID(self.gamesList[idx])
	if game_idx > 0 then
		local el = self.document:GetElementById(self.games[game_idx].key)
		self.games_list_el:RemoveChild(el)
		table.remove(self.games, game_idx)
	end
	table.remove(self.gamesList, idx)
end

function JoinGameController:getGameIndexByID(id)
	for i = 1, #self.games do
		if self.games[i].InternalID == id then
			return i
		end
	end
	return -1
end

function JoinGameController:exit()
	ui.MultiJoinGame.closeMultiJoin()
	ScpuiSystem.MultiJoinReady = false
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PXO"])
	--Go back to mainhall if not in pxo options!
end

function JoinGameController:dialog_response(response)
	local path = self.promptControl
	self.promptControl = nil
	if path == 1 then --MOTD
		--Do nothing!
	elseif path == 2 then --Join Private Channel
		if response and response ~= "" then
			ui.MultiPXO.joinPrivateChannel(response)
		end
	elseif path == 3 then --Show Player Stats
		--Do nothing!
	elseif path == 4 then --Find player
		if response and response ~= "" then
			self:GetPlayerChannel(response)
		end
	elseif path == 5 then --Find player response
		if response == true then
			self:joinChannel(self.foundChannel)
		end
		self.foundChannel = nil
	end
end

function JoinGameController:Show(text, title, input, buttons)
	--Create a simple dialog box with the text and title

	currentDialog = true
	
	local dialog = dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:input(input)
		for i = 1, #buttons do
			dialog:button(buttons[i].b_type, buttons[i].b_text, buttons[i].b_value, buttons[i].b_keypress)
		end
		dialog:escape("")
		dialog:show(self.document.context)
		:continueWith(function(response)
			self:dialog_response(response)
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.document.context)
end

function JoinGameController:join_pressed()
	ui.MultiJoinGame:sendJoinRequest()
end

function JoinGameController:help_pressed()
	--show help overlay
end

function JoinGameController:options_pressed()
	ui.MultiJoinGame:createGame()
end

function JoinGameController:exit_pressed()
	self:exit()
end

function JoinGameController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
       self:exit()
	end
end

function JoinGameController:InputFocusLost()
	--do nothing
end

function JoinGameController:updateLists()
	ui.MultiJoinGame.runNetwork()

	if #ui.MultiJoinGame.ActiveGames == 0 then
		ScpuiSystem:ClearEntries(self.games_list_el)
		self.games_list_el.inner_rml = "[No game servers found]"
		self.cleared = true
	else
		if self.cleared then
			ScpuiSystem:ClearEntries(self.games_list_el)
			self.cleared = nil
		end
		-- check for new games
		for i = 1, #ui.MultiJoinGame.ActiveGames do
			local int_id = ui.MultiJoinGame.ActiveGames[i].Server .. "_" .. i
			if not utils.table.contains(self.gamesList, int_id) then
				local entry = {
					Status = ui.MultiJoinGame.ActiveGames[i].Status,
					Type = ui.MultiJoinGame.ActiveGames[i].Type,
					Speed = ui.MultiJoinGame.ActiveGames[i].Speed,
					Standalone = ui.MultiJoinGame.ActiveGames[i].Standalone,
					Campaign = ui.MultiJoinGame.ActiveGames[i].Campaign,
					Server = ui.MultiJoinGame.ActiveGames[i].Server,
					Mission = ui.MultiJoinGame.ActiveGames[i].Mission,
					Ping = ui.MultiJoinGame.ActiveGames[i].Ping,
					Players = ui.MultiJoinGame.ActiveGames[i].Players,
					InternalID = int_id,
					Index = i
				}
				self:addGame(entry)
			end
		end
		
		-- now check for games that expired
		local games = {}
		
		-- create a simple table to use for comparing
		for i = 1, #ui.MultiJoinGame.ActiveGames do
			table.insert(games, ui.MultiJoinGame.ActiveGames[i].Server .. "_" .. i)
		end
		
		for i = 1, #self.gamesList do
			if not utils.table.contains(games, self.gamesList[i]) then
				self:removeGame(i)
			end
		end
	end
	
	self.document:GetElementById("status_text").inner_rml = ui.MultiJoinGame.StatusText
	
	async.run(function()
        async.await(async_util.wait_for(0.01))
        self:updateLists()
    end, async.OnFrameExecutor)
	
end

return JoinGameController
