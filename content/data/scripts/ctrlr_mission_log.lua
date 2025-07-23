-----------------------------------
--Controller for the Mission Log UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local MissionlogController = Class()

MissionlogController.SECTION_OBJECTIVES = 1 --- @type number The objectives section of the mission log
MissionlogController.SECTION_MESSAGES = 2 --- @type number The messages section of the mission log
MissionlogController.SECTION_EVENTS = 3 --- @type number The events section of the mission log

--- Called by the class constructor
--- @return nil
function MissionlogController:init()
	self.CurrentSection = nil --- @type number The current section of the mission log
	self.TotalSections = 3 --- @type number The number of sections in the mission log
	self.UnhideBonusGoals = false --- @type boolean Whether or not to unhide the bonus goals section
	self.Document = nil --- @type Document The RML document
	self.LogTimestamps = nil --- @type string[] The timestamps for the mission log entries
	self.LogSubjects = nil --- @type string[] The subject names for the mission log entries
	self.LogDescriptions = nil --- @type string[] The descriptions for the mission log entries
	self.MessageTimestamps = nil --- @type string[] The timestamps for the message log entries
	self.MessageTexts = nil --- @type string[] The text for the message log entries
end

--- Called by the RML document
--- @param document Document
function MissionlogController:initialize(document)

	self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	if mn.isInMission() then
		ScpuiSystem:pauseAllAudio(true)
	end

	local mission_time = mn.getMissionTime() + mn.MissionHUDTimerPadding
	local hours = math.floor(mission_time/3600)
	local minutes = math.floor(math.fmod(mission_time,3600)/60)
	local seconds = math.floor(math.fmod(mission_time,60))

	self.Document:GetElementById("gametime").inner_rml = string.format("%02d:%02d:%02d", hours,minutes,seconds) .. "  Current Time"

	ui.MissionLog.initMissionLog()

	self:initMissionLog()
	self:initMessageLog()
	self:initGoalsLog()

	ui.MissionLog.closeMissionLog()

	Topics.missionlog.initialize:send(self)

	self:change_section(self.Document:GetElementById("main_background"), ScpuiSystem.data.memory.LogSection)

end

--- Initialize the mission log and create all the log entries with proper colors
--- @return nil
function MissionlogController:initMissionLog()

	self.LogTimestamps = {}
	self.LogSubjects = {}
	self.LogDescriptions = {}

	for logs = 1, #ui.MissionLog.Log_Entries do
		local entry = ui.MissionLog.Log_Entries[logs]

		local segment = ""

		for segments = 1, #entry.SegmentTexts do
			segment = segment .. "<span style=\"color:rgba(" .. entry.SegmentColors[segments].Red .. "," .. entry.SegmentColors[segments].Green .. "," .. entry.SegmentColors[segments].Blue .. "," .. entry.SegmentColors[segments].Alpha .. ");\">" .. entry.SegmentTexts[segments] .. " </span>"
		end

		local subject = "<span style=\"color:rgba(" .. entry.ObjectiveColor.Red .. "," .. entry.ObjectiveColor.Green .. "," .. entry.ObjectiveColor.Blue .. "," .. entry.ObjectiveColor.Alpha .. ");\">" .. entry.ObjectiveText .. " </span>"

		self.LogTimestamps[logs] = entry.paddedTimestamp
		self.LogSubjects[logs] = subject
		self.LogDescriptions[logs] = segment
	end
end

--- Initialize the message log and create all the log entries with proper colors
--- @return nil
function MissionlogController:initMessageLog()

	self.MessageTimestamps = {}
	self.MessageTexts = {}

	for logs = 1, #ui.MissionLog.Log_Messages do
		local entry = ui.MissionLog.Log_Messages[logs]

		-- Escape any HTML meta-characters
		local textString = entry.Text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
		local textElements = {}
		local count = 1
		for i in string.gmatch(textString, "(.-):") do
			textElements[count] = i
			count = count + 1
		end

		--If element 2 is nil then we didn't actually split any text which means it's
		--special message that doesn't need any underlining.
		if textElements[2] ~= nil then
			textString = "<span class=\"underline\">" .. textElements[1] .. ":</span>" .. textElements[2]
		end

		local text = "<span style=\"color:rgba(" .. entry.Color.Red .. "," .. entry.Color.Green .. "," .. entry.Color.Blue .. "," .. entry.Color.Alpha .. ");\">" .. textString .. " </span>"

		self.MessageTimestamps[logs] = entry.paddedTimestamp
		self.MessageTexts[logs] = text
	end
end

