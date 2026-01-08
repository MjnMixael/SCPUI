-----------------------------------
--Controller for the Control Config UI
-----------------------------------

local AsyncUtil = require("lib_async")
local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local ControlConfigController = Class()

ControlConfigController.PROMPT_TYPE_NONE = 0 --- @type number Enumeration for no prompt dialog
ControlConfigController.PROMPT_TYPE_NEW_PRESET = 1 --- @type number Enumeration for the new preset dialog
ControlConfigController.PROMPT_TYPE_CLONE_PRESET = 2 --- @type number Enumeration for the clone preset dialog
ControlConfigController.PROMPT_TYPE_CLEAR_ALL_BINDS = 3 --- @type number Enumeration for the clear all binds dialog
ControlConfigController.PROMPT_TYPE_GET_PRESET_NAME = 4 --- @type number Enumeration for the get preset name dialog
ControlConfigController.PROMPT_TYPE_DELETE_PRESET = 5 --- @type number Enumeration for the delete preset dialog
ControlConfigController.PROMPT_TYPE_OVERWRITE_NEW_PRESET = 6 --- @type number Enumeration for the overwrite preset dialog
ControlConfigController.PROMPT_TYPE_OVERWRITE_CLONE_PRESET = 7 --- @type number Enumeration for the overwrite clone preset dialog

ControlConfigController.TAB_TYPE_TARGET = 0 --- @type number Enumeration for the target tab
ControlConfigController.TAB_TYPE_SHIP = 1 --- @type number Enumeration for the ship tab
ControlConfigController.TAB_TYPE_WEAPON = 2 --- @type number Enumeration for the weapon tab
ControlConfigController.TAB_TYPE_MISC = 3 --- @type number Enumeration for the misc tab

--- Called by the class constructor
--- @return nil
function ControlConfigController:init()
	self.Document = nil --- @type Document The RML document
	self.Conflict = false --- @type boolean Whether there is a conflict in the current control configuration
	self.PreviousPreset = nil --- @type number The index of the previous preset
	self.CurrentPreset = nil --- @type number The index of the current preset
	self.CurrentTab = 0 --- @type number The current controls list tab index
	self.PreviousControl = nil --- @type number | nil The index of the previous control entry
	self.CurrentControl = nil --- @type number | nil The currently selected ui list item, if any
	self.CurrentBind = nil --- @type number The currently selected bind ID
	self.NumBinds = nil --- @type number The total number of binds
	self.PromptControl = ControlConfigController.PROMPT_TYPE_NONE --- @type number Controls which dialog prompt to show the player. Should be one of the PROMPT_TYPE enumerations
	ScpuiSystem.data.memory.control_config.NextDialog = nil --- @type dialog_setup The next dialog to show
end

--- Called by the RML document
--- @param document Document
function ControlConfigController:initialize(document)

    self.Document = document
	ScpuiSystem.data.memory.control_config.Context = self

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)
	self.Document:GetElementById("conflict_warning"):SetClass("h1", true)

	ui.ControlConfig.initControlConfig()

	self:initPresets()
	self.Document:GetElementById("new_lock"):SetClass("hidden", false)

	Topics.controlconfig.initialize:send(self)

	self:changeSection(self.TAB_TYPE_TARGET)
end

--- Initialize the presets list and create all the elements
--- @return nil
function ControlConfigController:initPresets()
	local parent_el = self.Document:GetElementById("list_presets_ul")

	ScpuiSystem:clearEntries(parent_el)

	for i = 1, #ui.ControlConfig.ControlPresets do
		local entry = ui.ControlConfig.ControlPresets[i]

		local li_el = self.Document:CreateElement("li")
		li_el.id = "preset_" .. i

		li_el:SetClass("preset_list_element", true)
		li_el:SetClass("button_3", true)

		li_el.inner_rml = entry.Name

		li_el:AddEventListener("click", function(_, _, _)
				self:selectPreset(i, entry.Name)
			end)

		parent_el:AppendChild(li_el)

		local current_preset = ui.ControlConfig:getCurrentPreset()

		if entry.Name == current_preset then
			li_el:SetPseudoClass("checked", true)
			self.CurrentPreset = i
			self.PreviousPreset = i

			--unlock clone and delete
			self.Document:GetElementById("clone_lock"):SetClass("hidden", true)
			if entry.Name ~= "default" then
				self.Document:GetElementById("delete_lock"):SetClass("hidden", true)
			else
				self.Document:GetElementById("delete_lock"):SetClass("hidden", false)
			end
		end
	end

end

