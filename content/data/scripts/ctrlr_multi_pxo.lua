-----------------------------------
--Controller for the Multi PXO UI
-----------------------------------

local Dialogs = require("lib_dialogs")
local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractMultiController = require("ctrlr_multi_common")

--- This multi controller is merged with the Multi Common Controller
local PXOController = Class(AbstractMultiController)

--- Called by the class constructor
--- @return nil
function PXOController:init()
	self.SubmittedChatValue = "" --- @type string the player's text input
	self.PlayerStats = "" --- @type string the current player stats
	self.SelectedPxoPlayer = nil --- @type scpui_pxo_chat_player the currently selected player
	self.SelectedPxoChannel = nil --- @type scpui_pxo_channel the currently selected channel
	self.FoundChannel = nil --- @type scpui_pxo_channel the channel name found by the player search
	self.Motd = "" --- @type string the current message of the day
	self.ChatInputEl = nil --- @type Element the chat input element
	self.PlayersEl = nil --- @type Element the players list element
	self.ChannelsEl = nil --- @type Element the channels list element
	self.ChatEl = nil --- @type Element the chat window element
	self.BannerEl = nil --- @type Element the banner element
	self.StatusTextEl = nil --- @type Element the status text element
	self.Document = nil --- @type Document the RML document

	self.Subclass = AbstractMultiController.CTRL_PXO
end

--- Called by the RML document
--- @param document Document
function PXOController:initialize(document)
	AbstractMultiController.initialize(self, document)
	ScpuiSystem.data.memory.multiplayer_general.Context = self

	self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.PlayersEl = self.Document:GetElementById("players_list_ul")
	self.ChannelsEl = self.Document:GetElementById("channels_list_ul")
	self.ChatEl = self.Document:GetElementById("chat_window")
	self.BannerEl = self.Document:GetElementById("banner_div")
	self.StatusTextEl = self.Document:GetElementById("status_text")

	self.ChatInputEl = self.Document:GetElementById("chat_input")

	if not ScpuiSystem.data.memory.MultiReady then
		ui.MultiPXO.initPXO()
	end

	ScpuiSystem.data.memory.MultiReady = true

	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
	ui.MultiGeneral.setPlayerState()

	Topics.multipxo.initialize:send(self)

end

--- Called by the RML when the join button is pressed. Joins the selected channel, if any
--- @return nil
function PXOController:join_public_pressed()
	if self.SelectedPxoChannel then
		AbstractMultiController.joinChannel(self, self.SelectedPxoChannel)
	end
end

--- Called by the RML when the join private channel button is pressed. Creates a dialog box to enter the channel name
--- @return nil
function PXOController:join_private_pressed()
	ScpuiSystem.data.memory.multiplayer_general.DialogType = AbstractMultiController.DIALOG_JOIN_PRIVATE

	local text = "Enter the name of the private channel to join"
	local title = "Join Private Channel"
	--- @type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = Dialogs.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Okay", 888290),
		Value = "",
		Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
	}

	AbstractMultiController.showDialog(self, text, title, true, buttons)
end

--- Called by the RML when the web rank button is pressed
--- @return nil
function PXOController:web_rank_pressed()
	ba.warning("Need to setup getting the PXO urls from FSO through the API! Tell Mjn!")
end

--- Called by the RML when the pilot info button is pressed
--- @return nil
function PXOController:pilot_info_pressed()
	if self.SelectedPxoPlayer then
		AbstractMultiController.getPlayerStats(self, self.SelectedPxoPlayer.Name)
	end
end

--- Called by the RML when the find pilot button is pressed. Creates a dialog box to enter the player name
--- @return nil
function PXOController:find_pilot_pressed()
	ScpuiSystem.data.memory.multiplayer_general.DialogType = AbstractMultiController.DIALOG_FIND_PLAYER

	local text = "Enter the name of the player to search for."
	local title = "Search for player"
	--- @type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = Dialogs.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Okay", 888290),
		Value = "",
		Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
	}

	AbstractMultiController.showDialog(self, text, title, true, buttons)
end

