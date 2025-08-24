-----------------------------------
--Controller for the Journal UI
-----------------------------------

local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local JournalController = Class()

--- @type JournalUi
local JournalUi = ScpuiSystem.extensions.JournalUi

--- Called by the class constructor
--- @return nil
function JournalController:init()
    self.Document = nil --- @type Document the Rml document
    self.Data = nil --- @type scpui_journal_data the journal data
    self.SaveData = {} --- @type table<number, scpui_journal_save_data[]> the journal save data
    self.SelectedEntry = nil --- @type string the selected entry
    self.SelectedSection = nil --- @type number the selected section
end

--- Called by the RML document
--- @param document Document
function JournalController:initialize(document)

    self.Document = document

    ---Load background choice
    self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

    ---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    self:registerEventHandlers()

    local player = ba.getCurrentPlayer()
    local campaign_filename = player:getCampaignFilename()

    self.Data = JournalUi:parseJournalTable(campaign_filename .. "-journal.tbl")

    if not self.Data then return end

    self.Data.Visible_List = {}
    self.SaveData = JournalUi:loadDataFromFile()

    self.SelectedEntry = nil

    for i=1, #self.Data.Section_List do
        if self.Data.Section_List[i] then
            self.Document:GetElementById("label_"..i).inner_rml = "<p>" .. self.Data.Section_List[i].Display .. "</p>"
        end
    end

    Topics.journal.initialize:send(self)

    self.SelectedSection = nil
    self:change_section(1)

end

--- Changes to the specified section
--- @param section number the section to change to
--- @return nil
function JournalController:change_section(section)

    if self.Data and (section ~= self.SelectedSection) and self.Data.Section_List[section] then

        if self.SelectedEntry then
            self:ClearEntry()
        end

        --If we had an old section on, remove the active class
        if self.SelectedSection then
            local oldbullet = self.Document:GetElementById("btn_"..self.SelectedSection)
            oldbullet:SetPseudoClass("checked", false)
        end

        self.SelectedSection = section
        self:createJournalEntries(self.SelectedSection)
        local newbullet = self.Document:GetElementById("btn_"..self.SelectedSection)
        newbullet:SetPseudoClass("checked", true)

    end

end

--- Create a journal list item element and returns it
--- @param entry scpui_journal_entry the entry to create the element for
--- @param unread boolean whether the entry is unread
--- @return Element li_el the created element
function JournalController:createJournalListItemElement(entry, unread)

    local li_el = self.Document:CreateElement("li")

    li_el.inner_rml = ScpuiSystem:createListItemHeader(entry.Display, unread)
    li_el:SetClass("journallist_element", true)
    li_el:AddEventListener("click", function(_, _, _)
        self:selectEntry(entry.Key)
    end)

    self.Data.Visible_List[entry.Key] = li_el

    return li_el

end

--- Creates all entries for the current section
--- @param section number the section to create the entries for
--- @return nil
function JournalController:createJournalEntries(section)

    local list_el = self.Document:GetElementById("list_items_ul")

    ScpuiSystem:clearEntries(list_el)
    self.Data.Visible_List = {}

    for i, v in ipairs(self.Data.Entry_List[section]) do
        local saved_data = (self.SaveData[section] or {})[i]
        if saved_data and saved_data.Visible then
            -- Add all the elements
            ba.print("Adding entry " .. i .. ": " .. v.Name .. "\n" )
            list_el:AppendChild(self:createJournalListItemElement(v,saved_data.Unread))
        end
    end
end

--- Clears the selected entry
--- @return nil
function JournalController:ClearEntry()
    self.Data.Visible_List[self.SelectedEntry]:SetPseudoClass("checked", false)
    self.SelectedEntry = nil

    self.Document:GetElementById("journaltext").inner_rml = "<p> </p>"
end

--- Converts the journal plain text to rml format
--- @param text string the text to convert
--- @return string text the converted text
function JournalController:convertTextToRml(text)
    local lines = Utils.split(text, "\n\n")

    local paragraphs = Utils.table.map(lines, function(line)
        return "<p>" .. Utils.rml_escape(line) .. "</p>"
    end)

    return table.concat(paragraphs, "<br></br>")
end

--- Selects the specified entry by key
--- @param key string the key of the entry to select
--- @return nil
function JournalController:selectEntry(key)

    if self.Data then
        if key ~= self.SelectedEntry then

            if self.SelectedEntry then
                local previous_entry = self.Data.Visible_List[self.SelectedEntry]
                if previous_entry then previous_entry:SetPseudoClass("checked", false) end
            end

            local this_entry = self.Data.Visible_List[key]
            self.SelectedEntry = key
            this_entry:SetPseudoClass("checked", true)

            local index = self:getIndexFromKey(key, self.SelectedSection)

            if index then

                local entry_data = self.Data.Entry_List[self.SelectedSection][index]
                local filename = entry_data.File
                local text = self:getTextFromFile(filename)
                local image = entry_data.Image
                local caption = entry_data.Caption

                if text then
                    self.Document:GetElementById("journaltext").inner_rml = "<p>" ..  self:convertTextToRml(text) .."</p>"

                    if image and caption then
                        self.Document:GetElementById("journaltext").inner_rml = "<div id=journalpic><img src=\"" .. image .."\"></img><div class=\"s1\" id=piccaption><p>" .. caption .. "</p></div></div>" .. self.Document:GetElementById("journaltext").inner_rml
                    elseif image then
                        self.Document:GetElementById("journaltext").inner_rml = "<div id=journalpic><img src=\"" .. image .."\"></img></div>" .. self.Document:GetElementById("journaltext").inner_rml
                    end

                else
                    ba.error("Can't find journal text file ".. filename .. "\n")
                end

                local saved_data = self.SaveData[self.SelectedSection][index]

                if saved_data.Unread then
                    this_entry.inner_rml = self.Data.Entry_List[self.SelectedSection][index].Name
                    saved_data.Unread = false
                    JournalUi:saveDataToFile(self.SaveData)
                end

            end
        end
    end

end

--- Gets the index of the specified key in the specified section
--- @param key string the key to search for
--- @param section number the section to search in
--- @return number? index the index of the key
function JournalController:getIndexFromKey(key, section)
    for i,v in ipairs(self.Data.Entry_List[section]) do
        if v.Key == key then return i end
    end

    return nil
end

--- Gets the text from the specified file
--- @param file string the file to get the text from
--- @return string text the text from the file
function JournalController:getTextFromFile(file)

	if ba.getCurrentLanguageExtension() ~= "" then
		file = file .. "-" .. ba.getCurrentLanguageExtension()
	end

    local this_file = cf.openFile(file,"rb","data/fiction")
    local text = this_file:read("*a")
    this_file:close()

    return text

end

--- Called by the RML to exit the journal UI
--- @param element Element the element that called this function
--- @return nil
function JournalController:exit(element)
    ui.playElementSound(element, "click", "success")
    ScpuiSystem:returnToState(ScpuiSystem.data.LastState)
    self.Document:Close()
end

--- Registers event handlers?? Does nothing now, obviously
--- @return nil
function JournalController:registerEventHandlers()

end

--- Called when the screen is being unloaded
--- @return nil
function JournalController:unload()
	Topics.journal.unload:send(self)
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function JournalController:global_keydown(element, event)
    local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()
        self.Document:Close()
        ScpuiSystem:returnToState(ScpuiSystem.data.LastState)
    end
end

return JournalController
