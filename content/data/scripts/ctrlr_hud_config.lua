-----------------------------------
--Controller for the HUD Config UI
-----------------------------------

local Topics = require("lib_ui_topics")

local class = require("lib_class")

local HudConfigController = class()

HudConfigController.SLIDER_RED = 1 --- @type number Red slider id
HudConfigController.SLIDER_GREEN = 2 --- @type number Green slider id
HudConfigController.SLIDER_BLUE = 3 --- @type number Blue slider id
HudConfigController.SLIDER_ALPHA = 4 --- @type number Alpha slider id

HudConfigController.GAUGE_FLAG_ON = 1 --- @type number Show gauge flag
HudConfigController.GAUGE_FLAG_OFF = 2 --- @type number Hide gauge flag
HudConfigController.GAUGE_FLAG_POPUP = 3 --- @type number Popup gauge flag

HudConfigController.PROMPT_GET_PRESET_NAME = 1 --- @type number Get preset name prompt

--- Called by the class constructor
--- @return nil
function HudConfigController:init()
	self.Document = nil --- @type Document RML document
	self.DefaultConfigFile = "hud_3.hcf" --- @type string Default config file
	self.PresetColors = {} --- @type scpui_hud_config_color[] Preset colors
	self.RedValue = 0 --- @type number Red color value
	self.GreenValue = 0 --- @type number Green color value
	self.BlueValue = 0 --- @type number Blue color value
	self.AlphaValue = 0 --- @type number Alpha color value
	self.Mutex = true --- @type boolean	Prevents circular updates
	self.SelectAll = false --- @type boolean Select all gauges
	self.PreviousPreset = nil --- @type number The previous preset index
	self.CurrentPreset = nil --- @type number The current preset index
	self.CurrentPresetName = nil --- @type string The current preset name
	self.SelectedGaugeName = nil --- @type string The selected gauge name
	self.SelectedGauge = nil --- @type gauge_config The selected gauge
	self.Click = false --- @type boolean Mouse click flag
	self.PreviousAlphaValue = 0 --- @type number Previous alpha value
	self.PromptControl = nil --- @type number Used to control the prompt dialog

	--- Setup our built-in presets
	--green
	self.PresetColors[1] = {
		Name = "green",
		R = 0,
		G = 255,
		B = 0,
		A = 255
	}
	--amber
	self.PresetColors[2] = {
		Name = "amber",
		R = 255,
		G = 297,
		B = 0,
		A = 255
	}
	--blue
	self.PresetColors[3] = {
		Name = "blue",
		R = 67,
		G = 123,
		B = 203,
		A = 255
	}

	--- Make sure to clear the memory data
	ScpuiSystem.data.memory.hud_config = {
		Ready = false,
	}
end

--- Called by the RML document
--- @param document Document
function HudConfigController:initialize(document)

    self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	ScpuiSystem.data.memory.hud_config.Mx = 0
	ScpuiSystem.data.memory.hud_config.My = 0
	ScpuiSystem.data.memory.hud_config.Draw = true
	ScpuiSystem.data.memory.hud_config.Parent = self.Document:GetElementById("hud_drawn_content")

	self.Mutex = true -- stop circular updates at start

	self:sliderValueUpdate(self.RedValue, self.GreenValue, self.BlueValue, self.AlphaValue)

	self.Mutex = false -- now allow updates

	self.Document:GetElementById("popup_btn"):SetClass("hidden", true)
	self.Document:GetElementById("hud_on_btn"):SetClass("hidden", true)
	self.Document:GetElementById("hud_off_btn"):SetClass("hidden", true)

	self:drawHUD() -- Call this once to make sure all data is initialized

	self:initPresets()

	Topics.hudconfig.initialize:send(self)
end

