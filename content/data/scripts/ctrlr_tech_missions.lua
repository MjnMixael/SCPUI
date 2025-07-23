-----------------------------------
--Controller for the Tech Missions UI
-----------------------------------

local AsyncUtil = require("lib_async")
local Dialogs = require("lib_dialogs")
local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local TechMissionsController = Class()

TechMissionsController.STATE_DATABASE = 0 --- @type number The enumeration for the database state
TechMissionsController.STATE_SIMULATOR = 1 --- @type number The enumeration for the simulator state
TechMissionsController.STATE_CUTSCENE = 2 --- @type number The enumeration for the cutscene state
TechMissionsController.STATE_CREDITS = 3 --- @type number The enumeration for the credits state

TechMissionsController.SECTION_SINGLE = 1 --- @type number The enumeration for the single mission section
TechMissionsController.SECTION_CAMPAIGN = 2 --- @type number The enumeration for the campaign section

--- Called by the class constructor
--- @return nil
function TechMissionsController:init()
	self.Document = nil --- @type Document The RML document
	self.HelpShown = false --- @type boolean Whether the help text is shown
	self.ShowAll = false --- @type boolean Whether all missions are shown
	self.Counter = 0 --- @type number The counter for the number of missions
	self.SelectedEntry = nil --- @type string The selected mission entry
	self.SelectedIndex = 0 --- @type number The index of the selected mission
	self.SelectedSection = nil --- @type string The selected section
	self.SectionIndex = 0 --- @type number The index of the selected section. Should be one of the SECTION_ enumerations
	self.Missions_List = {} --- @type scpui_mission_entry[] The current list of missions
	self.ScrollingElement = nil --- @type Element The mission description element that is currently scrolling
	self.ScrollTimer = nil --- @type number The timer for scrolling the mission description
	self.CampaignName = "" --- @type string The name of the campaign
	self.CampaignFilename = "" --- @type string The filename of the campaign
end

--- Called by the RML document
--- @param document Document
function TechMissionsController:initialize(document)
    self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	self.Document:GetElementById("tech_btn_1"):SetPseudoClass("checked", false)
	self.Document:GetElementById("tech_btn_2"):SetPseudoClass("checked", true)
	self.Document:GetElementById("tech_btn_3"):SetPseudoClass("checked", false)
	self.Document:GetElementById("tech_btn_4"):SetPseudoClass("checked", false)

	Topics.techroom.initialize:send(self)

	Topics.simulator.initialize:send(self)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self:showDialog("Building missions list...", "Mission Simulator")

	async.run(function()
		async.await(AsyncUtil.wait_for(0.001))

		ui.TechRoom.buildMissionList()

		self:getPlayersCampaign()

		self.Document:GetElementById("campaign_title").inner_rml = self.CampaignName
		self.Document:GetElementById("campaign_file").inner_rml = self.CampaignFilename

		self.SelectedEntry = nil

		--Check for last loaded section
		local new_section = ScpuiSystem.data.ScpuiOptionValues.Sim_Room_Choice or self.SECTION_CAMPAIGN


		self.SelectedSection = nil
		self:change_section(new_section)

		ScpuiSystem:closeDialog()

	end, async.OnFrameExecutor)

end

--- Show a dialog box
--- @param text string The text to display in the dialog box
--- @param title string The title of the dialog box
--- @return nil
function TechMissionsController:showDialog(text, title)
	--Create a simple dialog box with the text and title

	local dialog = Dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:show(self.Document.context)
		:continueWith(function()end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.Document.context)
end

--- Called by the RML to change the tech room game state
--- @param element Element The element that was clicked
--- @param state number The state to change to. Should be one of the STATE_ enumerations
--- @return nil
function TechMissionsController:change_tech_state(element, state)

	if state == self.STATE_DATABASE then
		if Topics.techroom.btn1Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end
	if state == self.STATE_SIMULATOR then
		--This is where we are already, so don't do anything
		--if Topics.techroom.btn2Action:send() == false then
			--ui.playElementSound(element, "click", "error")
		--end
	end
	if state == self.STATE_CUTSCENE then
		if Topics.techroom.btn3Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end
	if state == self.STATE_CREDITS then
		if Topics.techroom.btn4Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end

end

