-----------------------------------
--Controller for the Pilot Select UI, Shared with the Barracks Controller
-----------------------------------

local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local PilotSelectController = Class()


PilotSelectController.VALID_MODES = { "single", "multi" } --- @type string[] The list of valid modes for the player. Either "single" or "multi"
PilotSelectController.CONTROLLER_PLAYER_SELECT = 1 --- @type number The player select controller enumeration
PilotSelectController.CONTROLLER_BARRACKS      = 2 --- @type number The barracks controller enumeration

--- Called by the class constructor
--- @return nil
function PilotSelectController:init()
    self.Controller = PilotSelectController.CONTROLLER_PLAYER_SELECT --- @type number The current UI Controller. Used to separate functionality between barracks and pilot select in the class
    self.Document = nil --- @type Document The current document
    self.SelectedPilotName = nil --- @type string | nil The currently selected pilot name
    self.SelectedPilotHandle = nil --- @type player The currently selected pilot handle
    self.CurrentMode = "" --- @type string The current mode of the player. Either "single" or "multi"
    self.Pilot_Elements = {} --- @type Element[] The list of pilot elements
    self.CallsignInputActive = false --- @type boolean True if the callsign input is currently active and player can type
    self.callsignInputAction = nil --- @type function The function to call when the callsign has been submitted
end

--- Called by the RML document
--- @param document Document
function PilotSelectController:initialize(document)
    self.Document  = document

    ---Load the desired font size from the save file
    self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    if self.Controller == PilotSelectController.CONTROLLER_PLAYER_SELECT then
        self.Document:GetElementById("copyright_info"):SetClass("s2", true)
    end

    local pilot_ul = document:GetElementById("pilotlist_ul")
    local pilots   = ui.PilotSelect.enumeratePilots()

    local current  = self:getInitialCallsign()
    if current ~= nil then
        -- Make sure that the last pilot appears at the top of the list
        local index = Utils.table.ifind(pilots, current)
        if index > 0 then
            table.remove(pilots, index)
            table.insert(pilots, 1, current)
        end
    else
        self:set_player_mode(nil, "single")
    end

    self.pilots = pilots
    for _, v in ipairs(self.pilots) do
        local li_el = self:createPilotListItem(v)

        pilot_ul:AppendChild(li_el)
    end

    if self.Controller == PilotSelectController.CONTROLLER_PLAYER_SELECT then
        ---Load background choice
        self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

        document:GetElementById("fso_version_info").inner_rml = ba.getVersionString()
        local version = ba.getModVersion()
        if version ~= "" then
            version = " v" .. version
        end
        document:GetElementById("mod_version_info").inner_rml = ScpuiSystem:getModTitle() .. version

        --Hide Multi stuff maybe
        if ScpuiSystem.data.table_flags.HideMulti == true then
            self.Document:GetElementById("singleplayer_text"):SetClass("hidden", true)
            self.Document:GetElementById("multiplayer_text"):SetClass("hidden", true)
            self.Document:GetElementById("singleplayer_btn"):SetClass("hidden", true)
            self.Document:GetElementById("multiplayer_btn"):SetClass("hidden", true)
        end
    end

    if current ~= nil then
        self:selectPilot(current)

        local pilot = ba.loadPlayer(current)
        if not pilot:isValid() then
            self:set_player_mode(nil, "single")
        else
            local is_multi
            if self.Controller == PilotSelectController.CONTROLLER_PLAYER_SELECT then
                is_multi = pilot.WasMultiplayer
            else
                is_multi = pilot.IsMultiplayer
            end
            if is_multi then
                self:set_player_mode(nil, "multi")
            else
                self:set_player_mode(nil, "single")
            end
        end
        ui.PilotSelect.unloadPilot()
    end

    if Topics.pilotselect.startsound:send(self) then
        ui.MainHall.startAmbientSound()
    end

    --Only show this warning on first boot
    if not ScpuiSystem.data.memory.WarningCountShown then
        if ui.PilotSelect.WarningCount > 10 or ui.PilotSelect.ErrorCount > 0 then
            local text    = string.format(ba.XSTR("The currently active mod has generated %d warnings and/or errors during"
                                                          .. "program startup.  These could have been caused by anything from incorrectly formatted table files to"
                                                          .. " corrupt models.  While FreeSpace Open will attempt to compensate for these issues, it cannot"
                                                          .. " guarantee a trouble-free gameplay experience.  Source Code Project staff cannot provide assistance"
                                                          .. " or support for these problems, as they are caused by the mod's data files, not FreeSpace Open's"
                                                          .. " source code.", -1),
                                          ui.PilotSelect.WarningCount + ui.PilotSelect.ErrorCount)

            local title = ba.XSTR("Warning", 888395)
            --- @type dialog_button[]
            local buttons = {}
            buttons[1] = {
                Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
                Text = ba.XSTR("Ok", 888286),
                Value = "",
                Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1)
            }

            --- @type dialog_setup
            local params = {
                Title = title,
                Text = text,
                Buttons = buttons,
            }

            ScpuiSystem:showDialog(self, params)
        end
    end

    ScpuiSystem.data.memory.WarningCountShown = true

    if self.Controller == PilotSelectController.CONTROLLER_PLAYER_SELECT then
        if ui.PilotSelect.isAutoselect() then
            self.Document:GetElementById("playercommit_btn"):Click()
        end

        Topics.pilotselect.initialize:send(self)
    end