--- Initialize our color presets
--- @return nil
function HudConfigController:initPresets()
	local parent_el = self.Document:GetElementById("list_presets_ul")

	ScpuiSystem:clearEntries(parent_el)

	self.PreviousPreset = nil

	for i = 1, #self.PresetColors do
		local entry = self.PresetColors[i]

		local li_el = self.Document:CreateElement("li")
		li_el.id = "preset_" .. i

		li_el:SetClass("preset_list_element", true)
		li_el:SetClass("button_1", true)

		li_el.inner_rml = entry.Name

		li_el:AddEventListener("click", function(_, _, _)
				self:selectPreset(i, entry.Name)
			end)

		parent_el:AppendChild(li_el)
	end

	for i = 1, #ui.HudConfig.GaugePresets do
		local entry = ui.HudConfig.GaugePresets[i]

		local li_el = self.Document:CreateElement("li")
		li_el.id = "preset_" .. i + #self.PresetColors

		li_el:SetClass("preset_list_element", true)
		li_el:SetClass("button_1", true)

		li_el.inner_rml = entry.Name

		li_el:AddEventListener("click", function(_, _, _)
				self:selectPreset(i + #self.PresetColors, entry.Name)
			end)

		parent_el:AppendChild(li_el)
	end

end

--- Set a all gauges to a preset color setting
--- @param idx number The preset index
--- @return nil
function HudConfigController:setColor(idx)

	local entry = self.PresetColors[idx]

	self.RedValue = entry.R
	self.GreenValue = entry.G
	self.BlueValue = entry.B
	self.AlphaValue = entry.A

	for i = 1, #ui.HudConfig.GaugeConfigs do
		self:changeGaugeColor(ui.HudConfig.GaugeConfigs[i])
	end

end

--- Select a preset color setting, either file or built-in color
--- @param idx number The preset index
--- @param name string The preset name
--- @return nil
function HudConfigController:selectPreset(idx, name)

	--deselect all if all is selected
	if self.SelectAll == true then
		self:select_all()
	end

	if self.CurrentPreset == idx then
		return
	end

	self.CurrentPreset = idx

	if self.PreviousPreset == nil then
		self.PreviousPreset = idx
	else
		self.Document:GetElementById("preset_" .. self.PreviousPreset):SetPseudoClass("checked", false)

		self.PreviousPreset = idx
	end

	self.Document:GetElementById("preset_" .. self.PreviousPreset):SetPseudoClass("checked", true)

	--is this a built-in preset?
	local builtin = 0
	for i = 1, #self.PresetColors do
		local entry = self.PresetColors[i]

		if entry.Name == name then
			builtin = i
			break
		end
	end

	if builtin > 0 then
		self:setColor(builtin)
	else
		ui.HudConfig.usePresetFile(name)
	end

	self.CurrentPresetName = name

	--causes nothing to be selected and updates the UI accordingly
	self:mouse_click()

end

--- Unselect all presets in the preset list
--- @return nil
function HudConfigController:unselectAllPresets()
	if not self.Click then
		if self.PreviousPreset ~= nil then
			local presetID = "preset_" .. self.PreviousPreset
			self.Document:GetElementById(presetID):SetPseudoClass("checked", false)
		end

		self.PreviousPreset = nil
		self.CurrentPreset = nil
		self.CurrentPresetName = nil
	end
end

--- Save the current settings as a preset file
--- @param name string The preset name
--- @return nil
function HudConfigController:savePreset(name)

	local continue = true

	--Make sure preset names have no spaces and aren't longer than 28 characters
	name = name:gsub("%s+", "")
	if #name > 28 then
		name = name:sub(1, 28)
	end

	for i = 1, #ui.HudConfig.GaugePresets do
		local entry = ui.HudConfig.GaugePresets[i]
		if entry.Name == name then
			continue = false
			break
		end
	end

	--is this a built-in preset?
	for i = 1, #self.PresetColors do
		local entry = self.PresetColors[i]

		if entry.Name == name then
			continue = false
			break
		end
	end

	if continue == true then
		ui.HudConfig.saveToPreset(name)
		self:initPresets()
	else
		local text = "An identical preset already exists!"
		local title = ""
		--- @type dialog_button[]
		local buttons = {}
		buttons[1] = {
			Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
			Text = ba.XSTR("Okay", 888290),
			Value = "",
			Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
		}

		--- @type dialog_setup
		local params = {
			Title = title,
			Text = text,
			Buttons_List = buttons,
		}

		ScpuiSystem:showDialog(self, params, function(response)
            self:dialogReponse(response)
        end)
	end

end

--- Called by the RML to delete the selected preset
--- @return nil
function HudConfigController:delete_preset()

	if self.CurrentPresetName == nil then
		return
	end

	local preset = self.CurrentPresetName

	for i = 1, #ui.HudConfig.GaugePresets do
		local entry = ui.HudConfig.GaugePresets[i]

		if entry.Name == preset then
			entry:deletePreset()
			break
		end
	end

	self:initPresets()

end

--- Called by the RML to exit the HUD Config UI
--- @param element Element
--- @return nil
function HudConfigController:exit(element)

    ui.playElementSound(element, "click", "success")
	ScpuiSystem.data.memory.hud_config.Draw = nil
	ui.HudConfig.closeHudConfig(true)
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])

