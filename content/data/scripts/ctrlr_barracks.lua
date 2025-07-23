-----------------------------------
--Controller for the Barracks UI
-----------------------------------

local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local PilotSelectController = require("ctrlr_pilot_select")

--- Barracks Controller is merged with the Pilot Select Controller
local BarracksScreenController = Class(PilotSelectController)

--- Called by the class constructor
--- @return nil
function BarracksScreenController:init()
    self.Controller = PilotSelectController.CONTROLLER_BARRACKS --- @type number The current UI Controller. Used to separate functionality between barracks and pilot select in the class
    self.HelpShown = false --- @type boolean If the help boxes are currently shown or not
    self.Pilot_Images = ui.Barracks.listPilotImages() --- @type string[] The list of pilot images
    self.Squad_Images = ui.Barracks.listSquadImages() --- @type string[] The list of squad images
    self.Document = nil --- @type Document The current document
    self.SelectedPilotName = nil --- @type string | nil The currently selected pilot name
    self.SelectedPilotHandle = nil --- @type player The currently selected pilot handle
    self.CurrentMode = "single" --- @type string The current mode of the player. Either "single" or "multi"
end

--- Called by the RML document
--- @param document Document
function BarracksScreenController:initialize(document)
    PilotSelectController.initialize(self, document)

    --Hide Multi stuff maybe
    if ScpuiSystem.data.table_flags.HideMulti == true then
        self.Document:GetElementById("multiplayer_btn"):SetClass("hidden", true)
    end

    ---Load background choice
    self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

    ---Load the desired font size from the save file
    self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    Topics.barracks.initialize:send(self)

end