end

--- Get the callsign of the last pilot used
--- @return string
function PilotSelectController:getInitialCallsign()
    return ui.PilotSelect.getLastPilot()
end

--- Create a list item element for the pilot
--- @param pilot_name string
--- @return Element
function PilotSelectController:createPilotListItem(pilot_name)
    local li_el = self.Document:CreateElement("li")

    li_el.inner_rml = pilot_name
    li_el:SetClass("pilotlist_element", true)
    li_el:AddEventListener("click", function(_, _, _)
        self:selectPilot(pilot_name)
    end)

    self.Pilot_Elements[pilot_name] = li_el

    return li_el
end

--- Select a pilot by name
--- @param pilot string | nil The name of the pilot to select
--- @return nil
function PilotSelectController:selectPilot(pilot)
    if self.SelectedPilotName == pilot then
        -- No changes
        -- Actually causes lots of issues with barracks.lua
        -- So only do if in Initial Pilot Select
        if self.Controller == PilotSelectController.CONTROLLER_PLAYER_SELECT then
            return
        end
    end

    if self.SelectedPilotHandle ~= nil then
        ba.savePlayer(self.SelectedPilotHandle) -- Save the player in case there were changes
        self.SelectedPilotHandle = nil
    end
    if self.SelectedPilotName ~= nil and self.Pilot_Elements[self.SelectedPilotName] ~= nil then
        self.Pilot_Elements[self.SelectedPilotName]:SetPseudoClass("checked", false)
    end

    self.SelectedPilotName = pilot
    if self.SelectedPilotName ~= nil and self.Controller == PilotSelectController.CONTROLLER_BARRACKS then
        self.SelectedPilotHandle = ba.loadPlayer(self.SelectedPilotName)
    end

    if self.SelectedPilotName ~= nil and self.Pilot_Elements[self.SelectedPilotName] ~= nil then
        self.Pilot_Elements[pilot]:SetPseudoClass("checked", true)
        self.Pilot_Elements[pilot]:ScrollIntoView()
    end
end

--- The commit button was pressed
--- @return nil
function PilotSelectController:commit_pressed()
    local button = self.Document:GetElementById("playercommit_btn")

    Topics.pilotselect.commit:send(self)

    if self.SelectedPilotName == nil then
        ui.playElementSound(button, "click", "error")

        local text = ba.XSTR("You must select a valid pilot first", 888397)
        --- @type dialog_button[]
        local buttons = {}
        buttons[1] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
            Text = ba.XSTR("Ok", 888286),
            Value = "",
            Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1)
        }

        --- @type dialog_setup
        local params = {
            Title = "",
            Text = text,
            Buttons = buttons,
        }

        ScpuiSystem:showDialog(self, params)
        return
    end

    if not ui.PilotSelect.checkPilotLanguage(self.SelectedPilotName) then
        ui.playElementSound(button, "click", "error")

        self:showWrongPilotLanguageDialog()
        return
    end

    ui.PilotSelect.selectPilot(self.SelectedPilotName, self.CurrentMode == "multi")
    ui.playElementSound(button, "click", "commit")
end

