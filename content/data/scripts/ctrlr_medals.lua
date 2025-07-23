-----------------------------------
--Controller for the Medals UI
-----------------------------------

local Dialogs = require("lib_dialogs")
local Topics = require("lib_ui_topics")
local Utils = require('lib_utils')

local Class = require("lib_class")

local MedalsController = Class()

MedalsController.STATE_MEDALS = 0 --- @type number The state for viewing medals
MedalsController.STATE_RIBBONS = 1 --- @type number The state for viewing ribbons
MedalsController.STATE_ACHIEVEMENTS = 2 --- @type number The state for viewing achievements

--- Called by the class constructor
--- @return nil
function MedalsController:init()
	self.Document = nil --- @type Document The RML document
	self.PlayerMedals = nil --- @type table<number, number> The player's medals
	self.PlayerRank = nil --- @type string The player's rank
	self.PlayerName = nil --- @type string The player's name
	self.RibbonCounts = nil --- @type table<string, number> The number of ribbons from each source
	self.RibbonColumn = nil --- @type number The current column for ribbons
	self.CurrentState = 0 --- @type number The current state of the controller. Will be one of the STATE_ enumerations

	ScpuiSystem.data.memory.medal_text = {
		Name = nil,
		X = 0,
		Y = 0
	}
end

--- Called by the RML document
--- @param document Document
function MedalsController:initialize(document)

	self.Document = document
	self.RibbonColumn = 1

	--This will reparse the medal info data in SCPUI's tables to make positioning medals
	--easier. Basically this makes it so ctrl-shift-r will allow reflecting table data
	--changes without having to restart the entire game.
	self:reparseTableData()

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self:setupMedals()

	self:setupRibbons()

	self:setupAchievements()

	Topics.medals.initialize:send(self)

	self:change_view(self.STATE_MEDALS)

end

--- Setup the medals elements
--- @return nil
function MedalsController:setupMedals()
	self.PlayerMedals = ba.getCurrentPlayer().Stats.Medals
	self.PlayerRank = ba.getCurrentPlayer().Stats.Rank.Name
	self.PlayerName = ba.getCurrentPlayer():getName()

	for i = 1, #self.PlayerMedals do
		self:buildMedalDiv(i)
	end

	for i = 1, #self.PlayerMedals do
		if self.PlayerMedals[i] > 0 then
			self:showMedal(i)
		end

		--rank can be zero
		if ui.Medals.Medals_List[i].Name == "Rank" then
			self:showMedal(i)
		end
	end

	self.Document:GetElementById("medals_text").inner_rml = self.PlayerName
end

--- Setup the ribbons elements
--- @return nil
function MedalsController:setupRibbons()
	ScpuiSystem:loadRibbonsFromFile()

	table.sort(ScpuiSystem.data.Player_Ribbons, function(a, b)
        return a.Name < b.Name
    end)

	self.RibbonCounts = {}
	for i = 1, #ScpuiSystem.data.Player_Ribbons do
		self:buildRibbonDiv(i)
	end
end

--- Setup the achievements elements
--- @return nil
function MedalsController:setupAchievements()
	ScpuiSystem:loadAchievementsFromFile()

	local hidden_count = 0
	local count = 0
	for i = 1, #ScpuiSystem.data.Achievements.Current_Achievements do
		local show = true
		if ScpuiSystem.data.Achievements.Current_Achievements[i].Hidden then
			local id = ScpuiSystem.data.Achievements.Current_Achievements[i].Id
			if not ScpuiSystem.data.Achievements.Completed_Achievements[id] then
				show = false
			end
		end
		if not show then
			hidden_count = hidden_count + 1
		else
			self:buildAchievementDiv(i, count)
			count = count + 1
		end
	end

	local hidden_string = "+" .. tostring(hidden_count) .. " " .. ba.XSTR("Hidden Achievements", 888564)
	self.Document:GetElementById("hidden_achievements").inner_rml = hidden_string

	local visibility = false
	if count == 0 and hidden_count == 0 then
		visibility = true
	end

	self.Document:GetElementById("award_btn_3"):SetClass("hidden", visibility)