--- Create a bullet element for a goal
--- @param status number The status of the goal, 0 for failed, 1 for complete, otherwise incomplete
--- @return Element bullet_el The bullet element
function MissionlogController:makeBullet(status)
	local bullet_el = self.Document:CreateElement("div")
	local img = nil
	if status == 0 then
		bullet_el.id = "goalsdot_img_failed"
		img = "goal-failed.png"
	elseif status == 1 then
		bullet_el.id = "goalsdot_img_complete"
		img = "goal-complete.png"
	else
		bullet_el.id = "goalsdot_img_incomplete"
		bullet_el:SetClass("brightblue", true)
		img = "goal-incomplete.png"
	end
	bullet_el:SetClass("goalsdot", true)

	local bullet_img = self.Document:CreateElement("img")
	bullet_img:SetClass("psuedo_img", true)
	bullet_img:SetAttribute("src", img)
	bullet_el:AppendChild(bullet_img)

	return bullet_el
end

--- Create a goal item for the mission log
--- @param title string The title of the goal
--- @param status number The status of the goal, 0 for failed, 1 for complete, otherwise incomplete
--- @return Element goal_el The goal element
function MissionlogController:createGoalItem(title, status)
	local goal_el = self.Document:CreateElement("li")
	goal_el:SetClass("goal", true)
	goal_el:AppendChild(self:makeBullet(status))

	local goal_text = self.Document:CreateElement("div")
	goal_text.inner_rml = title .. "<br></br>"
	goal_el:AppendChild(goal_text)

	return goal_el
end

--- Initialize the goals logs elements
--- @return nil
function MissionlogController:initGoalsLog()

	local goals = ui.Briefing.Objectives
	local primaryWrapper = self.Document:GetElementById("primary_goal_list")
	local secondaryWrapper = self.Document:GetElementById("secondary_goal_list")
	local bonusWrapper = self.Document:GetElementById("bonus_goal_list")
	for i = 1, #goals do
		local goal = goals[i]
		if goal.isGoalValid and goal.Message ~= "" then
			if goal.Type == "primary" then
				primaryWrapper:AppendChild(self:createGoalItem(goal.Message, goal.isGoalSatisfied))
			end
			if goal.Type == "secondary" then
				secondaryWrapper:AppendChild(self:createGoalItem(goal.Message, goal.isGoalSatisfied))
			end
			if goal.Type == "bonus" then
				if goal.isGoalSatisfied == 1 then
					bonusWrapper:AppendChild(self:createGoalItem(goal.Message, goal.isGoalSatisfied))
					--unhide bonus goals section if we have a completed bonus goal
					self.UnhideBonusGoals = true
				end
			end
		end
	end

	--These are for the goals key
	local incompleteBulletHTML = "<div id=\"goalsdot_img_incomplete\" class=\"goalsdot_key brightblue\"><img src=\"goal-incomplete.png\" class=\"psuedo_img\"></img></div>"
	local completeBulletHTML = "<div id=\"goalsdot_img_complete\" class=\"goalsdot_key\"><img src=\"goal-complete.png\" class=\"psuedo_img\"></img></div>"
	local failedBulletHTML = "<div id=\"goalsdot_img_failed\" class=\"goalsdot_key\"><img src=\"goal-failed.png\" class=\"psuedo_img\"></img></div>"

	self.Document:GetElementById("goal_complete").inner_rml = completeBulletHTML .. "   Complete"
	self.Document:GetElementById("goal_incomplete").inner_rml = incompleteBulletHTML .. "   Incomplete"
	self.Document:GetElementById("goal_failed").inner_rml = failedBulletHTML .. "   Failed"

	self.Document:GetElementById("briefing_goals"):SetClass("hidden", true)
	self.Document:GetElementById("goal_key"):SetClass("hidden", true)
	self.Document:GetElementById("bonus_goals"):SetClass("hidden", true)

end

--- Change the current section of the mission log. Should be one of the SECTION_ enumerations
--- @param element Element The element that was clicked
--- @param section number The section to change to
--- @return nil
function MissionlogController:change_section(element, section)

	local changeSection = false

	if self.CurrentSection == nil then
		changeSection = true
	elseif self.CurrentSection ~= section then
		changeSection = true
	end

	if changeSection then

		ui.playElementSound(element, "click", "success")

		--first we clean up
		if self.CurrentSection == self.SECTION_OBJECTIVES then
			self:cleanupGoalsLog()
			self.Document:GetElementById("objectives_btn"):SetPseudoClass("checked", false)
		end
		if self.CurrentSection == self.SECTION_MESSAGES then
			self:cleanupMessageLog()
			self.Document:GetElementById("messages_btn"):SetPseudoClass("checked", false)
		end
		if self.CurrentSection == self.SECTION_EVENTS then
			self:cleanupMissionLog()
			self.Document:GetElementById("events_btn"):SetPseudoClass("checked", false)
		end

		--set the section
		self.CurrentSection = section
		ScpuiSystem.data.memory.LogSection = section

		if section == self.SECTION_OBJECTIVES then
			self:createGoalsLog()
			self.Document:GetElementById("objectives_btn"):SetPseudoClass("checked", true)
		end

		if section == self.SECTION_MESSAGES then
			self:createMessageLot()
			self.Document:GetElementById("messages_btn"):SetPseudoClass("checked", true)
		end

		if section == self.SECTION_EVENTS then
			self:createMissionLog()
			self.Document:GetElementById("events_btn"):SetPseudoClass("checked", true)
		end

	end