--- Show a dialog indicating that the selected pilot was created with a different language
--- @return nil
function PilotSelectController:showWrongPilotLanguageDialog()
    local text = ba.XSTR("Selected pilot was created with a different language to the currently active language.\n\nPlease select a different pilot or change the language", -1)
    --- @type dialog_button[]
    local buttons = {}
    buttons[1] = {
        Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
        Text = ba.XSTR("Ok", 888286),
        Value = "",
        Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1)
    }

    --- @type dialog_setup
    local params = {
        Title = "",
        Text = text,
        Buttons = buttons,
    }

    ScpuiSystem:showDialog(self, params)
end

--- Set the player mode to single or multi. Returns true if the mode was changed
--- @param element Element | nil The element that triggered the change
--- @param mode string The mode to set. Either "single" or "multi"
--- @return boolean
function PilotSelectController:set_player_mode(element, mode)
    assert(Utils.table.contains(PilotSelectController.VALID_MODES, mode), "Mode " .. tostring(mode) .. " is not valid!")

    if self.CurrentMode == mode then
        if element ~= nil then
            ui.playElementSound(element, "click", "error")
        end
        return false
    end

    local elements

    if self.Controller == PilotSelectController.CONTROLLER_PLAYER_SELECT then
        elements = {
            {
                multi  = "multiplayer_btn",
                single = "singleplayer_btn"
            },
            {
                multi  = "multiplayer_text",
                single = "singleplayer_text"
            },
        }
    else
        elements = {
            {
                multi  = "multiplayer_btn",
                single = "singleplayer_btn"
            },
        }
    end

    local is_single = mode == "single"
    self.CurrentMode = mode

    for _, v in ipairs(elements) do
        local multi_el  = self.Document:GetElementById(v.multi)
        local single_el = self.Document:GetElementById(v.single)

        multi_el:SetPseudoClass("checked", not is_single)
        single_el:SetPseudoClass("checked", is_single)
    end

    if element ~= nil then
        ui.playElementSound(element, "click", "success")
    end

    return true
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function PilotSelectController:global_keydown(element, event)
    local keys = ScpuiSystem:getKeyInfo(event)
    if self.Controller == PilotSelectController.CONTROLLER_PLAYER_SELECT then
        if keys.ESCAPE and Topics.pilotselect.escKeypress:send(self) == true then
            event:StopPropagation()
            ba.postGameEvent(ba.GameEvents["GS_EVENT_QUIT_GAME"])
        elseif keys.UP and Topics.pilotselect.upKeypress:send(self) == true then
            self:down_button_pressed()
        elseif keys.DOWN and Topics.pilotselect.dwnKeypress:send(self) == true then
            self:up_button_pressed()
        elseif keys.RETURN and Topics.pilotselect.retKeypress:send(self) == true then
            self:commit_pressed()
        elseif keys.DELETE and Topics.pilotselect.delKeypress:send(self) == true then
            self:delete_player()
        else
            --Catch all for customization
            Topics.pilotselect.globalKeypress:send({self, event})
        end
    end
end

--- Cancel inputting a callsign and reset the input variables
--- @return nil
function PilotSelectController:callsignInputCancel()
    local input_el = Element.As.ElementFormControlInput(self.Document:GetElementById("pilot_name_input"))
    input_el:SetClass("hidden", true) -- Show the element
    input_el.value              = ""

    self.CallsignInputActive  = false
    self.callsignInputAction = nil
end

--- On keyup check if ESC was pressed, if so and the input is active, cancel the input
--- @param element Element The element that triggered the event
--- @param event Event The event that was triggered
--- @return nil
function PilotSelectController:callsign_keyup(element, event)
    local keys = ScpuiSystem:getKeyInfo(event)

    if not self.CallsignInputActive then
        return
    end

    if not keys.ESCAPE then
        return
    end
    event:StopPropagation()

    self:callsignInputCancel()
end