end

--- Force reparsing of the medal info data in SCPUI's tables
--- @return nil
function MedalsController:reparseTableData()
	ScpuiSystem.data.Medal_Info = {}
	if cf.fileExists("scpui.tbl") then
        self:parseMedalInfo("scpui.tbl")
    end
    for _, v in ipairs(cf.listFiles("data/tables", "*-ui.tbm")) do
        self:parseMedalInfo(v)
    end
end

--- Parse the medals section of a table file, skipping to it
--- @param data string The file to parse
--- @return nil
function MedalsController:parseMedalInfo(data)
	parse.readFileText(data, "data/tables")

	if parse.skipToString("#Medal Placements") then

		ScpuiSystem:parseMedals()

	end

	parse.stop()
end

--- Check if a medal is a badge
--- @param medal medal The medal to check
--- @return boolean val if the medal is a badge, false otherwise
function MedalsController:isBadge(medal)
	return (medal.KillsNeeded > 0)
end

--- Check if a medal is a rank
--- @param medal medal The medal to check
--- @return boolean val if the medal is a rank, false otherwise
function MedalsController:isRank(medal)
	return medal:isRank()
end

--- Get the medal info for a given id from SCPUI's medal data
--- @param id string The id of the medal
--- @return medal_info medal The medal info
function MedalsController:getMedalInfo(id)
	local info = ScpuiSystem.data.Medal_Info[id]

	if info == nil then
		info = {
			X = 0,
			Y = 0,
			W = 10
		}
	end

	return info
end

--- Create a div element for a medal, placing it in the correct position. Defaults to setting the image as the empty version
--- @param idx number The index of the medal in the list
--- @return nil
function MedalsController:buildMedalDiv(idx)
	local medal = ui.Medals.Medals_List[idx]

	local parent_el = self.Document:GetElementById("medals_wrapper_actual")

	local id = string.lower(medal.Bitmap:match("(.+)%..+$"))
	local info = self:getMedalInfo(medal.Name)

	local medal_el = self.Document:CreateElement("div")
	medal_el.id = id
	medal_el:SetClass("medal", true)
	medal_el.style.position = "absolute"
	medal_el.style.width = info.W .. "%"
	medal_el.style.top = info.Y .. "%"
	medal_el.style.left = info.X .. "%"

	local filename = id
	if info.AltBitmap then
		filename = info.AltBitmap
	end

	local img_el = self.Document:CreateElement("img")
	img_el:SetAttribute("src", filename .. "_00.png")

	medal_el:AppendChild(img_el)
	parent_el:AppendChild(medal_el)
end

--- If the player has earned one or more of the medal then replace the image with the earned version and setup the mouseover listeners
--- @param idx number The index of the medal in the list
--- @return nil
function MedalsController:showMedal(idx)

	local medal = ui.Medals.Medals_List[idx]

	--get the div
	local medal_el = self.Document:GetElementById(string.lower(medal.Bitmap:match("(.+)%..+$")))
	local info = self:getMedalInfo(medal.Name)
	local filename = medal_el.id
	if info.AltBitmap then
		filename = info.AltBitmap
	end

	--create new image element based on number earned
	local img_el = self.Document:CreateElement("img")

	local num = math.min(self.PlayerMedals[idx], ui.Medals.Medals_List[idx].NumMods)

	--create the display string
	local display = medal.Name
	if num > 1 then
		display = medal.Name .. " (" .. self.PlayerMedals[idx] .. ")"
	end

	--rank is special because reasons
	if medal.Name == "Rank" then
		num = num + 1
		display = self.PlayerRank
	end

	--now setup for the png name
	local num_string = "_" .. self:setupCountString(num)

	--Special access to the png id for external scripts
	num_string = Topics.medals.setRankBitmap:send({medal.Name, num_string})

	filename = filename .. num_string .. ".png"

	img_el:SetAttribute("src", filename)

	--replace the old image
	medal_el:ReplaceChild(img_el, medal_el.first_child)

	--add mouseover listener
	medal_el:AddEventListener("mouseover", function()
		ScpuiSystem.data.memory.medal_text.Name = display
	end)

	medal_el:AddEventListener("mouseout", function()
		ScpuiSystem.data.memory.medal_text.Name = nil
	end)