--- Selects a preset to apply to the control config
--- @param idx number The index of the preset list item
--- @param name string The name of the preset to send to FSO to apply
function ControlConfigController:selectPreset(idx, name)

	if self.CurrentPreset == idx then
		return
	end

	self.CurrentPreset = idx

	if self.PreviousPreset == nil then
		self.PreviousPreset = idx
	else
		local previous_preset_id = "preset_" .. self.PreviousPreset
		self.Document:GetElementById(previous_preset_id):SetPseudoClass("checked", false)

		self.PreviousPreset = idx
	end

	local preset_id = "preset_" .. self.PreviousPreset
	self.Document:GetElementById(preset_id):SetPseudoClass("checked", true)

	ui.ControlConfig.usePreset(name)

	--unlock clone and delete
	self.Document:GetElementById("clone_lock"):SetClass("hidden", true)
	if name ~= "default" then
		self.Document:GetElementById("delete_lock"):SetClass("hidden", true)
	else
		self.Document:GetElementById("delete_lock"):SetClass("hidden", false)
	end

	--reload the keys list
	self:changeSection(self.CurrentTab)

end

--- Deselects the currently selected preset list item. Used when the controls are changed and the preset is no longer a match
--- @return nil
function ControlConfigController:unselectPreset()
	if self.PreviousPreset == nil then
		return
	else
		local preset_id = "preset_" .. self.PreviousPreset
		self.Document:GetElementById(preset_id):SetPseudoClass("checked", false)

		self.PreviousPreset = nil
		self.CurrentPreset = nil
	end

	--lock clone and delete
	self.Document:GetElementById("clone_lock"):SetClass("hidden", false)
	self.Document:GetElementById("delete_lock"):SetClass("hidden", false)
end

--- Tries to select the preset in the UI that is currently active in FSO
--- @return nil
function ControlConfigController:checkPresets()
	local cur = ui.ControlConfig.getCurrentPreset()

	if cur == nil then
		self:unselectPreset()
		self.Document:GetElementById("new_lock"):SetClass("hidden", true)
	end

	for i = 1, #ui.ControlConfig.ControlPresets do
		local entry = ui.ControlConfig.ControlPresets[i]

		if entry.Name == cur then
			self:selectPreset(i, entry.Name)
			self.Document:GetElementById("new_lock"):SetClass("hidden", false)
			break
		end
	end
end

--- Builds a dialog box to prompt the player for a new preset name
--- @param preset_type number The type of preset to create. PROMPT_TYPE_NEW_PRESET or PROMPT_TYPE_CLONE_PRESET
--- @return nil
function ControlConfigController:getPresetInput(preset_type)

	assert(preset_type == ControlConfigController.PROMPT_TYPE_NEW_PRESET or preset_type == ControlConfigController.PROMPT_TYPE_CLONE_PRESET, "Invalid preset type! Got .. '" .. preset_type .. "'")

	self.PromptControl = preset_type

	local text = "Please enter a name for the preset: "
	local title = ""
	---@type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Okay", 888290),
		Value = "",
		Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
	}

	ScpuiSystem.data.memory.control_config.NextDialog = {
		Text = text,
		Title = title,
		Input = true,
		Buttons_List = buttons
	}
end

--- Wrapper function to prompt for user input. Called by the RML
--- @param preset_type number The type of preset to create. PROMPT_TYPE_NEW_PRESET or PROMPT_TYPE_CLONE_PRESET
--- @return nil
function ControlConfigController:get_preset_input(preset_type)
	self:getPresetInput(preset_type)
end

--- Creates a new controls preset in FSO if the name is unique
--- @param name string The name of the new preset
--- @param overwrite? boolean Whether to overwrite the existing preset
--- @return nil
function ControlConfigController:newPreset(name, overwrite)

	if not overwrite then
		overwrite = false
	end

	if not name then
		return
	else
		--Make sure preset names have no spaces and aren't longer than 28 characters
		name = name:gsub("%s+", "")
		if #name > 28 then
			name = name:sub(1, 28)
		end

		local can_overwrite = true
		if not ba.isEngineVersionAtLeast(25, 0, 0) then
			can_overwrite = false
		end

		local result = false
		if can_overwrite then
			result = ui.ControlConfig.createPreset(name, overwrite)
		else
			result = ui.ControlConfig.createPreset(name)
		end

		if result then
			self:initPresets()
			self:changeSection(self.CurrentTab)
		else
			if name:lower() == "default" then
				local text = "Cannot overwrite the default preset!"
				local title = ""
				---@type dialog_button[]
				local buttons = {}
				buttons[1] = {
					Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
					Text = ba.XSTR("Okay", 888290),
					Value = "",
					Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
				}

				ScpuiSystem.data.memory.control_config.NextDialog = {
					Text = text,
					Title = title,
					Input = false,
					Buttons_List = buttons
				}
			elseif not can_overwrite or overwrite then
				self.PromptControl = ControlConfigController.PROMPT_TYPE_NEW_PRESET

				local text = "An error occurred. Please enter a new name for the preset: "
				local title = ""
				---@type dialog_button[]
				local buttons = {}
				buttons[1] = {
					Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
					Text = ba.XSTR("Okay", 888290),
					Value = "",
					Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
				}

				ScpuiSystem.data.memory.control_config.NextDialog = {
					Text = text,
					Title = title,
					Input = true,
					Buttons_List = buttons
				}
			else
				self.PromptControl = ControlConfigController.PROMPT_TYPE_OVERWRITE_NEW_PRESET

				local text = "An identical preset already exists! Overwrite?"
				local title = ""
				---@type dialog_button[]
				local buttons = {}
				buttons[1] = {
					Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
					Text = ba.XSTR("Yes", 888296),
					Value = name,
					Keypress = string.sub(ba.XSTR("Yes", 888296), 1, 1)
				}
				buttons[2] = {
					Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
					Text = ba.XSTR("No", 888298),
					Value = false,
					Keypress = string.sub(ba.XSTR("No", 888298), 1, 1)
				}

				ScpuiSystem.data.memory.control_config.NextDialog = {
					Text = text,
					Title = title,
					Input = false,
					Buttons_List = buttons
				}
			end
		end
	end

