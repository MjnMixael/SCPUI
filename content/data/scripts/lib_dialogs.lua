-----------------------------------
--This file contains all the code necessary to display a popup dialog box within SCPUI.
-----------------------------------

local module                = {}

-- The type of a dialog
module.TYPE_SIMPLE          = 1

-- The various button
module.BUTTON_TYPE_POSITIVE = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE
module.BUTTON_TYPE_NEGATIVE = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE
module.BUTTON_TYPE_NEUTRAL  = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEUTRAL

-- Regular or Death dialog style. Other styles can be added later if desired.
module.STYLE_REGULAR        = ScpuiSystem.constants.Dialog_Constants.DIALOG_STYLE_REGULAR
module.STYLE_DEATH          = ScpuiSystem.constants.Dialog_Constants.DIALOG_STYLE_DEATH

module.BUTTON_MAPPING       = {
    [module.BUTTON_TYPE_POSITIVE] = "button_positive",
    [module.BUTTON_TYPE_NEGATIVE] = "button_negative",
    [module.BUTTON_TYPE_NEUTRAL]  = "button_neutral"
}

module.BUTTON_TEXT_MAPPING       = {
    [module.BUTTON_TYPE_POSITIVE] = "pos",
    [module.BUTTON_TYPE_NEGATIVE] = "neg",
    [module.BUTTON_TYPE_NEUTRAL]  = "neu"
}

--- Finds the character to underline in a string and applies the underline class to it
--- @param haystack string The string to search in
--- @param needle string The character to underline
--- @return string string The string with the character underlined classes applied
local function underline(haystack, needle)
    local s, e = string.find(haystack, needle)
    if s then
        return string.sub(haystack, 1, s - 1) .. "<span class=\"underline\">" .. string.upper(needle) .. "</span>" .. string.sub(haystack, e + 1)
    else
        return haystack
    end
end

--- Returns a string with the keypress underlined if it is found in the string
--- @param string string The string to underline
--- @param keypress string The keypress to underline
--- @return string string The string with the keypress underlined classes applied
local function text_with_keypress(string, keypress)
    if string and keypress then
        return underline(string, string.upper(keypress)) or underline(string, keypress) or string
    else
        return string
    end
end

--- Initialize the buttons of a dialog
--- @param document Document The document to initialize the buttons in
--- @param properties dialog_factory The properties of the dialog
--- @param finish_func function The function to call when the dialog is closed
--- @return nil
local function initialize_buttons(document, properties, finish_func)
    ---@param i number
    ---@param v dialog_button
    for i, v in ipairs(properties.Buttons_List) do
        local button_id = 'button_' .. tostring(i)
        local button = document:GetElementById(button_id)
        button:SetClass(module.BUTTON_MAPPING[v.Type], true)
        button:SetClass("button_1", true)
        button:SetClass("button_img", true)

        button:AddEventListener("click", function(_, _, _)
            local val = v.Value
            if properties.InputChoice then
                val = document:GetElementById("dialog_input"):GetAttribute("value")
            end
            if finish_func then finish_func(val) end
            --document:Close()
            ScpuiSystem:closeDialog()
        end)

        local button_text_id = button_id .. '_text'
        local button_text = document:GetElementById(button_text_id)
        button_text.inner_rml = text_with_keypress(v.Text, v.Keypress)
        button_text:SetClass(module.BUTTON_TEXT_MAPPING[v.Type], true)
    end
end

