local rocket_utils = require("rocket_util")
local topics = require("ui_topics")
local class = require("class")
local async_util = require("async_util")
local utils = require("utils")
local dialogs = require("dialogs")

local JoinGameController = class(AbstractBriefingController)

function JoinGameController:init()

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
	
	ui.MultiStartGame.initMultiStart()
	
	self:updateLists()
	
	--topics.multijoingame.initialize:send(self)

end

function JoinGameController:exit()
	ui.MultiStartGame.closeMultiStart()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MULTI_JOIN_GAME"])
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
	ui.MultiStartGame.setName("Test Name")
	ui.MultiStartGame.setGameType(MULTI_GAME_TYPE_PASSWORD, "1234")
	ui.MultiStartGame.closeMultiStart()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MULTI_HOST_SETUP"])
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
	ui.MultiStartGame.runNetwork()
	
	--self.document:GetElementById("status_text").inner_rml = ui.MultiJoinGame.StatusText
	
	async.run(function()
        async.await(async_util.wait_for(0.01))
        self:updateLists()
    end, async.OnFrameExecutor)
	
end

return JoinGameController
