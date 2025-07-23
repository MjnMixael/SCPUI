-----------------------------------
--Controller for the Options UI
-----------------------------------

local AsyncUtil = require("lib_async")
local DataSource = require("lib_datasource")
local Dialogs  = require("lib_dialogs")
local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local AbstractOptionsController = require("ctrlr_options_controls")

--- This multi controller is merged with the Companion Options Controller
local OptionsController = Class(AbstractOptionsController)

function OptionsController:init()
	self.Document = nil --- @type Document the RML document
	self.CustomValues = ScpuiSystem.data.ScpuiOptionValues --- @type custom_option_data Shorthand reference to the global options table
	self.CustomOptions = {} --- @type scpui_option_control[] A table of custom option controls that have been created
	self.GraphicsOptions = {} --- @type scpui_graphics_option_control[] A table of graphics option controls that have been created
	self.ModCustom = true --- @type boolean Whether or not the custom options have been modified
	self.GraphicsCustom = true --- @type boolean Whether or not the graphics options have been modified

	self.SelectedIpElement = nil --- @type Element The currently selected IP address element
	self.SubmittedIp = "" --- @type string The IP address that has been submitted
	self.IpInputElement = nil --- @type Element The IP address input element
	self.LoginChanged = false --- @type boolean Whether or not the login field has been modified
	self.PassChanged = false --- @type boolean Whether or not the password field has been modified
	self.SquadChanged = false --- @type boolean Whether or not the squad field has been modified

	self.GraphicsPresets = {
		"option_graphics_detail_element",
		"option_graphics_nebuladetail_element",
		"option_graphics_texture_element",
		"option_graphics_particles_element",
		"option_graphics_smalldebris_element",
		"option_graphics_shieldeffects_element",
		"option_graphics_stars_element",
		"option_graphics_lighting_element",
		"option_graphics_shadows_element",
		"option_graphics_anisotropy_element",
		"option_graphics_aamode_element",
		"option_graphics_msaasamples_element",
		"option_graphics_postprocessing_element",
		"option_graphics_lightshafts_element",
		"option_graphics_softparticles_element",
		"option_graphics_deferredlighting_element"
	}

	self.BuiltInGraphicsKeys = {
		"Graphics.NebulaDetail",
		"Graphics.Lighting",
		"Graphics.Detail",
		"Graphics.Texture",
		"Graphics.Particles",
		"Graphics.SmallDebris",
		"Graphics.ShieldEffects",
		"Graphics.Stars",
	};

	self.FontChoice = nil --- @type string The font class to be applied to the main background element

    self.DataSources = {} --- @type scpui_option_data_source[] A table of data sources for the options
    self.Options = {} --- @type scpui_option[] A table of custom options
    self.Categorized_Options = {
        Basic  = {}, --- @type scpui_option[] A table of basic options
        Graphics = {}, --- @type scpui_option[] A table of graphics options
        Misc  = {}, --- @type scpui_option[] A table of miscellaneous options
        Multi  = {} --- @type scpui_option[] A table of multi options
    }

	self.TooltipTimers = {} --- @type number[] A table of timers for the options UI
	self.TooltipWait = 5 --- @type number The time to wait before showing a tooltip
    self.OptionBackups = {} --- @class ValueDescription[] A table of mappings option->ValueDescription which contains backups of the original values for special options that apply their changes immediately

end

--- Called by the RML document
--- @param document Document
function OptionsController:initialize(document)
	AbstractOptionsController.initialize(self, document)
    self.Document = document

	if mn.isInMission() then
		ScpuiSystem:pauseAllAudio(true)
	end

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    -- Persist current changes since we might discard them in this screen
    opt.persistChanges()

    self.Options = opt.Options
    ba.print("Printing option ID mapping:\n")
    for _, v_opt in ipairs(self.Options) do
        ba.print(string.format("%s (%s): %s\n", v_opt.Title, v_opt.Key, AbstractOptionsController.getOptionElementId(self, v_opt)))

		--Creates data sources for built-in dropdowns
        if v_opt.Type == OPTION_TYPE_SELECTION then
            self.DataSources[v_opt.Key] = self:createOptionSource(v_opt)
        end

        local category = v_opt.Key:match("([^%.]+)")
        local key      = v_opt.Key

		local basicOptions = {
			"Input.Joystick",
			"Input.Joystick1",
			"Input.Joystick2",
			"Input.Joystick3",
			"Input.JoystickDeadZone",
			"Input.JoystickSensitivity",
			"Input.ForceFeedback",
			"Input.FFStrength",
			"Input.HitEffect",
			"Input.UseMouse",
			"Input.MouseSensitivity",
			"Game.Language",
			"Audio.Effects",
			"Audio.Music",
			"Audio.Voice",
			"Game.SkillLevel",
			"Graphics.Gamma",
			"Game.FontScaleFactor"
		}

        if Utils.table.contains(basicOptions, key) then
            table.insert(self.Categorized_Options.Basic, v_opt)
        elseif category == "Graphics" then
            table.insert(self.Categorized_Options.Graphics, v_opt)
		elseif category == "Multi" then
			table.insert(self.Categorized_Options.Multi, v_opt)
		else
            table.insert(self.Categorized_Options.Misc, v_opt)
        end
    end

	--Creates data sources for custom dropdowns
	for _, v_custopt in ipairs(ScpuiSystem.data.Custom_Options) do
		v_custopt.Category = "Custom"
		ba.print(string.format("%s (%s): %s\n", v_custopt.Title, v_custopt.Key, AbstractOptionsController.getOptionElementId(self, v_custopt)))
		if (v_custopt.Type == "Multi") or (v_custopt.Type == "Binary") then
			self.DataSources[v_custopt.Key] = self:createOptionSource(v_custopt)
		end
	end

    ba.print("Done.\n")

    self:initializeBuiltInBasicOptions()

	self:initializeBuiltInMiscOptions()

    self:initializeBuiltInGraphicsOptions()

	self:initializeBuiltInMultiOptions()

	self:initializeCustomOptions()

	if ScpuiSystem.data.table_flags.HideMulti == true then
		self.Document:GetElementById("multi_btn"):SetClass("hidden", true)
	end

	Topics.options.initialize:send(self)
end

--- Creates a data source from an option
--- @param option scpui_option
--- @return scpui_option_data_source
function OptionsController:createOptionSource(option)
    return DataSource(option)
end

