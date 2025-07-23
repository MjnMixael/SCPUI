-----------------------------------
--Controller for the Multi Host Options UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractMultiController = require("ctrlr_multi_common")

--- This multi controller is merged with the Multi Common Controller
local HostOptionsController = Class(AbstractMultiController)

--- Called by the class constructor
--- @return nil
function HostOptionsController:init()
	self.Document = nil ---@type Document The RML document
	self.ChatEl = nil ---@type Element The chat window element
	self.ChatInputEl = nil ---@type Element The chat input element
	self.TimeLimitInputEl = nil ---@type Element The time limit input element
	self.RespawnLimitInputEl = nil ---@type Element The respawn limit input element
	self.KillLimitInputEl = nil ---@type Element The kill limit input element
	self.ObserversLimitInputEl = nil ---@type Element The observers limit input element
	self.Netgame = nil ---@type netgame The current netgame
	self.HostModifies = false ---@type boolean Whether the host modifies ships
	self.TimeLimit = 0 ---@type number The time limit
	self.RespawnLimit = 0 ---@type number The respawn limit
	self.KillLimit = 0 ---@type number The kill limit
	self.ObserversLimit = 0 ---@type number The observers limit
	self.SubmittedChatValue = "" ---@type string The submitted chat value

	self.Subclass = AbstractMultiController.CTRL_HOST_OPTIONS
end

--- Called by the RML document
--- @param document Document
function HostOptionsController:initialize(document)
	AbstractMultiController.initialize(self, document)
	ScpuiSystem.data.memory.multiplayer_general.Context = self

	self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.ChatEl = self.Document:GetElementById("chat_window")
	self.ChatInputEl = self.Document:GetElementById("chat_input")
	--self.status_text_el = self.Document:GetElementById("status_text")

	self.TimeLimitInputEl = self.Document:GetElementById("time_limit_input")
	self.RespawnLimitInputEl = self.Document:GetElementById("respawn_limit_input")
	self.KillLimitInputEl = self.Document:GetElementById("kill_limit_input")
	self.ObserversLimitInputEl = self.Document:GetElementById("observers_limit_input")

	self.Netgame = ui.MultiGeneral.getNetGame()

	self:buildDropdowns()

	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
	ui.MultiGeneral.setPlayerState()

	if self.Netgame.HostModifiesShips then
		self.HostModifies = true
	else
		self.HostModifies = false
	end
	self.Document:GetElementById("host_modifies_btn"):SetPseudoClass("checked", self.HostModifies)

	if self.Netgame.TimeLimit < 0 then
		self.TimeLimitInputEl:SetAttribute("value", 0)
	else
		self.TimeLimitInputEl:SetAttribute("value", self.Netgame.TimeLimit)
	end
	self.KillLimitInputEl:SetAttribute("value", self.Netgame.RespawnLimit)
	self.RespawnLimitInputEl:SetAttribute("value", self.Netgame.KillLimit)
	self.ObserversLimitInputEl:SetAttribute("value", self.Netgame.ObserverLimit)

	Topics.multihostoptions.initialize:send(self)

end

--- Build all the dropdown lists in the UI
--- @return nil
function HostOptionsController:buildDropdowns()
	local ai_orders_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("ai_orders_cont").first_child)

	ScpuiSystem:clearDropdown(ai_orders_el)

	ai_orders_el:Add("Highest Rank", "Highest Rank", 1)
	ai_orders_el:Add("Team/Wing-Leader", "Team/Wing-Leader", 2)
	ai_orders_el:Add("Any", "Any", 3)
	ai_orders_el:Add("Host", "Host", 4)

	if self.Netgame.Orders == MULTI_OPTION_RANK then
		ai_orders_el.selection = 1
	elseif self.Netgame.Orders == MULTI_OPTION_HOST then
		ai_orders_el.selection = 4
	elseif self.Netgame.Orders == MULTI_OPTION_LEAD then
		ai_orders_el.selection = 2
	else
		ai_orders_el.selection = 1
	end

	local end_mission_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("end_mission_cont").first_child)

	ScpuiSystem:clearDropdown(end_mission_el)

	end_mission_el:Add("Highest Rank", "Highest Rank", 1)
	end_mission_el:Add("Team/Wing-Leader", "Team/Wing-Leader", 2)
	end_mission_el:Add("Any", "Any", 3)
	end_mission_el:Add("Host", "Host", 4)

	if self.Netgame.EndMission == MULTI_OPTION_RANK then
		end_mission_el.selection = 1
	elseif self.Netgame.EndMission == MULTI_OPTION_HOST then
		end_mission_el.selection = 4
	elseif self.Netgame.EndMission == MULTI_OPTION_LEAD then
		end_mission_el.selection = 2
	else
		end_mission_el.selection = 1
	end

	local difficulty_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("difficulty_cont").first_child)

	ScpuiSystem:clearDropdown(difficulty_el)

	difficulty_el:Add(ba.XSTR("Very Easy", 469), "Very Easy", 1)
	difficulty_el:Add(ba.XSTR("Easy", 470), "Easy", 2)
	difficulty_el:Add(ba.XSTR("Normal", 471), "Normal", 3)
	difficulty_el:Add(ba.XSTR("Hard", 472), "Hard", 4)
	difficulty_el:Add(ba.XSTR("Insane", 473), "Insane", 5)

	difficulty_el.selection = self.Netgame.SkillLevel + 1
end

--- Called by the RML to exit the Multi Host Options UI
--- @return nil
function HostOptionsController:exit()
	self.Netgame:acceptOptions()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MULTI_HOST_SETUP"])
end

--- Called by the RML to commit the changes made in the UI
--- @return nil
function HostOptionsController:commit_pressed()
	self:exit()
end

