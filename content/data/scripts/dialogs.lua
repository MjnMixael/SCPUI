local templates              = require("rocket_templates")

local module                = {}

-- The type of a dialog
module.TYPE_SIMPLE          = 1

-- The various button
module.BUTTON_TYPE_POSITIVE = 1
module.BUTTON_TYPE_NEGATIVE = 2
module.BUTTON_TYPE_NEUTRAL  = 3

module.BUTTON_MAPPING       = {
    [module.BUTTON_TYPE_POSITIVE] = "button_positive",
    [module.BUTTON_TYPE_NEGATIVE] = "button_negative",
    [module.BUTTON_TYPE_NEUTRAL] = "button_neutral"
}

module.BUTTON_TEXT_MAPPING       = {
    [module.BUTTON_TYPE_POSITIVE] = "pos",
    [module.BUTTON_TYPE_NEGATIVE] = "neg",
    [module.BUTTON_TYPE_NEUTRAL] = "pos"
}

local function underline(haystack, needle)
    local s, e = string.find(haystack, needle)
    if s then
        return string.sub(haystack, 1, s - 1) .. "<span class=\"underline\">" .. string.upper(needle) .. "</span>" .. string.sub(haystack, e + 1)
    else
        return haystack
    end
end

local function text_with_keypress(string, keypress)
    if string and keypress then
        return underline(string, string.upper(keypress)) or underline(string, keypress) or string
    else
        return string
    end
end

local function initialize_buttons(document, properties, finish_func)
		for i, v in ipairs(properties.buttons) do
		    local button_id = 'button_' .. tostring(i)
				local button = document:GetElementById(button_id)
        button:SetClass(module.BUTTON_MAPPING[v.type], true)
		button:SetClass("button_1", true)
		button:SetClass("button_img", true)
        button:AddEventListener("click", function(_, _, _)
			local val = v.value
			if properties.input_choice then
				val = document:GetElementById("dialog_input"):GetAttribute("value")
			end
            if finish_func then finish_func(val) end
            document:Close()
        end)
		    local button_text_id = button_id .. '_text'
				local button_text = document:GetElementById(button_text_id)
				button_text.inner_rml = text_with_keypress(v.text, v.keypress)
				button_text:SetClass(module.BUTTON_TEXT_MAPPING[v.type], true)
		end
end

local function show_dialog(context, properties, finish_func, reject, abortCBTable)
    local dialog_doc = nil
    
    if properties.style_value == 2 then
        dialog_doc = context:LoadDocument("data/interface/markup/deathdialog.rml")
		properties.click_escape = nil -- This is never allowed for death dialogs
    else
        dialog_doc = context:LoadDocument("data/interface/markup/dialog.rml")
    end
	
	if properties.background_color then
		dialog_doc:GetElementById("main_background").style["background-color"] = properties.background_color
	end
	
	if string.len(properties.title_string) > 0 then
		dialog_doc.title = properties.title_string
	end

    dialog_doc:GetElementById("title_container").inner_rml = properties.title_string
	-- Put the dialog content into a <p> container so that scrolling works properly
    local text_el = dialog_doc:CreateElement("p")
	text_el.inner_rml = properties.text_string
	dialog_doc:GetElementById("text_container"):AppendChild(text_el)
    dialog_doc:GetElementById("dialog_body"):SetClass(("p1-" .. ScpuiSystem:getFontSize()), true)
    
    if properties.input_choice then
        local input_el = dialog_doc:CreateElement("input")
        dialog_doc:GetElementById("text_container"):AppendChild(input_el)
        input_el.type = "text"
        input_el.maxlength = 32
		input_el.id = "dialog_input"
        
        input_el:AddEventListener("change", function(event, _, _)
            if event.parameters.linebreak == 1 then
                finish_func(event.parameters.value)
                ScpuiSystem:CloseDialog()
            end
        end)
    end

    if #properties.buttons > 0 then
    
        --verify that all key shortcuts are unique
        local keys = {}
        
        for i = 1, #properties.buttons, 1 do
            if properties.buttons[i].keypress ~= nil then
                if #keys == 0 then
                    table.insert(keys, properties.buttons[i].keypress)
                else
                    for j = 1, #keys, 1 do
                        if properties.buttons[i].keypress == keys[j] then
                            properties.buttons[i].keypress = nil
                        else
                            table.insert(keys, properties.buttons[i].keypress)
                        end
                    end
                end
            end
        end
    
        initialize_buttons(dialog_doc, properties, finish_func)
    end
    
	dialog_doc:AddEventListener("keydown", function(event, _, _)
		if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
			if properties.escape_value ~= nil then
				finish_func(properties.escape_value)
				ScpuiSystem:CloseDialog()
			end
		end
		for i = 1, #properties.buttons, 1 do
			if properties.buttons[i].keypress ~= nil then
				thisKey = string.upper(properties.buttons[i].keypress)
				if event.parameters.key_identifier == rocket.key_identifier[thisKey] then
					local val = properties.buttons[i].value
					if properties.input_choice then
						val = dialog_doc:GetElementById("dialog_input"):GetAttribute("value")
					end
					finish_func(val)
					ScpuiSystem:CloseDialog()
				end
			end
		end
	end)
	
	if properties.click_escape and properties.escape_value then
		bg_el = dialog_doc:GetElementById("click_detect")
		
		bg_el:AddEventListener("click", function(event, _, _)
			finish_func(properties.escape_value)
            ScpuiSystem:CloseDialog()
        end)
	end
    
    if abortCBTable ~= nil then
        abortCBTable.Abort = function()
            ScpuiSystem:CloseDialog()
            reject()
        end
    end

    dialog_doc:Show(DocumentFocus.FOCUS) -- MODAL would be better than FOCUS but then the debugger cannot be used anymore
	
	if ScpuiSystem.dialog ~= nil then
		ba.print("SCPUI got command to close a dialog while creating a dialog! This is unusual!\n")
		ScpuiSystem:CloseDialog()
	end
	
	ScpuiSystem.dialog = dialog_doc
end


---@class DialogFactory A dialog factory
local factory_mt   = {}

factory_mt.__index = factory_mt

function factory_mt:type(type)
    self.type_val = type
    return self
end

function factory_mt:title(title)
    self.title_string = ""
    if title ~= nil then
        self.title_string = title
    end
    return self
end

function factory_mt:text(text)
    self.text_string = ""
    if text ~= nil then
        self.text_string = text
    end
    return self
end

function factory_mt:button(type, text, value, keypress)
    if value == nil then
        value = #self.buttons + 1
    end

    table.insert(self.buttons, {
        type  = type,
        text  = text,
        value = value,
        keypress = keypress
    })
    return self
end

function factory_mt:input(input)
    self.input_choice = input
    return self
end

function factory_mt:escape(escape)
    self.escape_value = escape
    return self
end

function factory_mt:clickescape(clickescape)
    self.click_escape = clickescape
    return self
end

function factory_mt:style(style)
    self.style_value = style
    return self
end

function factory_mt:background(color)
    self.background_color = color
    return self
end

function factory_mt:show(context, abortCBTable)
    return async.promise(function(resolve, reject)
        show_dialog(context, self, resolve, reject, abortCBTable)
    end)
end

--- Creates a new dialog factory
--- @return DialogFactory A factory for creating dialogs
function module.new()
    local factory = {
        type_val     = module.TYPE_SIMPLE,
        buttons      = {},
        title_string = "",
        text_string  = "",
        input_choice = false,
        escape_value = nil,
		click_escape = nil,
        style_value = 1,
		background_color = nil
    }
    setmetatable(factory, factory_mt)
    return factory
end

return module