--- Create and show a dialog, selecting between regular and death dialog versions
--- @param context Context to create the dialog in
--- @param properties dialog_factory The properties of the dialog
--- @param finish_func function The function to call when the dialog is closed
--- @param reject function The function to call when the dialog is rejected
--- @param abort_cb_table table The table to store the abort functions in
--- @return nil
local function show_dialog(context, properties, finish_func, reject, abort_cb_table)
    ---@type Document
    local dialog_doc = nil

    if properties.StyleValue == module.STYLE_DEATH then
        dialog_doc = context:LoadDocument("data/interface/markup/death_dialog.rml")
        properties.ClickEscape = nil -- This is never allowed for death dialogs
    else
        dialog_doc = context:LoadDocument("data/interface/markup/dialog.rml")
    end

    if properties.BackgroundColor then
        dialog_doc:GetElementById("main_background").style["background-color"] = properties.BackgroundColor
    end

    if string.len(properties.TitleString) > 0 then
        dialog_doc.title = properties.TitleString
    end

    dialog_doc:GetElementById("title_container").inner_rml = properties.TitleString
    -- Put the dialog content into a <p> container so that scrolling works properly
    local text_el = dialog_doc:CreateElement("p")
    text_el.inner_rml = properties.TextString
    dialog_doc:GetElementById("text_container"):AppendChild(text_el)
    dialog_doc:GetElementById("dialog_body"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    if properties.InputChoice then
        local input_el = dialog_doc:CreateElement("input")
        dialog_doc:GetElementById("text_container"):AppendChild(input_el)
        input_el.type = "text"
        input_el.maxlength = 32
        input_el.id = "dialog_input"

        input_el:AddEventListener("change", function(event, _, _)
            if event.parameters.linebreak == 1 then
                finish_func(event.parameters.value)
                ScpuiSystem:closeDialog()
            end
        end)
    end

    if #properties.Buttons_List > 0 then

        --verify that all key shortcuts are unique
        local keys = {}

        for i = 1, #properties.Buttons_List, 1 do
            if properties.Buttons_List[i].Keypress ~= nil then
                if #keys == 0 then
                    table.insert(keys, properties.Buttons_List[i].Keypress)
                else
                    for j = 1, #keys, 1 do
                        if properties.Buttons_List[i].Keypress == keys[j] then
                            properties.Buttons_List[i].Keypress = nil
                        else
                            table.insert(keys, properties.Buttons_List[i].Keypress)
                        end
                    end
                end
            end
        end

        initialize_buttons(dialog_doc, properties, finish_func)
    end

    dialog_doc:AddEventListener("keydown", function(event, _, _)
        local keys = ScpuiSystem:getKeyInfo(event)
        if keys.ESCAPE then
            if properties.EscapeValue ~= nil then
                finish_func(properties.EscapeValue)
                ScpuiSystem:closeDialog()
            end
        end
        for i = 1, #properties.Buttons_List, 1 do
            if properties.Buttons_List[i].Keypress ~= nil then
                local this_key = string.upper(properties.Buttons_List[i].Keypress)
                if event.parameters.key_identifier == rocket.key_identifier[this_key] then
                    local val = properties.Buttons_List[i].Value
                    if properties.InputChoice then
                        val = dialog_doc:GetElementById("dialog_input"):GetAttribute("value")
                    end
                    finish_func(val)
                    ScpuiSystem:closeDialog()
                end
            end
        end
    end)

    if properties.ClickEscape and properties.EscapeValue then
        local bg_el = dialog_doc:GetElementById("click_detect")

        bg_el:AddEventListener("click", function(event, _, _)
            finish_func(properties.EscapeValue)
            ScpuiSystem:closeDialog()
        end)
    end

    if abort_cb_table ~= nil then
        abort_cb_table.Abort = function()
            ScpuiSystem:closeDialog()
            reject()
        end
    end

    dialog_doc:Show(DocumentFocus.FOCUS) -- MODAL would be better than FOCUS but then the debugger cannot be used anymore

    -- Apply triple monitor centering if needed
    if ScpuiSystem.applyTripleMonitorLayoutFix then
        ScpuiSystem:applyTripleMonitorLayoutFix(dialog_doc)
    end

    if ScpuiSystem.data.DialogDoc ~= nil then
        ba.print("SCPUI got command to close a dialog while creating a dialog! This is unusual!\n")
        ScpuiSystem:closeDialog()
    end

    ScpuiSystem.data.DialogDoc = dialog_doc
end


---@class dialog_factory A dialog factory
local factory_mt   = {}

factory_mt.__index = factory_mt

function factory_mt:type(type)
    self.TypeVal = type
    return self
end

function factory_mt:title(title)
    self.TitleString = ""
    if title ~= nil then
        self.TitleString = title
    end
    return self
end

function factory_mt:text(text)
    self.TextString = ""
    if text ~= nil then
        self.TextString = text
    end
    return self
end

function factory_mt:button(type, text, value, keypress)
    if value == nil then
        value = #self.Buttons_List + 1
    end

    table.insert(self.Buttons_List, {
        Type  = type,
        Text  = text,
        Value = value,
        Keypress = keypress
    })
    return self
end

function factory_mt:input(input)
    self.InputChoice = input
    return self
end

function factory_mt:escape(escape)
    self.EscapeValue = escape
    return self
end

function factory_mt:clickescape(clickescape)
    self.ClickEscape = clickescape
    return self
end

function factory_mt:style(style)
    self.StyleValue = style
    return self
end

function factory_mt:background(color)
    self.BackgroundColor = color
    return self
end

function factory_mt:show(context, abort_cb_table)
    return async.promise(function(resolve, reject)
        show_dialog(context, self, resolve, reject, abort_cb_table)
    end)
end

--- Creates a new dialog factory
--- @return dialog_factory A factory for creating dialogs
function module.new()
    ---@type dialog_factory
    local factory = {
        TypeVal     = module.TYPE_SIMPLE,
        Buttons_List = {},
        TitleString = "",
        TextString  = "",
        InputChoice = false,
        EscapeValue = nil,
        ClickEscape = nil,
        StyleValue = module.STYLE_REGULAR,
        BackgroundColor = nil
    }
    setmetatable(factory, factory_mt)
    return factory
end

return module