--- On input change, capture the event and pass it to the action
--- @param element Element The element that triggered the event
--- @param event Event The event that was triggered
--- @return nil
function PilotSelectController:callsign_input_change(element, event)
    if not self.CallsignInputActive then
        -- Only process enter events when we are actually inputting something
        return
    end

    -- if the linebreak parameter is not set, then clear out any invalid characters
    if event.parameters.linebreak ~= 1 then
        local function sanitizeString(input)
            local sanitized = input:gsub("[^%a%d%s_%-%d]", "")
            sanitized = sanitized:gsub("^[^%a]+", "") -- Ensure the first character is a letter
            return sanitized
        end

        element:SetAttribute("value", sanitizeString(event.parameters.value))
        return
    end

    event:StopPropagation()
    self.callsignInputAction(event.parameters.value)
    self:callsignInputCancel()
end

--- Begin inputting a callsign and set the action to be executed when the callsign has been entered
--- @param end_action function The function to execute when the callsign has been entered
--- @return nil
function PilotSelectController:beginCallsignInput(end_action)
    local input_el = self.Document:GetElementById("pilot_name_input")
    input_el:SetClass("hidden", false) -- Show the element
    input_el:Focus()
    ui.playElementSound(input_el, "click", "success")

    self.CallsignInputActive  = true

    -- This is the function that will be executed when the name has been entered and submitted
    self.callsignInputAction = end_action
end

--- Complete pilot creation, send it to FSO, and create the pilot list element
--- @param element Element The element that triggered the event
--- @param callsign string The callsign of the pilot to create
--- @param clone_from string | nil The callsign of the pilot to clone from
--- @param overwrite_pilot boolean True if the pilot should be overwritten
--- @return nil
function PilotSelectController:finishPilotCreate(element, callsign, clone_from, overwrite_pilot)
    local result
    if clone_from ~= nil then
        result = ui.PilotSelect.createPilot(callsign, self.CurrentMode == "multi", clone_from)
    else
        result = ui.PilotSelect.createPilot(callsign, self.CurrentMode == "multi")
    end

    if not result then
        ui.playElementSound(element, "click", "error")
        return
    end

    if not overwrite_pilot then
        -- If first_child is nil then this will add at the end of the list
        table.insert(self.pilots, 1, callsign)
        local pilot_ul = self.Document:GetElementById("pilotlist_ul")
        local new_li = self:createPilotListItem(callsign)
        pilot_ul:InsertBefore(new_li, pilot_ul.first_child)
    end

    self:selectPilot(callsign)
end

--- Create a new pilot if the callsign is not a duplicate or we are cloning a pilot
--- @param element Element The element that triggered the event
--- @param callsign string The callsign of the pilot to create
--- @param clone_from string | nil The callsign of the pilot to clone from
--- @return nil
function PilotSelectController:actualPilotCreate(element, callsign, clone_from)
    if Utils.table.contains(self.pilots, callsign, function(left, right)
        return left:lower() == right:lower()
    end) then
        local title = ba.XSTR("Warning", 888284)
        local text = ba.XSTR("A duplicate pilot exists\nOverwrite?", 888401)
        --- @type dialog_button[]
        local buttons = {}
        buttons[1] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
            Text = ba.XSTR("Yes", 888296),
            Value = "",
            Keypress = string.sub(ba.XSTR("Yes", 888296), 1, 1)
        }
        buttons[2] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
            Text = ba.XSTR("No", 888298),
            Value = "",
            Keypress = string.sub(ba.XSTR("No", 888298), 1, 1)
        }

        ---@type dialog_setup
        local params = {
            Title = title,
            Text = text,
            Buttons = buttons,
        }

        ScpuiSystem:showDialog(self, params, function(response)
            if not response then
                return
            end
            self:finishPilotCreate(element, callsign, clone_from, true)
        end)
        return
    end

    self:finishPilotCreate(element, callsign, clone_from, false)
end

--- The create pilot button was pressed
--- @param element Element The element that triggered the event
--- @return nil
function PilotSelectController:create_player(element)
    if #self.pilots >= ui.PilotSelect.MAX_PILOTS then
        ui.playElementSound(element, "click", "error")
        return
    end

    self.SelectedPilotHandle = nil

    self:beginCallsignInput(function(callsign)
        self:actualPilotCreate(element, callsign)
    end)
end

--- The clone pilot button was pressed
--- @param element Element The element that triggered the event
--- @return nil
function PilotSelectController:clone_player(element)
    if #self.pilots >= ui.PilotSelect.MAX_PILOTS then
        ui.playElementSound(element, "click", "error")
        return
    end

    local current = self.SelectedPilotName

    if current == nil then
        return
    end

    self:beginCallsignInput(function(callsign)
        self:actualPilotCreate(element, callsign, current)
    end)