end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function HudConfigController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()
		ScpuiSystem.data.memory.hud_config.Draw = nil
		ui.HudConfig.closeHudConfig(false)
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
	elseif keys.LEFT then
		ui.HudConfig.selectPrevHud()
	elseif keys.RIGHT then
		ui.HudConfig.selectNextHud()
	end
end

--- Tells FSO to draw the gauges for the HUD Config UI
--- @return nil
function HudConfigController:drawHUD()
	if not ScpuiSystem.data.memory.hud_config.Ready then
		local hud_el = ScpuiSystem.data.memory.hud_config.Parent

		if hud_el == nil then
			ScpuiSystem.data.memory.hud_config.Draw = false
			return
		end

		--get coords to draw at
		local hx = ScpuiSystem:getAbsoluteLeft(hud_el)
		local hy = ScpuiSystem:getAbsoluteTop(hud_el)
		local hw = hud_el.client_width
		local hh = hud_el.client_height

		--increase those coords by percentage
		hx = hx --+ (0.02 * hx)
		hy = hy --+ (-0.2 * hy)
		hw = hw --+ (0.2 * hw)
		hh = hh --+ (0.2 * hh)

		ui.HudConfig.initHudConfig(hx, hy, hw, hh)

		ScpuiSystem.data.memory.hud_config.Ready = true
	end

	if ScpuiSystem.data.memory.hud_config ~= nil then
		if ScpuiSystem.data.memory.hud_config.Draw == false then
			return
		end
		ScpuiSystem.data.memory.hud_config.Gauge = ui.HudConfig.drawHudConfig(ScpuiSystem.data.memory.hud_config.Mx, ScpuiSystem.data.memory.hud_config.My)
	end
end

--- Change a gauge's color
--- @param gauge gauge_config The gauge to change
--- @return nil
function HudConfigController:changeGaugeColor(gauge)
	local color = gr.createColor(self.RedValue, self.GreenValue, self.BlueValue, self.AlphaValue)
	gauge.CurrentColor = color
end

--- Convert a slider value to a color value
--- @param num number The slider value
--- @return integer value The color value
function HudConfigController:convertSliderToVal(num)
	--reverse the order first
	local rev = 1 - num
	return math.floor(rev * 255)
end

--- Convert a color value to a slider value
--- @param num integer The color value
--- @return number value The slider value
function HudConfigController:convertValToSlider(num)
	local rev = num / 255
	--now reverse the value
	return 1 - rev
end

--- Recalculate what the alpha value should be based on the current colors
--- @return nil
function HudConfigController:recalculateAlpha()
	self.AlphaValue = math.floor((self.RedValue + self.GreenValue + self.BlueValue) / 3)
end

--- Recalculate what the color values should be based on the current alpha value
--- @return nil
function HudConfigController:recalculateColors()
	if self.AlphaValue > self.PreviousAlphaValue then
		local pct = (self.AlphaValue - self.PreviousAlphaValue) / (255 - self.PreviousAlphaValue)

		self.RedValue = self.RedValue + ((255 - self.RedValue) * pct)
		self.GreenValue = self.GreenValue + ((255 - self.GreenValue) * pct)
		self.BlueValue = self.BlueValue + ((255 - self.BlueValue) * pct)
	else
		local pct = (self.PreviousAlphaValue - self.AlphaValue) / self.PreviousAlphaValue

		self.RedValue = self.RedValue - (self.RedValue * pct)
		self.GreenValue = self.GreenValue - (self.GreenValue * pct)
		self.BlueValue = self.BlueValue - (self.BlueValue * pct)
	end
end