--- Get the channel of a player and if found create a dialog box for the player to choose what to do next
--- @param player_name string the name of the player to search for
--- @return nil
function PXOController:getPlayerChannel(player_name)
	local response, channel = ui.MultiPXO.getPlayerChannel(player_name)

	ScpuiSystem.data.memory.multiplayer_general.DialogType = AbstractMultiController.DIALOG_FIND_PLAYER_CHANNEL

	local text = response
	local title = "Search for player"
	--- @type dialog_button[]
	local buttons = {}

	--If we have a channel then offer the option to join
	if channel ~= "" then
		--Create a dummy channel object
		self.FoundChannel = {
			Name = channel,
			NumPlayers = 0,
			NumGames = 0,
			IsCurrent = true
		}
		text = text .. "<br></br>Join channel?"
		buttons[1] = {
			Type = Dialogs.BUTTON_TYPE_POSITIVE,
			Text = ba.XSTR("Yes", 888296),
			Value = true,
			Keypress = string.sub(ba.XSTR("Yes", 888296), 1, 1)
		}
		buttons[2] = {
			Type = Dialogs.BUTTON_TYPE_NEGATIVE,
			Text = ba.XSTR("No", 888298),
			Value = false,
			Keypress = string.sub(ba.XSTR("No", 888298), 1, 1)
		}
	else
		buttons[1] = {
			Type = Dialogs.BUTTON_TYPE_POSITIVE,
			Text = ba.XSTR("Okay", 888290),
			Value = false,
			Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
		}
	end

	AbstractMultiController.showDialog(self, text, title, false, buttons)
end

--- Exit the PXO screen and shutdown multiplayer pxo
--- @return nil
function PXOController:exit()
	ui.MultiPXO.closePXO()
	ScpuiSystem.data.memory.MultiReady = false
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

--- Handle the dialog response
--- @return nil
function PXOController:dialogResponse()
	local path = ScpuiSystem.data.memory.multiplayer_general.DialogType
	ScpuiSystem.data.memory.multiplayer_general.DialogType = nil

	local response = ScpuiSystem.data.memory.multiplayer_general.DialogResponse
	ScpuiSystem.data.memory.multiplayer_general.DialogResponse = nil

	if path == AbstractMultiController.DIALOG_MOTD then --MOTD
		--Do nothing!
	elseif path == AbstractMultiController.DIALOG_JOIN_PRIVATE then --Join Private Channel
		if response and response ~= "" then
			ui.MultiPXO.joinPrivateChannel(response)
		end
	elseif path == AbstractMultiController.DIALOG_PLAYER_STATS then --Show Player Stats
		--Do nothing!
	elseif path == AbstractMultiController.DIALOG_FIND_PLAYER then --Find player
		if response and response ~= "" then
			self:getPlayerChannel(response)
		end
	elseif path == AbstractMultiController.DIALOG_FIND_PLAYER_CHANNEL then --Find player response
		if response == true then
			AbstractMultiController.joinChannel(self, self.FoundChannel)
		end
		self.FoundChannel = nil
	end
end

--- Called by the RML when the MOTD button is pressed. Displays the MOTD in a dialog box
--- @return nil
function PXOController:motd_pressed()

	ScpuiSystem.data.memory.multiplayer_general.DialogType = AbstractMultiController.DIALOG_MOTD

	local text = self.Motd
	local title = "Message of the Day"
	--- @type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = Dialogs.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Okay", 888290),
		Value = "",
		Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
	}

	AbstractMultiController.showDialog(self, text, title, false, buttons)

end

--- Called by the RML when the accept button is pressed. Closes the PXO screen and joins the game
--- @return nil
function PXOController:accept_pressed()
	ui.MultiPXO.closePXO()
	ScpuiSystem.data.memory.MultiReady = false
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MULTI_JOIN_GAME"])
end

--- Called by the RML when the help button is pressed. Goes to the PXO Help game state
--- @return nil
function PXOController:help_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PXO_HELP"])
end

--- Called by the RML when the exit button is pressed
--- @return nil
function PXOController:exit_pressed()
	self:exit()
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function PXOController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
       self:exit()
	end
end

--- Called by the RML to submit the chat to the server
--- @return nil
function PXOController:submit_pressed()
	if self.SubmittedChatValue then
		AbstractMultiController.sendChat(self)
	end
end

--- Called by the RML when the chat input has lost focus
--- @return nil
function PXOController:input_focus_lost()
	--do nothing
end

--- Called by the RML when the chat input has accepted a keypress
--- @param event Event the event that was triggered
--- @return nil
function PXOController:input_change(event)

	if event.parameters.linebreak ~= 1 then
		local val = self.ChatInputEl:GetAttribute("value")
		self.SubmittedChatValue = val
	else
		local submit_id = self.Document:GetElementById("submit_btn")
		ui.playElementSound(submit_id, "click")
		AbstractMultiController.sendChat(self)
	end

end

--- Called when the screen is being unloaded
--- @return nil
function PXOController:unload()
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = false
	Topics.multipxo.unload:send(self)
end

return PXOController