--- Change the image of the pilot head by filename
--- @param new_img string | nil
--- @return nil
function BarracksScreenController:changeImage(new_img)
    if new_img == nil then
        self.Document:GetElementById("pilot_head_text_el").inner_rml = ""
        self.Document:GetElementById("pilot_head_img_el"):SetAttribute("src", "")
        return
    end

    new_img     = Utils.strip_extension(new_img) -- The image may have an extension
    local index = Utils.table.ifind(self.Pilot_Images, new_img)

    if index <= 0 then
        local text_el     = self.Document:GetElementById("pilot_head_text_el")
        text_el.inner_rml = ""

        self.Document:GetElementById("pilot_head_img_el"):SetAttribute("src", "")
    else
        local text_el     = self.Document:GetElementById("pilot_head_text_el")
        text_el.inner_rml = string.format("%d of %d", index, #self.Pilot_Images)

        self.Document:GetElementById("pilot_head_img_el"):SetAttribute("src", new_img)
    end
end

--- Change the image index of the pilot head using an offset
--- @param element Element The element that was clicked
--- @param diff number The offset to change the image index by
--- @return nil
function BarracksScreenController:changeImgIndex(element, diff)
    if self.SelectedPilotName == nil or #self.Pilot_Images <= 0 then
        ui.playElementSound(element, "click", "error")
        return
    end

    local current_img = Utils.strip_extension(self.SelectedPilotHandle.ImageFilename) -- The image may have an extension
    local index       = Utils.table.ifind(self.Pilot_Images, current_img)

    index             = index + diff
    if index > #self.Pilot_Images then
        index = 1
    elseif index < 1 then
        index = #self.Pilot_Images
    end

    self.SelectedPilotHandle.ImageFilename = self.Pilot_Images[index]
    self:changeImage(self.Pilot_Images[index])

    ui.playElementSound(element, "click", "success")
end

--- Increment the image index of the pilot head
--- @param element Element The element that was clicked
--- @return nil
function BarracksScreenController:next_image_pressed(element)
    self:changeImgIndex(element, 1)
end

--- Decrement the image index of the pilot head
--- @param element Element The element that was clicked
--- @return nil
function BarracksScreenController:prev_image_pressed(element)
    self:changeImgIndex(element, -1)
end

--- Add a heading element to the stats
--- @param parent Element The parent element to append the heading to
--- @param text string The text to display
--- @return nil
function BarracksScreenController:addHeadingElement(parent, text)
    local container = self.Document:CreateElement("div")
    local text_el   = self.Document:CreateTextNode(text)

    container:AppendChild(text_el)
    container:SetClass("stats_heading", true)
    container:SetClass("header_text", true)

    parent:AppendChild(container)
end

--- Add a value element to the stats
--- @param parent Element The parent element to append the value to
--- @param text string The text to display
--- @param value string | number The value to display
--- @return nil
function BarracksScreenController:addValueElement(parent, text, value)
    local text_container = self.Document:CreateElement("div")
    local text_el        = self.Document:CreateTextNode(text)
    text_container:AppendChild(text_el)
    text_container:SetClass("stats_value_label", true)

    local value_container = self.Document:CreateElement("div")
    local value_el        = self.Document:CreateTextNode(tostring(value))
    value_container:AppendChild(value_el)
    value_container:SetClass("stats_value_text", true)

    parent:AppendChild(text_container)
    parent:AppendChild(value_container)
end

--- Add an empty line to the stats
--- @param parent Element The parent element to append the empty line to
--- @return nil
function BarracksScreenController:addEmptyLine(parent)
    local text_container = self.Document:CreateElement("div")
    text_container:SetClass("stats_empty_line", true)

    parent:AppendChild(text_container)
end

--- Initialize the stats text
--- @return nil
function BarracksScreenController:initializeStatsText()
    local text_container     = self.Document:GetElementById("pilot_stats_text")

    -- Always clear the container to remove old elements
    text_container.inner_rml = ""
    if self.SelectedPilotHandle == nil then
        return
    end

    local stats = self.SelectedPilotHandle.Stats

    self:addHeadingElement(text_container, ba.XSTR("All Time Stats", 50, false))
    self:addValueElement(text_container, ba.XSTR("Primary weapon shots:", 51, false), stats.PrimaryShotsFired)
    self:addValueElement(text_container, ba.XSTR("Primary weapon hits:", 52, false), stats.PrimaryShotsHit)
    self:addValueElement(text_container, ba.XSTR("Primary friendly hits:", 53, false), stats.PrimaryFriendlyHit)
    self:addValueElement(text_container, ba.XSTR("Primary hit %:", 54, false), Utils.compute_percentage(stats.PrimaryShotsHit, stats.PrimaryShotsFired))
    self:addValueElement(text_container, ba.XSTR("Primary friendly hit %:", 56, false), Utils.compute_percentage(stats.PrimaryFriendlyHit, stats.PrimaryShotsFired))
    self:addEmptyLine(text_container)

    self:addValueElement(text_container, ba.XSTR("Secondary weapon shots:", 57, false), stats.SecondaryShotsFired)
    self:addValueElement(text_container, ba.XSTR("Secondary weapon hits:", 58, false), stats.SecondaryShotsHit)
    self:addValueElement(text_container, ba.XSTR("Secondary friendly hits:", 59, false), stats.SecondaryFriendlyHit)
    self:addValueElement(text_container, ba.XSTR("Secondary hit %:", 60, false), Utils.compute_percentage(stats.SecondaryShotsHit, stats.SecondaryShotsFired))
    self:addValueElement(text_container, ba.XSTR("Secondary friendly hit %:", 61, false), Utils.compute_percentage(stats.SecondaryFriendlyHit, stats.SecondaryShotsFired))
    self:addEmptyLine(text_container)

    self:addValueElement(text_container, ba.XSTR("Total kills:", 62, false), stats.TotalKills)
    self:addValueElement(text_container, ba.XSTR("Assists:", 63, false), stats.Assists)
    self:addEmptyLine(text_container)

    self:addValueElement(text_container, ba.XSTR("Current Score:", 1583, false), stats.Score)
    self:addEmptyLine(text_container)
    self:addEmptyLine(text_container)

    self:addHeadingElement(text_container, ba.XSTR("Kills by Ship Type", 1636, false))
    local score_from_kills = 0
    for i = 1, #tb.ShipClasses do
        local ship_cls = tb.ShipClasses[i]
        local kills    = stats:getShipclassKills(ship_cls)

        if kills > 0 then
            local name = Topics.ships.name:send(ship_cls)
            score_from_kills = score_from_kills + kills * ship_cls.Score
            self:addValueElement(text_container, name .. ":", kills)
        end
    end
    self:addValueElement(text_container, ba.XSTR("Score from kills only:", 51, false), score_from_kills)
end

--- Select a pilot by name
--- @param pilot string The name of the pilot to select
--- @return nil
function BarracksScreenController:selectPilot(pilot)
    PilotSelectController.selectPilot(self, pilot)
    --PilotSelectController.selectPilot(self, pilot) explicitly calls the selectPilot method of the PilotSelectController class.
    --This ensures that the parent class's implementation of selectPilot is executed first.

    if self.SelectedPilotHandle ~= nil then
        self.SelectedPilotHandle:loadCampaignSavefile()
    end

    if pilot == nil then
        self:changeImage(nil)
        self:changeSquad(nil)
    else
        self:changeImage(self.SelectedPilotHandle.ImageFilename)
        if self.CurrentMode == "multi" then
            self:changeSquad(self.SelectedPilotHandle.MultiSquadFilename)
        else
            self:changeSquad(self.SelectedPilotHandle.SingleSquadFilename)
        end
    end

    self:initializeStatsText()
end

--- Get the current player's callsign
--- @return string
function BarracksScreenController:getInitialCallsign()
    return ba.getCurrentPlayer():getName()
end

--- Commit button was pressed
--- @param element Element The element that was clicked
--- @return nil
function BarracksScreenController:commit_pressed(element)
    if self.SelectedPilotName == nil then
        ui.playElementSound(element, "click", "error")
        return
    end

    if not ui.PilotSelect.checkPilotLanguage(self.SelectedPilotName) then
        ui.playElementSound(element, "click", "error")

        PilotSelectController.showWrongPilotLanguageDialog(self)
        return
    end

    ui.playElementSound(element, "click", "commit")
    ui.Barracks.acceptPilot(self.SelectedPilotHandle)
end

--- Medals button was pressed
--- @return nil
function BarracksScreenController:medals_button_clicked()
    if self.SelectedPilotHandle ~= nil then
        ba.savePlayer(self.SelectedPilotHandle) -- Save the player in case there were changes
        ui.Barracks.acceptPilot(self.SelectedPilotHandle, false)
    end

    ba.postGameEvent(ba.GameEvents['GS_EVENT_VIEW_MEDALS'])
end

--- Options button was pressed
--- @return nil
function BarracksScreenController:options_button_clicked()
    if self.SelectedPilotHandle ~= nil then
        ba.savePlayer(self.SelectedPilotHandle) -- Save the player in case there were changes
        ui.Barracks.acceptPilot(self.SelectedPilotHandle, false)
    end

    ba.postGameEvent(ba.GameEvents['GS_EVENT_OPTIONS_MENU'])
end

--- Set the player mode between single and multiplayer
--- @param element Element The element that was clicked
--- @param mode string The mode to set the player to. Must be one of "single" or "multi"
--- @return boolean success True if the mode was set successfully, false otherwise
function BarracksScreenController:set_player_mode(element, mode)
    if not PilotSelectController.set_player_mode(self, element, mode) then
        return false
    end

    local is_multi     = mode == "multi"

    ba.MultiplayerMode = is_multi
    if self.SelectedPilotHandle then
        self.SelectedPilotHandle.IsMultiplayer = is_multi
    end

    self.Document:GetElementById("squad_select_right_btn"):SetClass("hidden", not is_multi)
    self.Document:GetElementById("squad_select_left_btn"):SetClass("hidden", not is_multi)
    self.Document:GetElementById("pilot_squad_counter"):SetClass("hidden", not is_multi)

    if self.CurrentMode == "multi" then
        self:changeSquad(self.SelectedPilotHandle.MultiSquadFilename)
    else
        self:changeSquad(self.SelectedPilotHandle.SingleSquadFilename)
    end

    return true
end

--- Change the squad image by filename
--- @param new_img string | nil
--- @return nil
function BarracksScreenController:changeSquad(new_img)
    if new_img == nil then
        self.Document:GetElementById("pilot_squad_text_el").inner_rml = ""
        self.Document:GetElementById("pilot_squad_img_el"):SetAttribute("src", "")
        return
    end

    new_img     = Utils.strip_extension(new_img) -- The image may have an extension
    local index = Utils.table.ifind(self.Squad_Images, new_img)

    if index <= 0 then
        -- Invalid image found. Let's try to avoid displaying a warning here
        local text_el     = self.Document:GetElementById("pilot_squad_text_el")
        text_el.inner_rml = ""

        self.Document:GetElementById("pilot_squad_img_el"):SetAttribute("src", "")
    else
        local text_el     = self.Document:GetElementById("pilot_squad_text_el")
        text_el.inner_rml = string.format("%d of %d", index, #self.Squad_Images)

        self.Document:GetElementById("pilot_squad_img_el"):SetAttribute("src", new_img)
    end
end

--- Change squad image by index offset
--- @param element Element The element that was clicked
--- @param diff number The offset to change the image index by
--- @return nil
function BarracksScreenController:changeSquadIndex(element, diff)
    if self.SelectedPilotName == nil or #self.Squad_Images <= 0 then
        ui.playElementSound(element, "click", "error")
        return
    end

    local squad
    if self.CurrentMode == "multi" then
        squad = self.SelectedPilotHandle.MultiSquadFilename
    else
        squad = self.SelectedPilotHandle.SingleSquadFilename
    end

    local current_img = Utils.strip_extension(squad) -- The image may have an extension
    local index       = Utils.table.ifind(self.Squad_Images, current_img)

    index             = index + diff
    if index > #self.Squad_Images then
        index = 1
    elseif index < 1 then
        index = #self.Squad_Images
    end

    if self.CurrentMode == "multi" then
        self.SelectedPilotHandle.MultiSquadFilename = self.Squad_Images[index]
    else
        self.SelectedPilotHandle.SingleSquadFilename = self.Squad_Images[index]
    end
    self:changeSquad(self.Squad_Images[index])

    ui.playElementSound(element, "click", "success")
end

--- Next squad button was pressed
--- @param element Element The element that was clicked
--- @return nil
function BarracksScreenController:next_squad_pressed(element)
    self:changeSquadIndex(element, 1)
end

--- Previous squad button was pressed
--- @param element Element The element that was clicked
--- @return nil
function BarracksScreenController:prev_squad_pressed(element)
    self:changeSquadIndex(element, -1)
end

--- Help button was clicked
--- @return nil
function BarracksScreenController:help_clicked()
    self.HelpShown  = not self.HelpShown

    local help_texts = self.Document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.HelpShown)
    end
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function BarracksScreenController:global_keydown(element, event)
    local keys = ScpuiSystem:getKeyInfo(event)
    if self.Controller == PilotSelectController.CONTROLLER_BARRACKS then
        if keys.ESCAPE then
            if self.SelectedPilotHandle == nil then
                ui.playElementSound(element, "click", "error")
                return
            end
            ui.Barracks.acceptPilot(self.SelectedPilotHandle, false)
            event:StopPropagation()
            ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
        end
    end
end

--- Called when the screen is being unloaded
--- @return nil
function BarracksScreenController:unload()
    Topics.barracks.unload:send(self)
end

return BarracksScreenController