end

--- Clones an existing preset if the name is unique
--- @param name string The name of the new preset
--- @param overwrite? boolean Whether to overwrite the existing preset
--- @return nil
function ControlConfigController:clonePreset(name, overwrite)

	if not overwrite then
		overwrite = false
	end

	--Make sure preset names have no spaces and aren't longer than 28 characters
	name = name:gsub("%s+", "")
	if #name > 28 then
		name = name:sub(1, 28)
	end

	local preset = ui.ControlConfig.ControlPresets[self.CurrentPreset]

	--If the player tries to clone a preset and overwrite it with the same name then just do nothing
	if preset.Name == name then
		return
	end

	local can_overwrite = true
	if not ba.isEngineVersionAtLeast(25, 0, 0) then
		can_overwrite = false
	end

	local result = false
	if can_overwrite then
		result = preset:clonePreset(name, overwrite)
	else
		result = preset:clonePreset(name)
	end

	if result then
		self:initPresets()
		self:changeSection(self.CurrentTab)
	else
		if name:lower() == "default" then
			local text = "Cannot overwrite the default preset!"
			local title = ""
			---@type dialog_button[]
			local buttons = {}
			buttons[1] = {
				Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
				Text = ba.XSTR("Okay", 888290),
				Value = "",
				Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
			}

			ScpuiSystem.data.memory.control_config.NextDialog = {
				Text = text,
				Title = title,
				Input = false,
				Buttons_List = buttons
			}
		elseif not can_overwrite or overwrite then
			self.PromptControl = ControlConfigController.PROMPT_TYPE_CLONE_PRESET

			local text = "An error occurred. Please enter a new name for the preset: "
			local title = ""
			---@type dialog_button[]
			local buttons = {}
			buttons[1] = {
				Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
				Text = ba.XSTR("Okay", 888290),
				Value = "",
				Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
			}

			ScpuiSystem.data.memory.control_config.NextDialog = {
				Text = text,
				Title = title,
				Input = true,
				Buttons_List = buttons
			}
		else
			self.PromptControl = ControlConfigController.PROMPT_TYPE_OVERWRITE_CLONE_PRESET

			local text = "An identical preset already exists! Overwrite?"
			local title = ""
			---@type dialog_button[]
			local buttons = {}
			buttons[1] = {
				Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
				Text = ba.XSTR("Yes", 888296),
				Value = name,
				Keypress = string.sub(ba.XSTR("Yes", 888296), 1, 1)
			}
			buttons[2] = {
				Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
				Text = ba.XSTR("No", 888298),
				Value = false,
				Keypress = string.sub(ba.XSTR("No", 888298), 1, 1)
			}

			ScpuiSystem.data.memory.control_config.NextDialog = {
				Text = text,
				Title = title,
				Input = false,
				Buttons_List = buttons
			}
		end
	end

end

--- Creates a dialog box to confirm the deletion of a preset
--- @return nil
function ControlConfigController:verify_delete()

	self.PromptControl = ControlConfigController.PROMPT_TYPE_DELETE_PRESET

	local text = "Are you sure you want to delete the preset?"
	local title = ""
	---@type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Yes", 888296),
		Value = true,
		Keypress = string.sub(ba.XSTR("Yes", 888296), 1, 1)
	}
	buttons[2] = {
		Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
		Text = ba.XSTR("No", 888298),
		Value = false,
		Keypress = string.sub(ba.XSTR("No", 888298), 1, 1)
	}

	ScpuiSystem.data.memory.control_config.NextDialog = {
		Text = text,
		Title = title,
		Input = false,
		Buttons_List = buttons
	}
