-----------------------------------
--Controller for the Multi Sync UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractMultiController = require("ctrlr_multi_common")

--- This multi controller is merged with the Multi Common Controller
local MultiSyncController = Class(AbstractMultiController)

--- Called by the class constructor
--- @return nil
function MultiSyncController:init()
	self.Player_List = {} --- @type scpui_multi_setup_player[] list of actual players
	self.Document = nil --- @type Document the RML document
	self.PlayersListEl = nil --- @type Element the players list element
	self.ChatEl = nil --- @type Element the chat window element
	self.ChatInputEl = nil --- @type Element the chat input element
	self.CommonTextEl = nil --- @type Element the common text element
	self.SelectedPlayerEl = nil --- @type Element the selected player element
	self.SubmittedChatValue = "" --- @type string the submitted chat value
	self.Netgame = nil --- @type netgame the netgame object

	self.Subclass = AbstractMultiController.CTRL_SYNC
end

--- Called by the RML document
--- @param document Document
function MultiSyncController:initialize(document)
	AbstractMultiController.initialize(self, document)
	ScpuiSystem.data.memory.multiplayer_general.Context = self

	self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	--Hide these until we know if we're the host or not
	self.Document:GetElementById("bottom_panel_a"):SetClass("hidden", true)
	self.Document:GetElementById("bottom_panel_c"):SetClass("hidden", true)

	self.PlayersListEl = self.Document:GetElementById("players_list_ul")
	self.ChatEl = self.Document:GetElementById("chat_window")
	self.ChatInputEl = self.Document:GetElementById("chat_input")
	self.CommonTextEl = self.Document:GetElementById("common_text")
	--self.status_text_el = self.Document:GetElementById("status_text")

	ui.MultiSync.initMultiSync()

	self.Netgame = ui.MultiGeneral.getNetGame()

	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
	ui.MultiGeneral.setPlayerState()

	Topics.multisync.initialize:send(self)

end

--- Exit the Multi Sync UI and quits the multi game
--- @return nil
function MultiSyncController:exit()
	ui.MultiSync.closeMultiSync(true)
end

--- Called by the RML when the chat submit button is pressed
--- @return nil
function MultiSyncController:submit_pressed()
	if self.SubmittedChatValue then
		AbstractMultiController.sendChat(self)
	end
end

--- Kicks a player from the current game
--- @param player net_player the player to kick
--- @return nil
function MultiSyncController:kickPlayer(player)
	player:kickPlayer()
end

--- Called by the RML when the kick button is pressed
--- @return nil
function MultiSyncController:kick_pressed()
	if self.SelectedPlayerEl then
		self:kickPlayer(AbstractMultiController.getPlayerByKey(self, self.SelectedPlayerEl.id).Entry)
	end
end

--- Called by the RML when the launch button is pressed
--- @return nil
function MultiSyncController:launch_pressed()
	ui.MultiSync:startCountdown()
end

--- Called by the RML when the exit button is pressed
--- @return nil
function MultiSyncController:exit_pressed()
	self:exit()
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function MultiSyncController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
       --escape key is not allowed here
	end
end

--- Callled by the RML when the chat input focus is lost
--- @return nil
function MultiSyncController:input_focus_lost()
	--do nothing
end

--- Called by the RML when the chat input accepts a keypress
--- @param event Event The event that was triggered
--- @return nil
function MultiSyncController:input_change(event)

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
function MultiSyncController:unload()
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = false
	Topics.multisync.unload:send(self)
end

return MultiSyncController
