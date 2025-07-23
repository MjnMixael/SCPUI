-----------------------------------
--Controller for the Game Help UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local GamehelpController = Class()

--- Called by the class constructor
--- @return nil
function GamehelpController:init()
	self.Document = nil ---@type Document The RML document
	self.TotalSections = 0 ---@type number The total number of sections in the game help to display
	self.Sections = {} ---@type game_help_section[] The sections of the game help
	self.CurrentSection = 1 ---@type number The current section of the game help to display
end

--- Called by the RML document
--- @param document Document
function GamehelpController:initialize(document)

    self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	if mn.isInMission() then
		ScpuiSystem:pauseAllAudio(true)
	end

	ui.GameHelp.initGameHelp()

	self.TotalSections = #ui.GameHelp.Help_Sections
	if ScpuiSystem.data.table_flags.HideMulti then
		self.TotalSections = self.TotalSections - 1
	end
	self.Sections = {}

	local count = 1
	for i = 1, #ui.GameHelp.Help_Sections do
		if ui.GameHelp.Help_Sections[i].Title == 'Multiplayer Keys' and ScpuiSystem.data.table_flags.HideMulti then
			--Skip adding the multi keys
		else
			self.Sections[count] = {
				Title = ui.GameHelp.Help_Sections[i].Title,
				Subtitle = "Page " .. count .. " of " .. self.TotalSections,
				Header = ui.GameHelp.Help_Sections[i].Header,
				Keys = ui.GameHelp.Help_Sections[i].Keys,
				Texts = ui.GameHelp.Help_Sections[i].Texts,
				isValid = function() return ui.GameHelp.Help_Sections[i]:isValid() end
			}

			count = count + 1
		end
	end

	ui.GameHelp.closeGameHelp()

	Topics.gamehelp.initialize:send(self)

	self:changeSection(1)

end

--- Go to a specific section of the game help
--- @param section number The section to go to
--- @return nil
function GamehelpController:changeSection(section)

	self.CurrentSection = section
	self:createSectionListItems()
	self.Document:GetElementById("gamehelp_title").inner_rml = self.Sections[section].Title
	self.Document:GetElementById("gamehelp_subtitle").inner_rml = self.Sections[section].Subtitle
	self.Document:GetElementById("gamehelp_header").inner_rml = self.Sections[section].Header

end

--- Create the entries for the current section
--- @return nil
function GamehelpController:createSectionListItems()

	local list_keys_el = self.Document:GetElementById("list_keys_ul")

	ScpuiSystem:clearEntries(list_keys_el)

	for i = 1, #self.Sections[self.CurrentSection].Keys do
		local line = self.Sections[self.CurrentSection].Keys[i]
		local li_el = self.Document:CreateElement("li")
		li_el.inner_rml = line
		list_keys_el:AppendChild(li_el)
	end

	local list_texts_el = self.Document:GetElementById("list_texts_ul")

	ScpuiSystem:clearEntries(list_texts_el)

	for i = 1, #self.Sections[self.CurrentSection].Texts do
		local line = self.Sections[self.CurrentSection].Texts[i]
		local li_el = self.Document:CreateElement("li")
		li_el.inner_rml = line
		list_texts_el:AppendChild(li_el)
	end
end

--- Decrement the current section and loop back to the last section if needed
--- @param element Element The element that triggered the event
--- @return nil
function GamehelpController:decrement_section(element)

    if self.CurrentSection == 1 then
		self:changeSection(self.TotalSections)
	else
		self:changeSection(self.CurrentSection - 1)
	end

end

--- Increment the current section and loop back to the first section if needed
--- @param element Element The element that triggered the event
--- @return nil
function GamehelpController:increment_section(element)

    if self.CurrentSection == self.TotalSections then
		self:changeSection(1)
	else
		self:changeSection(self.CurrentSection + 1)
	end

end

--- The exit button was clicked
--- @param element Element The element that triggered the event
--- @return nil
function GamehelpController:exit(element)

    ui.playElementSound(element, "click", "success")
	if mn.isInMission() then
		ScpuiSystem:pauseAllAudio(false)
	end
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])

end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function GamehelpController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()
		if mn.isInMission() then
			ScpuiSystem:pauseAllAudio(false)
		end
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
    end
end

--- Called when the screen is being unloaded
--- @return nil
function GamehelpController:unload()
	Topics.gamehelp.unload:send(self)
end

return GamehelpController