end

--- Setup the count string for the medal image. If the number is less than 10 then add a leading zero
--- @param num number The number to format
--- @return string r_string The formatted string
function MedalsController:setupCountString(num)
	local r_string
	if num < 10 then
		r_string = "0" .. num
	else
		r_string = tostring(num)
	end
	return r_string
end

--- Create a div element for a ribbon, placing it in the correct position
--- @param idx number The index of the ribbon in the list
--- @return nil
function MedalsController:buildRibbonDiv(idx)
	local ribbon = ScpuiSystem.data.Player_Ribbons[idx]

	if not self.RibbonCounts[ribbon.Source] then
		self.RibbonCounts[ribbon.Source] = 1
	else
		self.RibbonCounts[ribbon.Source] = self.RibbonCounts[ribbon.Source] + 1
	end

	-- Don't display more than 5 ribbons from a single game
	if self.RibbonCounts[ribbon.Source] > 5 then return end

	local img = ScpuiSystem:createRibbonImage(ribbon)

	local parent_id = "ribbon_column_" .. self.RibbonColumn
	self.RibbonColumn = self.RibbonColumn + 1
	if self.RibbonColumn > 5 then
		self.RibbonColumn = 1
	end

	local parent_el = self.Document:GetElementById(parent_id)

	local ribbon_el = self.Document:CreateElement("div")
	ribbon_el.id = "ribbon_" .. idx
	ribbon_el:SetClass("ribbon", true)

	--add mouseover listener
	ribbon_el:AddEventListener("mouseover", function()
		ScpuiSystem.data.memory.medal_text.Name = ribbon.Description
	end)

	ribbon_el:AddEventListener("mouseout", function()
		ScpuiSystem.data.memory.medal_text.Name = nil
	end)

	local img_el = self.Document:CreateElement("img")
	img_el:SetAttribute("src", img)

	local title_el = self.Document:CreateElement("p")
	title_el.inner_rml = ribbon.Name

	ribbon_el:AppendChild(img_el)
	ribbon_el:AppendChild(title_el)
	parent_el:AppendChild(ribbon_el)
end

