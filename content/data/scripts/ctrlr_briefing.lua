-----------------------------------
--Controller for the Briefing UI
-----------------------------------

local AsyncUtil = require("lib_async")
local LoadoutHandler = require("lib_loadout_handler")
local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractBriefingController = require("ctrlr_briefing_common")

--- Briefing controller is merged with the Briefing Common Controller
local BriefingController = Class(AbstractBriefingController)

BriefingController.STATE_BRIEFING = 1 --- @type number The enumeration for the briefing game state
BriefingController.STATE_SHIP_SELECTION = 2 --- @type number The enumeration for the ship selection game state
BriefingController.STATE_WEAPON_SELECTION = 3 --- @type number The enumeration for the weapon selection game state

--- Make sure the briefing map is uninitialized
ScpuiSystem.data.memory.briefing_map = nil

--- Called by the class constructor
--- @return nil
function BriefingController:init()

	--- Check if we should play a cutscene before the briefing
	if not ScpuiSystem.data.memory.CutscenePlayed then
		ScpuiSystem:maybePlayCutscene(MOVIE_PRE_BRIEF)
	end
	ScpuiSystem.data.memory.CutscenePlayed = true

	--- Now initialize all our variables
    self.Stages_List = {} --- @type briefing_stage[] The stages of the briefing
	self.HelpShown = false --- @type boolean Whether the help text is shown or not
	self.Commit = false --- @type boolean Whether the player has committed to the mission
	self.Required_Weapons = {} --- @type string[] List of required weapons for the mission
	self.ChatEl = nil --- @type Element The chat window element
	self.ChatInputEl = nil --- @type Element The chat input window element
	self.SubmittedChatValue = "" --- @type string The value of the chat input
	self.Document = nil --- @type Document The RML document

	--- @type scpui_brief_element_list List of ui element names for player control of the stages
    self.Element_Names = {
        PauseBtn = "cmdpause_btn",
        LastBtn = "cmdlast_btn",
        NextBtn = "cmdnext_btn",
        PrevBtn = "cmdprev_btn",
        FirstBtn = "cmdfirst_btn",
        TextEl = "brief_text_el",
        StageTextEl = "brief_stage_text_el",
    }

	LoadoutHandler:init()

	--Whenever we start a new mission, we reset the log ui to goals
	ScpuiSystem.data.memory.LogSection = 1

end

