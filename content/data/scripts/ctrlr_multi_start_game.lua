-----------------------------------
--Controller for the Multi Start Game UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractMultiController = require("ctrlr_multi_common")

--- This multi controller is merged with the Multi Common Controller
local JoinGameController = Class(AbstractMultiController)

--- Called by the class constructor
--- @return nil
function JoinGameController:init()
	self.MissionTitle = nil --- @type string the title of the mission
	self.GamePassword = nil --- @type string The password for the game
	self.SelectedRank = nil --- @type number The selected rank value
	self.GameType = nil --- @type enumeration The type of game being created. Should be one of the MULTI_GAME_TYPE enumerations
	self.TitleInputEl = nil --- @type Element The title input element
	self.PasswordInputEl = nil --- @type Element The password input element
	self.Document = nil --- @type Document The RML document

	self.Subclass = AbstractMultiController.CTRL_START_GAME
end

--- Called by the RML document
--- @param document Document
function JoinGameController:initialize(document)
	AbstractMultiController.initialize(self, document)
	ScpuiSystem.data.memory.multiplayer_general.Context = self

	self.Document = document

	self.MissionTitle = ba.getCurrentPlayer():getName() .. "'s game"
	self.GamePassword = ""
	self.SelectedRank = 1
	self.GameType = MULTI_GAME_TYPE_OPEN

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.TitleInputEl = self.Document:GetElementById("title_input")
	self.TitleInputEl:SetAttribute("value", self.MissionTitle)

	self.PasswordInputEl = self.Document:GetElementById("password_input")

	ui.MultiStartGame.initMultiStart()

	self:buildRankList()

	self.Document:GetElementById("open_btn"):SetPseudoClass("checked", true)

	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
	ui.MultiGeneral.setPlayerState()

	Topics.multistartgame.initialize:send(self)

end

--- Add each valid rank to the ranks dropdown
--- @return nil
function JoinGameController:buildRankList()
	local select_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("dropdown_cont").first_child)

	ScpuiSystem:clearDropdown(select_el)

	for i = 1, #ui.Medals.Ranks_List do
		local rank = ui.Medals.Ranks_List[i].Name
		select_el:Add(rank, rank, i)
	end

	if #ui.Medals.Ranks_List > 0 then
		select_el.selection = 1
	end
end