--- Completely reloads the list of missions and updates the UI
--- @return nil
function TechMissionsController:reloadList()
	local list_items_el = self.Document:GetElementById("list_item_names_ul")
	ScpuiSystem:clearEntries(list_items_el)
	self:clearData()
	self.SelectedEntry = nil
	self.visibleList = {}
	self.Counter = 0
	self:createMissionList(self.Missions_List)
	if #self.visibleList > 0 then
		self:selectMissionEntry(self.visibleList[1])
	end
end

--- Called by the RML to change the missions list section
--- @param section number The section to change to. Should be one of the SECTION_ enumerations
--- @return nil
function TechMissionsController:change_section(section)

	self.SectionIndex = section
	local section_name = ''

	if section == self.SECTION_SINGLE then
		section_name = "single"
	elseif section == self.SECTION_CAMPAIGN then
		section_name = "campaign"
	else
		section_name = Topics.simulator.sectionname:send(section)

		if section_name == nil then
			section_name = "campaign"
			self.SectionIndex = self.SECTION_CAMPAIGN
		end
	end

	--save the choice to the player file
	ScpuiSystem.data.ScpuiOptionValues.Sim_Room_Choice = self.SectionIndex
	ScpuiSystem:saveOptionsToFile(ScpuiSystem.data.ScpuiOptionValues)

	self.ShowAll = false
	self.Counter = 0

	if section_name ~= self.SelectedSection then

		local m_list = nil
		self.Missions_List = {}

		if section_name == "single" then
			self.Document:GetElementById("campaign_name_wrapper"):SetClass("hidden", true)
			m_list = ui.TechRoom.SingleMissions
			local i = 0
			local j = 1
			while (i ~= #m_list) do
				local file = m_list[i].Filename
				if Topics.simulator.listSingle:send(file) == true then
					self.Missions_List[j] = {
						Name = m_list[i].Name,
						Filename = m_list[i].Filename,
						Description = m_list[i].Description:gsub("\n", ""),
						Author = m_list[i].Author,
						Visible = true,
						Key = '',
						Index = 0
					}
					j = j + 1
				end
				i = i + 1
			end
		elseif section_name == "campaign" then
			self.Document:GetElementById("campaign_name_wrapper"):SetClass("hidden", false)
			m_list = ui.TechRoom.CampaignMissions
			local i = 0
			local j = 1
			while (i ~= #m_list) do
				self.Missions_List[j] = {
					Name = m_list[i].Name,
					Filename = m_list[i].Filename,
					Description = m_list[i].Description:gsub("\n", ""),
					Author = m_list[i].Author,
					Visible = m_list[i].isVisible,
					Key = '',
					Index = 0
				}
				j = j + 1
				i = i + 1
			end
		else
			Topics.simulator.newsection:send({self, section_name})
		end

		if self.SelectedEntry then
			self:clearSelectedEntry()
		end

		--If we had an old section on, remove the active class
		if self.SelectedSection then
			local prev_bullet = self.Document:GetElementById(self.SelectedSection.."_btn")
			prev_bullet:SetPseudoClass("checked", false)
		end

		self.SelectedSection = section_name

		--Only create entries if there are any to create
		if self.Missions_List[1] then
			self.visibleList = {}
			self:createMissionList(self.Missions_List)
			--Only select an entry if there is one available to select
			if #self.visibleList > 0 then
				self:selectMissionEntry(self.visibleList[1])
			end
		else
			local list_names_el = self.Document:GetElementById("list_item_names_ul")
			ScpuiSystem:clearEntries(list_names_el)
			self:clearData()
		end

		local new_bullet = self.Document:GetElementById(self.SelectedSection.."_btn")
		new_bullet:SetPseudoClass("checked", true)

	end

end

--- Runs every 0.05 seconds to scroll the mission description, if necessary
--- @param element Element The element to scroll
--- @return nil
function TechMissionsController:scrollMissionDescription(element)
	if self.ScrollingElement == element then
		if self.ScrollingElement.scroll_left < math.floor(self.ScrollingElement.scroll_width -  self.ScrollingElement.client_width) then
			if self.ScrollTimer == nil then
				self.ScrollTimer = 15
			elseif self.ScrollTimer > 0 then
				self.ScrollTimer = self.ScrollTimer - 1
			else
				self.ScrollingElement.scroll_left = self.ScrollingElement.scroll_left + 0.5
				self.ScrollTimer = -1
			end
		else
			if self.ScrollTimer ~= nil then
				if self.ScrollTimer == -1 then
					self.ScrollTimer = 50
				elseif self.ScrollTimer > 0 then
					self.ScrollTimer = self.ScrollTimer - 1
				else
					self.ScrollingElement.scroll_left = 0
					self.ScrollTimer = nil
				end
			end
		end

		async.run(function()
			async.await(AsyncUtil.wait_for(0.05))
			self:scrollMissionDescription(element)
		end, async.OnFrameExecutor)
	end
end

--- When the mouse is hovered over a mission, start scrolling the description if it's longer than the view window
--- @param element Element The element to scroll
--- @return nil
function TechMissionsController:startDescriptionScrolling(element)
	if element ~= nil and element.inner_rml ~= self.ScrollingElement then
		if self.ScrollingElement ~= nil then
			self.ScrollingElement.scroll_left = 0
		end
		self.ScrollTimer = nil
		self.ScrollingElement = element
		self:scrollMissionDescription(element)
	end
end

--- When the mouse leaves a mission, stop scrolling the description and reset the globals
--- @param element Element The element to reset
--- @return nil
function TechMissionsController:resetMissionDescriptionScroll(element)
	if element ~= nil then
		self.ScrollTimer = nil
		self.ScrollingElement = nil
		element.scroll_left = 0
	end
end

--- Create a mission list item element and return it
--- @param entry scpui_mission_entry The mission entry to create the element for
--- @param index number The index of the mission entry
--- @return Element li_el The created element
function TechMissionsController:createMissionListItemElement(entry, index)

	self.Counter = self.Counter + 1

	local li_el = self.Document:CreateElement("li")

	local name_el = self.Document:CreateElement("div")
	name_el:SetClass("missionlist_name", true)
	name_el.inner_rml = entry.Name

	local author_el = self.Document:CreateElement("div")
	author_el:SetClass("missionlist_author", true)
	author_el.inner_rml = entry.Author

	local file_el = self.Document:CreateElement("div")
	file_el:SetClass("missionlist_filename", true)
	file_el.inner_rml = entry.Filename

	local desc_el = self.Document:CreateElement("div")
	desc_el:SetClass("missionlist_description", true)
	desc_el.inner_rml = entry.Description

	li_el:AppendChild(name_el)
	li_el:AppendChild(author_el)
	li_el:AppendChild(file_el)
	li_el:AppendChild(desc_el)

	li_el.id = entry.Filename

	li_el:SetClass("missionlist_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:selectMissionEntry(entry)
	end)
	li_el:AddEventListener("mouseover", function(_, _, _)
		self:startDescriptionScrolling(li_el.first_child.next_sibling.next_sibling.next_sibling)
	end)
	li_el:AddEventListener("mouseout", function(_, _, _)
		self:resetMissionDescriptionScroll(li_el.first_child.next_sibling.next_sibling.next_sibling)
	end)
	self.visibleList[self.Counter] = entry
	entry.Key = li_el.id

	self.visibleList[self.Counter].Index = self.Counter

	Topics.simulator.createitem:send(li_el)

	return li_el
end

--- Create the list of missions
--- @param list scpui_mission_entry[] The list of missions to create
--- @return nil
function TechMissionsController:createMissionList(list)

	local list_names_el = self.Document:GetElementById("list_item_names_ul")

	ScpuiSystem:clearEntries(list_names_el)

	for i, v in pairs(list) do
		if self.ShowAll and Topics.simulator.allowall:send(self) then
			list_names_el:AppendChild(self:createMissionListItemElement(v, i))
		elseif v.Visible == true then
			list_names_el:AppendChild(self:createMissionListItemElement(v, i))
		end
	end
end

--- Set the selected mission entry as unchecked
--- @return nil
function TechMissionsController:clearSelectedEntry()
	self.Document:GetElementById(self.SelectedEntry):SetPseudoClass("checked", false)
	self.SelectedEntry = nil
end

--- Originally intended to clear the UI?
--- @return nil
function TechMissionsController:clearData()

	--We have nothing to clear here!

end

--- Sets the selected mission entry as checked
--- @param entry scpui_mission_entry The mission entry to select
--- @return nil
function TechMissionsController:selectMissionEntry(entry)

	if entry.Key ~= self.SelectedEntry then

		self.SelectedIndex = entry.Index

		if self.SelectedEntry then
			local previous_entry = self.Document:GetElementById(self.SelectedEntry)
			if previous_entry then previous_entry:SetPseudoClass("checked", false) end
		end

		local this_entry = self.Document:GetElementById(entry.Key)
		self.SelectedEntry = entry.Key
		this_entry:SetPseudoClass("checked", true)

	end

end

--- Gets the player's current campaign name and filename into the globals
--- @return nil
function TechMissionsController:getPlayersCampaign()

	ui.CampaignMenu.loadCampaignList()

    local names, filenames, descriptions = ui.CampaignMenu.getCampaignList()

    local current_campaign_file = ba.getCurrentPlayer():getCampaignFilename()
    local selected_campaign = ""

    for i, v in ipairs(names) do
        if string.lower(filenames[i]) == string.lower(current_campaign_file) then
            selected_campaign = v
        end
    end

	--It's possible that the current campaign is invalid for the mod, so let's check
	if selected_campaign == "" and not cf.fileExists(current_campaign_file .. ".fc2") then
		self.CampaignFilename = ""
	else
		self.CampaignFilename = current_campaign_file .. ".fc2"
	end

	self.CampaignName = selected_campaign
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function TechMissionsController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    elseif keys.S and keys.Ctrl and keys.Shift then
		self.ShowAll = not self.ShowAll
		self:reloadList()
	elseif keys.UP and keys.Ctrl then
		self:change_tech_state(element, 1)
	elseif keys.DOWN and keys.Ctrl then
		self:change_tech_state(element, 3)
	elseif keys.TAB then
		local newSection = Topics.simulator.tabkey:send(self.SectionIndex)
		self:change_section(newSection)
	elseif keys.UP and keys.Shift then
		self:scrollList(self.Document:GetElementById("mission_list"), 0)
	elseif keys.DOWN and keys.Shift then
		self:scrollList(self.Document:GetElementById("mission_list"), 1)
	elseif keys.UP then
		self:selectPrev(element)
	elseif keys.DOWN then
		self:selectNext(element)
	elseif keys.LEFT then
		--self:select_prev()
	elseif keys.RIGHT then
		--self:select_next()
	elseif keys.RETURN then
		self:commit_pressed(element)
	elseif keys.F1 then
		self:help_clicked(element)
	elseif keys.F2 then
		self:options_button_clicked(element)
	end
end

--- Scrolls the mission list up or down
--- @param element Element The element to scroll
--- @param direction number The direction to scroll. 0 for up, 1 for down
--- @return nil
function TechMissionsController:scrollList(element, direction)
	if direction == 0 then
		element.scroll_top = element.scroll_top - 15
	else
		element.scroll_top = element.scroll_top + 15
	end
end

--- Called by the RML to select the next mission
--- @param element Element The element that was clicked
--- @return nil
function TechMissionsController:selectNext(element)
    local num = #self.visibleList

	if self.SelectedIndex == num then
		ui.playElementSound(element, "click", "error")
	else
		self:selectMissionEntry(self.visibleList[self.SelectedIndex + 1])
	end
end

--- Called by the RML to select the previous mission
--- @param element Element The element that was clicked
--- @return nil
function TechMissionsController:selectPrev(element)
	if self.SelectedIndex == 1 then
		ui.playElementSound(element, "click", "error")
	else
		self:selectMissionEntry(self.visibleList[self.SelectedIndex - 1])
	end
end

--- Called by the RML to start the selected mission
--- @param element Element The element that was clicked
--- @return nil
function TechMissionsController:commit_pressed(element)
	if self.SelectedEntry then
		mn.startMission(self.SelectedEntry)
	end
end

--- Called by the RML to show the options menu
--- @param element Element The element that was clicked
--- @return nil
function TechMissionsController:options_button_clicked(element)
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- Called by the RML to show or hide the help text
--- @param element Element The element that was clicked
--- @return nil
function TechMissionsController:help_clicked(element)
    self.HelpShown  = not self.HelpShown

    local help_texts = self.Document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.HelpShown)
    end
end

--- Called when the screen is being unloaded
--- @return nil
function TechMissionsController:unload()
	Topics.simulator.unload:send(self)
end

return TechMissionsController
