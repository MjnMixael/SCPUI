-----------------------------------
--This file contains miscellaneous functions for dialog prompts
-----------------------------------

local Dialogs = require("lib_dialogs")

--- Shows a custom SCPUI dialog box
--- @param context_or_caller scpui_context | Context This should be the active UI Class and contain .Document or a valid context
--- @param title string Title of the dialog (required)
--- @param text string Main text content (required)
--- @param buttons dialog_button[]? Array of button configs (optional, defaults to empty)
--- @param input boolean? Whether to show an input field (optional, defaults to false)
--- @param escape_value any? Value to return when the dialog is closed with the escape key (optional, defaults to nil)
--- @param allow_click_escape boolean? Whether to allow clicking outside the dialog to close it (optional, defaults to false)
--- @param style integer? The style of the dialog. Should be one of the dialog_constants.DIALOG_STYLE_ enumerations (optional, defaults to regular)
--- @param background string? Sets a background color for the entire screen behind the dialog (optional, defaults to clear)
--- @param callback fun(result: string?)? Function to call when the dialog completes (optional)
--- @return nil
function ScpuiSystem:showDialog(context_or_caller, title, text, buttons, input, escape_value, allow_click_escape, style, background, callback)
    local context = context_or_caller.Document and context_or_caller.Document.context or context_or_caller
    if not context then
        error("showDialog expected a RocketContext or scpui_context with .Document.context")
    end

	local dialog = Dialogs.new()

    dialog:style(style or ScpuiSystem.constants.Dialog_Constants.DIALOG_STYLE_REGULAR)
    dialog:title(title)
    dialog:text(text)
    dialog:input(input or false)
    dialog:escape(escape_value)
    dialog:clickescape(allow_click_escape or false)
    dialog:background(background or "#00000000") -- Default to clear background

    buttons = buttons or {}
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
