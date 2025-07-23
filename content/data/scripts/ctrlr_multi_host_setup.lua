-----------------------------------
--Controller for the Multi Host Setup UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractMultiController = require("ctrlr_multi_common")

--- This multi controller is merged with the Multi Common Controller
local HostSetupController = Class(AbstractMultiController)

--- Called by the class constructor
--- @return nil
function HostSetupController:init()
	self.Player_List = {} --- @type scpui_multi_setup_player[] list of actual players
	self.MissionsListEl = nil --- @type Element mission list element
	self.PlayersListEl = nil --- @type Element player list element
	self.ChatEl = nil --- @type Element chat element
	self.ChatInputEl = nil --- @type Element chat input element
	self.CommonTextEl = nil --- @type Element common text element
	self.Document = nil --- @type Document the RML document
	self.Netgame = nil --- @type netgame the netgame object
	self.SelectedPlayerEl = nil --- @type Element the selected player element
	self.SelectedMissionEl = nil --- @type Element the selected mission element
	self.SubmittedChatValue = "" --- @type string the submitted chat value
	self.GameClosed = false --- @type boolean whether the game is closed
	self.Squadwar = false --- @type boolean whether the game is a squadwar

	self.Subclass = AbstractMultiController.CTRL_HOST_SETUP
end

