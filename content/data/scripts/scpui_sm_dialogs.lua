-----------------------------------
--This file contains miscellaneous functions for dialog prompts
-----------------------------------

local Dialogs = require("lib_dialogs")

--- Shows a custom SCPUI dialog box
--- @param context_or_caller scpui_context | Context This should be the active UI Class and contain .Document or a valid context
--- @param params dialog_setup The params table
--- @param callback fun(result: string?)? Function to call when the dialog completes (optional)
--- @return nil
function ScpuiSystem:showDialog(context_or_caller, params, callback)
    local context = context_or_caller.Document and context_or_caller.Document.context or context_or_caller
    if not context then
        error("showDialog expected a RocketContext or scpui_context with .Document.context")
    end

    if not params.Title then error("Missing required dialog Title") end
    if not params.Text then error("Missing required dialog Text") end

	local dialog = Dialogs.new()

    dialog:style(params.Style or ScpuiSystem.constants.Dialog_Constants.DIALOG_STYLE_REGULAR)
    dialog:title(params.Title)
    dialog:text(params.Text)
    dialog:input(params.Input or false)
    dialog:escape(params.EscapeValue)
    dialog:clickescape(params.ClickEscape or false)
    dialog:background(params.BackgroundColor or "#00000000") -- Default to clear background

    local buttons = params.Buttons_List or {}
    for i = 1, #buttons do
        dialog:button(buttons[i].Type, buttons[i].Text, buttons[i].Value, buttons[i].Keypress)
    end

    dialog:show(context):continueWith(function(response)
        if callback then
            callback(response)
        end
    end)

	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(context)
end

--- Shows a simple SCPUI dialog box with a single "OK" button and no callback
--- @param context_or_caller scpui_context | Context This should be the active UI Class and contain .Document or a valid context
--- @param title string The title of the dialog
--- @param text string The text content of the dialog
--- @return nil
function ScpuiSystem:showSimpleDialog(context_or_caller, title, text)
    local context = context_or_caller.Document and context_or_caller.Document.context or context_or_caller
    if not context then
        error("showSimpleDialog expected a RocketContext or scpui_context with .Document.context")
    end

    local params = {
        Title = title,
        Text = text,
        Buttons_List = {
            { Type = Dialogs.BUTTON_TYPE_POSITIVE, Text = ba.XSTR("Ok", 888286), Value = true, Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1) }
        }
    }

    self:showDialog(context, params)
end