--- Create a div element for an achievement, placing it in the correct position
--- @param idx number The index of the achievement in the Current_Achievements list
--- @param count number The current count of achievements displayed
--- @return nil
function MedalsController:buildAchievementDiv(idx, count)
    local achievement = ScpuiSystem.data.Achievements.Current_Achievements[idx]

    -- Prevent processing if achievement data is missing
    if not achievement then return end

    -- Determine the parent element for current achievements
    local parent_el

	if Utils.isOdd(count) then
		parent_el = self.Document:GetElementById("achievements_left")
	else
		parent_el = self.Document:GetElementById("achievements_right")
	end

	local r, g, b, a = ScpuiSystem:findParentColor(parent_el)

	if achievement.TextColor then
		r, g, b, a = Utils.hexToRgba(achievement.TextColor)
	end

    -- Create a new div for the achievement
    local achievement_el = self.Document:CreateElement("div")
    achievement_el.id = "achievement_" .. idx
    achievement_el:SetClass("achievement_box", true)
	achievement_el.style["border-color"] = Utils.rgbaToHex(r or 255, g or 255, b or 255, Utils.clamp(a - 150, 25, 255))

    -- Top inner box for name and description
    local top_box_el = self.Document:CreateElement("div")
    top_box_el:SetClass("achievement_top_box", true)

    -- Create and append the name element (bold)
    local name_el = self.Document:CreateElement("p")
    name_el:SetClass("achievement_name", true)
    name_el.inner_rml = "<b>" .. achievement.Name .. "</b>"
	name_el.style["color"] = Utils.rgbaToHex(r or 255, g or 255, b or 255, a)
    top_box_el:AppendChild(name_el)

    -- Create and append the description element (smaller, not bold)
    local description_el = self.Document:CreateElement("p")
    description_el:SetClass("achievement_description", true)
    description_el.inner_rml = achievement.Description
	description_el.style["color"] = Utils.rgbaToHex(r or 255, g or 255, b or 255, Utils.clamp(a - 75, 50, 255))
    top_box_el:AppendChild(description_el)

    achievement_el:AppendChild(top_box_el)

    -- Bottom inner box for progress bar and percentage
    local bottom_box_el = self.Document:CreateElement("div")
    bottom_box_el:SetClass("achievement_bottom_box", true)

    -- Create and append the progress bar container
    local progress_container_el = self.Document:CreateElement("div")
    progress_container_el:SetClass("progress_container", true)
	progress_container_el.style["background-color"] = Utils.rgbaToHex(r or 255, g or 255, b or 255, Utils.clamp(a - 150, 25, 255))

    -- Create the progress bar
    local progress_bar_el = self.Document:CreateElement("div")
    progress_bar_el:SetClass("progress_bar", true)

    -- Calculate random progress for testing
    local progress = ScpuiSystem.data.Achievements.Completed_Achievements[achievement.Id] or 0

	if not achievement.Criteria.Threshold then
		if progress ~= 0 then
			progress = 100
		end
	else
		if progress > achievement.Criteria.Threshold then
			progress = achievement.Criteria.Threshold
		end
	end

	if progress < 0 then progress = 0 end

	local progress_pct = math.min((progress / achievement.Criteria.Threshold) * 100, 100)

    progress_bar_el:SetAttribute("style", "width: " .. progress_pct .. "%;")
	progress_bar_el.style["background-color"] = achievement.BarColor
    progress_container_el:AppendChild(progress_bar_el)
    bottom_box_el:AppendChild(progress_container_el)

    -- Create and append the percentage text
	if achievement.Criteria.Threshold > 1 then
		local percent_el = self.Document:CreateElement("p")
		percent_el:SetClass("progress_percent", true)
		percent_el.inner_rml = progress .. "/" .. achievement.Criteria.Threshold
		percent_el.style["color"] = Utils.rgbaToHex(r or 255, g or 255, b or 255, Utils.clamp(a - 75, 50, 255))
		bottom_box_el:AppendChild(percent_el)
	end

    achievement_el:AppendChild(bottom_box_el)

    -- Append the achievement element to the parent
    parent_el:AppendChild(achievement_el)
end

--- Called by the RML to toggle between medals and ribbons.
--- @param state number The state to change to. Should be one of the STATE_ enumerations
--- @return nil
function MedalsController:change_view(state)
	self.CurrentState = state
	local medal_el = self.Document:GetElementById("medals_wrapper")
	local ribbon_el = self.Document:GetElementById("ribbons_wrapper")
	local achievements_el = self.Document:GetElementById("achievements_wrapper")

	medal_el:SetClass("hidden", state ~= self.STATE_MEDALS)
	ribbon_el:SetClass("hidden", state ~= self.STATE_RIBBONS)
	achievements_el:SetClass("hidden", state ~= self.STATE_ACHIEVEMENTS)

	local medal_btn_el = self.Document:GetElementById("award_btn_1")
	local ribbon_btn_el = self.Document:GetElementById("award_btn_2")
	local achievements_btn_el = self.Document:GetElementById("award_btn_3")

	medal_btn_el:SetPseudoClass("checked", state == self.STATE_MEDALS)
	ribbon_btn_el:SetPseudoClass("checked", state == self.STATE_RIBBONS)
	achievements_btn_el:SetPseudoClass("checked", state == self.STATE_ACHIEVEMENTS)