end

--- Deletes the currently selected preset from FSO and updates the UI
--- @return nil
function ControlConfigController:deletePreset()

	local preset = ui.ControlConfig.ControlPresets[self.CurrentPreset]

	ui.ControlConfig.usePreset("default")

	preset:deletePreset()

	self:initPresets()
	self:changeSection(self.CurrentTab)

end

--- Creates the list of control configurations for the selected tab
--- @param tab number The index of the tab to display. Should be one of the TAB_TYPE enumerations
--- @return nil
function ControlConfigController:initKeysList(tab)

	local parent_el = self.Document:GetElementById("list_items_ul")

	for i = 1, #ui.ControlConfig.ControlConfigs do
		local entry = ui.ControlConfig.ControlConfigs[i]

		if entry.Tab == tab and not entry.Disabled then

			local li_el = self.Document:CreateElement("li")
			li_el.id = "line_" .. i

			li_el:SetClass("control_configlist_element", true)
			li_el:SetClass("button_3", true)

			parent_el:AppendChild(li_el)

			--build the name div
			local na_el = self.Document:CreateElement("div")
			na_el.id = "name_" .. i
			na_el:SetClass("name_display", true)
			na_el:SetClass("button_3", true)
			na_el.inner_rml = entry.Name

			na_el:AddEventListener("click", function(_, _, _)
				self:selectControl(i)
			end)

			li_el:AppendChild(na_el)

			--build the binds divs
			local bindings = entry.Bindings

			for j = 1, #bindings do
				local bi_el = self.Document:CreateElement("div")
				bi_el.id = "bind_" .. j .. "_" .. i
				bi_el:SetClass("bind_display", true)
				bi_el:SetClass("button_3", true)
				bi_el.inner_rml = bindings[j]

				bi_el:AddEventListener("click", function(_, _, _)
					self:selectBind(i, j)
				end)

				bi_el:AddEventListener("dblclick", function(_, _, _)
					self:bindKey(i, j)
				end)

				li_el:AppendChild(bi_el)
			end

			--on first run save total number of bindings
			if self.NumBinds == nil then
				self.NumBinds = #bindings
			end

		end
	end

end

