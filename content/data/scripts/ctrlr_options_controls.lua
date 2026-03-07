-----------------------------------
--Companion Controller for the Options UI to create and initialize each control
-----------------------------------

local Templates = require("lib_templates")
local Utils = require("lib_utils")

local Class = require("lib_class")

local AbstractOptionsController = Class()

function AbstractOptionsController:init()
    self.Document = nil --- @type Document The RML document
    self.CustomValues = ScpuiSystem.data.ScpuiOptionValues --- @type custom_option_data Shorthand reference to the global options table
	self.CustomOptions = {} --- @type scpui_option_control[] A table of custom option controls that have been created
end

--- Called by the RML document
--- @param document Document
function AbstractOptionsController:initialize(document)
    self.Document = document
end

function AbstractOptionsController:getOptionElementId(option)
    local key = option.Key
    key = key:gsub("%.", "_")
    key = key:lower()

    return string.format("option_%s_element", key)
end

--- Initializes a point slider control which is a slider with a fixed number of points that can be selected. Either 5 or 10 points are supported.
--- @param value_el Element | nil The element that displays the current value
--- @param btn_left Element The left arrow button
--- @param btn_right Element The right arrow button
--- @param point_buttons Element[] The buttons that represent the points
--- @param option scpui_option The option that this control represents
--- @param onchange_func function | nil The function that is called when the value changes
--- @param el_actual Element The actual element that contains the control
--- @return nil
function AbstractOptionsController:initPointSliderControl(value_el, btn_left, btn_right, point_buttons, option, onchange_func, el_actual)
    local value = nil --- @type ValueDescription | any The current value of the option
    local range_val = nil --- @type number The current range value of the option
    local num_value_points = #point_buttons - 1 --- @type integer The number of points that can be selected
	local Key = option.Key --- @type string The key of the option
	local custom_init = 0 --- @type integer No idea what this is for HA! Looks like nothing
	local default = nil --- @type any The default value of the option

	if option.Category ~= "Custom" then
		--- @type ValueDescription | any
		value = option.Value
		range_val = option:getInterpolantFromValue(value)
	else
		local cur_val = (ScpuiSystem.data.ScpuiOptionValues[Key]) or option.Value
		value = (cur_val / #point_buttons) or 0
		range_val = (cur_val / #point_buttons) or 0
		self.CustomValues[Key] = ScpuiSystem.data.ScpuiOptionValues[Key] or option.Value
		default = option.Value
	end

    --- Update a range value
    --- @param v ValueDescription | any The new value
    --- @param rv number The new range value
    local function updateRangeValue(v, rv)
        option.Value = v
        if value_el then
			if option.Category ~= "Custom" then
				value_el.inner_rml = v.Display
			else
				local index = (math.floor(option.Value * #point_buttons)) + custom_init
				if index > 5 then index = 5 end
				if index < 1 then index = 1 end
				if option.DisplayNames then
					value_el.inner_rml = option.DisplayNames[index]
				else
					value_el.inner_rml = tostring(index)
				end
			end
        end

		if option.Category == "Custom" then
			self.CustomValues[Key] = (math.ceil(option.Value * #point_buttons)) + custom_init
			self.CustomOptions[Key].CurrentValue = (math.ceil(option.Value * #point_buttons)) + custom_init
			self.CustomOptions[Key].IncrementValue = option.Value
			self.CustomOptions[Key].SavedValue = (math.ceil(option.Value * #point_buttons)) + custom_init
			self:setModDefaultStatus()
		end

        -- This gives us the index of the last button that should be shown as active. The value is in the range between
        -- 0 and 1 so multiplying that with 9 maps that to our buttons since the first button has the value 0. We floor
        -- the value to get a definite index into our array
        -- + 1 is needed since Lua has 1-based arrays
        local last_active = math.floor(rv * num_value_points) + 1

        for i, button in ipairs(point_buttons) do
            button:SetPseudoClass("checked", i <= last_active)
        end
    end

	--Save all the data for custom options here for resetting to default
	if option.Category == "Custom" then
		local display_strings = nil
		if option.DisplayNames then
			display_strings = option.DisplayNames
		end
		self.CustomOptions[Key] = {
			Key = Key,
			Type = "MultiPoint",
			DefaultValue = default,
			CurrentValue = self.CustomValues[Key],
			SavedValue = self.CustomValues[Key],
			IncrementValue = value,
			ParentEl = el_actual,
			Buttons = point_buttons,
			NumPoints = num_value_points,
			Strings = display_strings,
			Range = range_val,
			ValueEl = value_el,
			HasDefault = option.HasDefault
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
				if option_val ~= self.CustomOptions[Key].IncrementValue then
					updateRangeValue(option_val, btn_range_value)
					self.CustomValues[Key] = (1 + math.ceil(option_val * #point_buttons))
					if onchange_func then
						onchange_func(option_val)
					end
				end
			end
        end)
    end

    --- Make a listener function for the left and right buttons
    --- @param value_increment number The value that should be added to the current value
    --- @return function listener The listener function
    local function makeClickListener(value_increment)
        return function()
			custom_init = 0
            local current_range_val = nil
			if option.Category ~= "Custom" then
				---@type ValueDescription | any
				local this_value = option.Value
				current_range_val = option:getInterpolantFromValue(this_value)
			else
				current_range_val = self.CustomOptions[Key].IncrementValue
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
					self.CustomValues[Key] = (math.ceil(new_val * #point_buttons))
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

    btn_left:AddEventListener("click", makeClickListener(-(1.0 / num_value_points)))
    btn_right:AddEventListener("click", makeClickListener(1.0 / num_value_points))
end

--- Creates a ten point range control element
--- @param option scpui_option The option that this control represents
--- @param parent_id string The id of the parent element
--- @param parameters table The parameters for the template
--- @param onchange_func function | nil The function that is called when the value changes
--- @return Element actual_el The actual element that contains the control
function AbstractOptionsController:createTenPointRangeElement(option, parent_id, parameters, onchange_func)
    local parent_el = self.Document:GetElementById(parent_id)
    local actual_el, title_el, btn_left, btn_right, btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7, btn_8, btn_9 = Templates.instantiate_template(self.Document,
                                                                                                                                                         "tenpoint_selector_template",
                                                                                                                                                         self:getOptionElementId(option),
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

    local buttons = { btn_0, btn_1, btn_2, btn_3, btn_4, btn_5, btn_6, btn_7, btn_8, btn_9 }

    self:initPointSliderControl(nil, btn_left, btn_right, buttons, option, onchange_func, actual_el)

    return actual_el
end

--- Creates a ten point range control element
--- @param option scpui_option The option that this control represents
--- @param parent_id string The id of the parent element
--- @param onchange_func function | nil The function that is called when the value changes
--- @return Element actual_el The actual element that contains the control
function AbstractOptionsController:createFivePointRangeElement(option, parent_id, onchange_func)
    local parent_el = self.Document:GetElementById(parent_id)
    local actual_el, title_el, value_el, btn_left, btn_right, btn_0, btn_1, btn_2, btn_3, btn_4 = Templates.instantiate_template(self.Document,
                                                                                                                                "fivepoint_selector_template",
                                                                                                                                self:getOptionElementId(option),
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

    local buttons = { btn_0, btn_1, btn_2, btn_3, btn_4 }

    self:initPointSliderControl(value_el, btn_left, btn_right, buttons, option, onchange_func, actual_el)

    return actual_el
end

--- Initializes a binary control which is a control with two buttons that can be toggled
--- @param left_btn Element The left button
--- @param right_btn Element The right button
--- @param option scpui_option The option that this control represents
--- @param vals any[] The values that the option can have
--- @param change_func function | nil The function that is called when the value changes
--- @param el_actual Element The actual element that contains the control
--- @return nil
function AbstractOptionsController:initBinaryControl(left_btn, right_btn, option, vals, change_func, el_actual)

	local Key = option.Key
	local default = nil

    left_btn:AddEventListener("click", function()
		if option.Category == "Custom" then
			option.Value = vals[1]
			self.CustomValues[Key] = option.Value
			self.CustomOptions[Key].CurrentValue = option.Value
			self.CustomOptions[Key].SavedValue = option.Value
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
			self:setGraphicsDefaultStatus()
        end
    end)
    right_btn:AddEventListener("click", function()
		if option.Category == "Custom" then
			option.Value = vals[2]
			self.CustomValues[Key] = option.Value
			self.CustomOptions[Key].CurrentValue = option.Value
			self.CustomOptions[Key].SavedValue = option.Value
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
			self:setGraphicsDefaultStatus()
        end
    end)

	if option.Category == "Custom" then
		default = option.Value
		option.Value = ScpuiSystem.data.ScpuiOptionValues[Key] or option.Value
		self.CustomValues[Key] = ScpuiSystem.data.ScpuiOptionValues[Key] or option.Value
	end

    local value          = option.Value
    local right_selected = value == vals[2]
    left_btn:SetPseudoClass("checked", not right_selected)
    right_btn:SetPseudoClass("checked", right_selected)

	--Save all the data for custom options here for resetting to default
	if option.Category == "Custom" then
		self.CustomOptions[Key] = {
			Key = Key,
			Type = "Binary",
			DefaultValue = default,
			CurrentValue = option.Value,
			SavedValue = option.Value,
			ValidValues = vals,
			ParentEl = el_actual,
			HasDefault = option.HasDefault
		}
	else
		for _, v in pairs(self.GraphicsPresets) do
			if el_actual.id == v then
				self.GraphicsOptions[Key] = {
					Key = Key,
					Title = option.Title,
					Type = "Binary",
					Option = option,
					CurrentValue = value,
					SavedValue = value,
					ValidValues = vals,
					ParentEl = el_actual
				}
			end
		end
	end

end

--- Creates a binary control element
--- @param option scpui_option The option that this control represents
--- @param vals any[] The values that the option can have
--- @param parent_id string The id of the parent element
--- @param onchange_func function | nil The function that is called when the value changes
--- @return Element actual_el The actual element that contains the control
function AbstractOptionsController:createBinaryOptionElement(option, vals, parent_id, onchange_func)
    local parent_el = self.Document:GetElementById(parent_id)
    local actual_el, title_el, btn_left, text_left, btn_right, text_right = Templates.instantiate_template(self.Document,
                                                                                                          "binary_selector_template",
                                                                                                          self:getOptionElementId(option),
                                                                                                          {
                                                                                                              "binary_text_el",
                                                                                                              "binary_left_btn_el",
                                                                                                              "binary_left_text_el",
                                                                                                              "binary_right_btn_el",
                                                                                                              "binary_right_text_el",
                                                                                                          })
    parent_el:AppendChild(actual_el)

    title_el.inner_rml = option.Title

	--OR is for custom options built from the CFG file
    text_left.inner_rml = vals[1].Display or option.DisplayNames[vals[1]]
    text_right.inner_rml = vals[2].Display or option.DisplayNames[vals[2]]

    self:initBinaryControl(btn_left, btn_right, option, vals, onchange_func, actual_el)

    return actual_el
end

--- Initializes a selection control which is a dropdown with a list of options
--- @param element Element The element that represents the control
--- @param option scpui_option The option that this control represents
--- @param vals any[] The values that the option can have
--- @param change_func function | nil The function that is called when the value changes
--- @param el_actual Element The actual element that contains the control
--- @return nil
function AbstractOptionsController:initSelectionControl(element, option, vals, change_func, el_actual)

	local default = nil

    local select_el = Element.As.ElementFormControlDataSelect(element)
	if option.Category ~= "Custom" then
		select_el:SetDataSource(option.Key:gsub("%.", "_") .. ".Default")
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
		option.Value = ScpuiSystem.data.ScpuiOptionValues[option.Key] or option.ValidValues[count]
		self.CustomValues[option.Key] = ScpuiSystem.data.ScpuiOptionValues[option.Key] or option.ValidValues[count]
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
				self.CustomValues[option.Key] = vals[count]
				self.CustomOptions[option.Key].CurrentValue = vals[count]
				self.CustomOptions[option.Key].SavedValue = vals[count]
			else
				for _, v in pairs(self.GraphicsPresets) do
					if el_actual.id == v then
						if el_actual.id == "option_graphics_anisotropy_element" then
							--This option saves reports the string so we need to save the known index
							local a_value = 5
							if event.parameters.value == "1.0" then a_value = 1 end
							if event.parameters.value == "2.0" then a_value = 2 end
							if event.parameters.value == "4.0" then a_value = 3 end
							if event.parameters.value == "8.0" then a_value = 4 end
							self.GraphicsOptions[option.Key].CurrentValue = a_value
							self.GraphicsOptions[option.Key].SavedValue = a_value
						else
							--Translate from a 0 based index to a 1 based index because reasons??
							if tonumber(event.parameters.value) then
								self.GraphicsOptions[option.Key].CurrentValue = event.parameters.value + 1
								self.GraphicsOptions[option.Key].SavedValue = event.parameters.value + 1
							end
						end
					end
				end
			end
        end
		if option.Category ~= "Custom" then
			self:setGraphicsDefaultStatus()
		else
			self:setModDefaultStatus()
		end
    end)

	--Save all the data for custom options here for resetting to default
	if option.Category == "Custom" then
		self.CustomOptions[option.Key] = {
			Key = option.Key,
			Type = "Multi",
			DefaultValue = default,
			CurrentValue = option.Value,
			SavedValue = option.Value,
			ValidVals = vals,
			ParentEl = el_actual,
			SelectEl = select_el,
			HasDefault = option.HasDefault
		}
	else
		for k, v in pairs(self.GraphicsPresets) do
			if el_actual.id == v then
				self.GraphicsOptions[option.Key] = {
					Key = option.Key,
					Type = "Multi",
					CurrentValue = Utils.table.ifind(vals, value),
					SavedValue = Utils.table.ifind(vals, value),
					ValidValues = vals,
					ParentEl = el_actual,
					SelectEl = select_el
				}
			end
		end
	end
    select_el.selection = Utils.table.ifind(vals, value)
end

--- Creates a selection control element
--- @param option scpui_option The option that this control represents
--- @param vals any[] The values that the option can have
--- @param parent_id string The id of the parent element
--- @param parameters table | nil The parameters for the template
--- @param onchange_func function | nil The function that is called when the value changes
--- @return Element actual_el The actual element that contains the control
function AbstractOptionsController:createSelectionOptionElement(option, vals, parent_id, parameters, onchange_func)
    local parent_el = self.Document:GetElementById(parent_id)
    local actual_el, text_el, dataselect_el = Templates.instantiate_template(self.Document, "dropdown_template",
                                                                            self:getOptionElementId(option), {
                                                                                "dropdown_text_el",
                                                                                "dropdown_dataselect_el"
                                                                            }, parameters)
    parent_el:AppendChild(actual_el)

    -- If no_title was specified then this element will be nil
    if text_el ~= nil then
        text_el.inner_rml = option.Title
    end

    self:initSelectionControl(dataselect_el, option, vals, onchange_func, actual_el)

    return actual_el
end

--- Initializes a range control which is a slider with a range of values
--- @param element Element The element that represents the control
--- @param value_el Element The element that displays the current value
--- @param option scpui_option The option that this control represents
--- @param change_func function | nil The function that is called when the value changes
--- @param el_actual Element The actual element that contains the control
--- @return nil
function AbstractOptionsController:initRangeControl(element, value_el, option, change_func, el_actual)

	local default = nil

    local range_el = Element.As.ElementFormControlInput(element)

	--- Ensures range UI value and attribute stay in sync so the thumb is positioned correctly.
    --- @param input_el ElementFormControlInput
    --- @param value number | string
    local function setRangeInputValue(input_el, value)
        local normalized = tonumber(value)
        if normalized == nil then
            return
        end

        local as_string = tostring(normalized)
        input_el.value = as_string
        input_el:SetAttribute("value", as_string)
    end

    element:AddEventListener("change", function(event, _, _)
		local value = nil
		if option.Category ~= "Custom" then
			value        = option:getValueFromRange(event.parameters.value)
			value_el.inner_rml = value.Display
		else
			value        = event.parameters.value
			value_el.inner_rml = tostring(value * option.Max):sub(1,4)
			self.CustomValues[option.Key] = tostring(value * option.Max):sub(1,4)
			if self.CustomOptions[option.Key] then
				self.CustomOptions[option.Key].CurrentValue = tostring(value * option.Max):sub(1,4)
				self.CustomOptions[option.Key].SavedValue = tostring(value * option.Max):sub(1,4)
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
	if ba.isEngineVersionAtLeast(24, 3, 0) then
		if option.Key == "Game.FontScaleFactor" then
			element:AddEventListener("click", function(event, _, _)
				--- @type ValueDescription | any
				local this_value = option.Value
				ScpuiSystem.data.FontValue = tonumber(this_value.Serialized)
				local new_class = "base_font" .. ScpuiSystem:getFontPixelSize()
				--Clear the last class
				self.Document:GetElementById("main_background"):SetClass(ScpuiSystem.data.CurrentBaseFontClass, false)

				--Now apply the new class
				ScpuiSystem.data.CurrentBaseFontClass = new_class
				self.Document:GetElementById("main_background"):SetClass(new_class, true)
			end)
		end
	else
		if option.Key == "Font_Adjustment" then
			element:AddEventListener("click", function(event, _, _)
				setRangeInputValue(range_el, self.CustomOptions[option.Key].CurrentValue)
				local new_class = "base_font" .. ScpuiSystem:getFontPixelSize(self.CustomOptions[option.Key].CurrentValue)
				--Clear the last class
				self.Document:GetElementById("main_background"):SetClass(ScpuiSystem.data.CurrentBaseFontClass, false)

				--Now apply the new class
				ScpuiSystem.data.CurrentBaseFontClass = new_class
				self.Document:GetElementById("main_background"):SetClass(new_class, true)
			end)
		end
	end


	if option.Category ~= "Custom" then
		--- @type ValueDescription | any
		local this_value = option.Value
		setRangeInputValue(range_el, option:getInterpolantFromValue(this_value))
	else
		local thisValue = ScpuiSystem.data.ScpuiOptionValues[option.Key] or option.Value
		default = option.Value
		option.Value = thisValue
		setRangeInputValue(range_el, thisValue / option.Max)
		range_el.step = (option.Max - option.Min) / 100
	end

	--Save all the data for custom options here for resetting to default
	if option.Category == "Custom" then
		self.CustomOptions[option.Key] = {
			Key = option.Key,
			Type = "Range",
			DefaultValue = default,
			CurrentValue = option.Value,
			SavedValue = option.Value,
			ParentEl = el_actual,
			RangeEl = range_el,
			MaxValue = option.Max,
			HasDefault = option.HasDefault
		}
	end
end

--- Creates a range control element
--- @param option scpui_option The option that this control represents
--- @param parent_id string The id of the parent element
--- @param onchange_func function | nil The function that is called when the value changes
--- @return Element actual_el The actual element that contains the control
function AbstractOptionsController:createRangeOptionElement(option, parent_id, onchange_func)
    local parent_el = self.Document:GetElementById(parent_id)
    local actual_el, title_el, value_el, range_el = Templates.instantiate_template(self.Document, "slider_template",
                                                                                  self:getOptionElementId(option), {
                                                                                      "slider_title_el",
                                                                                      "slider_value_el",
                                                                                      "slider_range_el"
                                                                                  })
    parent_el:AppendChild(actual_el)

    title_el.inner_rml = option.Title

    self:initRangeControl(range_el, value_el, option, onchange_func, actual_el)

    return actual_el
end

--- Initializes a header option element which is a header with a title
--- @param option scpui_option The option that this control represents
--- @param parent_id string The id of the parent element
--- @return Element actual_el The actual element that contains the control
function AbstractOptionsController:createHeaderOptionElement(option, parent_id)
    local parent_el = self.Document:GetElementById(parent_id)
    local actual_el, title_el = Templates.instantiate_template(self.Document, "header_template",
                                                               self:getOptionElementId(option), {
                                                                   "header_title_el"
                                                               })
    parent_el:AppendChild(actual_el)

    title_el.inner_rml = option.Title

	---Load the desired font size from the save file
	self.Document:GetElementById(actual_el.id):SetClass("p2", true)

    return actual_el
end

return AbstractOptionsController