--- uncheck all the buttons
--- @return nil
function JoinGameController:uncheckButtons()
	self.Document:GetElementById("open_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("password_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("rank_above_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("rank_below_btn"):SetPseudoClass("checked", false)
end

--- toggle the password input field on or off
--- @param lock boolean
--- @return nil
function JoinGameController:lockPassword(lock)
	self.Document:GetElementById("password_lock"):SetClass("hidden", not lock)
end

--- toggle the rank dropdown on or off
--- @param lock boolean
--- @return nil
function JoinGameController:lockRank(lock)
	self.Document:GetElementById("rank_lock"):SetClass("hidden", not lock)
end

--- Exit the game creation screen and close Multi Start
--- @param continue? boolean -- Unused
--- @return nil
function JoinGameController:exit(continue)
	ui.MultiStartGame.closeMultiStart(false)
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MULTI_JOIN_GAME"])
end

--- Called by the RML when the join button is pressed
--- @return nil
function JoinGameController:join_pressed()
	ui.MultiStartGame.setName(self.MissionTitle)

	local arg = nil

	if self.GameType == MULTI_GAME_TYPE_PASSWORD then
		arg = self.GamePassword
	end

	if self.GameType == MULTI_GAME_TYPE_RANK_ABOVE or self.GameType == MULTI_GAME_TYPE_RANK_BELOW then
		arg = self.SelectedRank
	end

	ui.MultiStartGame.setGameType(self.GameType, arg)
	ui.MultiStartGame.closeMultiStart(true)
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MULTI_HOST_SETUP"])
end

--- Called by the RML when the help button is pressed
--- @return nil
function JoinGameController:help_pressed()
	--show help overlay
end

--- Called by the RML when the open button is pressed
--- @return nil
function JoinGameController:open_pressed()
	self:uncheckButtons()
	self.Document:GetElementById("open_btn"):SetPseudoClass("checked", true)
	self:lockPassword(true)
	self:lockRank(true)

	self.GameType = MULTI_GAME_TYPE_OPEN
end

--- Called by the RML when the password button is pressed
--- @return nil
function JoinGameController:password_pressed()
	self:uncheckButtons()
	self.Document:GetElementById("password_btn"):SetPseudoClass("checked", true)
	self:lockPassword(false)
	self:lockRank(true)

	self.GameType = MULTI_GAME_TYPE_PASSWORD
end

--- Called by the RML when the rank above button is pressed
--- @return nil
function JoinGameController:rank_above_pressed()
	self:uncheckButtons()
	self.Document:GetElementById("rank_above_btn"):SetPseudoClass("checked", true)
	self:lockPassword(true)
	self:lockRank(false)

	self.GameType = MULTI_GAME_TYPE_RANK_ABOVE
end

--- Called by the RML when the rank below button is pressed
--- @return nil
function JoinGameController:rank_below_pressed()
	self:uncheckButtons()
	self.Document:GetElementById("rank_below_btn"):SetPseudoClass("checked", true)
	self:lockPassword(true)
	self:lockRank(false)

	self.GameType = MULTI_GAME_TYPE_RANK_BELOW
end

--- Called by the RML when the options button is pressed
--- @return nil
function JoinGameController:options_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- Called by the RML when the exit button is pressed
--- @return nil
function JoinGameController:exit_pressed()
	self:exit()
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function JoinGameController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
       self:exit()
	end
end

--- Called by the RML when an input box loses focus
--- @return nil
function JoinGameController:input_focus_lost()
	--do nothing
end

--- Get the index of a rank by rank name
--- @param rank_name string The name of the rank
--- @return number index The index of the rank
function JoinGameController:getRankIndex(rank_name)
	for i = 1, #ui.Medals.Ranks_List do
		if ui.Medals.Ranks_List[i].Name == rank_name then
			return i
		end
	end
	return -1
end

--- Called by the RML when the rank dropdown is changed
--- @return nil
function JoinGameController:rank_changed()
	local select_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("dropdown_cont").first_child)

	local rank = select_el.options[select_el.selection - 1].value

	local player_rank = ba.getCurrentPlayer().Stats.Rank.Index

	local rank_idx = self:getRankIndex(rank)

	if self.GameType == MULTI_GAME_TYPE_RANK_ABOVE then
		if player_rank < rank_idx then
			select_el.selection = player_rank
			--Maybe show a popup warning that they can't choose a rank above their own!
			rank_idx = player_rank
		end
	end

	if self.GameType == MULTI_GAME_TYPE_RANK_BELOW then
		if player_rank > rank_idx then
			select_el.selection = player_rank
			--Maybe show a popup warning that they can't choose a rank below their own!
			rank_idx = player_rank
		end
	end

	if rank_idx then
		self.SelectedRank = rank_idx
	end
end

--- Called by the RML when the title input box has a keyup event
--- @param element Element The title input element
--- @param event Event The event that was triggered
--- @return nil
function JoinGameController:title_keyup(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if not keys.ESCAPE then
        return
    end
end

--- Called by the RML when the title input box has a keypress event
--- @param event Event The event that was triggered
--- @return nil
function JoinGameController:title_input_change(event)
    --local stringValue = event.parameters.value:gsub("^%s*(.-)%s*$", "%1")
	--self.title_input_el:SetAttribute("value", stringValue)
	self.MissionTitle = event.parameters.value
end

--- Called by the RML when the password input box has a keyup event
--- @param element Element The password input element
--- @param event Event The event that was triggered
--- @return nil
function JoinGameController:password_keyup(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if not keys.ESCAPE then
        return
    end
end

--- Called by the RML when the password input box has a keypress event
--- @param event Event The event that was triggered
--- @return nil
function JoinGameController:password_input_change(event)
    local stringValue = event.parameters.value:gsub("^%s*(.-)%s*$", "%1")
	self.PasswordInputEl:SetAttribute("value", stringValue)
	self.GamePassword = stringValue
end

--- Called when the screen is being unloaded
--- @return nil
function JoinGameController:unload()
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = false
	Topics.multistartgame.unload:send(self)
end

return JoinGameController
