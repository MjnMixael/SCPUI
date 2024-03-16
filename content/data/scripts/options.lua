local utils = require('utils')
local tblUtil  = utils.table
local templates = require("rocket_templates")
local dialogs  = require("dialogs")
local topics   = require("ui_topics")
local class    = require("class")

local async_util = require("async_util")

local customValues = ScpuiOptionValues
local customOptions = {}
local detailOptions = {}
local modCustom = true
local graphicsCustom = true

local detailPresets = {
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

local fontChoice = nil

local function getFormatterName(key)
    return key:gsub("%.", "_")
end

local function getCategoryFromKey(key)
	return key:match("([^%.]+)")
end

local function getOptionElementId(option)
    local key = option.Key
    key       = key:gsub("%.", "_")
    key       = key:lower()

    return string.format("option_%s_element", key)
end

local DataSourceWrapper = class()

function DataSourceWrapper:init(option)
	if option.Category ~= "Custom" then
		self.option   = option
	else
		self.option = {}
	end

    local source      = DataSource.new(getFormatterName(option.Key))

	if option.Category ~= "Custom" then
		self.values   = option:getValidValues()
	else
		if string.lower(option.Type) == "binary" then
			--binary options don't need translation here
			self.values   = option.ValidValues
		elseif string.lower(option.Type) == "multi" then
			--multi selector options get translated
			self.values = {}
			
			for i = 1, #option.ValidValues do
				local thisVal = option.DisplayNames[option.ValidValues[i]]
				table.insert(self.values, thisVal)
			end
		else
			ba.error("Houston, how did we get here?! Get Mjn STAT!")
		end
	end
	
	if option.Category ~= "Custom" then
		source.GetNumRows = function()
			return #self.values
		end
		source.GetRow     = function(_, i, columns)
			local val = self.values[i]
			local out = {}
			for _, v in ipairs(columns) do
				if v == "serialized" then
					table.insert(out, val.Serialized)
				elseif v == "display" then
					table.insert(out, val.Display)
				else
					table.insert(out, "")
				end
			end
			return out
		end
	else
		source.GetNumRows = function()
			return #self.values
		end
		source.GetRow	= function(_, i, columns)
			local val = self.values[i]
			local out = {}
			for _, v in ipairs(columns) do
				table.insert(out, val)
			end
			return out
		end
	end

    self.source       = source

end

function DataSourceWrapper:updateValues()
    self.values = self.option:getValidValues()
    self.source:NotifyRowChange("Default")
end

local function createOptionSource(option)
    return DataSourceWrapper(option)
end

local OptionsController = class()

function OptionsController:init()
    self.sources          = {}
    self.options          = {}
    self.category_options = {
        basic  = {},
        detail = {},
		prefs  = {},
        other  = {},
        multi  = {}
    }
	
	self.timers = {}
    -- A list of mappings option->ValueDescription which contains backups of the original values for special options
    -- that apply their changes immediately
    self.option_backup    = {}
	
	if mn.isInMission() then
		ScpuiSystem:pauseAllAudio(true)
	end
	
end

function OptionsController:init_point_slider_element(value_el, btn_left, btn_right, point_buttons, option,
                                                     onchange_func, el_actual)
    local value            = nil
    local range_val        = nil
    local num_value_points = #point_buttons - 1
	local Key = option.Key
	local custom_init = 0
	local default = nil
	
	if option.Category ~= "Custom" then
		value = option.Value
		range_val = option:getInterpolantFromValue(value)
	else
		local cur_val = (ScpuiOptionValues[Key]) or option.Value
		value = (cur_val / #point_buttons) or 0
		range_val = (cur_val / #point_buttons) or 0
		customValues[Key] = ScpuiOptionValues[Key] or option.Value
		default = option.Value
	end
	
    local function updateRangeValue(value, range_val)
        option.Value = value
        if value_el then
			if option.Category ~= "Custom" then
				value_el.inner_rml = value.Display
			else
				local index = (math.floor(option.Value * #point_buttons)) + custom_init
				if index > 5 then index = 5 end
				if index < 1 then index = 1 end
				if option.DisplayNames then
					value_el.inner_rml = option.DisplayNames[index]
				else
					value_el.inner_rml = index
				end
			end
        end
		
		if option.Category == "Custom" then
			customValues[Key] = (math.ceil(option.Value * #point_buttons)) + custom_init
			customOptions[Key].currentValue = (math.ceil(option.Value * #point_buttons)) + custom_init
			customOptions[Key].incrementValue = option.Value
			customOptions[Key].savedValue = (math.ceil(option.Value * #point_buttons)) + custom_init
			self:setModDefaultStatus()
		end

        -- This gives us the index of the last button that should be shown as active. The value is in the range between
        -- 0 and 1 so multiplying that with 9 maps that to our buttons since the first button has the value 0. We floor
        -- the value to get a definite index into our array
        -- + 1 is needed since Lua has 1-based arrays
        local last_active = math.floor(range_val * num_value_points) + 1

        for i, button in ipairs(point_buttons) do
            button:SetPseudoClass("checked", i <= last_active)
        end
    end
	
	--Save all the data for custom options here for resetting to default
	if option.Category == "Custom" then
		local displayStrings = nil
		if option.DisplayNames then
			displayStrings = option.DisplayNames
		end
		customOptions[Key] = {
			key = Key,
			optType = "MultiPoint",
			defaultValue = default,
			currentValue = customValues[Key],
			savedValue = customValues[Key],
			incrementValue = value,
			parentID = el_actual,
			buttons = point_buttons,
			numPoints = num_value_points,
			strings = displayStrings,
			range = range_val,
			valueID = value_el,
			noDefault = option.NoDefault
			
		}
	end

    updateRangeValue(value, range_val)

    for i, v in ipairs(point_buttons) do
        -- Basically the reverse from above, get the range value that corresponds to this button
        local btn_range_value = (i - 1) / num_value_points
		

        v:AddEventListener("click", function()
			local option_val = nil
			custom_init = 1

			if option.Category ~= "Custom" then
				option_val = option:getValueFromRange(btn_range_value)
				if option_val ~= option.Value then
					updateRangeValue(option_val, btn_range_value)
					if onchange_func then
						onchange_func(option_val)
					end
				end
			else
				option_val = (i - 1) / (num_value_points +1)
				if option_val ~= customOptions[Key].incrementValue then
					updateRangeValue(option_val, btn_range_value)
					customValues[Key] = (1 + math.ceil(option_val * #point_buttons))
					if onchange_func then
						onchange_func(option_val)
					end
				end
			end
        end)
    end

    local function make_click_listener(value_increment)
        return function()
			custom_init = 0
            local current_range_val = nil
			if option.Category ~= "Custom" then
				current_range_val = option:getInterpolantFromValue(option.Value)
			else
				current_range_val = customOptions[Key].incrementValue
			end

            -- Every point more represents one num_value_points th of the range
            current_range_val       = current_range_val + value_increment
            if current_range_val < 0 then
                current_range_val = 0
            end
            if current_range_val > 1 then
                current_range_val = 1
            end

			local new_val = nil
			
			if option.Category ~= "Custom" then
				new_val = option:getValueFromRange(current_range_val)
			else
				new_val = current_range_val
			end

            if new_val ~= option.Value then
				if option.Category ~= "Custom" then
					updateRangeValue(new_val, current_range_val)
				else
					updateRangeValue(new_val, current_range_val)
					customValues[Key] = (math.ceil(new_val * #point_buttons))
				end

                ui.playElementSound(btn_left, "click", "success")

                if onchange_func then
                    onchange_func(new_val)
                end
            else
                ui.playElementSound(btn_left, "click", "error")
            end
        end
    end

    btn_left:AddEventListener("click", make_click_listener(-(1.0 / num_value_points)))
    btn_right:AddEventListener("click", make_click_listener(1.0 / num_value_points))
end

function OptionsController:createTenPointRangeElement(option, parent_id, parameters, onchange_func)
    local parent_el                                                                                                      = self.document:GetElementById(parent_id)
    local actual_el, title_el, btn_left, btn_right, btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7, btn_8, btn_9 = templates.instantiate_template(self.document,
                                                                                                                                                         "tenpoint_selector_template",
                                                                                                                                                         getOptionElementId(option),
                                                                                                                                                         {
                                                                                                                                                             "tps_title_el",
                                                                                                                                                             "tps_left_arrow",
                                                                                                                                                             "tps_right_arrow",
                                                                                                                                                             "tps_button_0",
                                                                                                                                                             "tps_button_1",
                                                                                                                                                             "tps_button_2",
                                                                                                                                                             "tps_button_3",
                                                                                                                                                             "tps_button_4",
                                                                                                                                                             "tps_button_5",
                                                                                                                                                             "tps_button_6",
                                                                                                                                                             "tps_button_7",
                                                                                                                                                             "tps_button_8",
                                                                                                                                                             "tps_button_9",
                                                                                                                                                         },
                                                                                                                                                         parameters)
    parent_el:AppendChild(actual_el)

    title_el.inner_rml = option.Title

    self:init_point_slider_element(nil, btn_left, btn_right,
                                   { btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7, btn_8, btn_9 }, option,
                                   onchange_func, actual_el)

    return actual_el
end

function OptionsController:createFivePointRangeElement(option, parent_id, onchange_func)
    local parent_el                                                                             = self.document:GetElementById(parent_id)
    local actual_el, title_el, value_el, btn_left, btn_right, btn_0, btn_1, btn_2, btn_3, btn_4 = templates.instantiate_template(self.document,
                                                                                                                                "fivepoint_selector_template",
                                                                                                                                getOptionElementId(option),
                                                                                                                                {
                                                                                                                                    "fps_title_text",
                                                                                                                                    "fps_value_text",
                                                                                                                                    "fps_left_btn",
                                                                                                                                    "fps_right_btn",
                                                                                                                                    "fps_button_0",
                                                                                                                                    "fps_button_1",
                                                                                                                                    "fps_button_2",
                                                                                                                                    "fps_button_3",
                                                                                                                                    "fps_button_4",
                                                                                                                                })
    parent_el:AppendChild(actual_el)

    title_el.inner_rml = option.Title

    self:init_point_slider_element(value_el, btn_left, btn_right, { btn_0, btn_1, btn_2, btn_3, btn_4 }, option,
                                   onchange_func, actual_el)

    return actual_el
end

function OptionsController:init_binary_element(left_btn, right_btn, option, vals, change_func, el_actual)

	local Key = option.Key
	local default = nil

    left_btn:AddEventListener("click", function()
		if option.Category == "Custom" then
			option.Value = vals[1]
			customValues[Key] = option.Value
			customOptions[Key].currentValue = option.Value
			customOptions[Key].savedValue = option.Value
			left_btn:SetPseudoClass("checked", true)
            right_btn:SetPseudoClass("checked", false)
			self:setModDefaultStatus()
		elseif option.Category ~= "Custom" and vals[1] ~= option.Value then
			option.Value = vals[1]
            left_btn:SetPseudoClass("checked", true)
            right_btn:SetPseudoClass("checked", false)
            if change_func then
                change_func(vals[1])
            end
			self:setDetailDefaultStatus()
        end
    end)
    right_btn:AddEventListener("click", function()
		if option.Category == "Custom" then
			option.Value = vals[2]
			customValues[Key] = option.Value
			customOptions[Key].currentValue = option.Value
			customOptions[Key].savedValue = option.Value
			left_btn:SetPseudoClass("checked", false)
            right_btn:SetPseudoClass("checked", true)
			self:setModDefaultStatus()
		elseif option.Category ~= "Custom" and vals[2] ~= option.Value then
			option.Value = vals[2]
            left_btn:SetPseudoClass("checked", false)
            right_btn:SetPseudoClass("checked", true)
            if change_func then
                change_func(vals[2])
            end
			self:setDetailDefaultStatus()
        end
    end)
	
	if option.Category == "Custom" then
		default = option.Value
		option.Value = ScpuiOptionValues[Key] or option.Value
		customValues[Key] = ScpuiOptionValues[Key] or option.Value
	end

    local value          = option.Value
    local right_selected = value == vals[2]
    left_btn:SetPseudoClass("checked", not right_selected)
    right_btn:SetPseudoClass("checked", right_selected)
	
	--Save all the data for custom options here for resetting to default
	if option.Category == "Custom" then
		customOptions[Key] = {
			key = Key,
			optType = "Binary",
			defaultValue = default,
			currentValue = option.Value,
			savedValue = option.Value,
			validVals = vals,
			parentID = el_actual,
			noDefault = option.NoDefault
		}
	else
		for k, v in pairs(detailPresets) do
			if el_actual.id == v then
				detailOptions[Key] = {
					key = Key,
					title = option.Title,
					optType = "Binary",
					validVals = vals,
					optionID = option,
					currentValue = value,
					savedValue = value,
					validVals = vals,
					parentID = el_actual
				}
			end
		end
	end
			
end

function OptionsController:createBinaryOptionElement(option, vals, parent_id, onchange_func)
    local parent_el                                                       = self.document:GetElementById(parent_id)
    local actual_el, title_el, btn_left, text_left, btn_right, text_right = templates.instantiate_template(self.document,
                                                                                                          "binary_selector_template",
                                                                                                          getOptionElementId(option),
                                                                                                          {
                                                                                                              "binary_text_el",
                                                                                                              "binary_left_btn_el",
                                                                                                              "binary_left_text_el",
                                                                                                              "binary_right_btn_el",
                                                                                                              "binary_right_text_el",
                                                                                                          })
    parent_el:AppendChild(actual_el)

    title_el.inner_rml   = option.Title

	--OR is for custom options built from the CFG file
    text_left.inner_rml  = vals[1].Display or option.DisplayNames[vals[1]]
    text_right.inner_rml = vals[2].Display or option.DisplayNames[vals[2]]

    self:init_binary_element(btn_left, btn_right, option, vals, onchange_func, actual_el)

    return actual_el
end

function OptionsController:init_selection_element(element, option, vals, change_func, el_actual)

	local Key = option.Key
	local default = nil

    local select_el = Element.As.ElementFormControlDataSelect(element)
	if option.Category ~= "Custom" then
		select_el:SetDataSource(getFormatterName(option.Key) .. ".Default")
	else
		select_el:SetDataSource(option.Key .. ".Default")
	end
	
	if option.Category == "Custom" then
		--Find the index of the translated value
		local count = 1
		for i = 1, #option.ValidValues do
			if option.Value == option.DisplayNames[option.ValidValues[i]] then
				count = i
				break
			end
		end
	
		default = option.Value
		option.Value = ScpuiOptionValues[Key] or option.ValidValues[count]
		customValues[Key] = ScpuiOptionValues[Key] or option.ValidValues[count]
	end
	
	local value = option.Value

    element:AddEventListener("change", function(event, _, _)
        for _, v in ipairs(vals) do
            if v.Serialized == event.parameters.value and option.Value ~= v then
                option.Value = v
                if change_func then
                    change_func(v)
                end
            end
			if option.Category == "Custom" then
				
				--Find the index of the translated value
				local count = 1
				for i = 1, #option.ValidValues do
					if event.parameters.value == option.DisplayNames[option.ValidValues[i]] then
						count = i
						break
					end
				end
				
				--Use the index to save the actual internal value
				customValues[Key] = vals[count]
				customOptions[Key].currentValue = vals[count]
				customOptions[Key].savedValue = vals[count]
			else
				for k, v in pairs(detailPresets) do
					if el_actual.id == v then
						if el_actual.id == "option_graphics_anisotropy_element" then
							--This option saves reports the string so we need to save the known index
							local a_value = 5
							if event.parameters.value == "1.0" then a_value = 1 end
							if event.parameters.value == "2.0" then a_value = 2 end
							if event.parameters.value == "4.0" then a_value = 3 end
							if event.parameters.value == "8.0" then a_value = 4 end
							detailOptions[Key].currentValue = a_value
							detailOptions[Key].savedValue = a_value
						else
							--Translate from a 0 based index to a 1 based index because reasons??
							if tonumber(event.parameters.value) then
								detailOptions[Key].currentValue = event.parameters.value + 1
								detailOptions[Key].savedValue = event.parameters.value + 1
							end
						end
					end
				end
			end
        end
		if option.Category ~= "Custom" then
			self:setDetailDefaultStatus()
		else
			self:setModDefaultStatus()
		end
    end)
	
	--Save all the data for custom options here for resetting to default
	if option.Category == "Custom" then
		customOptions[Key] = {
			key = Key,
			optType = "Multi",
			defaultValue = default,
			currentValue = option.Value,
			savedValue = option.Value,
			validVals = vals,
			parentID = el_actual,
			selectID = select_el,
			noDefault = option.NoDefault
		}
	else
		for k, v in pairs(detailPresets) do
			if el_actual.id == v then
				detailOptions[Key] = {
					key = Key,
					optType = "Multi",
					currentValue = tblUtil.ifind(vals, value),
					savedValue = tblUtil.ifind(vals, value),
					validVals = vals,
					parentID = el_actual,
					selectID = select_el
				}
			end
		end
	end
    select_el.selection = tblUtil.ifind(vals, value)
end

function OptionsController:createSelectionOptionElement(option, vals, parent_id, parameters, onchange_func)
    local parent_el                         = self.document:GetElementById(parent_id)
    local actual_el, text_el, dataselect_el = templates.instantiate_template(self.document, "dropdown_template",
                                                                            getOptionElementId(option), {
                                                                                "dropdown_text_el",
                                                                                "dropdown_dataselect_el"
                                                                            }, parameters)
    parent_el:AppendChild(actual_el)

    -- If no_title was specified then this element will be nil
    if text_el ~= nil then
        text_el.inner_rml = option.Title
    end

    self:init_selection_element(dataselect_el, option, vals, onchange_func, actual_el)

    return actual_el
end

function OptionsController:init_range_element(element, value_el, option, change_func, el_actual)

	local Key = option.Key
	local default = nil

    local range_el = Element.As.ElementFormControlInput(element)

    element:AddEventListener("change", function(event, _, _)
		local value = nil
		if option.Category ~= "Custom" then
			value        = option:getValueFromRange(event.parameters.value)
			value_el.inner_rml = value.Display
		else
			value        = event.parameters.value
			value_el.inner_rml = tostring(value * option.Max):sub(1,4)
			customValues[Key] = tostring(value * option.Max):sub(1,4)
			if customOptions[Key] then
				customOptions[Key].currentValue = tostring(value * option.Max):sub(1,4)
				customOptions[Key].savedValue = tostring(value * option.Max):sub(1,4)
				self:setModDefaultStatus()
			end
		end

        if option.Value ~= value then
            option.Value = value
            if change_func then
                change_func(value)
            end
        end
    end)
	
	--This is a special case just for Font_Multiplier to allow live update
	if Key == "Font_Multiplier" then
		element:AddEventListener("click", function(event, _, _)
			range_el.value = customOptions[Key].currentValue
			fontChoice = "p1-" .. ScpuiSystem:getFontSize(customOptions[Key].currentValue)
			
			--Clear all possible font classes
			for i = 0, ScpuiSystem.numFontSizes do
				local class = "p1-" .. i
				self.document:GetElementById("main_background"):SetClass(class, false)
			end
			
			--Now apply the new class
			self.document:GetElementById("main_background"):SetClass(fontChoice, true)
		end)
	end
			

	if option.Category ~= "Custom" then
		range_el.value = option:getInterpolantFromValue(option.Value)
	else
		local thisValue = ScpuiOptionValues[Key] or option.Value
		default = option.Value
		option.Value = thisValue
		range_el.value = thisValue / option.Max
		range_el.step = (option.Max - option.Min) / 100
	end
	
	--Save all the data for custom options here for resetting to default
	if option.Category == "Custom" then
		customOptions[Key] = {
			key = Key,
			optType = "Range",
			defaultValue = default,
			currentValue = option.Value,
			savedValue = option.Value,
			parentID = el_actual,
			rangeID = range_el,
			maxValue = option.Max,
			noDefault = option.NoDefault
		}
	end
end

function OptionsController:createRangeOptionElement(option, parent_id, onchange_func)
    local parent_el                               = self.document:GetElementById(parent_id)
    local actual_el, title_el, value_el, range_el = templates.instantiate_template(self.document, "slider_template",
                                                                                  getOptionElementId(option), {
                                                                                      "slider_title_el",
                                                                                      "slider_value_el",
                                                                                      "slider_range_el"
                                                                                  })
    parent_el:AppendChild(actual_el)

    title_el.inner_rml = option.Title

    self:init_range_element(range_el, value_el, option, onchange_func, actual_el)

    return actual_el
end

function OptionsController:createHeaderOptionElement(option, parent_id)
    local parent_el                               = self.document:GetElementById(parent_id)
    local actual_el, title_el = templates.instantiate_template(self.document, "header_template",
                                                               getOptionElementId(option), {
                                                                   "header_title_el"
                                                               })
    parent_el:AppendChild(actual_el)

    title_el.inner_rml = option.Title

	---Load the desired font size from the save file
	self.document:GetElementById(actual_el.id):SetClass("p2-" .. ScpuiSystem:getFontSize(), true)

    return actual_el
end

function OptionsController:create(option, parent_id, onchange_func)
    local parent_el                               = self.document:GetElementById(parent_id)
    local actual_el, title_el, value_el, range_el = templates.instantiate_template(self.document, "slider_template",
                                                                                  getOptionElementId(option), {
                                                                                      "slider_title_el",
                                                                                      "slider_value_el",
                                                                                      "slider_range_el"
                                                                                  })
    parent_el:AppendChild(actual_el)

    title_el.inner_rml = option.Title

    self:init_range_element(range_el, value_el, option, onchange_func)

    return actual_el
end

function OptionsController:createOptionElement(option, parent_id, onchange_func)
    if option.Type == OPTION_TYPE_SELECTION then
        local vals = option:getValidValues()

        if #vals == 2 and not option.Flags.ForceMultiValueSelection then
            -- Special case for binary options
            return self:createBinaryOptionElement(option, vals, parent_id, onchange_func)
        else
            return self:createSelectionOptionElement(option, vals, parent_id, nil, onchange_func)
        end
    elseif option.Type == OPTION_TYPE_RANGE then
        return self:createRangeOptionElement(option, parent_id, onchange_func)
    end
end

function OptionsController:createCustomOptionElement(option, parent_id, onchange_func)
    if (option.Type == "Binary") or (option.Type == "Multi") then
        local vals = option.ValidValues
		
		--self.sources[option.Key] = createOptionSource(option)

        if #vals == 2 and not option.ForceSelector then
            -- Special case for binary options
            return self:createBinaryOptionElement(option, vals, parent_id, onchange_func)
        else
			return self:createSelectionOptionElement(option, vals, parent_id, nil, onchange_func)
        end
    elseif option.Type == "Range" then
        return self:createRangeOptionElement(option, parent_id, onchange_func)
	elseif option.Type == "TenPoint" then
		local wrapper = option.Key .. "_wrapper"
		return self:createTenPointRangeElement(option, parent_id, {
                text_alignment = "left",
                no_background  = false
            })
    elseif option.Type == "FivePoint" then
		return self:createFivePointRangeElement(option, parent_id)
	elseif option.Type == "Header" then
        return self:createHeaderOptionElement(option, parent_id)
	end
end

function OptionsController:handleBrightnessOption(option, onchange_func)
    local increase_btn = self.document:GetElementById("brightness_increase_btn")
    local decrease_btn = self.document:GetElementById("brightness_decrease_btn")
    local value_el     = self.document:GetElementById("brightness_value_el")

    local vals         = option:getValidValues()
    local current      = option.Value

    value_el.inner_rml = current.Display

    increase_btn:AddEventListener("click", function()
        local current_index = tblUtil.ifind(vals, option.Value)
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
        local current_index = tblUtil.ifind(vals, option.Value)
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

function OptionsController:initialize_basic_options()
	--Create the font size selector option
	local fontOption = {
		Title = utils.xstr({"Font Size Multiplier", -1}),
		Description = utils.xstr({"Multiplies the font size", -1}),
		Key = "Font_Multiplier",
		Type = "Range",
		Category = "Custom",
		Min = 0,
		Max = 1,
		Value = 0.25
	}
	local font_el = self:createCustomOptionElement(fontOption, "font_size_selector")
	self:AddOptionTooltip(fontOption, font_el)
	
    for _, option in ipairs(self.category_options.basic) do
        local key = option.Key
		local opt_el = nil
        if key == "Input.Joystick2" then
            opt_el = self:createSelectionOptionElement(option, option:getValidValues(), "joystick_column_1", {
                --no_title = true
            })
		elseif key == "Input.Joystick" then
            opt_el = self:createSelectionOptionElement(option, option:getValidValues(), "joystick_column_1", {
                --no_title = true
            })
		elseif key == "Input.Joystick1" then
            opt_el = self:createSelectionOptionElement(option, option:getValidValues(), "joystick_column_2", {
                --no_title = true
            })
		elseif key == "Input.Joystick3" then
            opt_el = self:createSelectionOptionElement(option, option:getValidValues(), "joystick_column_2", {
                --no_title = true
            })
        elseif key == "Input.JoystickDeadZone" then
            opt_el = self:createTenPointRangeElement(option, "joystick_values_wrapper", {
                text_alignment = "right",
                --no_background  = true
            })
        elseif key == "Input.JoystickSensitivity" then
            opt_el = self:createTenPointRangeElement(option, "joystick_values_wrapper", {
                text_alignment = "right",
                --no_background  = true
            })
        elseif key == "Input.UseMouse" then
            opt_el = self:createOptionElement(option, "mouse_options_container")
        elseif key == "Input.MouseSensitivity" then
            opt_el = self:createTenPointRangeElement(option, "mouse_options_container", {
                text_alignment = "left",
                no_background  = false
            })
		elseif key == "Game.Language" then
            opt_el = self:createSelectionOptionElement(option, option:getValidValues(), "language_selector", {
                --no_title = true
            })
		elseif key == "Game.Discord" then
            opt_el = self:createOptionElement(option, "discord_selector")
        elseif key == "Audio.BriefingVoice" then
            opt_el = self:createOptionElement(option, "briefing_voice_container")
		elseif key == "Game.UnfocusedPause" then
            opt_el = self:createOptionElement(option, "unfocused_pause_container")
        elseif key == "Audio.Effects" then
            -- The audio options are applied immediately so the user hears the effects
            self.option_backup[option] = option.Value

            opt_el = self:createTenPointRangeElement(option, "volume_sliders_container", {
                text_alignment = "left",
                no_background  = true
            }, function(_)
                option:persistChanges()
				topics.options.changeEffectsVol:send(self)
            end)
        elseif key == "Audio.Music" then
            self.option_backup[option] = option.Value

            opt_el = self:createTenPointRangeElement(option, "volume_sliders_container", {
                text_alignment = "left",
                no_background  = true
            }, function(_)
                option:persistChanges()
            end)
        elseif key == "Audio.Voice" then
            self.option_backup[option] = option.Value

            opt_el = self:createTenPointRangeElement(option, "volume_sliders_container", {
                text_alignment = "left",
                no_background  = true
            }, function(_)
                option:persistChanges()
                ui.OptionsMenu.playVoiceClip()
				topics.options.changeVoiceVol:send(self)
            end)
        elseif key == "Game.SkillLevel" then
            opt_el = self:createFivePointRangeElement(option, "skill_level_container")
        elseif key == "Graphics.Gamma" then
            self.option_backup[option] = option.Value

            self:handleBrightnessOption(option, function(_)
                -- Apply changes immediately to make them visible
                option:persistChanges()
            end)
			
			opt_el = self.document:GetElementById("gamma_option")
        end
		
		if option.Description then
			self:AddOptionTooltip(option, opt_el)
		end
    end
end

local built_in_detail_keys = {
    "Graphics.NebulaDetail",
    "Graphics.Lighting",
    "Graphics.Detail",
    "Graphics.Texture",
    "Graphics.Particles",
    "Graphics.SmallDebris",
    "Graphics.ShieldEffects",
    "Graphics.Stars",
};

function OptionsController:initialize_detail_options()
    local current_column = 3
    for _, option in ipairs(self.category_options.detail) do
		local opt_el = nil
		
        if option.Key == "Graphics.Resolution" then
            opt_el = self:createOptionElement(option, "detail_column_1")
        elseif option.Key == "Graphics.WindowMode" then
            opt_el = self:createOptionElement(option, "detail_column_1")
        elseif option.Key == "Graphics.Display" then
            opt_el = self:createOptionElement(option, "detail_column_1", function(_)
                self.sources["Graphics.Resolution"]:updateValues()
            end)
        elseif tblUtil.contains(built_in_detail_keys, option.Key) then
            opt_el = self:createOptionElement(option, "detail_column_2")
        else
            local el = self:createOptionElement(option, string.format("detail_column_%d", current_column))
			
			opt_el = el

            if current_column == 2 or current_column == 3 then
                el:SetClass("horz_middle", true)
            elseif current_column == 4 then
                el:SetClass("horz_right", true)
            end

            current_column = current_column + 1
            if current_column > 4 then
                current_column = 3
            end
        end
		
		if option.Description then
			self:AddOptionTooltip(option, opt_el)
		end
    end
	
	self:setDetailDefaultStatus()
end

--Here are where we parse and place mod options into the Preferences tab
function OptionsController:initialize_prefs_options()
    local current_column = 1
	
	--Handle built-in preferences options
	for _, option in ipairs(self.category_options.prefs) do
		local el = self:createOptionElement(option, string.format("prefs_column_%d", current_column))
		
		if option.Description then
			self:AddOptionTooltip(option, el)
		end

		if current_column == 2 or current_column == 3 then
			el:SetClass("horz_middle", true)
		elseif current_column == 4 then
			el:SetClass("horz_right", true)
		end
		
		current_column = current_column + 1
		if current_column > 4 then
			current_column = 3
		end
	end
	
	--Handle mod custom preferences options
    for _, option in ipairs(ScpuiSystem.CustomOptions) do
		option.Category = "Custom"
		--option.Title = option.Title
		local el = self:createCustomOptionElement(option, string.format("prefs_column_%d", option.Column))
		
		if option.Description then
			self:AddOptionTooltip(option, el)
		end

		if option.Column == 2 or option.Column == 3 then
			el:SetClass("horz_middle", true)
		elseif option.Column == 4 then
			el:SetClass("horz_right", true)
		end

		current_column = current_column + 1
		if current_column > 4 then
			current_column = 3
		end
    end
	
	self:setModDefaultStatus()
	
end

function OptionsController:RemoveSelectedIP()
	if self.selectedIP then
		local ip_el = self.document:GetElementById("ipaddress_list")
		for _, child in ipairs(ip_el.child_nodes) do
			if child.id == self.selectedIP.id then
				ip_el:RemoveChild(child)
				break
			end
		end
	end
end

function OptionsController:IsDuplicateIP(id)
	local ip_el = self.document:GetElementById("ipaddress_list")
	for _, child in ipairs(ip_el.child_nodes) do
		if child.id == id then
			return true
		end
	end
	
	return false
end

function OptionsController:AddSelectedIP()
	if string.len(self.submittedIP) > 0 then
		--if not self:IsDuplicateIP(self.submittedIP) then
			if opt.verifyIPAddress(self.submittedIP) then
				local ip_el = self.document:GetElementById("ipaddress_list")
				ip_el:AppendChild(self:CreateIPItem(self.submittedIP))
			else
				local builder      = dialogs.new()
				builder:title(ba.XSTR("Invalid IP", -1))
				builder:text(ba.XSTR("Ip string is invalid!", 386))
				builder:escape(false)
				builder:button(dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Ok", -1), true, string.sub(ba.XSTR("Ok", -1), 1, 1))
				builder:show(self.document.context):continueWith(function() end)
			end
		--[[else
			local builder      = dialogs.new()
			builder:title(ba.XSTR("Duplicate IP", -1))
			builder:text(ba.XSTR("IP Address already listed!", -1))
			builder:escape(false)
			builder:button(dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Ok", -1), true, string.sub(ba.XSTR("Ok", -1), 1, 1))
			builder:show(self.document.context):continueWith(function() end)
		end]]--
	end
	
	self.ip_input_el:SetAttribute("value", "")
	self.submittedIP = ""
end

function OptionsController:IPInputChange(event)
	--remove all whitespace
	local stringValue = event.parameters.value:gsub("^%s*(.-)%s*$", "%1")
	
	--If RETURN was not pressed then make sure the input is a number with no spaces. Else save the value, clear the field, and continue.
	if event.parameters.linebreak ~= 1 then
		local lastCharacter = string.sub(stringValue, -1)
		if type(tonumber(lastCharacter)) == "number" or lastCharacter == "." then
			self.ip_input_el:SetAttribute("value", stringValue)
		else
			--remove the trailing character because it was not valid
			stringValue = stringValue:sub(1, -2)
			self.ip_input_el:SetAttribute("value", stringValue)
		end
		
		self.submittedIP = self.ip_input_el:GetAttribute("value")
	else
		self:AddSelectedIP()
	end
end

function OptionsController:SelectIP(el)
	if self.selectedIP then
		self.selectedIP:SetPseudoClass("checked", false)
	end
	self.selectedIP = el
	self.selectedIP:SetPseudoClass("checked", true)
end

function OptionsController:CreateIPItem(entry)

	local li_el = self.document:CreateElement("li")

	li_el.inner_rml = entry
	li_el.id = entry

	li_el:SetClass("ipaddress_list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:SelectIP(li_el)
	end)

	return li_el
end

function OptionsController:togglePXO(toggle)
	local loc_el = self.document:GetElementById("local_btn")
	local pxo_el = self.document:GetElementById("pxo_btn")
	local loc_vals = self.local_opt:getValidValues()
	local pxo_vals = self.pxo_opt:getValidValues()
	
	if toggle then
		loc_el:SetPseudoClass("checked", false)
		pxo_el:SetPseudoClass("checked", true)
		self.local_opt.Value = loc_vals[1]
		self.pxo_opt.Value = loc_vals[2]
	else
		loc_el:SetPseudoClass("checked", true)
		pxo_el:SetPseudoClass("checked", false)
		self.local_opt.Value = loc_vals[2]
		self.pxo_opt.Value = loc_vals[1]
	end
end

function OptionsController:LoginChanged()
	self.login_changed = true
end

function OptionsController:PassChanged()
	self.pass_changed = true
end

function OptionsController:SquadChanged()
	self.squad_changed = true
end

function OptionsController:initialize_multi_options()
	
	--Handle the IP Address list
	local ips = opt.readIPAddressTable()
	self.submittedIP = ""
	self.ip_input_el = self.document:GetElementById("add_ip_field")
	
	local ip_el = self.document:GetElementById("ipaddress_list")
	
	for i = 1, #ips do
		ip_el:AppendChild(self:CreateIPItem(ips[i]))
	end
	
	local ip_opt = {
		Key = "ipaddress_list",
		Description = "IP Addresses to watch or something. I dunno. Mjn Fix this."
	}
	
	self:AddOptionTooltip(ip_opt, self.ip_input_el)
	
	--Handle the login info
	self.document:GetElementById("login_field"):SetAttribute("value", opt.MultiLogin)
	self.document:GetElementById("squad_field"):SetAttribute("value", opt.MultiSquad)
	if opt.MultiPassword then
		self.document:GetElementById("pass_field"):SetAttribute("value", "******")
	end
	
	self.login_changed = false
	self.pass_changed = false
	self.squad_changed = false
	
	local login_opt = {
		Key = "login_info",
		Description = "Your PXO multiplayer username"
	}
	
	local pass_opt = {
		Key = "password_info",
		Description = "Your PXO multiplayer password"
	}
	
	local squad_opt = {
		Key = "squad_info",
		Description = "Your PXO multiplayer squadron name"
	}
	
	self:AddOptionTooltip(login_opt, self.document:GetElementById("login_field"))
	self:AddOptionTooltip(pass_opt, self.document:GetElementById("pass_field"))
	self:AddOptionTooltip(squad_opt, self.document:GetElementById("squad_field"))
	
	--Handle the rest of the options
	for _, option in ipairs(self.category_options.multi) do
		if option.Key == "Multi.LocalBroadcast" then
			self.local_opt = option
			local btn_el = self.document:GetElementById("local_btn")
			btn_el:AddEventListener("click", function()
				if option.Value.Display == "Off" then
					self:togglePXO(false)
				end
			end)
			if option.Value.Display == "On" then
				btn_el:SetPseudoClass("checked", true)
			else
				btn_el:SetPseudoClass("checked", false)
			end
			self:AddOptionTooltip(option, btn_el)
		elseif option.Key == "Multi.TogglePXO" then
			self.pxo_opt = option
			local btn_el = self.document:GetElementById("pxo_btn")
			btn_el:AddEventListener("click", function()
				if option.Value.Display == "Off" then
					self:togglePXO(true)
				end
			end)
			if option.Value.Display == "On" then
				self.document:GetElementById("pxo_btn"):SetPseudoClass("checked", true)
			else
				self.document:GetElementById("pxo_btn"):SetPseudoClass("checked", false)
			end
			self:AddOptionTooltip(option, btn_el)
		elseif option.Key == "Multi.TransferMissions" then
			opt_el = self:createOptionElement(option, "multi_column_2")
		elseif option.Key == "Multi.FlushCache" then
			opt_el = self:createOptionElement(option, "multi_column_2")
		end
	end
end

function OptionsController:AddOptionTooltip(option, parent)
	if option == nil or parent == nil then
		return
	end

	local tool_el = self.document:CreateElement("div")
	tool_el.id = option.Key .. "_tooltip"
	tool_el:SetClass("tooltip", true)
	tool_el.inner_rml = "<span class=\"tooltiptext\">" .. option.Description .. "</span>"
	parent:AppendChild(tool_el)
	
	parent:AddEventListener("mouseover", function()
		if self.timers[option.Key] == nil then
			self.timers[option.Key] = 0
		else
			self:MaybeShowTooltip(tool_el, option.Key)
		end
	end)
	
	parent:AddEventListener("mouseout", function()
		self.timers[option.Key] = nil
		tool_el:SetPseudoClass("shown", false)
	end)
end

function OptionsController:MaybeShowTooltip(tool_el, key)
	if self.timers[key] == nil then
		return
	end
	
	if self.timers[key] >= 5 then
		tool_el:SetPseudoClass("shown", true)
	else
		async.run(function()
			async.await(async_util.wait_for(1.0))
			if self.timers[key] ~= nil then
				self.timers[key] = self.timers[key] + 1
				self:MaybeShowTooltip(tool_el, key)
			end
		end, async.OnFrameExecutor)
	end
end

function OptionsController:initialize(document)
    self.document = document
	
	---Load background choice
	self.document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)
	
	---Load the desired font size from the save file
	self.document:GetElementById("main_background"):SetClass(("p1-" .. ScpuiSystem:getFontSize()), true)

    -- Persist current changes since we might discard them in this screen
    opt.persistChanges()

    self.options = opt.Options
    ba.print("Printing option ID mapping:\n")
    for _, v in ipairs(self.options) do
        ba.print(string.format("%s (%s): %s\n", v.Title, v.Key, getOptionElementId(v)))

		--Creates data sources for built-in dropdowns
        if v.Type == OPTION_TYPE_SELECTION then
            self.sources[v.Key] = createOptionSource(v)
        end
		
		--Creates data sources for custom dropdowns
		for i, v in ipairs(ScpuiSystem.CustomOptions) do
			v.Category = "Custom"
			if (v.Type == "Multi") or (v.Type == "Binary") then
				self.sources[v.Key] = createOptionSource(v)
			end
		end

        local category = getCategoryFromKey(v.Key)
        local key      = v.Key

        if category == "Input" or category == "Audio" or category == "Game" or key == "Graphics.Gamma" then
            table.insert(self.category_options.basic, v)
        elseif category == "Graphics" then
            table.insert(self.category_options.detail, v)
		elseif category == "Other" then
            table.insert(self.category_options.prefs, v)
		elseif category == "Multi" then
			table.insert(self.category_options.multi, v)
        end
    end
    ba.print("Done.\n")

    self:initialize_basic_options()

    self:initialize_detail_options()
	
	self:initialize_prefs_options()
	
	self:initialize_multi_options()
	
	if ScpuiSystem.hideMulti == true then
		self.document:GetElementById("multi_btn"):SetClass("hidden", true)
	end
	
	topics.options.initialize:send(self)
end

function OptionsController:acceptChanges(state)
	
	ScpuiOptionValues = customValues

	--Save mod options to file
	ScpuiSystem:saveOptionsToFile(ScpuiOptionValues)
	
	--Save mod options to global file for recalling before a player is selected
	saveFilename = "scpui_options_global.cfg"
	local json = require('dkjson')
    local file = cf.openFile(saveFilename, 'w', 'data/players')
    file:write(json.encode(ScpuiOptionValues))
    file:close()

	--Persist base options
    local unchanged = opt.persistChanges()
	
	--Save the IP table
	local ip_el = self.document:GetElementById("ipaddress_list")
	local ip_tbl = {}
	for _, child in ipairs(ip_el.child_nodes) do
		table.insert(ip_tbl, child.inner_rml)
	end
	opt.writeIPAddressTable(ip_tbl)
	
	--Save the login info
	if self.login_changed == true then
		opt.MultiLogin = self.document:GetElementById("login_field"):GetAttribute("value")
	end
	if self.pass_changed == true then
		opt.MultiPassword = self.document:GetElementById("pass_field"):GetAttribute("value")
	end
	if self.squad_changed == true then
		opt.MultiSquad = self.document:GetElementById("squad_field"):GetAttribute("value")
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

    local dialog_text  = string.format(ba.XSTR("<p>The following changes require a restart to apply their changes:</p><p>%s</p>",
                                               -1), changed_text)

    local builder      = dialogs.new()
    builder:title(ba.XSTR("Restart required", -1))
    builder:text(dialog_text)
	builder:escape(false)
    builder:button(dialogs.BUTTON_TYPE_NEGATIVE, ba.XSTR("Cancel", -1), false, string.sub(ba.XSTR("Cancel", -1), 1, 1))
    builder:button(dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Ok", -1), true, string.sub(ba.XSTR("Ok", -1), 1, 1))
    builder:show(self.document.context):continueWith(function(val)
        if val then
			
			if mn.isInMission() then
				ScpuiSystem:pauseAllAudio(false)
			end
		
            ba.postGameEvent(ba.GameEvents[state])
        end
    end)
end

function OptionsController:SetDetailBullet(level)
	
	local lowbullet = self.document:GetElementById("det_low_btn")
	local medbullet = self.document:GetElementById("det_med_btn")
	local higbullet = self.document:GetElementById("det_hig_btn")
	local ultbullet = self.document:GetElementById("det_ult_btn")
	local cstbullet = self.document:GetElementById("det_cst_btn")
	local minbullet = self.document:GetElementById("det_min_btn")
	
	minbullet:SetPseudoClass("checked", level == "min")
	lowbullet:SetPseudoClass("checked", level == "low")
	medbullet:SetPseudoClass("checked", level == "med")
	higbullet:SetPseudoClass("checked", level == "hig")
	ultbullet:SetPseudoClass("checked", level == "ult")
	cstbullet:SetPseudoClass("checked", level == "cst")

end

function OptionsController:DetailMinimum(element)

	for k, v in pairs(detailOptions) do
		local option = detailOptions[k]
		for k, v in pairs(detailPresets) do
			if option.parentID.id == v then
				local parent = self.document:GetElementById(option.parentID.id)
				local savedValue = option.savedValue
				if option.optType == "Multi" then
					if option.parentID.id == "option_graphics_aamode_element" then
						option.currentValue = 1
						option.selectID.selection = 1
					elseif option.parentID.id == "option_graphics_msaasamples_element" then
						option.currentValue = 1
						option.selectID.selection = 1
					else
						option.currentValue = 1
						option.selectID.selection = 1
					end
				elseif option.optType == "Binary" then
					option.currentValue = option.validVals[1]
					local right_selected = option.currentValue == option.validVals[2]
					parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for k, v in pairs(opts) do
						if v.Key == option.key then
							v.Value = option.validVals[1]
						end
					end
				end
				option.savedValue = savedValue
			end
		end
	end
	
	graphicsCustom = false
	self:SetDetailBullet("min")

end

function OptionsController:DetailLow(element)
	
	for k, v in pairs(detailOptions) do
		local option = detailOptions[k]
		for k, v in pairs(detailPresets) do
			if option.parentID.id == v then
				local parent = self.document:GetElementById(option.parentID.id)
				local savedValue = option.savedValue
				if option.optType == "Multi" then
					if option.parentID.id == "option_graphics_aamode_element" then
						option.currentValue = 5
						option.selectID.selection = 5
					elseif option.parentID.id == "option_graphics_msaasamples_element" then
						option.currentValue = 1
						option.selectID.selection = 1
					else
						option.currentValue = 2
						option.selectID.selection = 2
					end
				elseif option.optType == "Binary" then
					option.currentValue = option.validVals[1]
					local right_selected = option.currentValue == option.validVals[2]
					parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for k, v in pairs(opts) do
						if v.Key == option.key then
							v.Value = option.validVals[1]
						end
					end
				end
				option.savedValue = savedValue
			end
		end
	end
	
	graphicsCustom = false
	self:SetDetailBullet("low")

end

function OptionsController:DetailMedium(element)
	
	for k, v in pairs(detailOptions) do
		local option = detailOptions[k]
		for k, v in pairs(detailPresets) do
			if option.parentID.id == v then
				local parent = self.document:GetElementById(option.parentID.id)
				local savedValue = option.savedValue
				if option.optType == "Multi" then
					if option.parentID.id == "option_graphics_aamode_element" then
						option.currentValue = 6
						option.selectID.selection = 6
					elseif option.parentID.id == "option_graphics_msaasamples_element" then
						option.currentValue = 2
						option.selectID.selection = 2
					else
						option.currentValue = 3
						option.selectID.selection = 3
					end
				elseif option.optType == "Binary" then
					option.currentValue = option.validVals[1]
					local right_selected = option.currentValue == option.validVals[2]
					parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for k, v in pairs(opts) do
						if v.Key == option.key then
							v.Value = option.validVals[1]
						end
					end
				end
				option.savedValue = savedValue
			end
		end
	end
	
	graphicsCustom = false
	self:SetDetailBullet("med")

end

function OptionsController:DetailHigh(element)
	
	for k, v in pairs(detailOptions) do
		local option = detailOptions[k]
		for k, v in pairs(detailPresets) do
			if option.parentID.id == v then
				local parent = self.document:GetElementById(option.parentID.id)
				local savedValue = option.savedValue
				if option.optType == "Multi" then
					if option.parentID.id == "option_graphics_aamode_element" then
						option.currentValue = 7
						option.selectID.selection = 7
					elseif option.parentID.id == "option_graphics_msaasamples_element" then
						option.currentValue = 3
						option.selectID.selection = 3
					else
						option.currentValue = 4
						option.selectID.selection = 4
					end
				elseif option.optType == "Binary" then
					option.currentValue = option.validVals[2]
					local right_selected = option.currentValue == option.validVals[2]
					parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for k, v in pairs(opts) do
						if v.Key == option.key then
							v.Value = option.validVals[2]
						end
					end
				end
				option.savedValue = savedValue
			end
		end
	end
	
	graphicsCustom = false
	self:SetDetailBullet("hig")

end

function OptionsController:DetailUltra(element)
	
	for k, v in pairs(detailOptions) do
		local option = detailOptions[k]
		for k, v in pairs(detailPresets) do
			if option.parentID.id == v then
				local parent = self.document:GetElementById(option.parentID.id)
				local savedValue = option.savedValue
				if option.optType == "Multi" then
					if option.parentID.id == "option_graphics_aamode_element" then
						option.currentValue = 8
						option.selectID.selection = 8
					elseif option.parentID.id == "option_graphics_msaasamples_element" then
						option.currentValue = 4
						option.selectID.selection = 4
					else
						option.currentValue = 5
						option.selectID.selection = 5
					end
				elseif option.optType == "Binary" then
					option.currentValue = option.validVals[2]
					local right_selected = option.currentValue == option.validVals[2]
					parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
					local opts = opt.Options
					for k, v in pairs(opts) do
						if v.Key == option.key then
							v.Value = option.validVals[2]
						end
					end
				end
				option.savedValue = savedValue
			end
		end
	end
	
	graphicsCustom = false
	self:SetDetailBullet("ult")

end

function OptionsController:DetailCustom(element)
	
	if graphicsCustom == false then
		for k, v in pairs(detailOptions) do
			local option = detailOptions[k]
			for k, v in pairs(detailPresets) do
				if option.parentID.id == v then
					local parent = self.document:GetElementById(option.parentID.id)
					if option.optType == "Multi" then
						option.currentValue = option.savedValue
						option.selectID.selection = option.savedValue
					elseif option.optType == "Binary" then
						option.currentValue = option.savedValue
						local right_selected = option.savedValue == option.validVals[2]
						parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
						parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
						local opts = opt.Options
						for k, v in pairs(opts) do
							if v.Key == option.key then
								v.Value = option.savedValue
							end
						end
					end
				end
			end
		end
		
		graphicsCustom = true
		self:SetDetailBullet("cst")
	end

end

function OptionsController:isDetailPreset(value)
	for k, v in pairs(detailOptions) do
		local option = detailOptions[k]
		if option.parentID.id == "option_graphics_aamode_element" then
			local a_value = 8
			if value == 1 then a_value = 1 end
			if value == 2 then a_value = 5 end
			if value == 3 then a_value = 6 end
			if value == 4 then a_value = 7 end
			if option.currentValue ~= a_value then
				return false
			end
		elseif option.parentID.id == "option_graphics_postprocessing_element" then
			local a_value = "On"
			if value == 1 then a_value = "Off" end
			if value == 2 then a_value = "Off" end
			if value == 3 then a_value = "Off" end
			if value == 4 then a_value = "On" end
			if option.currentValue.Display ~= a_value then
				return false
			end
		elseif option.parentID.id == "option_graphics_lightshafts_element" then
			local a_value = "On"
			if value == 1 then a_value = "Off" end
			if value == 2 then a_value = "Off" end
			if value == 3 then a_value = "Off" end
			if value == 4 then a_value = "On" end
			if option.currentValue.Display ~= a_value then
				return false
			end
		elseif option.parentID.id == "option_graphics_softparticles_element" then
			local a_value = "On"
			if value == 1 then a_value = "Off" end
			if value == 2 then a_value = "Off" end
			if value == 3 then a_value = "Off" end
			if value == 4 then a_value = "On" end
			if option.currentValue.Display ~= a_value then
				return false
			end
		else
			if option.currentValue ~= value then
				return false
			end
		end
	end
	return true
end

function OptionsController:setDetailDefaultStatus()
	
	local preset = "cst"
	graphicsCustom = true
	
	if self:isDetailPreset(1) then
		preset = "min"
		graphicsCustom = false
	elseif self:isDetailPreset(2) then
		preset = "low"
		graphicsCustom = false
	elseif self:isDetailPreset(3) then
		preset = "med"
		graphicsCustom = false
	elseif self:isDetailPreset(4) then
		preset = "hig"
		graphicsCustom = false
	elseif self:isDetailPreset(5) then
		preset = "ult"
		graphicsCustom = false
	end

	self:SetDetailBullet(preset)

end

function OptionsController:ModDefault(element)

	for k, v in pairs(customOptions) do
		local option = customOptions[k]
		if not option.noDefault then
			if option.optType == "Binary" and option.currentValue ~= option.defaultValue then
				local parent = self.document:GetElementById(option.parentID.id)
				customValues[option.key] = option.defaultValue
				option.currentValue = option.defaultValue
				local right_selected = option.defaultValue == option.validVals[2]
				parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
				parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
			end
			
			if option.optType == "Multi" and option.currentValue ~= option.defaultValue then
				local parent = self.document:GetElementById(option.parentID.id)
				customValues[option.key] = option.defaultValue
				option.currentValue = option.defaultValue
				local savedValue = option.savedValue				
				option.selectID.selection = tblUtil.ifind(option.validVals, option.defaultValue)
				option.savedValue = savedValue
			end
			
			if option.optType == "Range" and option.currentValue ~= option.defaultValue then
				local parent = self.document:GetElementById(option.parentID.id)
				customValues[option.key] = option.defaultValue
				option.currentValue = option.defaultValue
				local savedValue = option.savedValue
				option.rangeID.value = option.defaultValue / option.maxValue
				option.savedValue = savedValue
			end
			
			if option.optType == "MultiPoint" and option.currentValue ~= option.defaultValue then
				local parent = self.document:GetElementById(option.parentID.id)
				--local value_el = self.document:GetElementById(option.valueID.id)
				--ba.warning(option.currentValue .. " \ " .. option.defaultValue)
				customValues[option.key] = option.defaultValue
				option.currentValue = option.defaultValue
				local savedValue = option.savedValue
				--if value_el then
					local index = option.defaultValue
					if option.strings then
						if index > 5 then index = 5 end
						if index < 1 then index = 1 end
						parent.first_child.first_child.next_sibling.next_sibling.inner_rml = option.strings[index]
					else
						--value_el.inner_rml = index
					end
					option.incrementValue = (option.defaultValue / #option.buttons)
					customValues[option.key] = option.defaultValue
					customOptions[option.key].currentValue = option.defaultValue
				--end

				local last_active = option.defaultValue --math.floor(option.range * option.numPoints) + 1

				for i, button in ipairs(option.buttons) do
					button:SetPseudoClass("checked", i <= last_active)
				end
				option.savedValue = savedValue
			end
		end
	end
	
	modCustom = false
	local custombullet = self.document:GetElementById("mod_custom_btn")
	local modbullet = self.document:GetElementById("mod_default_btn")
	custombullet:SetPseudoClass("checked", false)
	modbullet:SetPseudoClass("checked", true)

end

function OptionsController:ModCustom(element)

	if modCustom == false then
		for k, v in pairs(customOptions) do
			local option = customOptions[k]
			if not option.noDefault then
				if option.optType == "Binary" and option.currentValue ~=savedValue then
					local parent = self.document:GetElementById(option.parentID.id)
					customValues[option.key] = option.savedValue
					option.currentValue = option.savedValue
					local right_selected = option.savedValue == option.validVals[2]
					parent.first_child.next_sibling.first_child.first_child:SetPseudoClass("checked", not right_selected)
					parent.first_child.next_sibling.first_child.next_sibling.first_child:SetPseudoClass("checked", right_selected)
				end
				
				if option.optType == "Multi" and option.currentValue ~= option.savedValue then
					local parent = self.document:GetElementById(option.parentID.id)
					customValues[option.key] = option.defaultValue
					option.currentValue = option.savedValue
					option.selectID.selection = tblUtil.ifind(option.validVals, option.savedValue)
				end
				
				if option.optType == "Range" and option.currentValue ~= option.savedValue then
					local parent = self.document:GetElementById(option.parentID.id)
					customValues[option.key] = option.defaultValue
					option.currentValue = option.savedValue
					option.rangeID.value = option.savedValue / option.maxValue
				end
				
				if option.optType == "MultiPoint" and option.currentValue ~= option.savedValue then
					local parent = self.document:GetElementById(option.parentID.id)
					--local value_el = self.document:GetElementById(option.valueID.id)
					customValues[option.key] = option.savedValue
					option.currentValue = option.savedValue
					local savedValue = option.savedValue
					--if value_el then
						local index = option.savedValue
						if option.strings then
							if index > 5 then index = 5 end
							if index < 1 then index = 1 end
							parent.first_child.first_child.next_sibling.next_sibling.inner_rml = option.strings[index]
						else
							--value_el.inner_rml = index
						end
						option.incrementValue = (option.savedValue / #option.buttons)
						customValues[option.key] = option.savedValue
						customOptions[option.key].currentValue = option.savedValue
					--end

					local last_active = option.savedValue --math.floor(option.range * option.numPoints) + 1

					for i, button in ipairs(option.buttons) do
						button:SetPseudoClass("checked", i <= last_active)
					end
					option.savedValue = savedValue
				end
			end
		end

		modCustom = true
		local custombullet = self.document:GetElementById("mod_custom_btn")
		local modbullet = self.document:GetElementById("mod_default_btn")
		custombullet:SetPseudoClass("checked", true)
		modbullet:SetPseudoClass("checked", false)
	end

end

function OptionsController:isModDefault()
	for k, v in pairs(customOptions) do
		local option = customOptions[k]
		if not option.noDefault then
			if option.currentValue ~= option.defaultValue then
				return false
			end
		end
	end
	return true
end

function OptionsController:setModDefaultStatus()
	local custombullet = self.document:GetElementById("mod_custom_btn")
	local modbullet = self.document:GetElementById("mod_default_btn")
	
	if self:isModDefault() == true then
		custombullet:SetPseudoClass("checked", false)
		modbullet:SetPseudoClass("checked", true)
		modCustom = false
	else
		custombullet:SetPseudoClass("checked", true)
		modbullet:SetPseudoClass("checked", false)
		modCustom = true
	end
end

function OptionsController:discardChanges()
    opt.discardChanges()

    for opt, value in pairs(self.option_backup) do
        opt.Value = value
        opt:persistChanges()
    end
end

function OptionsController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

        self:discardChanges()
		
		if mn.isInMission() then
			ScpuiSystem:pauseAllAudio(false)
		end

        ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
    end
end

function OptionsController:accept_clicked(element)
	self:acceptChanges("GS_EVENT_PREVIOUS_STATE")
end

function OptionsController:control_config_clicked()
    self:acceptChanges("GS_EVENT_CONTROL_CONFIG")
end

function OptionsController:hud_config_clicked()
    self:acceptChanges("GS_EVENT_HUD_CONFIG")
end

function OptionsController:exit_game_clicked()
    local builder = dialogs.new()
    builder:text(ba.XSTR("Exit Game?", -1))
    builder:button(dialogs.BUTTON_TYPE_NEGATIVE, ba.XSTR("No", -1), false)
    builder:button(dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Yes", -1), true)
    builder:show(self.document.context):continueWith(function(result)
        if not result then
            return
        end
        ba.postGameEvent(ba.GameEvents["GS_EVENT_QUIT_GAME"])
    end)
end

return OptionsController