end

--- Create the mission log, building all the needed elements
--- @return nil
function MissionlogController:createMissionLog()

	local parent_el = self.Document:GetElementById("log_text_wrapper")

	--create the list container
	local list_el = self.Document:CreateElement("ul")
	list_el.id = "list_entries"
	parent_el:AppendChild(list_el)

	for i = 1, #self.LogTimestamps do

		--create the list item
		local item_el = self.Document:CreateElement("li")
		list_el:AppendChild(item_el)

		--create the time div
		local entry_el = self.Document:CreateElement("div")
		entry_el.id = "list_times_ul"

		--fill the time div with text
		local line = self.LogTimestamps[i]
		entry_el.inner_rml = line
		item_el:AppendChild(entry_el)

		--create the subject div
		local subject_el = self.Document:CreateElement("div")
		subject_el.id = "list_subjects_ul"

		--fill the subject div with text
		local subject_line = self.LogSubjects[i]
		subject_el.inner_rml = subject_line
		item_el:AppendChild(subject_el)

		--create the description div
		local description_el = self.Document:CreateElement("div")
		description_el.id = "list_descriptions_ul"

		--fill the description div with text
		local description_line = self.LogDescriptions[i]
		description_el.inner_rml = description_line
		item_el:AppendChild(description_el)
	end

	--now scroll to the bottom by default
	parent_el.scroll_top = parent_el.scroll_height
end

--- Create the message log, building all the needed elements
--- @return nil
function MissionlogController:createMessageLot()

	local parent_el = self.Document:GetElementById("log_text_wrapper")

	--create the list container
	local list_el = self.Document:CreateElement("ul")
	list_el.id = "list_entries"
	parent_el:AppendChild(list_el)

	for i = 1, #self.MessageTexts do

		--create the list item
		local item_el = self.Document:CreateElement("li")
		list_el:AppendChild(item_el)

		--create the time div
		local entry_el = self.Document:CreateElement("div")
		entry_el.id = "list_times_ul"

		--fill the time div with text
		local line = self.MessageTimestamps[i]
		entry_el.inner_rml = line
		item_el:AppendChild(entry_el)

		--create the message div
		local message_el = self.Document:CreateElement("div")
		message_el.id = "list_messages_ul"

		--fill the message div with text
		local message_line = self.MessageTexts[i]
		message_el.inner_rml = message_line
		item_el:AppendChild(message_el)
	end

	--now scroll to the bottom by default
	parent_el.scroll_top = parent_el.scroll_height
end

--- Create the goals log, building all the needed elements
--- @return nil
function MissionlogController:createGoalsLog()

	self.Document:GetElementById("briefing_goals"):SetClass("hidden", false)
	self.Document:GetElementById("goal_key"):SetClass("hidden", false)

	if self.UnhideBonusGoals then
		self.Document:GetElementById("bonus_goals"):SetClass("hidden", false)
	end

end

--- Cleanup the mission log text element to prepare for a section change
--- @return nil
function MissionlogController:cleanupMissionLog()

	local parent_el = self.Document:GetElementById("log_text_wrapper")

	ScpuiSystem:clearEntries(parent_el)

end

--- Cleanup the message log text element to prepare for a section change
--- @return nil
function MissionlogController:cleanupMessageLog()

	local parent_el = self.Document:GetElementById("log_text_wrapper")

	ScpuiSystem:clearEntries(parent_el)

end

--- Cleanup the goals log text element to prepare for a section change
--- @return nil
function MissionlogController:cleanupGoalsLog()

	self.Document:GetElementById("briefing_goals"):SetClass("hidden", true)
	self.Document:GetElementById("goal_key"):SetClass("hidden", true)

end

--- Go to the previous section. UNUSED
--- @param element Element The element that was clicked
--- @return nil
function MissionlogController:decrement_section(element)

	if self.CurrentSection == 1 then
		self:change_section(element, self.TotalSections)
	else
		self:change_section(element, self.CurrentSection - 1)
	end

end

--- Go to the next section. UNUSED
--- @param element Element The element that was clicked
--- @return nil
function MissionlogController:increment_section(element)

	if self.CurrentSection == self.TotalSections then
		self:change_section(element, 1)
	else
		self:change_section(element, self.CurrentSection + 1)
	end

end

--- Called by the RML to exit the mission log
--- @param element Element The element that was clicked
--- @return nil
function MissionlogController:exit(element)

	ui.playElementSound(element, "click", "success")
	if mn.isInMission() then
		ScpuiSystem:pauseAllAudio(false)
		ui.PauseScreen.closePause()
	end
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])

end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function MissionlogController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
	if keys.ESCAPE then
		event:StopPropagation()
		if mn.isInMission() then
			ScpuiSystem:pauseAllAudio(false)
			ui.PauseScreen.closePause()
		end
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
	end
end

--- Called when the screen is being unloaded
--- @return nil
function MissionlogController:unload()
	Topics.missionlog.unload:send(self)
end

return MissionlogController