end

--- Called by the RML to exit the medals screen
--- @return nil
function MedalsController:accept_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
end

--- Show a dialog box with the given text and title
--- @param text string the text to display
--- @param title string the title to display
--- @return nil
function MedalsController:showDialog(text, title, input, buttons, callback)
	--Create a simple dialog box with the text and title

	local dialog = Dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:input(input)
		for i = 1, #buttons do
			dialog:button(buttons[i].Type, buttons[i].Text, buttons[i].Value, buttons[i].Keypress)
		end
		dialog:escape("")
		dialog:show(self.Document.context)
		:continueWith(function(response)
            if callback then
				callback(response)
			end
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.Document.context)
end

--- Called by the RML when the join private channel button is pressed. Creates a dialog box to enter the channel name
--- @return nil
function MedalsController:showResetAchievementDialog()
	local text = Utils.xstr("Type the name of the achievement to reset progress or type 'all' to reset all achievements.", 888565)
	local title = Utils.xstr("Reset Achievement", 888566)
	--- @type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = Dialogs.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Okay", 888290),
		Value = "",
		Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
	}

	self:showDialog(text, title, true, buttons, function(response)
		ScpuiSystem:resetAchievements(response)
		local left_el = self.Document:GetElementById("achievements_left")
		local right_el = self.Document:GetElementById("achievements_right")
		ScpuiSystem:clearEntries(left_el)
		ScpuiSystem:clearEntries(right_el)
		self:setupAchievements()
	end)
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function MedalsController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)

    if keys.ESCAPE then
        ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
	elseif keys.D and keys.Ctrl then
		if self.CurrentState == self.STATE_ACHIEVEMENTS and ba.inDebug() then
			self:showResetAchievementDialog()
		end
	end
end

--- Called by the RML when the mouse moves over the medals elements
--- @param element Element The element that the mouse is over
--- @param event Event The event that was triggered
--- @return nil
function MedalsController:mouse_move(element, event)
	ScpuiSystem.data.memory.medal_text.X = event.parameters.mouse_x
	ScpuiSystem.data.memory.medal_text.Y = event.parameters.mouse_y
end

--- Draw the current text for a medal at the mouse coordinates
--- @return nil
function MedalsController:drawText()
	if ScpuiSystem.data.memory.medal_text.Name ~= nil then
		--save the current color
		local r, g, b, a = gr.getColor()

		--set the color to white
		gr.setColor(255, 255, 255, 255)

		--get the string width
		local w = gr.getStringWidth(ScpuiSystem.data.memory.medal_text.Name)

		local draw = {}
		draw.x = ScpuiSystem.data.memory.medal_text.X - w
		draw.y = ScpuiSystem.data.memory.medal_text.Y - 25

		if draw.x < 5 then
			draw.x = 5
		end

		--draw the string
		gr.setColor(255, 255, 0, 255)
		gr.drawRectangle(draw.x-2, draw.y-2, draw.x + w + 6+2, draw.y + 20+2)
		gr.setColor(0, 0, 0, 255)
		gr.drawRectangle(draw.x, draw.y, draw.x + w + 6, draw.y + 20)
		gr.setColor(255, 255, 255, 255)
		gr.drawString(ScpuiSystem.data.memory.medal_text.Name, draw.x + 3, draw.y + 3)

		--reset the color
		gr.setColor(r, g, b, a)
	end
end

--- Called when the screen is being unloaded
--- @return nil
function MedalsController:unload()
	Topics.medals.unload:send(self)
end

--- Every frame if the mouse is over a medal, draw a text box with the name of th medal
ScpuiSystem:addHook("On Frame", function()
	MedalsController:drawText()
end, {State="GS_STATE_VIEW_MEDALS"}, function()
    return false
end)

return MedalsController