--- Called by the RML to update a slider value
--- @param element Element The slider element
--- @param event Event The event that was triggered
--- @param id number The slider id. Should be one of the SLIDER_ enumerations
--- @return nil
function HudConfigController:slider_update(element, event, id)
	if id == self.SLIDER_RED then
		if self.RedValue ~= self:convertSliderToVal(event.parameters.value) and not self.Mutex then
			self.Mutex = true
			self.RedValue = self:convertSliderToVal(event.parameters.value)
			self:recalculateAlpha()
		else
			return
		end
	end
	if id == self.SLIDER_GREEN then
		if self.GreenValue ~= self:convertSliderToVal(event.parameters.value) and not self.Mutex then
			self.Mutex = true
			self.GreenValue = self:convertSliderToVal(event.parameters.value)
			self:recalculateAlpha()
		else
			return
		end
	end
	if id == self.SLIDER_BLUE then
		if self.BlueValue ~= self:convertSliderToVal(event.parameters.value) and not self.Mutex then
			self.Mutex = true
			self.BlueValue = self:convertSliderToVal(event.parameters.value)
			self:recalculateAlpha()
		else
			return
		end
	end
	if id == self.SLIDER_ALPHA then
		if self.AlphaValue ~= self:convertSliderToVal(event.parameters.value) and not self.Mutex then
			self.Mutex = true
			self.PreviousAlphaValue = self.AlphaValue
			self.AlphaValue = self:convertSliderToVal(event.parameters.value)
			self:recalculateColors()
		else
			return
		end
	end

	if self.SelectAll then
		for i = 1, #ui.HudConfig.GaugeConfigs do
			self:changeGaugeColor(ui.HudConfig.GaugeConfigs[i])
		end
	else
		if self.SelectedGaugeName ~= nil then
			self:changeGaugeColor(self.SelectedGauge)
		end
	end

	self:sliderValueUpdate(self.RedValue, self.GreenValue, self.BlueValue, self.AlphaValue)

	self.Mutex = false
	self:unselectAllPresets()
end

--- Update the slider values based on the color values
--- @param r number The red color value
--- @param g number The green color value
--- @param b number The blue color value
--- @param a number The alpha color value
--- @return nil
function HudConfigController:sliderValueUpdate(r, g, b, a)
	Element.As.ElementFormControlInput(self.Document:GetElementById("r_slider")).value = self:convertValToSlider(r)
	Element.As.ElementFormControlInput(self.Document:GetElementById("g_slider")).value = self:convertValToSlider(g)
	Element.As.ElementFormControlInput(self.Document:GetElementById("b_slider")).value = self:convertValToSlider(b)
	Element.As.ElementFormControlInput(self.Document:GetElementById("a_slider")).value = self:convertValToSlider(a)
end

--- Toggle the slider controls on or off
--- @param lock boolean Lock the controls
--- @return nil
function HudConfigController:lockColorControls(lock)
	local color_lock_el = self.Document:GetElementById("color_lock")

	if lock then
		color_lock_el:SetClass("locked", true)
		color_lock_el:SetClass("unlocked", false)
	else
		color_lock_el:SetClass("locked", false)
		color_lock_el:SetClass("unlocked", true)
	end
end

--- Called by the RML to set the gauge flags
--- @param flag number The flag to set. Should be one of the GAUGE_FLAG_ enumerations
--- @return nil
function HudConfigController:set_gauge_flags(flag)

	if flag == self.GAUGE_FLAG_ON then
		self.SelectedGauge.ShowGaugeFlag = true
		self:lockColorControls(false)
	end

	if flag == self.GAUGE_FLAG_OFF then
		self.SelectedGauge.ShowGaugeFlag = false
		self:lockColorControls(true)
	end

	if flag == self.GAUGE_FLAG_POPUP then
		self.SelectedGauge.PopupGaugeFlag = not self.SelectedGauge.PopupGaugeFlag
		self.SelectedGauge.ShowGaugeFlag = true
		self:lockColorControls(false)
	end

	self:setupButtonOptions()
	self:sliderValueUpdate(63, 63, 63, 63)
end

--- Toggles the popup option for the current gauge
--- @return nil
function HudConfigController:togglePopupOption()
	local popup_el = self.Document:GetElementById("popup_btn")

	if self.SelectedGauge.CanPopup then
		popup_el:SetClass("hidden", false)
	else
		popup_el:SetClass("hidden", true)
	end
end