--- Called by the RML document
--- @param document Document
function HostSetupController:initialize(document)
	AbstractMultiController.initialize(self, document)
	ScpuiSystem.data.memory.multiplayer_general.Context = self

	self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.MissionsListEl = self.Document:GetElementById("mission_list_ul")
	self.PlayersListEl = self.Document:GetElementById("players_list_ul")
	self.ChatEl = self.Document:GetElementById("chat_window")
	self.ChatInputEl = self.Document:GetElementById("chat_input")
	self.CommonTextEl = self.Document:GetElementById("common_text")
	--self.status_text_el = self.Document:GetElementById("status_text")

	if not ScpuiSystem.data.memory.multiplayer_host.MultiHostSetup then
		ui.MultiHostSetup.initMultiHostSetup()
		ScpuiSystem.data.memory.multiplayer_host.MultiHostSetup = true
		ScpuiSystem.data.memory.multiplayer_host.HostFilter = nil
		ScpuiSystem.data.memory.multiplayer_host.HostList = "missions"
	end

	self.Netgame = ui.MultiGeneral.getNetGame()

	self:buildFilters()

	if ScpuiSystem.data.memory.multiplayer_host.HostList == "missions" then
		self.Document:GetElementById("missions_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("campaigns_btn"):SetPseudoClass("checked", true)
	end

	self.SelectedPlayerEl= nil
	self.SelectedMissionEl = nil

	self.SubmittedChatValue = ""

	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
	ui.MultiGeneral.setPlayerState()

	self.GameClosed = self.Netgame.Closed
	if self.Netgame.Type == MULTI_TYPE_SQUADWAR then
		self.Squadwar = true
	else
		self.Squadwar = false
	end

	if self.GameClosed then
		self.Document:GetElementById("close_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("close_btn"):SetPseudoClass("checked", false)
	end

	if self.Squadwar then
		self.Document:GetElementById("squadwar_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("squadwar_btn"):SetPseudoClass("checked", false)
	end

	Topics.multihostsetup.initialize:send(self)

end

--- Add the mission filters to the dropdown
--- @return nil
function HostSetupController:buildFilters()
	local select_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("dropdown_cont").first_child)

	ScpuiSystem:clearDropdown(select_el)

	select_el:Add(ba.XSTR("All", 1256), "All", 1)
	select_el:Add(ba.XSTR("Co-op", 1257), "Co-op", 2)
	select_el:Add(ba.XSTR("Team", 1258), "Team", 3)
	select_el:Add(ba.XSTR("Dogfight", 1259), "Dogfight", 4)

	select_el.selection = 1
end

--- Exits the host setup screen
--- @param quit boolean True to accept the changes, false to cancel
--- @return nil
function HostSetupController:exit(quit)
	ui.MultiHostSetup.closeMultiHostSetup(quit)
	ScpuiSystem.data.memory.multiplayer_host.MultiHostSetup = nil
end

--- Respond to dialog closure
--- @return nil
function HostSetupController:dialogResponse()
	local path = ScpuiSystem.data.memory.multiplayer_general.DialogType
	ScpuiSystem.data.memory.multiplayer_general.DialogType = nil

	local response = ScpuiSystem.data.memory.multiplayer_general.DialogResponse
	ScpuiSystem.data.memory.multiplayer_general.DialogResponse = nil

	if path == AbstractMultiController.DIALOG_PLAYER_STATS then --Show Player Stats
		--Do nothing!
	end
end

--- Called by the RML when the squadwar button is pressed
--- @return nil
function HostSetupController:squadwar_pressed()
	--Not actually sure what this button is for!
	if self.Squadwar == false then
		self.Netgame.Type = MULTI_TYPE_SQUADWAR
		self.Document:GetElementById("squadwar_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("squadwar_btn"):SetPseudoClass("checked", false)
	end
end

--- Called by the RML when the help button is pressed
--- @return nil
function HostSetupController:help_pressed()
	--show help overlay
end

--- Called by the RML when the commit button is pressed
--- @return nil
function HostSetupController:commit_pressed()
	ui.MultiHostSetup.closeMultiHostSetup(true)
	ScpuiSystem.data.memory.multiplayer_host.MultiHostSetup = nil
end

--- Called by the RML when the host options button is pressed
--- @return nil
function HostSetupController:host_options_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MULTI_HOST_OPTIONS"])
end

--- Called by the RML when the missions button is pressed
--- @return nil
function HostSetupController:missions_pressed()
	self.Document:GetElementById("campaigns_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("missions_btn"):SetPseudoClass("checked", true)
	ScpuiSystem.data.memory.multiplayer_host.HostList = "missions"
end

--- Called by the RML when the campaigns button is pressed
--- @return nil
function HostSetupController:campaigns_pressed()
	self.Document:GetElementById("missions_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("campaigns_btn"):SetPseudoClass("checked", true)
	ScpuiSystem.data.memory.multiplayer_host.HostList = "campaigns"
end

--- Called by the RML when the team 1 button is pressed
--- @return nil
function HostSetupController:team_1_pressed()
	if self.SelectedPlayerEl then
		self.Document:GetElementById("team_2_btn"):SetPseudoClass("checked", false)
		self.Document:GetElementById("team_1_btn"):SetPseudoClass("checked", true)
		AbstractMultiController.getPlayerByKey(self, self.SelectedPlayerEl.id).Entry.Team = 0
	end
end

--- Called by the RML when the team 2 button is pressed
--- @return nil
function HostSetupController:team_2_pressed()
	if self.SelectedPlayerEl then
		self.Document:GetElementById("team_1_btn"):SetPseudoClass("checked", false)
		self.Document:GetElementById("team_2_btn"):SetPseudoClass("checked", true)
		AbstractMultiController.getPlayerByKey(self, self.SelectedPlayerEl.id).Entry.Team = 1
	end
end

--- Called by the RML when the player info button is pressed
--- @return nil
function HostSetupController:pilot_info_pressed()
	if self.SelectedPlayerEl then
		AbstractMultiController.getPlayerStats(self, AbstractMultiController.getPlayerByKey(self, self.SelectedPlayerEl.id).Name)
	end
end

--- Called by the RML when the kick button is pressed to kick the selected player
--- @return nil
function HostSetupController:kick_pressed()
	if self.SelectedPlayerEl then
		AbstractMultiController.getPlayerByKey(self, self.SelectedPlayerEl.id).Entry:kickPlayer()
	end
end

--- Called by the RML when the ban button is pressed
--- @return nil
function HostSetupController:close_pressed()
	--TODO: If not host then hide this button
	if self.GameClosed == true then
		self.Netgame.Closed = false
	else
		self.Netgame.Closed = true
	end
	self.GameClosed = self.Netgame.Closed
	self.Document:GetElementById("close_btn"):SetPseudoClass("checked", self.Netgame.Closed)
end

--- Called by the RML when the chat button is pressed
--- @return nil
function HostSetupController:submit_pressed()
	if self.SubmittedChatValue then
		AbstractMultiController.sendChat(self)
	end
end

--- Called by the RML when the options button is pressed
--- @return nil
function HostSetupController:options_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- Called by the RML when the exit button is pressed
--- @return nil
function HostSetupController:exit_pressed()
	self:exit(false)
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function HostSetupController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
       self:exit(false)
	end
end

--- Called by the RML when the chat input is no longer focused
--- @return nil
function HostSetupController:input_focus_lost()
	--do nothing
end

--- Called by the RML when the chat input accepts a keypress
--- @param event Event The event that was triggered
--- @return nil
function HostSetupController:input_change(event)

	if event.parameters.linebreak ~= 1 then
		local val = self.ChatInputEl:GetAttribute("value")
		self.SubmittedChatValue = val
	else
		local submit_id = self.Document:GetElementById("submit_btn")
		ui.playElementSound(submit_id, "click")
		AbstractMultiController.sendChat(self)
	end

end

--- Called by the RML when the filter dropdown changes
--- @return nil
function HostSetupController:filter_changed()
	local select_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("dropdown_cont").first_child)
	local val = select_el.options[select_el.selection - 1].value

	if val == "Co-op" then
		ScpuiSystem.data.memory.multiplayer_host.HostFilter = MULTI_TYPE_COOP
	elseif val == "Team" then
		ScpuiSystem.data.memory.multiplayer_host.HostFilter = MULTI_TYPE_TEAM
	elseif val == "Dogfight" then
		ScpuiSystem.data.memory.multiplayer_host.HostFilter = MULTI_TYPE_DOGFIGHT
	else
		ScpuiSystem.data.memory.multiplayer_host.HostFilter = nil
	end

	self.Mission_Files = {} -- list of mission files + ids only
	self.Missions_List = {} -- list of actual missions
	ScpuiSystem:clearEntries(self.MissionsListEl)
	self.SelectedMissionEl = nil
end

--- Called when the screen is being unloaded
--- @return nil
function HostSetupController:unload()
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = false
	Topics.multihostsetup.unload:send(self)
end

return HostSetupController