end

--- The delete pilot button was pressed
--- @param element Element | nil The element that triggered the event
--- @return nil
function PilotSelectController:delete_player(element)
    if self.SelectedPilotName == nil then
        return
    end

    if self.CurrentMode == "multi" then
        local title = ba.XSTR("Disabled!", 888404)
        local text = ba.XSTR("Multi and single player pilots are now identical. Deleting a multi-player pilot will also delete" ..
                                     " all single-player data for that pilot.\n\nAs a safety precaution, pilots can only be deleted from the" ..
                                     " single-player menu.", -1)
        --- @type dialog_button[]
        local buttons = {}
        buttons[1] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
            Text = ba.XSTR("Ok", 888286),
            Value = "",
            Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1)
        }

        --- @type dialog_setup
        local params = {
            Title = title,
            Text = text,
            Buttons = buttons,
        }

        ScpuiSystem:showDialog(self, params)
        return
    end

    local title = ba.XSTR("Warning!" , 888395)
    local text = ba.XSTR("Are you sure you wish to delete this pilot?", 888407)
    --- @type dialog_button[]
    local buttons = {}
    buttons[1] = {
        Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
        Text = ba.XSTR("Yes", 888296),
        Value = "",
        Keypress = string.sub(ba.XSTR("Yes", 888296), 1, 1)
    }
    buttons[2] = {
        Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
        Text = ba.XSTR("No", 888297),
        Value = "",
        Keypress = string.sub(ba.XSTR("No", 888297), 1, 1)
    }

    ---@type dialog_setup
    local params = {
        Title = title,
        Text = text,
        Buttons = buttons,
    }

    ScpuiSystem:showDialog(self, params, function(response)
        if not response then
            return
        end

        -- Deselect the pilot first to avoid restoring it later
        local pilot = self.SelectedPilotName
        self:selectPilot(nil)

        if(pilot == nil) then
            return
        end

        if not ui.PilotSelect.deletePilot(pilot) then
            local title = ba.XSTR("Error", 888408)
            local text = ba.XSTR("Failed to delete pilot file. File may be read-only.", 888409)
            --- @type dialog_button[]
            local buttons = {}
            buttons[1] = {
                Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
                Text = ba.XSTR("Ok", 888286),
                Value = "",
                Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1)
            }

            --- @type dialog_setup
            local params = {
                Title = title,
                Text = text,
                Buttons = buttons,
            }

            ScpuiSystem:showDialog(self, params)
            return
        end

        -- Remove the element from the list
        local removed_el = self.Pilot_Elements[pilot]
        removed_el.parent_node:RemoveChild(removed_el)
        self.Pilot_Elements[pilot] = nil

        Utils.table.iremove_el(self.pilots, pilot)

        self:selectFirstPilot()
    end)
end

--- Select the first pilot in the list, if any
--- @return nil
function PilotSelectController:selectFirstPilot()
    if #self.pilots <= 0 then
        self:selectPilot(nil)
        return
    end

    self:selectPilot(self.pilots[1])
end

--- Input focus was lost, currently does nothing
--- @return nil
function PilotSelectController:callsign_input_focus_lost()
--do nothing
end

--- The up arrow button was pressed
--- @return nil
function PilotSelectController:up_button_pressed()
    if self.SelectedPilotName == nil then
        self:selectFirstPilot()
        return
    end

    local idx = Utils.table.ifind(self.pilots, self.SelectedPilotName)
    idx       = idx + 1
    if idx > #self.pilots then
        idx = 1
    end

    self:selectPilot(self.pilots[idx])
end

--- The down arrow button was pressed
--- @return nil
function PilotSelectController:down_button_pressed()
    if self.SelectedPilotName == nil then
        self:selectFirstPilot()
        return
    end

    local idx = Utils.table.ifind(self.pilots, self.SelectedPilotName)
    idx       = idx - 1
    if idx < 1 then
        idx = #self.pilots
    end

    self:selectPilot(self.pilots[idx])
end

--- Called when the screen is being unloaded
--- @return nil
function PilotSelectController:unload()
    Topics.pilotselect.unload:send(self)
end

return PilotSelectController