function OptionsController:acceptChanges(state)

	ScpuiSystem.data.ScpuiOptionValues = self.CustomValues

	--Save mod options to file
	ScpuiSystem:saveOptionsToFile(ScpuiSystem.data.ScpuiOptionValues)

	--Save mod options to global file for recalling before a player is selected
	local saveFilename = "scpui_options_global.cfg"

	---@type json
	local Json = require('dkjson')
    local file = cf.openFile(saveFilename, 'w', 'data/players')
    file:write(Json.encode(ScpuiSystem.data.ScpuiOptionValues))
    file:close()

	--Persist base options
    local unchanged = opt.persistChanges()

	--Save the IP table
	local ip_el = self.Document:GetElementById("ipaddress_list")
	local ip_tbl = {}
	for _, child in ipairs(ip_el.child_nodes) do
		table.insert(ip_tbl, child.inner_rml)
	end
	opt.writeIPAddressTable(ip_tbl)

	--Save the login info
	if self.LoginChanged == true then
		opt.MultiLogin = self.Document:GetElementById("login_field"):GetAttribute("value")
	end
	if self.PassChanged == true then
		opt.MultiPassword = self.Document:GetElementById("pass_field"):GetAttribute("value")
	end
	if self.SquadChanged == true then
		opt.MultiSquad = self.Document:GetElementById("squad_field"):GetAttribute("value")
	end

	ui.OptionsMenu.savePlayerData()

    if #unchanged <= 0 then
        -- All options were applied
		if mn.isInMission() then
			ScpuiSystem:pauseAllAudio(false)
		end
        ba.postGameEvent(ba.GameEvents[state])
        return
    end

    local titles = {}
    for _, v in ipairs(unchanged) do
        table.insert(titles, string.format("<li>%s</li>", v.Title))
    end

    local changed_text = table.concat(titles, "\n")

    local dialog_text = string.format(ba.XSTR("<p>The following changes require a restart to apply their changes:</p><p>%s</p>", 888384), changed_text)

    local builder = Dialogs.new()
    builder:title(ba.XSTR("Restart required", 888385))
    builder:text(dialog_text)
	builder:escape(false)
    builder:button(Dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Ok", 888286), true, string.sub(ba.XSTR("Ok", 888286), 1, 1))
    builder:button(Dialogs.BUTTON_TYPE_NEGATIVE, ba.XSTR("Cancel", 888091), false, string.sub(ba.XSTR("Cancel", 888091), 1, 1))
    builder:show(self.Document.context):continueWith(function(val)
        if val then

			if mn.isInMission() then
				ScpuiSystem:pauseAllAudio(false)
			end

            ba.postGameEvent(ba.GameEvents[state])
        end
    end)
end

--- Creates an option control element for the given option. This function only handles Selection, Binary, and Range options for FSO Built-In options.
--- @param option scpui_option
--- @param parent_id string
--- @param onchange_func? function
--- @return Element? option_el The option element
function OptionsController:createOptionElement(option, parent_id, onchange_func)
    if option.Type == OPTION_TYPE_SELECTION then
        local vals = option:getValidValues()

        if #vals == 2 and not option.Flags.ForceMultiValueSelection then
            -- Special case for binary options
            return AbstractOptionsController.createBinaryOptionElement(self, option, vals, parent_id, onchange_func)
        else
            return AbstractOptionsController.createSelectionOptionElement(self, option, vals, parent_id, nil, onchange_func)
        end
    elseif option.Type == OPTION_TYPE_RANGE then
        return AbstractOptionsController.createRangeOptionElement(self, option, parent_id, onchange_func)
    end
end

--- Create an option control element for a custom option. This function handles all types of custom options.
--- @param option scpui_option
--- @param parent_id string
--- @param onchange_func? function
--- @return Element? option_el The option element
function OptionsController:createCustomOptionElement(option, parent_id, onchange_func)
    if (option.Type == "Binary") or (option.Type == "Multi") then
		---@type any[]
        local vals = option.ValidValues

        if #vals == 2 and not option.ForceSelector then
            -- Special case for binary options
            return AbstractOptionsController.createBinaryOptionElement(self, option, vals, parent_id, onchange_func)
        else
			return AbstractOptionsController.createSelectionOptionElement(self, option, vals, parent_id, nil, onchange_func)
        end
    elseif option.Type == "Range" then
        return AbstractOptionsController.createRangeOptionElement(self, option, parent_id, onchange_func)
	elseif option.Type == "TenPoint" then
		--local wrapper = option.Key .. "_wrapper"
		return AbstractOptionsController.createTenPointRangeElement(self, option, parent_id, {
                text_alignment = "left",
                no_background  = false
            })
    elseif option.Type == "FivePoint" then
		return AbstractOptionsController.createFivePointRangeElement(self, option, parent_id)
	elseif option.Type == "Header" then
        return AbstractOptionsController.createHeaderOptionElement(self, option, parent_id)
	end
end

--- Special function to create the brightness option control element
--- @param option scpui_option
--- @param onchange_func function
--- @return nil
function OptionsController:handleBrightnessOption(option, onchange_func)
    local increase_btn = self.Document:GetElementById("brightness_increase_btn")
    local decrease_btn = self.Document:GetElementById("brightness_decrease_btn")
    local value_el     = self.Document:GetElementById("brightness_value_el")

    local vals = option:getValidValues()
    local current = option.Value

    value_el.inner_rml = current.Display

    increase_btn:AddEventListener("click", function()
        local current_index = Utils.table.ifind(vals, option.Value)
        current_index       = current_index + 1
        if current_index > #vals then
            current_index = #vals
        end
        local new_val = vals[current_index]

        if new_val ~= option.Value then
            option.Value       = new_val
            value_el.inner_rml = new_val.Display

            if onchange_func then
                onchange_func(new_val)
            end

            ui.playElementSound(increase_btn, "click", "success")
        else
            ui.playElementSound(increase_btn, "click", "error")
        end
    end)
    decrease_btn:AddEventListener("click", function()
        local current_index = Utils.table.ifind(vals, option.Value)
        current_index       = current_index - 1
        if current_index < 1 then
            current_index = 1
        end
        local new_val = vals[current_index]

        if new_val ~= option.Value then
            option.Value       = new_val
            value_el.inner_rml = new_val.Display

            if onchange_func then
                onchange_func(new_val)
            end

            ui.playElementSound(decrease_btn, "click", "success")
        else
            ui.playElementSound(decrease_btn, "click", "error")
        end
    end)
end

--- Initializes the basic built-in options and built-in SCPUI options
--- @return nil
function OptionsController:initializeBuiltInBasicOptions()
	local builtin_font_element_created = false
	if ScpuiSystem.data.FontValue and not ba.isEngineVersionAtLeast(24, 3, 0) then
		--Create the font size selector option
		--- @type scpui_option
		local fontAdjustment = {
			Title = Utils.xstr({"Font Size Adjustment", 888393}),
			Description = Utils.xstr({"Increases or decreases the font size", 888394}),
			Key = "Font_Adjustment",
			Type = "Range",
			Category = "Custom",
			Min = 0,
			Max = 1,
			Value = 0.5,
			--- Rest are dummy values
			Flags = {},
			getValueFromRange = function() return { Value = 0, Display = "0" } end,
			getInterpolantFromValue = function() return 0 end,
			getValidValues = function() return {} end,
			persistChanges = function() return true end
		}
		local font_adjust_el = self:createCustomOptionElement(fontAdjustment, "font_size_selector")
		assert(font_adjust_el, "Failed to create option element for " .. fontAdjustment.Key)
		self:addOptionTooltip(fontAdjustment, font_adjust_el)
		builtin_font_element_created = true
	end

	--Create the briefing render style option
	--- @type scpui_option
	local briefRenderChoice = {
		Title = Utils.xstr({"Brief Render Option", 888554}),
		Description = Utils.xstr({"Toggles rendering directly to screen or to a texture. Can fix flickering in the briefing map.", 888555}),
		Key = "Brief_Render_Option",
		Type = "Binary",
		Category = "Custom",
		ValidValues = {
			[1] = "Texture",
			[2] = "Screen",
		},
		DisplayNames = {
			["Texture"] = Utils.xstr({"Texture", 888556}),
			["Screen"] = Utils.xstr({"Screen", 888557}),
		},
		Value = "Texture",
		ForceSelector = true,
		--- Rest are dummy values
		Flags = {},
		getValueFromRange = function() return { Value = 0, Display = "0" } end,
		getInterpolantFromValue = function() return 0 end,
		getValidValues = function() return {} end,
		persistChanges = function() return true end
	}
	self.DataSources[briefRenderChoice.Key] = self:createOptionSource(briefRenderChoice)
	local brief_choice_el = self:createCustomOptionElement(briefRenderChoice, "brief_choice_selector")
	assert(brief_choice_el, "Failed to create option element for " .. briefRenderChoice.Key)
	self:addOptionTooltip(briefRenderChoice, brief_choice_el)

    for _, option in ipairs(self.Categorized_Options.Basic) do
        local key = option.Key
		local opt_el = nil
        if key == "Input.Joystick2" then
            opt_el = AbstractOptionsController.createSelectionOptionElement(self, option, option:getValidValues(), "joystick_column_1", {
                --no_title = true
            })
		elseif key == "Input.Joystick" then
            opt_el = AbstractOptionsController.createSelectionOptionElement(self, option, option:getValidValues(), "joystick_column_1", {
                --no_title = true
            })
		elseif key == "Input.Joystick1" then
            opt_el = AbstractOptionsController.createSelectionOptionElement(self, option, option:getValidValues(), "joystick_column_2", {
                --no_title = true
            })
		elseif key == "Input.Joystick3" then
            opt_el = AbstractOptionsController.createSelectionOptionElement(self, option, option:getValidValues(), "joystick_column_2", {
                --no_title = true
            })
        elseif key == "Input.JoystickDeadZone" then
            opt_el = AbstractOptionsController.createTenPointRangeElement(self, option, "joystick_values_wrapper", {
                text_alignment = "right",
                --no_background  = true
            })
        elseif key == "Input.JoystickSensitivity" then
            opt_el = AbstractOptionsController.createTenPointRangeElement(self, option, "joystick_values_wrapper", {
                text_alignment = "right",
                --no_background  = true
            })
        elseif key == "Input.UseMouse" then
            opt_el = self:createOptionElement(option, "mouse_options_container")
        elseif key == "Input.MouseSensitivity" then
            opt_el = AbstractOptionsController.createTenPointRangeElement(self, option, "mouse_options_container", {
                text_alignment = "left",
                no_background  = false
            })
		elseif key == "Game.Language" then
            opt_el = AbstractOptionsController.createSelectionOptionElement(self, option, option:getValidValues(), "language_selector", {
                --no_title = true
            })
		elseif not builtin_font_element_created and key == "Game.FontScaleFactor" then
			opt_el = self:createOptionElement(option, "font_size_selector")
		elseif key == "Input.ForceFeedback" then
            opt_el = self:createOptionElement(option, "force_feeback_selector")
        elseif key == "Input.FFStrength" then
            opt_el = self:createOptionElement(option, "force_feedback_sensitivity")
		elseif key == "Input.HitEffect" then
            opt_el = self:createOptionElement(option, "directional_hit")
        elseif key == "Audio.Effects" then
            -- The audio options are applied immediately so the user hears the effects
            self.OptionBackups[option] = option.Value

            opt_el = AbstractOptionsController.createTenPointRangeElement(self, option, "volume_sliders_container", {
                text_alignment = "left",
                no_background  = true
            }, function(_)
                option:persistChanges()
				Topics.options.changeEffectsVol:send(self)
            end)
        elseif key == "Audio.Music" then
            self.OptionBackups[option] = option.Value

            opt_el = AbstractOptionsController.createTenPointRangeElement(self, option, "volume_sliders_container", {
                text_alignment = "left",
                no_background  = true
            }, function(_)
                option:persistChanges()
            end)
        elseif key == "Audio.Voice" then
            self.OptionBackups[option] = option.Value

            opt_el = AbstractOptionsController.createTenPointRangeElement(self, option, "volume_sliders_container", {
                text_alignment = "left",
                no_background  = true
            }, function(_)
                option:persistChanges()
                ui.OptionsMenu.playVoiceClip()
				Topics.options.changeVoiceVol:send(self)
            end)
        elseif key == "Game.SkillLevel" then
            opt_el = AbstractOptionsController.createFivePointRangeElement(self, option, "skill_level_container")
        elseif key == "Graphics.Gamma" then
            self.OptionBackups[option] = option.Value

            self:handleBrightnessOption(option, function(_)
                -- Apply changes immediately to make them visible
                option:persistChanges()
            end)

			opt_el = self.Document:GetElementById("gamma_option")
        end

		assert(opt_el, "Failed to create option element for " .. key)

		if option.Description then
			self:addOptionTooltip(option, opt_el)
		end
    end
end

--- Initializes the built-in graphics options
--- @return nil
function OptionsController:initializeBuiltInGraphicsOptions()
    local current_column = 3
    for _, option in ipairs(self.Categorized_Options.Graphics) do
		local opt_el = nil

        if option.Key == "Graphics.Resolution" then
            opt_el = self:createOptionElement(option, "graphics_column_1")
        elseif option.Key == "Graphics.WindowMode" then
            opt_el = self:createOptionElement(option, "graphics_column_1")
        elseif option.Key == "Graphics.Display" then
            opt_el = self:createOptionElement(option, "graphics_column_1", function(_)
                self.DataSources["Graphics.Resolution"]:updateValues()
            end)
        elseif Utils.table.contains(self.BuiltInGraphicsKeys, option.Key) then
            opt_el = self:createOptionElement(option, "graphics_column_2")
        else
            opt_el = self:createOptionElement(option, string.format("graphics_column_%d", current_column))

			assert(opt_el, "Failed to create option element for " .. option.Key)

            if current_column == 2 or current_column == 3 then
                opt_el:SetClass("horz_middle", true)
            elseif current_column == 4 then
                opt_el:SetClass("horz_right", true)
            end

            current_column = current_column + 1
            if current_column > 4 then
                current_column = 3
            end
        end

		assert(opt_el, "Failed to create option element for " .. option.Key)

		if option.Description then
			self:addOptionTooltip(option, opt_el)
		end
    end

	self:setGraphicsDefaultStatus()
end

--- Initializes the built in misc options
--- @return nil
function OptionsController:initializeBuiltInMiscOptions()
    local current_column = 1
	local count = 1

	--Handle built-in preferences options
	for _, option in ipairs(self.Categorized_Options.Misc) do
		local el = self:createOptionElement(option, string.format("misc_column_%d", current_column))

		assert(el, "Failed to create option element for " .. option.Key)

		if option.Description then
			self:addOptionTooltip(option, el)
		end

		if current_column == 2 or current_column == 3 then
			el:SetClass("horz_middle", true)
		elseif current_column == 4 then
			el:SetClass("horz_right", true)
		end

		count = count + 1

		if count > 10 then
			current_column = current_column + 1
			if current_column > 4 then
				current_column = 1
			end
			count = 1
		end
	end

end

--- Initializes the custom options
--- @return nil
function OptionsController:initializeCustomOptions()
    for _, option in ipairs(ScpuiSystem.data.Custom_Options) do
		option.Category = "Custom"
		--option.Title = option.Title
		local el = self:createCustomOptionElement(option, string.format("custom_column_%d", option.Column))

		assert(el, "Failed to create option element for " .. option.Key)

		if option.Description then
			self:addOptionTooltip(option, el)
		end

		if option.Column == 2 or option.Column == 3 then
			el:SetClass("horz_middle", true)
		elseif option.Column == 4 then
			el:SetClass("horz_right", true)
		end
    end

	self:setModDefaultStatus()
end

--- Called by the RML to remove the selected IP from the IP list
--- @return nil
function OptionsController:remove_selected_ip()
	if self.SelectedIpElement then
		local ip_el = self.Document:GetElementById("ipaddress_list")
		for _, child in ipairs(ip_el.child_nodes) do
			if child.id == self.SelectedIpElement.id then
				ip_el:RemoveChild(child)
				break
			end
		end
	end
end

--- Checks if an IP is a duplicate of one already in the list
--- @param id string The ID of the IP to check
--- @return boolean result True if the IP is a duplicate, false otherwise
function OptionsController:isDuplicateIp(id)
	local ip_el = self.Document:GetElementById("ipaddress_list")
	for _, child in ipairs(ip_el.child_nodes) do
		if child.id == id then
			return true
		end
	end

	return false
end

--- Called by the RML to add a typed IP to the IP list
--- @return nil
function OptionsController:add_selected_ip()
	if string.len(self.SubmittedIp) > 0 then
		if not self:isDuplicateIp(self.SubmittedIp) then
			if opt.verifyIPAddress(self.SubmittedIp) then
				local ip_el = self.Document:GetElementById("ipaddress_list")
				ip_el:AppendChild(self:createIpItem(self.SubmittedIp))
			else
				local builder      = Dialogs.new()
				builder:title(ba.XSTR("Invalid IP", 888376))
				builder:text(ba.XSTR("Ip string is invalid!", 888377))
				builder:escape(false)
				builder:button(Dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Ok", 888286), true, string.sub(ba.XSTR("Ok", 888286), 1, 1))
				builder:show(self.Document.context):continueWith(function() end)
			end
		else
			local builder      = Dialogs.new()
			builder:title(ba.XSTR("Duplicate IP", 888380))
			builder:text(ba.XSTR("IP Address already listed!", 888381))
			builder:escape(false)
			builder:button(Dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Ok", 888286), true, string.sub(ba.XSTR("Ok", 888286), 1, 1))
			builder:show(self.Document.context):continueWith(function() end)
		end
	end

	self.IpInputElement:SetAttribute("value", "")
	self.SubmittedIp = ""
end

--- Called by the RML when the IP input text box accepts a keypress
--- @param event Event The event that triggered the function
--- @return nil
function OptionsController:ip_input_change(event)
	--remove all whitespace
	local stringValue = event.parameters.value:gsub("^%s*(.-)%s*$", "%1")

	--If RETURN was not pressed then make sure the input is a number with no spaces. Else save the value, clear the field, and continue.
	if event.parameters.linebreak ~= 1 then
		local lastCharacter = string.sub(stringValue, -1)
		if type(tonumber(lastCharacter)) == "number" or lastCharacter == "." then
			self.IpInputElement:SetAttribute("value", stringValue)
		else
			--remove the trailing character because it was not valid
			stringValue = stringValue:sub(1, -2)
			self.IpInputElement:SetAttribute("value", stringValue)
		end

		self.SubmittedIp = self.IpInputElement:GetAttribute("value")
	else
		self:add_selected_ip()
	end
end

--- Sets an IP address as the selected IP
--- @param el Element The element that was clicked
--- @return nil
function OptionsController:selectIp(el)
	if self.SelectedIpElement then
		self.SelectedIpElement:SetPseudoClass("checked", false)
	end
	self.SelectedIpElement = el
	self.SelectedIpElement:SetPseudoClass("checked", true)
end

--- Create an IP address list element
--- @param entry string The IP address to create an element for
--- @return Element li_el The created element
function OptionsController:createIpItem(entry)

	local li_el = self.Document:CreateElement("li")

	li_el.inner_rml = entry
	li_el.id = entry

	li_el:SetClass("ipaddress_list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:selectIp(li_el)
	end)

	return li_el
end

--- Called by the RML when the login field is changed
--- @return nil
function OptionsController:login_changed()
	self.LoginChanged = true
end

--- Called by the RML when the password field is changed
--- @return nil
function OptionsController:password_changed()
	self.PassChanged = true
end

--- Called by the RML when the squad field is changed
--- @return nil
function OptionsController:squad_changed()
	self.SquadChanged = true
end

--- Initializes the built-in multi options
--- @return nil
function OptionsController:initializeBuiltInMultiOptions()

	--Handle the IP Address list
	local ips = opt.readIPAddressTable()
	self.SubmittedIp = ""
	self.IpInputElement = self.Document:GetElementById("add_ip_field")

	local ip_el = self.Document:GetElementById("ipaddress_list")

	for i = 1, #ips do
		ip_el:AppendChild(self:createIpItem(ips[i]))
	end

	--- Create an imitation option for the IP list
	--- @type scpui_option
	local ip_opt = {
		Key = "ipaddress_list",
		Description = "IP Addresses to watch or something. I dunno. Mjn Fix this.",
		Value = "",
		Type = "Custom",
		Title = "IP Address List",
		Category = "Multi",
		Flags = {},
		getValueFromRange = function() return { Value = "", Display = "" } end,
		getInterpolantFromValue = function() return 0 end,
		getValidValues = function() return {} end,
		persistChanges = function() return true end
	}

	self:addOptionTooltip(ip_opt, self.Document:GetElementById("ipaddress_list"))

	--Handle the login info
	self.Document:GetElementById("login_field"):SetAttribute("value", opt.MultiLogin)
	self.Document:GetElementById("squad_field"):SetAttribute("value", opt.MultiSquad)
	if opt.MultiPassword then
		self.Document:GetElementById("pass_field"):SetAttribute("value", "******")
	end

	self.LoginChanged = false
	self.PassChanged = false
	self.SquadChanged = false

	--- Create an imitation option for the login info
	--- @type scpui_option
	local login_opt = {
		Key = "login_info",
		Description = "Your PXO multiplayer username",
		Value = "",
		Type = "Custom",
		Title = "IP Address List",
		Category = "Multi",
		Flags = {},
		getValueFromRange = function() return { Value = "", Display = "" } end,
		getInterpolantFromValue = function() return 0 end,
		getValidValues = function() return {} end,
		persistChanges = function() return true end
	}

	--- Create an imitation option for the password info
	--- @type scpui_option
	local pass_opt = {
		Key = "password_info",
		Description = "Your PXO multiplayer password",
		Value = "",
		Type = "Custom",
		Title = "IP Address List",
		Category = "Multi",
		Flags = {},
		getValueFromRange = function() return { Value = "", Display = "" } end,
		getInterpolantFromValue = function() return 0 end,
		getValidValues = function() return {} end,
		persistChanges = function() return true end
	}

	--- Create an imitation option for the squad info
	--- @type scpui_option
	local squad_opt = {
		Key = "squad_info",
		Description = "Your PXO multiplayer squadron name",
		Value = "",
		Type = "Custom",
		Title = "IP Address List",
		Category = "Multi",
		Flags = {},
		getValueFromRange = function() return { Value = "", Display = "" } end,
		getInterpolantFromValue = function() return 0 end,
		getValidValues = function() return {} end,
		persistChanges = function() return true end
	}

	self:addOptionTooltip(login_opt, self.Document:GetElementById("login_field").parent_node)
	self:addOptionTooltip(pass_opt, self.Document:GetElementById("pass_field").parent_node)
	self:addOptionTooltip(squad_opt, self.Document:GetElementById("squad_field").parent_node)

	--Handle the rest of the options
	for _, option in ipairs(self.Categorized_Options.Multi) do
		local opt_el = nil
		if option.Key == "Multi.LocalBroadcast" then
			opt_el = self.Document:GetElementById("local_btn")
			opt_el:AddEventListener("click", function()
				local opt_el = self.Document:GetElementById("local_btn")
				local vals = option:getValidValues()
				if option.Value.Display == "On" then
					opt_el:SetPseudoClass("checked", false)
					option.Value = vals[1]
				else
					opt_el:SetPseudoClass("checked", true)
					option.Value = vals[2]
				end
			end)
			if option.Value.Display == "On" then
				opt_el:SetPseudoClass("checked", true)
			else
				opt_el:SetPseudoClass("checked", false)
			end
		elseif option.Key == "Multi.TogglePXO" then
			opt_el = self.Document:GetElementById("pxo_btn")
			opt_el:AddEventListener("click", function()
				local opt_el = self.Document:GetElementById("pxo_btn")
				local vals = option:getValidValues()
				if option.Value.Display == "On" then
					opt_el:SetPseudoClass("checked", false)
					option.Value = vals[1]
				else
					opt_el:SetPseudoClass("checked", true)
					option.Value = vals[2]
				end
			end)
			if option.Value.Display == "On" then
				opt_el:SetPseudoClass("checked", true)
			else
				opt_el:SetPseudoClass("checked", false)
			end
		elseif option.Key == "Multi.TransferMissions" then
			opt_el = self:createOptionElement(option, "multi_column_2")
		elseif option.Key == "Multi.FlushCache" then
			opt_el = self:createOptionElement(option, "multi_column_2")
		end

		assert(opt_el, "Failed to create option element for " .. option.Key)

		self:addOptionTooltip(option, opt_el)
	end
end

--- Add an option tooltip to an element that will show when the mouse hovers over it
--- @param option scpui_option The option to create a tooltip for
--- @param parent Element The element to attach the tooltip to
--- @return nil
function OptionsController:addOptionTooltip(option, parent)
	if option == nil or parent == nil then
		return
	end

	local tool_el = self.Document:CreateElement("div")
	tool_el.id = option.Key .. "_tooltip"
	tool_el:SetClass("tooltip", true)
	tool_el.inner_rml = "<span class=\"tooltiptext\">" .. option.Description .. "</span>"
	parent:AppendChild(tool_el)

	parent:AddEventListener("mouseover", function()
		if self.TooltipTimers[option.Key] == nil then
			self.TooltipTimers[option.Key] = 0
		else
			self:maybeShowTooltip(tool_el, option.Key)
		end
	end)

	parent:AddEventListener("mouseout", function()
		self.TooltipTimers[option.Key] = nil
		tool_el:SetPseudoClass("shown", false)
	end)
end

function OptionsController:maybeShowTooltip(tool_el, key)
	if self.TooltipTimers[key] == nil then
		return
	end

	if self.TooltipTimers[key] >= self.TooltipWait then
		tool_el:SetPseudoClass("shown", true)
	else
		async.run(function()
			async.await(AsyncUtil.wait_for(1.0))
			if self.TooltipTimers[key] ~= nil then
				self.TooltipTimers[key] = self.TooltipTimers[key] + 1
				self:maybeShowTooltip(tool_el, key)
			end
		end, async.OnFrameExecutor)
	end
end

--- Set the graphics preset bullet to a specified level
--- @param level string The level to set the bullet
--- @return nil
function OptionsController:SetGraphicsBullet(level)

	local lowbullet = self.Document:GetElementById("det_low_btn")
	local medbullet = self.Document:GetElementById("det_med_btn")
	local higbullet = self.Document:GetElementById("det_hig_btn")
	local ultbullet = self.Document:GetElementById("det_ult_btn")
	local cstbullet = self.Document:GetElementById("det_cst_btn")
	local minbullet = self.Document:GetElementById("det_min_btn")

	minbullet:SetPseudoClass("checked", level == "min")
	lowbullet:SetPseudoClass("checked", level == "low")
	medbullet:SetPseudoClass("checked", level == "med")
	higbullet:SetPseudoClass("checked", level == "hig")
	ultbullet:SetPseudoClass("checked", level == "ult")
	cstbullet:SetPseudoClass("checked", level == "cst")

end

--- Called by the RML to set the graphics level to minimum
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:set_detail_minimum(element)

	for k_gr_option, _ in pairs(self.GraphicsOptions) do
		local option = self.GraphicsOptions[k_gr_option]
		for _, v_gr_preset in pairs(self.GraphicsPresets) do
			if option.ParentEl.id == v_gr_preset then
				local parent = self.Document:GetElementById(option.ParentEl.id)
				local savedValue = option.SavedValue
				if option.Type == "Multi" then
					if option.ParentEl.id == "option_graphics_aamode_element" then
						option.CurrentValue = 1
						option.SelectEl.selection = 1
					elseif option.ParentEl.id == "option_graphics_msaasamples_element" then
						option.CurrentValue = 1
						option.SelectEl.selection = 1
					else
						option.CurrentValue = 1
						option.SelectEl.selection = 1
					end
				elseif option.Type == "Binary" then
					option.CurrentValue = option.ValidValues[1]
					local right_selected = option.CurrentValue == option.ValidValues[2]
					parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for _, v_opt in pairs(opts) do
						if v_opt.Key == option.Key then
							v_opt.Value = option.ValidValues[1]
						end
					end
				end
				option.SavedValue = savedValue
			end
		end
	end

	self.GraphicsCustom = false
	self:SetGraphicsBullet("min")

end

--- Called by the RML to set the graphics level to low
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:set_detail_low(element)

	for k_gr_option, _ in pairs(self.GraphicsOptions) do
		local option = self.GraphicsOptions[k_gr_option]
		for _, v_gr_preset in pairs(self.GraphicsPresets) do
			if option.ParentEl.id == v_gr_preset then
				local savedValue = option.SavedValue
				if option.Type == "Multi" then
					if option.ParentEl.id == "option_graphics_aamode_element" then
						option.CurrentValue = 5
						option.SelectEl.selection = 5
					elseif option.ParentEl.id == "option_graphics_msaasamples_element" then
						option.CurrentValue = 1
						option.SelectEl.selection = 1
					else
						option.CurrentValue = 2
						option.SelectEl.selection = 2
					end
				elseif option.Type == "Binary" then
					option.CurrentValue = option.ValidValues[1]
					local right_selected = option.CurrentValue == option.ValidValues[2]
					option.ParentEl.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					option.ParentEl.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for _, v_opt in pairs(opts) do
						if v_opt.Key == option.Key then
							v_opt.Value = option.ValidValues[1]
						end
					end
				end
				option.SavedValue = savedValue
			end
		end
	end

	self.GraphicsCustom = false
	self:SetGraphicsBullet("low")

end

--- Called by the RML to set the graphics level to medium
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:set_detail_medium(element)

	for k_gr_option, _ in pairs(self.GraphicsOptions) do
		local option = self.GraphicsOptions[k_gr_option]
		for _, v_gr_preset in pairs(self.GraphicsPresets) do
			if option.ParentEl.id == v_gr_preset then
				local savedValue = option.SavedValue
				if option.Type == "Multi" then
					if option.ParentEl.id == "option_graphics_aamode_element" then
						option.CurrentValue = 6
						option.SelectEl.selection = 6
					elseif option.ParentEl.id == "option_graphics_msaasamples_element" then
						option.CurrentValue = 2
						option.SelectEl.selection = 2
					else
						option.CurrentValue = 3
						option.SelectEl.selection = 3
					end
				elseif option.Type == "Binary" then
					option.CurrentValue = option.ValidValues[1]
					local right_selected = option.CurrentValue == option.ValidValues[2]
					option.ParentEl.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					option.ParentEl.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for _, v_opt in pairs(opts) do
						if v_opt.Key == option.Key then
							v_opt.Value = option.ValidValues[1]
						end
					end
				end
				option.SavedValue = savedValue
			end
		end
	end

	self.GraphicsCustom = false
	self:SetGraphicsBullet("med")

end

--- Called by the RML to set the graphics level to high
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:set_detail_high(element)

	for k_gr_option, _ in pairs(self.GraphicsOptions) do
		local option = self.GraphicsOptions[k_gr_option]
		for _, v_gr_preset in pairs(self.GraphicsPresets) do
			if option.ParentEl.id == v_gr_preset then
				local savedValue = option.SavedValue
				if option.Type == "Multi" then
					if option.ParentEl.id == "option_graphics_aamode_element" then
						option.CurrentValue = 7
						option.SelectEl.selection = 7
					elseif option.ParentEl.id == "option_graphics_msaasamples_element" then
						option.CurrentValue = 3
						option.SelectEl.selection = 3
					else
						option.CurrentValue = 4
						option.SelectEl.selection = 4
					end
				elseif option.Type == "Binary" then
					option.CurrentValue = option.ValidValues[2]
					local right_selected = option.CurrentValue == option.ValidValues[2]
					option.ParentEl.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					option.ParentEl.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for _, v_opt in pairs(opts) do
						if v_opt.Key == option.Key then
							v_opt.Value = option.ValidValues[2]
						end
					end
				end
				option.SavedValue = savedValue
			end
		end
	end

	self.GraphicsCustom = false
	self:SetGraphicsBullet("hig")

end

--- Called by the RML to set the graphics level to ultra
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:set_detail_ultra(element)

	for k_gr_option, _ in pairs(self.GraphicsOptions) do
		local option = self.GraphicsOptions[k_gr_option]
		for _, v_gr_preset in pairs(self.GraphicsPresets) do
			if option.ParentEl.id == v_gr_preset then
				local savedValue = option.SavedValue
				if option.Type == "Multi" then
					if option.ParentEl.id == "option_graphics_aamode_element" then
						option.CurrentValue = 8
						option.SelectEl.selection = 8
					elseif option.ParentEl.id == "option_graphics_msaasamples_element" then
						option.CurrentValue = 4
						option.SelectEl.selection = 4
					else
						option.CurrentValue = 5
						option.SelectEl.selection = 5
					end
				elseif option.Type == "Binary" then
					option.CurrentValue = option.ValidValues[2]
					local right_selected = option.CurrentValue == option.ValidValues[2]
					option.ParentEl.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					option.ParentEl.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for _, v_opt in pairs(opts) do
						if v_opt.Key == option.Key then
							v_opt.Value = option.ValidValues[2]
						end
					end
				end
				option.SavedValue = savedValue
			end
		end
	end

	self.GraphicsCustom = false
	self:SetGraphicsBullet("ult")

end

--- Called by the RML to set the graphics level to custom
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:set_detail_custom(element)

	if self.GraphicsCustom == false then
		for k_gr_option, _ in pairs(self.GraphicsOptions) do
			local option = self.GraphicsOptions[k_gr_option]
			for _, v_gr_preset in pairs(self.GraphicsPresets) do
				if option.ParentEl.id == v_gr_preset then
					if option.Type == "Multi" then
						option.CurrentValue = option.SavedValue
						option.SelectEl.selection = option.SavedValue
					elseif option.Type == "Binary" then
						option.CurrentValue = option.SavedValue
						local right_selected = option.SavedValue == option.ValidValues[2]
						option.ParentEl.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
						option.ParentEl.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
						local opts = opt.Options
						for _, v_opt in pairs(opts) do
							if v_opt.Key == option.Key then
								v_opt.Value = option.SavedValue
							end
						end
					end
				end
			end
		end

		self.GraphicsCustom = true
		self:SetGraphicsBullet("cst")
	end

end

--- Checks the current options against the preset levels to determine if the current settings are a preset or custom
--- @param value number The value to check against the presets
--- @return boolean result True if the settings are a preset, false otherwise
function OptionsController:isGraphicsPreset(value)
	for k_gr_option, _ in pairs(self.GraphicsOptions) do
		local option = self.GraphicsOptions[k_gr_option]
		if option.ParentEl.id == "option_graphics_aamode_element" then
			local a_value = 8
			if value == 1 then a_value = 1 end
			if value == 2 then a_value = 5 end
			if value == 3 then a_value = 6 end
			if value == 4 then a_value = 7 end
			if option.CurrentValue ~= a_value then
				return false
			end
		elseif option.ParentEl.id == "option_graphics_postprocessing_element" then
			local a_value = "On"
			if value == 1 then a_value = "Off" end
			if value == 2 then a_value = "Off" end
			if value == 3 then a_value = "Off" end
			if value == 4 then a_value = "On" end
			if option.CurrentValue.Display ~= a_value then
				return false
			end
		elseif option.ParentEl.id == "option_graphics_lightshafts_element" then
			local a_value = "On"
			if value == 1 then a_value = "Off" end
			if value == 2 then a_value = "Off" end
			if value == 3 then a_value = "Off" end
			if value == 4 then a_value = "On" end
			if option.CurrentValue.Display ~= a_value then
				return false
			end
		elseif option.ParentEl.id == "option_graphics_softparticles_element" then
			local a_value = "On"
			if value == 1 then a_value = "Off" end
			if value == 2 then a_value = "Off" end
			if value == 3 then a_value = "Off" end
			if value == 4 then a_value = "On" end
			if option.CurrentValue.Display ~= a_value then
				return false
			end
		else
			if option.CurrentValue ~= value then
				return false
			end
		end
	end
	return true
end

--- Sets the graphics preset bullet to the current preset level
--- @return nil
function OptionsController:setGraphicsDefaultStatus()

	local preset = "cst"
	self.GraphicsCustom = true

	if self:isGraphicsPreset(1) then
		preset = "min"
		self.GraphicsCustom = false
	elseif self:isGraphicsPreset(2) then
		preset = "low"
		self.GraphicsCustom = false
	elseif self:isGraphicsPreset(3) then
		preset = "med"
		self.GraphicsCustom = false
	elseif self:isGraphicsPreset(4) then
		preset = "hig"
		self.GraphicsCustom = false
	elseif self:isGraphicsPreset(5) then
		preset = "ult"
		self.GraphicsCustom = false
	end

	self:SetGraphicsBullet(preset)

end

--- Called by the RML to set the mod settings to default
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:set_mod_detail_default(element)

	for k, _ in pairs(self.CustomOptions) do
		local option = self.CustomOptions[k]
		if not option.HasDefault then
			if option.Type == "Binary" and option.CurrentValue ~= option.DefaultValue then
				local parent = self.Document:GetElementById(option.ParentEl.id)
				self.CustomValues[option.Key] = option.DefaultValue
				option.CurrentValue = option.DefaultValue
				local right_selected = option.DefaultValue == option.ValidValues[2]
				parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
				parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
			end

			if option.Type == "Multi" and option.CurrentValue ~= option.DefaultValue then
				local parent = self.Document:GetElementById(option.ParentEl.id)
				self.CustomValues[option.Key] = option.DefaultValue
				option.CurrentValue = option.DefaultValue
				local savedValue = option.SavedValue
				option.SelectEl.selection = Utils.table.ifind(option.ValidValues, option.DefaultValue)
				option.SavedValue = savedValue
			end

			if option.Type == "Range" and option.CurrentValue ~= option.DefaultValue then
				local parent = self.Document:GetElementById(option.ParentEl.id)
				self.CustomValues[option.Key] = option.DefaultValue
				option.CurrentValue = option.DefaultValue
				local savedValue = option.SavedValue
				option.RangeEl.value = option.DefaultValue / option.MaxValue
				option.SavedValue = savedValue
			end

			if option.Type == "MultiPoint" and option.CurrentValue ~= option.DefaultValue then
				local parent = self.Document:GetElementById(option.ParentEl.id)
				--local value_el = self.Document:GetElementById(option.valueID.id)
				--ba.warning(option.CurrentValue .. " \ " .. option.defaultValue)
				self.CustomValues[option.Key] = option.DefaultValue
				option.CurrentValue = option.DefaultValue
				local savedValue = option.SavedValue
				--if value_el then
					local index = option.DefaultValue
					if option.Strings then
						if index > 5 then index = 5 end
						if index < 1 then index = 1 end
						parent.first_child.first_child.next_sibling.next_sibling.inner_rml = option.Strings[index]
					else
						--value_el.inner_rml = index
					end
					option.IncrementValue = (option.DefaultValue / #option.Buttons)
					self.CustomValues[option.Key] = option.DefaultValue
					self.CustomOptions[option.Key].CurrentValue = option.DefaultValue
				--end

				local last_active = option.DefaultValue

				for i, button in ipairs(option.Buttons) do
					button:SetPseudoClass("checked", i <= last_active)
				end
				option.SavedValue = savedValue
			end
		end
	end

	self.ModCustom = false
	local custombullet = self.Document:GetElementById("mod_custom_btn")
	local modbullet = self.Document:GetElementById("mod_default_btn")
	custombullet:SetPseudoClass("checked", false)
	modbullet:SetPseudoClass("checked", true)

end

--- Called by the RML to set the mod settings to custom
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:set_mod_detail_custom(element)

	if self.ModCustom == false then
		for k, _ in pairs(self.CustomOptions) do
			local option = self.CustomOptions[k]
			if not option.HasDefault then
				if option.Type == "Binary" and option.CurrentValue ~= option.SavedValue then
					local parent = self.Document:GetElementById(option.ParentEl.id)
					self.CustomValues[option.Key] = option.SavedValue
					option.CurrentValue = option.SavedValue
					local right_selected = option.SavedValue == option.ValidValues[2]
					parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
				end

				if option.Type == "Multi" and option.CurrentValue ~= option.SavedValue then
					local parent = self.Document:GetElementById(option.ParentEl.id)
					self.CustomValues[option.Key] = option.DefaultValue
					option.CurrentValue = option.SavedValue
					option.SelectEl.selection = Utils.table.ifind(option.ValidValues, option.SavedValue)
				end

				if option.Type == "Range" and option.CurrentValue ~= option.SavedValue then
					local parent = self.Document:GetElementById(option.ParentEl.id)
					self.CustomValues[option.Key] = option.DefaultValue
					option.CurrentValue = option.SavedValue
					option.RangeEl.value = option.SavedValue / option.MaxValue
				end

				if option.Type == "MultiPoint" and option.CurrentValue ~= option.SavedValue then
					local parent = self.Document:GetElementById(option.ParentEl.id)
					--local value_el = self.Document:GetElementById(option.valueID.id)
					self.CustomValues[option.Key] = option.SavedValue
					option.CurrentValue = option.SavedValue
					local savedValue = option.SavedValue
					--if value_el then
						local index = option.SavedValue
						if option.Strings then
							if index > 5 then index = 5 end
							if index < 1 then index = 1 end
							parent.first_child.first_child.next_sibling.next_sibling.inner_rml = option.Strings[index]
						else
							--value_el.inner_rml = index
						end
						option.IncrementValue = (option.SavedValue / #option.Buttons)
						self.CustomValues[option.Key] = option.SavedValue
						self.CustomOptions[option.Key].CurrentValue = option.SavedValue
					--end

					local last_active = option.SavedValue --math.floor(option.range * option.numPoints) + 1

					for i, button in ipairs(option.Buttons) do
						button:SetPseudoClass("checked", i <= last_active)
					end
					option.SavedValue = savedValue
				end
			end
		end

		self.ModCustom = true
		local custombullet = self.Document:GetElementById("mod_custom_btn")
		local modbullet = self.Document:GetElementById("mod_default_btn")
		custombullet:SetPseudoClass("checked", true)
		modbullet:SetPseudoClass("checked", false)
	end

end

--- Checks if the mod settings are the default settings
--- @return boolean result True if the settings are default, false otherwise
function OptionsController:isModDefault()
	for k, _ in pairs(self.CustomOptions) do
		local option = self.CustomOptions[k]
		if not option.HasDefault then
			if option.CurrentValue ~= option.DefaultValue then
				return false
			end
		end
	end
	return true
end

--- Sets the mod settings bullet to the current status
--- @return nil
function OptionsController:setModDefaultStatus()
	local custombullet = self.Document:GetElementById("mod_custom_btn")
	local modbullet = self.Document:GetElementById("mod_default_btn")

	if self:isModDefault() == true then
		custombullet:SetPseudoClass("checked", false)
		modbullet:SetPseudoClass("checked", true)
		self.ModCustom = false
	else
		custombullet:SetPseudoClass("checked", true)
		modbullet:SetPseudoClass("checked", false)
		self.ModCustom = true
	end
end

--- Discards all options changes
--- @return nil
function OptionsController:discardChanges()
    opt.discardChanges()

    for opt, value in pairs(self.OptionBackups) do
        opt.Value = value
        opt:persistChanges()
    end
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function OptionsController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()

        self:discardChanges()

		if mn.isInMission() then
			ScpuiSystem:pauseAllAudio(false)
		end

        ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
    end
end

--- Called by the RML when the accept button is clicked
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:accept_clicked(element)
	self:acceptChanges("GS_EVENT_PREVIOUS_STATE")
end

--- Called by the RML when the control config button is clicked
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:control_config_clicked(element)
    self:acceptChanges("GS_EVENT_CONTROL_CONFIG")
end

--- Called by the RML when the hud config button is clicked
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:hud_config_clicked(element)
    self:acceptChanges("GS_EVENT_HUD_CONFIG")
end

--- Called by the RML when the exit button is clicked. Shows a dialog box to confirm the exit
--- @param element Element The element that was clicked
--- @return nil
function OptionsController:exit_game_clicked(element)
    local builder = Dialogs.new()
    builder:text(ba.XSTR("Exit Game?", 888390))
    builder:button(Dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Yes", 888296), true)
    builder:button(Dialogs.BUTTON_TYPE_NEGATIVE, ba.XSTR("No", 888298), false)
    builder:show(self.Document.context):continueWith(function(result)
        if not result then
            return
        end
        ba.postGameEvent(ba.GameEvents["GS_EVENT_QUIT_GAME"])
    end)
end

--- Called when the screen is being unloaded
--- @return nil
function OptionsController:unload()
	Topics.options.unload:send(self)
end

return OptionsController