--- Called by the RML document
--- @param document Document
function BriefingController:initialize(document)
    AbstractBriefingController.initialize(self, document)

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	ui.Briefing.initBriefing()

	if mn.hasNoBriefing() then
		self.Commit = true
		ScpuiSystem:stopMusic()
		ScpuiSystem.data.memory.CurrentMusicFile = nil
		ui.Briefing.commitToMission()
	end

	if mn.isScramble() or mn.isTraining() then
		local ss_btn = self.Document:GetElementById("s_select_btn")
		local ws_btn = self.Document:GetElementById("w_select_btn")

		ss_btn:SetClass("hidden", true)
		ws_btn:SetClass("hidden", true)

		local text_el = self.Document:CreateElement("div")
		text_el.style.width = "10%"
		text_el.style.position = "absolute"
		text_el.style.color = "#606060"
		text_el.style.top = "8%"
		text_el.style.left = "5%"
		text_el.inner_rml = ba.XSTR("Loadout selection not available", 888279)
		self.Document:GetElementById("main_background"):AppendChild(text_el)
	end


	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.ChatEl = self.Document:GetElementById("chat_window")
	self.ChatInputEl = self.Document:GetElementById("chat_input")

	--Get all the required weapons
	local j = 1
	while (j < #tb.WeaponClasses) do
		if tb.WeaponClasses[j]:isWeaponRequired() then
			self.Required_Weapons[#self.Required_Weapons + 1] = tb.WeaponClasses[j].Name
		end
		j = j + 1
	end

	self.Document:GetElementById("mission_title").inner_rml = mn.getMissionTitle()

    local briefing = ui.Briefing.getBriefing()

	local num_stages = 0

    for i = 1, #briefing do
        local stage = briefing[i]
		if stage then
			self.Stages_List[i] = stage
			num_stages = num_stages + 1
			--This is where we should replace variables and containers probably!
		end
    end
	if mn.hasGoalsStage() then
		local g = num_stages + 1
		self.Stages_List[g] = {
			Text = ba.XSTR( "Please review your objectives for this mission.", 395),
			hasBackwardCut = true,
			hasForwardCut = true,
			AudioFilename = ""
		}
		num_stages = num_stages + 1
	end
	if #self.Stages_List > 0 then
		AbstractBriefingController.goToStage(self, 1)
	end

	if mn.isInCampaign() then
		if mn.isTraining() then
			self.Document:GetElementById("skip_m_text").inner_rml = ba.XSTR("Skip Training", 888280)
			self.Document:GetElementById("top_panel_a"):SetClass("hidden", false)
		elseif mn.isInCampaignLoop() then
			self.Document:GetElementById("skip_m_text").inner_rml = ba.XSTR("Exit Loop", 888281)
			self.Document:GetElementById("top_panel_a"):SetClass("hidden", false)
		elseif mn.isMissionSkipAllowed() then
			self.Document:GetElementById("skip_m_text").inner_rml = ba.XSTR("Skip Mission", 888282)
			self.Document:GetElementById("top_panel_a"):SetClass("hidden", false)
		else
			self.Document:GetElementById("top_panel_a"):SetClass("hidden", true)
		end
	else
		self.Document:GetElementById("top_panel_a"):SetClass("hidden", true)
	end

	if ba.inDebug() then
		local mission_file = mn.getMissionFilename() .. ".fs2"
		local mission_date = mn.getMissionModifiedDate()
		self.Document:GetElementById("mission_debug_info").inner_rml = mission_file .. " mod " .. mission_date
	end

	self.Document:GetElementById("brief_btn"):SetPseudoClass("checked", true)

	--Default width is 888, default height is 371

	local brief_view_element = self.Document:GetElementById("briefing_grid")

	--The grid needs to be a very specific aspect ratio, so we'll calculate
	--the percent change here and use that to calculate the height below.
	local percent_change = ((brief_view_element.offset_width - 888) / 888) * 100

	ScpuiSystem.data.memory.briefing_map.X1 = ScpuiSystem:getAbsoluteLeft(brief_view_element)
	ScpuiSystem.data.memory.briefing_map.Y1 = ScpuiSystem:getAbsoluteTop(brief_view_element)
	ScpuiSystem.data.memory.briefing_map.X2 = brief_view_element.offset_width
	ScpuiSystem.data.memory.briefing_map.Y2 = 371 * ((100 + percent_change)/100)

	self:buildGoalsList()

	ScpuiSystem.data.memory.briefing_map.Texture = gr.createTexture(ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)
	ScpuiSystem.data.memory.briefing_map.Url = ui.linkTexture(ScpuiSystem.data.memory.briefing_map.Texture)
	ScpuiSystem.data.memory.briefing_map.Draw = true
	local aniEl = self.Document:CreateElement("img")
    aniEl:SetAttribute("src", ScpuiSystem.data.memory.briefing_map.Url)
	brief_view_element:ReplaceChild(aniEl, brief_view_element.first_child)

	if ScpuiSystem:inMultiGame() then
		ScpuiSystem.data.memory.multiplayer_general.Context = self
		ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
		ui.MainHall.stopMusic(true) -- In multi we're coming from the Multi Sync UI so we need to stop these manually
		ui.MainHall.stopAmbientSound()

		-- Expose some multiplayer elements
		self.Document:GetElementById("chat_wrapper"):SetClass("hidden", false)
		--self.Document:GetElementById("c_panel_wrapper_multi"):SetClass("hidden", false)
		self.Document:GetElementById("bottom_panel_c"):SetClass("hidden", false)
		ui.MultiGeneral.setPlayerState()
	end

	Topics.briefing.initialize:send(self)

end

--- Creates a bullet for the goals list and returns the element
--- @return Element
function BriefingController:makeGoalBullet()
	local bullet_el = self.Document:CreateElement("div")
	bullet_el.id = "goalsdot_img"
	bullet_el:SetClass("goalsdot", true)
	bullet_el:SetClass("brightblue", true)

	local bullet_img = self.Document:CreateElement("img")
	bullet_img:SetClass("psuedo_img", true)
	bullet_img:SetAttribute("src", "scroll-button.png")
	bullet_el:AppendChild(bullet_img)

	return bullet_el
end

--- Creates a goal list item for the goals list and returns the element
--- @param goal_text string The goal text
--- @return Element
function BriefingController:createGoalListItem(goal_text)
	local goal_el = self.Document:CreateElement("li")
	goal_el:SetClass("goal", true)
	goal_el:AppendChild(self:makeGoalBullet())

	local goal_inner_el = self.Document:CreateElement("div")
	goal_inner_el.inner_rml = goal_text .. "<br></br>"
	goal_el:AppendChild(goal_inner_el)

	return goal_el
end

--- Builds the goals bullet list
--- @return nil
function BriefingController:buildGoalsList()
    if mn.hasGoalsStage() then
		local goals = ui.Briefing.Objectives
		local primary_list_el = self.Document:GetElementById("primary_goal_list")
		local secondary_list_el = self.Document:GetElementById("secondary_goal_list")
		local bonus_list_el = self.Document:GetElementById("bonus_goal_list")
		for i = 1, #goals do
			local goal = goals[i]
			if goal.isGoalValid and goal.Message ~= "" then
				if goal.Type == "primary" then
					primary_list_el:AppendChild(self:createGoalListItem(goal.Message))
				end
				if goal.Type == "secondary" then
					secondary_list_el:AppendChild(self:createGoalListItem(goal.Message))
				end
				if goal.Type == "bonus" then
					bonus_list_el:AppendChild(self:createGoalListItem(goal.Message))
				end
			end
		end
	end
end

--- A brief state button was clicked by the player, so try to change to that game state
--- @param state number The state to change to. Should be one of the STATE enumerations
--- @return nil
function BriefingController:change_brief_state(state)
	if state == BriefingController.STATE_BRIEFING then
		--Do nothing because we're this is the current state!
		--ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
	elseif state == BriefingController.STATE_SHIP_SELECTION then
		if mn.isScramble() then
			ad.playInterfaceSound(10)
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_SHIP_SELECTION"])
		end
	elseif state == BriefingController.STATE_WEAPON_SELECTION then
		if mn.isScramble() then
			ad.playInterfaceSound(10)
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_WEAPON_SELECTION"])
		end
	end
end

--- Draws a frame of briefing map using the data stored in ScpuiSystem.data.memory.briefing_map
--- @return nil
function BriefingController:drawBriefingMap()

	if ScpuiSystem.data.memory.briefing_map == nil then
		return
	end

	--Testing icon ship rendering stuff
	ScpuiSystem.data.memory.briefing_map.RotationSpeed = ScpuiSystem.data.memory.briefing_map.RotationSpeed + (7 * ba.getRealFrametime())

	if ScpuiSystem.data.memory.briefing_map.RotationSpeed >= 100 then
		ScpuiSystem.data.memory.briefing_map.RotationSpeed = ScpuiSystem.data.memory.briefing_map.RotationSpeed - 100
	end

	gr.setTarget(ScpuiSystem.data.memory.briefing_map.Texture)

	local r = 160
	local g = 144
	local b = 160
	local a = 255
	gr.setLineWidth(2)

	if ScpuiSystem.data.memory.briefing_map.Draw == true then
		if ScpuiSystem.data.ScpuiOptionValues.Brief_Render_Option == nil then
			ScpuiSystem.data.ScpuiOptionValues.Brief_Render_Option = "screen"
		end
		if string.lower(ScpuiSystem.data.ScpuiOptionValues.Brief_Render_Option) == "texture" then
			gr.setTarget(ScpuiSystem.data.memory.briefing_map.Texture)
			gr.clearScreen(0,0,0,0)
			if not ScpuiSystem.data.memory.briefing_map.Goals then
				gr.drawImage(ScpuiSystem.data.memory.briefing_map.Bg, 0, 0, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)
			end
			ui.Briefing.drawBriefingMap(0, 0, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)

			if not ScpuiSystem.data.memory.briefing_map.Goals then
				gr.setColor(r, g, b, a)
				gr.drawLine(0, 0, 0, ScpuiSystem.data.memory.briefing_map.Y2)
				gr.drawLine(0, 0, ScpuiSystem.data.memory.briefing_map.X2, 0)
				gr.drawLine(ScpuiSystem.data.memory.briefing_map.X2, 0, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)
				gr.drawLine(0, ScpuiSystem.data.memory.briefing_map.Y2, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)
			end

		elseif string.lower(ScpuiSystem.data.ScpuiOptionValues.Brief_Render_Option) == "screen" then
			gr.clearScreen(0,0,0,0)
			if not ScpuiSystem.data.memory.briefing_map.Goals then
				gr.drawImage(ScpuiSystem.data.memory.briefing_map.Bg, 0, 0, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)

				gr.setColor(r, g, b, a)
				gr.drawLine(0, 0, 0, ScpuiSystem.data.memory.briefing_map.Y2)
				gr.drawLine(0, 0, ScpuiSystem.data.memory.briefing_map.X2, 0)
				gr.drawLine(ScpuiSystem.data.memory.briefing_map.X2, 0, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)
				gr.drawLine(0, ScpuiSystem.data.memory.briefing_map.Y2, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)
			end
			gr.setTarget()
			ui.Briefing.drawBriefingMap(ScpuiSystem.data.memory.briefing_map.X1, ScpuiSystem.data.memory.briefing_map.Y1, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)

		end

	else
		gr.clearScreen(0,0,0,0)

		gr.setColor(r, g, b, a)
		gr.drawLine(0, 0, 0, ScpuiSystem.data.memory.briefing_map.Y2)
		gr.drawLine(0, 0, ScpuiSystem.data.memory.briefing_map.X2, 0)
		gr.drawLine(ScpuiSystem.data.memory.briefing_map.X2, 0, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)
		gr.drawLine(0, ScpuiSystem.data.memory.briefing_map.Y2, ScpuiSystem.data.memory.briefing_map.X2, ScpuiSystem.data.memory.briefing_map.Y2)
	end

	gr.setTarget()

	if ScpuiSystem.data.memory.briefing_map.Pof ~= nil then

		--get the current color and save it
		local prev_c = {
			r = 0,
			g = 0,
			b = 0,
			a = 0
		}

		prev_c.r, prev_c.g, prev_c.b, prev_c.a = gr.getColor()

		--set the box coords and size
		local bx_size = math.floor(0.20 * gr.getScreenHeight()) --size of the box is 15% of screen height
		local bx_dist = 5 --this is the distance the box is drawn from the mouse in pixels
		local bx1 = ScpuiSystem.data.memory.briefing_map.Bx - bx_size - bx_dist
		local by1 = ScpuiSystem.data.memory.briefing_map.By - bx_size - bx_dist
		local bx2 = ScpuiSystem.data.memory.briefing_map.Bx - bx_dist
		local by2 = ScpuiSystem.data.memory.briefing_map.By - bx_dist

		--set the current color to black
		gr.setColor(0, 0, 0, 255)

		--draw a box at the mouse coords
		gr.drawRectangle(bx1, by1, bx2, by2)

		--set the current color to grey
		gr.setColor(50, 50, 50, 255)
		gr.drawLine(bx1, by1, bx1, by2)
		gr.drawLine(bx1, by1, bx2, by1)
		gr.drawLine(bx2, by2, bx1, by2)
		gr.drawLine(bx2, by2, bx2, by1)

		local ship = tb.ShipClasses[ScpuiSystem.data.memory.briefing_map.Pof]
		if ship.Name == "" then
			local jumpnode = false
			if ScpuiSystem.data.memory.briefing_map.Pof == "subspacenode.pof" then
				jumpnode = true
			end
			ui.Briefing.renderBriefingModel(ScpuiSystem.data.memory.briefing_map.Pof, ScpuiSystem.data.memory.briefing_map.CloseupZoom, ScpuiSystem.data.memory.briefing_map.CloseupPos, bx1+1, by1+1, bx2-1, by2-1, ScpuiSystem.data.memory.briefing_map.RotationSpeed, -15, 0, 1.1, true, jumpnode)
		else
			ship:renderTechModel(bx1+1, by1+1, bx2-1, by2-1, ScpuiSystem.data.memory.briefing_map.RotationSpeed, -15, 0, 1.1)
		end

		--set the current color to light grey
		gr.setColor(150, 150, 150, 255)

		gr.drawString(ScpuiSystem.data.memory.briefing_map.Label, bx1+1, by1+1, bx2-1, by2-1)

		--reset the color
		gr.setColor(prev_c.r, prev_c.g, prev_c.b, prev_c.a)
		gr.setLineWidth(1)
	end

end

--- The skip button was pressed so skip the mission, if possible
--- @return nil
function BriefingController:skip_pressed()

	ScpuiSystem:stopMusic()

	LoadoutHandler:unloadAll(false)
	ScpuiSystem.data.memory.CutscenePlayed = nil

	if mn.isTraining() then
		ui.Briefing.skipMission()
	elseif mn.isInCampaignLoop() then
		ui.Briefing.exitLoop()
	elseif mn.isMissionSkipAllowed() then
		ui.Briefing.skipMission()
	end

end

--- The mouse was moved over the briefing map so update the briefing map data
--- @param element Element The element the mouse is over
--- @param event Event The mouse move event
--- @return nil
function BriefingController:mouse_move(element, event)

	if ScpuiSystem.data.memory.briefing_map ~= nil then
		ScpuiSystem.data.memory.briefing_map.Mx = event.parameters.mouse_x
		ScpuiSystem.data.memory.briefing_map.My = event.parameters.mouse_y

		--for the ship box preview coords regardless of briefing render type
		ScpuiSystem.data.memory.briefing_map.Bx = event.parameters.mouse_x
		ScpuiSystem.data.memory.briefing_map.By = event.parameters.mouse_y

		--Get the grid coords
		local grid_el = self.Document:GetElementById("briefing_grid")
		local gx = grid_el.offset_left + grid_el.parent_node.offset_left + grid_el.parent_node.parent_node.offset_left
		local gy = grid_el.offset_top + grid_el.parent_node.offset_top + grid_el.parent_node.parent_node.offset_top

		if string.lower(ScpuiSystem.data.ScpuiOptionValues.Brief_Render_Option) == "texture" then

			ScpuiSystem.data.memory.briefing_map.Mx = ScpuiSystem.data.memory.briefing_map.Mx - gx
			ScpuiSystem.data.memory.briefing_map.My = ScpuiSystem.data.memory.briefing_map.My - gy

		end

		if ((ScpuiSystem.data.memory.briefing_map.Mx ~= nil) and (ScpuiSystem.data.memory.briefing_map.My ~= nil)) then
			ScpuiSystem.data.memory.briefing_map.Pof, ScpuiSystem.data.memory.briefing_map.CloseupZoom, ScpuiSystem.data.memory.briefing_map.CloseupPos, ScpuiSystem.data.memory.briefing_map.Label, ScpuiSystem.data.memory.briefing_map.IconIdentifier = ui.Briefing.checkStageIcons(ScpuiSystem.data.memory.briefing_map.Mx, ScpuiSystem.data.memory.briefing_map.My)
		end

		--double check we're still inside the map X coords
		if event.parameters.mouse_x < gx or event.parameters.mouse_x > (ScpuiSystem.data.memory.briefing_map.X2 + gx) then
			ScpuiSystem.data.memory.briefing_map.Pof = nil
			return
		end

		--double check we're still inside the map Y coords
		if event.parameters.mouse_y < gy or event.parameters.mouse_y > (ScpuiSystem.data.memory.briefing_map.Y2 + gy) then
			ScpuiSystem.data.memory.briefing_map.Pof = nil
			return
		end

		if ScpuiSystem.data.memory.briefing_map.Pof == nil then
			ScpuiSystem.data.memory.briefing_map.RotationSpeed = 40
		end
	end

end

--- The help button was clicked
--- @return nil
function BriefingController:help_clicked()
    self.HelpShown  = not self.HelpShown

    local help_texts = self.Document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.HelpShown)
    end
end

--- The multiplayer lock button was pressed
--- @return nil
function BriefingController:lock_pressed()
	ui.MultiGeneral.getNetGame().Locked = true
end

--- The multiplayer chat submit button was pressed
--- @return nil
function BriefingController:submit_pressed()
	if self.SubmittedChatValue then
		AbstractBriefingController.sendChat(self)
	end
end

--- For when the chat input loses focus. Currently does nothing
--- @return nil
function BriefingController:input_focus_lost()
	--do nothing
end

--- When the player types in the chat input box, get the value and save it. Also check for the return key to submit
--- @param event Event The input event
--- @return nil
function BriefingController:input_change(event)
	if event.parameters.linebreak ~= 1 then
		local val = self.ChatInputEl:GetAttribute("value")
		self.SubmittedChatValue = val
	else
		local submit_id = self.Document:GetElementById("submit_btn")
		ui.playElementSound(submit_id, "click")
		AbstractBriefingController.sendChat(self)
	end
end

--- During the briefing game state if SCPUI is rendering then try to draw the briefing map
ScpuiSystem:addHook("On Frame", function()
	if (ScpuiSystem.data.Render == true) then
		BriefingController:drawBriefingMap()
	end
end, {State="GS_STATE_BRIEFING"}, function()
    return false
end)

--- Prevent the briefing UI from being drawn if we're just going to skip it in a frame or two
ScpuiSystem:addHook("On Frame", function()
	if mn.hasNoBriefing() and not ui.isCutscenePlaying() then
		gr.clearScreen()
	end
end, {State="GS_STATE_BRIEFING"}, function()
    return false
end)

return BriefingController
