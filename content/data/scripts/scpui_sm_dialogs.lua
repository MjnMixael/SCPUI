-----------------------------------
--This file contains miscellaneous functions for dialog prompts
-----------------------------------

local Dialogs = require("lib_dialogs")

--- Shows a custom SCPUI dialog box
--- @param context_or_caller scpui_context | Context This should be the active UI Class and contain .Document or a valid context
--- @param title string Title of the dialog
--- @param text string Main text content
--- @param input boolean? Whether to show an input field
--- @param buttons table[] Array of button configs (see below)
--- @param callback fun(result: string?) Function to call when the dialog completes
--- @return nil
function ScpuiSystem:showDialog(context_or_caller, title, text, input, buttons, callback)
    local context = context_or_caller.Document and context_or_caller.Document.context or context_or_caller
    if not context then
        error("showDialog expected a RocketContext or scpui_context with .Document.context")
    end

	local dialog = Dialogs.new()

    dialog:title(title)
    dialog:text(text)
    dialog:input(input or false)
    for i = 1, #buttons do
        dialog:button(buttons[i].Type, buttons[i].Text, buttons[i].Value, buttons[i].Keypress)
    end
    dialog:escape("")
    dialog:show(context)
    :continueWith(function(response)
        if callback then
            callback(response)
        end
    end)

	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(context)
end