--- Changes the currently displayed tab and updates the UI
--- @param tab number The index of the tab to display. Should be one of the TAB_TYPE enumerations
--- @return nil
function ControlConfigController:changeSection(tab)

	local validPromptTypes = {
		[ControlConfigController.TAB_TYPE_TARGET] = true,
		[ControlConfigController.TAB_TYPE_SHIP] = true,
		[ControlConfigController.TAB_TYPE_WEAPON] = true,
		[ControlConfigController.TAB_TYPE_MISC] = true,
	}

	-- Check if the path is valid
	assert(validPromptTypes[tab], "Invalid tab type! Got '" .. tab .. "'")

	--uncheck all tabs
	self.Document:GetElementById("target_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("ship_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("weapon_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("misc_btn"):SetPseudoClass("checked", false)

	--uncheck all modifiers
	self.Document:GetElementById("alt_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("shift_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("invert_btn"):SetPseudoClass("checked", false)

	--set selections to nil
	self.CurrentControl = nil
	self.CurrentBind = nil
	self.PreviousControl = nil
	self.CurrentTab = tab

	self:checkLocks()

	if tab == 0 then
		self.Document:GetElementById("target_btn"):SetPseudoClass("checked", true)
	elseif tab == 1 then
		self.Document:GetElementById("ship_btn"):SetPseudoClass("checked", true)
	elseif tab == 2 then
		self.Document:GetElementById("weapon_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("misc_btn"):SetPseudoClass("checked", true)
		--just in case
		tab = 3
	end

	ScpuiSystem:clearEntries(self.Document:GetElementById("list_items_ul"))
	self:initKeysList(tab)

	self:checkConflict()
end

--- Changes the currently displayed tab and updates the UI. Called by the RML
--- @param tab number The index of the tab to display. Should be one of the TAB_TYPE enumerations
--- @return nil
function ControlConfigController:change_section(tab)
	self:changeSection(tab)
end

--- Select a control from the list and update the UI
--- @param idx number | nil The index of the control to select
--- @return nil
function ControlConfigController:selectControl(idx)

	self.CurrentControl = idx
	self.CurrentBind = nil

	if self.PreviousControl == nil then
		self.PreviousControl = idx
	else
		local previous_control_id = "name_" .. self.PreviousControl
		self.Document:GetElementById(previous_control_id):SetPseudoClass("checked", false)

		for i = 1, self.NumBinds do
			local previous_bind_id = "bind_" .. i .. "_" .. self.PreviousControl
			self.Document:GetElementById(previous_bind_id):SetPseudoClass("checked", false)
			self.Document:GetElementById(previous_bind_id):SetPseudoClass("enabled", false)
		end

		self.PreviousControl = idx
	end

	local control_id = "name_" .. self.PreviousControl
	self.Document:GetElementById(control_id):SetPseudoClass("checked", true)

	for i = 1, self.NumBinds do
		local bind_id = "bind_" .. i .. "_" .. self.PreviousControl
		self.Document:GetElementById(bind_id):SetPseudoClass("checked", true)
	end

	self:checkModifiers()
	self:checkConflict()
	self:checkLocks()
	self:checkPresets()
end

--- Select a specific bind from the list and update the UI
--- @param idx number | nil The index of the control to select
--- @param bind number The index of the bind to select
--- @return nil
function ControlConfigController:selectBind(idx, bind)

	self.CurrentControl = idx
	self.CurrentBind = bind

	if self.PreviousControl == nil then
		self.PreviousControl = idx
	else
		local previous_control_id = "name_" .. self.PreviousControl
		self.Document:GetElementById(previous_control_id):SetPseudoClass("checked", false)

		for i = 1, self.NumBinds do
			local previous_bind_id = "bind_" .. i .. "_" .. self.PreviousControl
			self.Document:GetElementById(previous_bind_id):SetPseudoClass("checked", false)
			self.Document:GetElementById(previous_bind_id):SetPseudoClass("enabled", false)
		end

		self.PreviousControl = idx
	end

	local control_id = "name_" .. self.PreviousControl
	self.Document:GetElementById(control_id):SetPseudoClass("checked", true)

	for i = 1, self.NumBinds do
		local bind_id = "bind_" .. i .. "_" .. self.PreviousControl
		if i == bind then
			self.Document:GetElementById(bind_id):SetPseudoClass("enabled", true)
		else
			self.Document:GetElementById(bind_id):SetPseudoClass("checked", true)
		end
	end

	self:checkModifiers()
	self:checkConflict()
	self:checkLocks()
	self:checkPresets()
end

--- Iterate over all control binds and check for conflicts. If a conflict is found, display it on the UI
--- @return nil
function ControlConfigController:checkConflict()

	self.Conflict = false
	for i = 1, #ui.ControlConfig.ControlConfigs do
		local entry = ui.ControlConfig.ControlConfigs[i]
		if entry.Conflicted ~= nil then
			self.Conflict = true
		end
	end

	--no conflicts, bail
	if self.Conflict == false then
		self.Document:GetElementById("conflict_warning").inner_rml = ""
		self.Document:GetElementById("conflict_description").inner_rml = ""
		return
	end

	--nothing selected, bail
	if self.CurrentControl == nil then
		self.Document:GetElementById("conflict_description").inner_rml = ""
		return
	end

	self.Document:GetElementById("conflict_warning").inner_rml = ba.XSTR("CONFLICT!", 888574)

	local conflict = ui.ControlConfig.ControlConfigs[self.CurrentControl].Conflicted

	if conflict ~= nil then
		self.Document:GetElementById("conflict_description").inner_rml = conflict
	else
		self.Document:GetElementById("conflict_description").inner_rml = ""
	end
end

--- Check all control modifiers. Shift, Alt, and Invert
--- @return nil
function ControlConfigController:checkModifiers()
	self:checkShifts()
	self:checkAlts()
	self:checkInverts()
end

--- Locked or unlock UI controls based on the current selection
--- @return nil
function ControlConfigController:checkLocks()
	local general_lock = false
	local invert_lock = false
	local conflict_lock = false
	local modifier_lock = false
	if self.CurrentControl ~= nil then
		general_lock = true
		if ui.ControlConfig.ControlConfigs[self.CurrentControl].Conflicted ~= nil then
			conflict_lock = true
		end
		if ui.ControlConfig.ControlConfigs[self.CurrentControl].IsAxis == true then
			invert_lock = true
		else
			modifier_lock = true
		end
	end

	--conflict
	self.Document:GetElementById("clear_conflict_lock"):SetClass("hidden", conflict_lock)

	--invert
	self.Document:GetElementById("invert_lock"):SetClass("hidden", invert_lock)

	--modifier
	self.Document:GetElementById("alt_lock"):SetClass("hidden", modifier_lock)
	self.Document:GetElementById("shift_lock"):SetClass("hidden", modifier_lock)

	--rest
	self.Document:GetElementById("clear_selected_lock"):SetClass("hidden", general_lock)
	self.Document:GetElementById("bind_lock"):SetClass("hidden", general_lock)
end

--- Update the Shift button on the UI based on the current selection
--- @return nil
function ControlConfigController:checkShifts()

	local shifted = ui.ControlConfig.ControlConfigs[self.CurrentControl].Shifted

	if shifted then
		self.Document:GetElementById("shift_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("shift_btn"):SetPseudoClass("checked", false)
	end

end

--- Update the Alt button on the UI based on the current selection
--- @return nil
function ControlConfigController:checkAlts()

	local alted = ui.ControlConfig.ControlConfigs[self.CurrentControl].Alted

	if alted then
		self.Document:GetElementById("alt_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("alt_btn"):SetPseudoClass("checked", false)
	end

end

--- Update the Invert button on the UI based on the current selection
--- @return nil
function ControlConfigController:checkInverts()

	local inverted = false
	if self.CurrentBind ~= nil then
		inverted = ui.ControlConfig.ControlConfigs[self.CurrentControl]:isBindInverted(self.CurrentBind)
	end

	if inverted then
		self.Document:GetElementById("invert_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("invert_btn"):SetPseudoClass("checked", false)
	end

end

--- Toggle the Alt modifier for the current bind in FSO and update the UI
--- @return nil
function ControlConfigController:toggle_alt()

	if self.CurrentControl == nil then
		return
	else --maybe also check that alt is allowed
		ui.ControlConfig.ControlConfigs[self.CurrentControl]:toggleAlted()
		local idx = self.CurrentControl
		self:changeSection(self.CurrentTab)
		self:selectControl(idx)
	end

end

--- Toggle the Shift modifier for the current bind in FSO and update the UI
--- @return nil
function ControlConfigController:toggle_shift()

	if self.CurrentControl == nil then
		return
	else --maybe also check that shift is allowed
		ui.ControlConfig.ControlConfigs[self.CurrentControl]:toggleShifted()
		local idx = self.CurrentControl
		self:changeSection(self.CurrentTab)
		self:selectControl(idx)
	end

end

--- Toggle the Invert modifier for the current bind in FSO and update the UI
--- @return nil
function ControlConfigController:toggle_invert()

	if self.CurrentControl == nil then
		return
	else --maybe also check that invert is allowed
		if self.CurrentBind == nil then
			return
		else
			ui.ControlConfig.ControlConfigs[self.CurrentControl]:toggleInverted(self.CurrentBind)
			local idx = self.CurrentControl
			local item = self.CurrentBind
			self:changeSection(self.CurrentTab)
			self:selectBind(idx, item)
		end
	end

end

--- Clear all binds that conflict with the current selection in FSO and update the UI
--- @return nil
function ControlConfigController:clear_conflict()

	if self.CurrentControl == nil then
		return
	else --maybe also check that shift is allowed
		ui.ControlConfig.ControlConfigs[self.CurrentControl]:clearConflicts()
		local idx = self.CurrentControl
		self:changeSection(self.CurrentTab)
		self:selectControl(idx)
	end

end

--- Clear the currently selected bind in FSO and update the UI
--- @return nil
function ControlConfigController:clear_selected()

	if self.CurrentControl == nil then
		return
	else --maybe also check that shift is allowed
		local idx = self.CurrentControl
		local bind = self.CurrentBind
		if bind == nil then
			bind = 1
		else
			bind = bind + 1 --convert 1/2 to 2/3
		end

		ui.ControlConfig.ControlConfigs[self.CurrentControl]:clearBind(bind)
		self:changeSection(self.CurrentTab)
		if bind == 3 then
			self:selectControl(idx)
		else
			self:selectBind(idx, bind)
		end
	end

end

--- Build a show a prompt box confirming the player wants to clear all binds
--- @return nil
function ControlConfigController:clear_all()

	self.PromptControl = ControlConfigController.PROMPT_TYPE_CLEAR_ALL_BINDS

	local text = "Are you sure you want to clear all binds?"
	local title = ""
	---@type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Yes", 888296),
		Value = true,
		Keypress = string.sub(ba.XSTR("Yes", 888296), 1, 1)
	}
	buttons[2] = {
		Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
		Text = ba.XSTR("No", 888298),
		Value = false,
		Keypress = string.sub(ba.XSTR("No", 888298), 1, 1)
	}

	ScpuiSystem.data.memory.control_config.NextDialog = {
		Text = text,
		Title = title,
		Input = false,
		Buttons_List = buttons
	}

end

--- Clear all binds in FSO and update the UI
--- @return nil
function ControlConfigController:clearAllActual()

	ui.ControlConfig.clearAll()

	local idx = self.CurrentControl

	self:changeSection(self.CurrentTab)

	if idx ~= nil then
		self:selectControl(idx)
	end
end

--- Undo the last control change and update the UI
--- @return nil
function ControlConfigController:undo_change()

	ui.ControlConfig.undoLastChange()

	local idx = self.CurrentControl
	local bind = self.CurrentBind

	self:changeSection(self.CurrentTab)

	if idx ~= nil then
		self:selectControl(idx)
	else
		if bind ~= nil then
			self:selectBind(idx, bind)
		end
	end

end

--- When Exit is pressed, check for conflicts and unsaved changes. Prompt the user if needed, else accept the bindings and return to the previous game state
--- @param element Element The element that was clicked
--- @return nil
function ControlConfigController:exit_pressed(element)

	local continue = true

	if self.Conflict then
		continue = false

		local text = "You must resolve conflicts first!"
		local title = ""
		---@type dialog_button[]
		local buttons = {}
		buttons[1] = {
			Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
			Text = ba.XSTR("Okay", 888290),
			Value = true,
			Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
		}

		ScpuiSystem.data.memory.control_config.NextDialog = {
			Text = text,
			Title = title,
			Input = false,
			Buttons_List = buttons
		}
	end
	if ui.ControlConfig.getCurrentPreset() == nil then
		self.PromptControl = ControlConfigController.PROMPT_TYPE_GET_PRESET_NAME
		continue = false

		local text = "You must save your controls as a preset. Do so now?"
		local title = ""
		---@type dialog_button[]
		local buttons = {}
		buttons[1] = {
			Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
			Text = ba.XSTR("Yes", 888296),
			Value = true,
			Keypress = string.sub(ba.XSTR("Yes", 888296), 1, 1)
		}
		buttons[2] = {
			Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
			Text = ba.XSTR("No", 888298),
			Value = false,
			Keypress = string.sub(ba.XSTR("No", 888298), 1, 1)
		}

		ScpuiSystem.data.memory.control_config.NextDialog = {
			Text = text,
			Title = title,
			Input = false,
			Buttons_List = buttons
		}
	end

	if continue then
		if ui.ControlConfig.acceptBinding() then
			ui.playElementSound(element, "click", "success")
			ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
			ui.ControlConfig.closeControlConfig()
		else
			local text = "Something went wrong, please try again!"
			local title = ""
			---@type dialog_button[]
			local buttons = {}
			buttons[1] = {
				Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
				Text = ba.XSTR("Okay", 888290),
				Value = true,
				Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
			}

			ScpuiSystem.data.memory.control_config.NextDialog = {
				Text = text,
				Title = title,
				Input = false,
				Buttons_List = buttons
			}
		end
	end

end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function ControlConfigController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
		ui.ControlConfig.cancelBinding()
		ui.ControlConfig.closeControlConfig()
	elseif keys.Z and keys.Ctrl then
		self:undo_change()
	end
end

--- Start a search for a bind. Disables the UI until a keypress is detected. If a bind matches the key, then switch to that tab and highlight that control
--- @return nil
function ControlConfigController:search_for_bind()

	async.run(function()
        ui.disableInput()

        --Do anything needed to lock the UI during the binding phase

		local search = 0

        while (search == 0) do
			search = ui.ControlConfig.searchBinds()
			async.await(async.yield())
		end

        --Do anything needed to unlock the UI after the binding phase

		if search > 0 then

			local bind = ui.ControlConfig.ControlConfigs[search]

			ui.enableInput(ScpuiSystem.data.Context)
			self:changeSection(bind.Tab)
			self:selectControl(search)
		else
			ui.enableInput(ScpuiSystem.data.Context)
		end
    end, async.OnFrameExecutor)

end

--- If we have a dialog to display then show it and wait for user input
--- @return nil
function ControlConfigController:maybeShowDialogs()
	if ScpuiSystem.data.memory.control_config.NextDialog ~= nil then
		-- Use utils.copy to create copies of the dialog data
		local dialogText = Utils.copy(ScpuiSystem.data.memory.control_config.NextDialog.Text) --- @type string
		local dialogTitle = Utils.copy(ScpuiSystem.data.memory.control_config.NextDialog.Title) --- @type string
		local dialogInput = Utils.copy(ScpuiSystem.data.memory.control_config.NextDialog.Input) --- @type boolean
		local dialogButtons = Utils.copy(ScpuiSystem.data.memory.control_config.NextDialog.Buttons_List) --- @type dialog_button[]

		---@type dialog_setup
		local params = {
			Title = dialogTitle,
			Text = dialogText,
			Buttons_List = dialogButtons,
			Input = dialogInput,
			EscapeValue = "",
		}

		ScpuiSystem:showDialog(self, params, function(response)
			ScpuiSystem.data.memory.control_config.DialogResponse = response
		end)

		ScpuiSystem.data.memory.control_config.NextDialog = nil
	end
end

--- Handle the response from the dialog prompts
--- @param response any The response from the dialog
--- @return nil
function ControlConfigController:dialogResponse(response)
	local path = self.PromptControl
	self.PromptControl = ControlConfigController.PROMPT_TYPE_NONE

	ScpuiSystem.data.memory.control_config.DialogResponse = nil

	local validPromptTypes = {
		[ControlConfigController.PROMPT_TYPE_NONE] = true,
		[ControlConfigController.PROMPT_TYPE_NEW_PRESET] = true,
		[ControlConfigController.PROMPT_TYPE_CLONE_PRESET] = true,
		[ControlConfigController.PROMPT_TYPE_CLEAR_ALL_BINDS] = true,
		[ControlConfigController.PROMPT_TYPE_GET_PRESET_NAME] = true,
		[ControlConfigController.PROMPT_TYPE_DELETE_PRESET] = true,
		[ControlConfigController.PROMPT_TYPE_OVERWRITE_NEW_PRESET] = true,
		[ControlConfigController.PROMPT_TYPE_OVERWRITE_CLONE_PRESET] = true,
	}

	-- Check if the path is valid
	assert(validPromptTypes[path], "Invalid prompt type! Got '" .. path .. "'")

	if path == ControlConfigController.PROMPT_TYPE_NEW_PRESET then
		self:newPreset(response)
	elseif path == ControlConfigController.PROMPT_TYPE_CLONE_PRESET then
		self:clonePreset(response)
	elseif path == ControlConfigController.PROMPT_TYPE_CLEAR_ALL_BINDS then
		if response == true then
			self:clearAllActual()
		end
	elseif path == ControlConfigController.PROMPT_TYPE_GET_PRESET_NAME then
		if response == true then
			self:getPresetInput(ControlConfigController.PROMPT_TYPE_NEW_PRESET)
		end
	elseif path == ControlConfigController.PROMPT_TYPE_DELETE_PRESET then
		if response == true then
			self:deletePreset()
		end
	elseif path == ControlConfigController.PROMPT_TYPE_OVERWRITE_NEW_PRESET then
		if response ~= false then
			self:newPreset(response, true)
		end
	elseif path == ControlConfigController.PROMPT_TYPE_OVERWRITE_CLONE_PRESET then
		if response ~= false then
			self:clonePreset(response, true)
		end
	end
end

--- Prepare to bind a key. Clear the current bind and start the binding process
--- @return nil
function ControlConfigController:begin_bind()
	if self.CurrentControl == nil then
		return
	end

	if self.CurrentBind == nil then
		self.CurrentBind = 1
	end

	self:bindKey(self.CurrentControl, self.CurrentBind)
end

--- Begin the process of binding a key. Disables the UI until a keypress is detected. If a key is detected, then bind it to the current control
--- @param idx number The index of the control to bind
--- @param item number The index of the bind to bind to the control
--- @return nil
function ControlConfigController:bindKey(idx, item)

	local entry = ui.ControlConfig.ControlConfigs[idx]
	local bind_id = "bind_" .. item .. "_" .. idx

	self.Document:GetElementById(bind_id).inner_rml = ">>"

	async.run(function()
        ui.disableInput()

        --Do anything needed to lock the UI during the binding phase

		local status = 0

        while (status == 0) do
			status = ui.ControlConfig.ControlConfigs[idx]:detectKeypress(item + 1)
			async.await(async.yield())
		end

        --Do anything needed to unlock the UI after the binding phase

		ui.enableInput(ScpuiSystem.data.Context)
		if status < 0 then
			local text = "That key cannot be bound! Please try again."
			local title = ""
			---@type dialog_button[]
			local buttons = {}
			buttons[1] = {
				Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
				Text = ba.XSTR("Okay", 888290),
				Value = "",
				Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
			}

			ScpuiSystem.data.memory.control_config.NextDialog = {
				Text = text,
				Title = title,
				Input = false,
				Buttons_List = buttons
			}
		end
		self:changeSection(self.CurrentTab)
		self:selectBind(idx, item)
    end, async.OnFrameExecutor)

end

--- Called when the screen is being unloaded
--- @return nil
function ControlConfigController:unload()
	Topics.controlconfig.unload:send(self)
end

ScpuiSystem:addHook("On Frame", function()
	if ScpuiSystem.data.memory.control_config.NextDialog ~= nil then
		ScpuiSystem.data.memory.control_config.Context:maybeShowDialogs()
	elseif ScpuiSystem.data.memory.control_config.DialogResponse ~= nil then
		ScpuiSystem.data.memory.control_config.Context:dialogResponse(ScpuiSystem.data.memory.control_config.DialogResponse)
	end
end, {State="GS_STATE_CONTROL_CONFIG"}, function()
    return false
end)

return ControlConfigController