--- Initialize the UI button options
--- @return nil
function HudConfigController:setupButtonOptions()
	local popup_el = self.Document:GetElementById("popup_btn")
	local hud_on_el = self.Document:GetElementById("hud_on_btn")
	local hud_off_el = self.Document:GetElementById("hud_off_btn")

	if self.SelectedGauge.PopupGaugeFlag then
		hud_on_el:SetPseudoClass("checked", false)
		hud_off_el:SetPseudoClass("checked", false)
		popup_el:SetPseudoClass("checked", true)
	else
		if self.SelectedGauge.ShowGaugeFlag then
			hud_on_el:SetPseudoClass("checked", true)
			hud_off_el:SetPseudoClass("checked", false)
			popup_el:SetPseudoClass("checked", false)
		else
			hud_on_el:SetPseudoClass("checked", false)
			hud_off_el:SetPseudoClass("checked", true)
			popup_el:SetPseudoClass("checked", false)
			self:lockColorControls(true)
		end
	end

	if self.SelectedGauge.UsesIffForColor then
		self:lockColorControls(true)
	end

end

--- Called by the RML to set the configuration back to default
--- @return nil
function HudConfigController:set_default()
	self:mouse_click()
	ui.HudConfig.setToDefault(self.DefaultConfigFile)
end

--- Called by the RML to select all gauges
--- @return nil
function HudConfigController:select_all()
	if self.SelectAll then
		self:mouse_click()
	else
		self:mouse_click()
		self.SelectAll = true
		self.Document:GetElementById("select_all_btn"):SetPseudoClass("checked", self.SelectAll)
		ui.HudConfig.selectAllGauges(self.SelectAll)
		self:lockColorControls(not self.SelectAll)
	end
end

--- Called by the RML to select a gauge. When click is try we capture the id of the gauge the mouse was over
--- @return nil
function HudConfigController:mouse_click()

	self.Document:GetElementById("hud_on_btn"):SetClass("hidden", true)
	self.Document:GetElementById("hud_off_btn"):SetClass("hidden", true)
	self.Document:GetElementById("popup_btn"):SetClass("hidden", true)
	self:lockColorControls(false)
	self.SelectAll = false
	ui.HudConfig.selectNoGauges()
	self.Document:GetElementById("select_all_btn"):SetPseudoClass("checked", self.SelectAll)

	self.Click = true

	if ScpuiSystem.data.memory.hud_config.Gauge then
		self.SelectedGaugeName = nil
		self.SelectedGauge = ScpuiSystem.data.memory.hud_config.Gauge
		self.SelectedGauge:setSelected(true)

		local color = self.SelectedGauge.CurrentColor
		self:sliderValueUpdate(color.Red, color.Blue, color.Green, color.Alpha)
		self.SelectedGaugeName = self.SelectedGauge.Name

		if self.SelectedGaugeName ~= nil then
			self.Document:GetElementById("hud_on_btn"):SetClass("hidden", false)
			self.Document:GetElementById("hud_off_btn"):SetClass("hidden", false)

			self:togglePopupOption()
			self:setupButtonOptions()
		end
	end

	self.Click = false
end

--- Called by the RML whenever the mouse moves over the HUD Gauges element
--- @param element Element The HUD Gauges element
--- @param event Event The event that was triggered
--- @return nil
function HudConfigController:mouse_move(element, event)

	if ScpuiSystem.data.memory.hud_config ~= nil then
		ScpuiSystem.data.memory.hud_config.Mx = event.parameters.mouse_x
		ScpuiSystem.data.memory.hud_config.My = event.parameters.mouse_y
	end

end

--- Create a dialog box to get a preset name
--- @return nil
function HudConfigController:get_preset_input()

	self.PromptControl = self.PROMPT_GET_PRESET_NAME

	local text = "Please enter a name for the preset: "
	local title = ""
	--- @type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Okay", 888290),
		Value = "",
		Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
	}

	--- @type dialog_setup
	local params = {
		Title = title,
		Text = text,
		Buttons_List = buttons,
		Input = true,
	}

	ScpuiSystem:showDialog(self, params, function(response)
		self:dialogReponse(response)
	end)
end

--- Handle dialog responses
--- @param response string The dialog response
--- @return nil
function HudConfigController:dialogResponse(response)
	local path = self.PromptControl
	self.PromptControl = nil
	ScpuiSystem.data.memory.hud_config.Draw = true
	if path == self.PROMPT_GET_PRESET_NAME then
		self:savePreset(response)
	end
end

--- Called when the screen is being unloaded
--- @return nil
function HudConfigController:unload()
	Topics.hudconfig.unload:send(self)
end

--- Create a hook to draw the hud gauges every frame
ScpuiSystem:addHook("On Frame", function()
	if ScpuiSystem.data.Render then
		HudConfigController:drawHUD()
	end
end, {State="GS_STATE_HUD_CONFIG"}, function()
    return false
end)

return HudConfigController