--- Called by the RML to submit the chat message
--- @return nil
function HostOptionsController:submit_pressed()
	if self.SubmittedChatValue then
		AbstractMultiController.sendChat(self)
	end
end

--- Called by the RML to toggle the host modifies ships option
--- @return nil
function HostOptionsController:host_modifies_pressed()
	if self.Netgame.HostModifiesShips then
		self.HostModifies = false
	else
		self.HostModifies = true
	end
	self.Netgame.HostModifiesShips = self.HostModifies
	self.Document:GetElementById("host_modifies_btn"):SetPseudoClass("checked", self.Netgame.HostModifiesShips)
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
       self:exit()
	end
end

--- When the element loses focus
--- @return nil
function HostOptionsController:input_focus_lost()
	--do nothing
end

--- Called by the RML when the chat input accepts a keypress
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:input_change(event)

	if event.parameters.linebreak ~= 1 then
		local val = self.ChatInputEl:GetAttribute("value")
		self.SubmittedChatValue = val
	else
		local submit_id = self.Document:GetElementById("submit_btn")
		ui.playElementSound(submit_id, "click")
		AbstractMultiController.sendChat(self)
	end

end

--- Trim the input value to remove any non-numeric characters and leading/trailing whitespace
--- @param val string The input value
--- @return string stringValue The trimmed input value
function HostOptionsController:trimInput(val)
	local string_value = val:gsub("^%s*(.-)%s*$", "%1")
	string_value = string_value:gsub("[^%d]", "")
	return string_value
end

--- Called by the RML on keyup in the time limit input
--- @param element Element The time limit input element
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:time_limit_keyup(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if not keys.ESCAPE then
        return
    end
end

--- Called by the RML on input change in the time limit input
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:time_limit_input_change(event)
	local string_value = self:trimInput(event.parameters.value)
	self.TimeLimitInputEl:SetAttribute("value", string_value)
	local numeric_value = tonumber(string_value)
	if numeric_value ~= nil then
		self.TimeLimit = numeric_value
	end
end

--- Called by the RML on keyup in the respawn limit input
--- @param element Element The respawn limit input element
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:respawn_limit_keyup(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if not keys.ESCAPE then
        return
    end
end

--- Called by the RML on input change in the respawn limit input
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:respawn_limit_input_change(event)
	local string_value = self:trimInput(event.parameters.value)
	self.RespawnLimitInputEl:SetAttribute("value", string_value)
	local numeric_value = tonumber(string_value)
	if numeric_value ~= nil then
		self.RespawnLimit = numeric_value
	end
end

--- Called by the RML on keyup in the kill limit input
--- @param element Element The kill limit input element
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:kill_limit_keyup(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if not keys.ESCAPE then
        return
    end
end

--- Called by the RML on input change in the kill limit input
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:kill_limit_input_change(event)
	local string_value = self:trimInput(event.parameters.value)
	self.KillLimitInputEl:SetAttribute("value", string_value)
	local numeric_value = tonumber(string_value)
	if numeric_value ~= nil then
		self.KillLimit = numeric_value
	end
end

--- Called by the RML on keyup in the observers limit input
--- @param element Element The observers limit input element
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:observers_limit_keyup(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if not keys.ESCAPE then
        return
    end
end

--- Called by the RML on input change in the observers limit input
--- @param event Event The event that was triggered
--- @return nil
function HostOptionsController:observers_limit_input_change(event)
	local string_value = self:trimInput(event.parameters.value)
	self.ObserversLimitInputEl:SetAttribute("value", string_value)
	local numeric_value = tonumber(string_value)
	if numeric_value ~= nil then
		self.ObserversLimit = numeric_value
	end
end

--- Called by the RML when the AI orders dropdown changes
--- @return nil
function HostOptionsController:ai_orders_changed()
	local select_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("ai_orders_cont").first_child)
	local val = select_el.options[select_el.selection - 1].value

	if val == "Highest Rank" then
		self.Netgame.Orders = MULTI_OPTION_RANK
	elseif val == "Team/Wing-Leader" then
		self.Netgame.Orders = MULTI_OPTION_LEAD
	elseif val == "Host" then
		self.Netgame.Orders = MULTI_OPTION_HOST
	else
		self.Netgame.Orders = MULTI_OPTION_ANY
	end
end

--- Called by the RML when the end mission dropdown changes
--- @return nil
function HostOptionsController:end_mission_changed()
	local select_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("end_mission_cont").first_child)
	local val = select_el.options[select_el.selection - 1].value

	if val == "Highest Rank" then
		self.Netgame.EndMission  = MULTI_OPTION_RANK
	elseif val == "Team/Wing-Leader" then
		self.Netgame.EndMission  = MULTI_OPTION_LEAD
	elseif val == "Host" then
		self.Netgame.EndMission  = MULTI_OPTION_HOST
	else
		self.Netgame.EndMission  = MULTI_OPTION_ANY
	end
end

--- Called by the RML when the difficulty dropdown changes
--- @return nil
function HostOptionsController:difficulty_changed()
	local select_el = Element.As.ElementFormControlDataSelect(self.Document:GetElementById("difficulty_cont").first_child)
	local val = select_el.options[select_el.selection - 1].value

	if val == "Very Easy" then
		self.Netgame.SkillLevel  = 0
	elseif val == "Easy" then
		self.Netgame.SkillLevel  = 1
	elseif val == "Hard" then
		self.Netgame.SkillLevel  = 3
	elseif val == "Insane" then
		self.Netgame.SkillLevel  = 4
	else
		self.Netgame.SkillLevel = 2 -- Normal
	end
end

--- Called when the screen is being unloaded
--- @return nil
function HostOptionsController:unload()
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = false
	Topics.multihostoptions.unload:send(self)
end

return HostOptionsController
