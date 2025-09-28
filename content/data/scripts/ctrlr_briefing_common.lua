-----------------------------------
--Shared Controller for Briefing, Command Briefing, and Fiction Viewer
-----------------------------------

local AsyncUtil = require("lib_async")
local LoadoutHandler = require("lib_loadout_handler")
local Topics = require("lib_ui_topics")

local Class = require("lib_class")

--- Briefing Common Controller can be merged with the Multi Common Controller during multiplayer
local AbstractMultiController = nil
local AbstractBriefingController = nil
if ScpuiSystem:inMultiGame() then
	AbstractMultiController = require("ctrlr_multi_common")
	AbstractBriefingController = Class(AbstractMultiController)
else
	AbstractBriefingController = Class()
end

AbstractBriefingController.CONTROLLER_FICTION_VIEWER = 1 --- @type number The fiction controller enumeration
AbstractBriefingController.CONTROLLER_BRIEFING = 2 --- @type number The briefing controller enumeration
AbstractBriefingController.CONTROLLER_COMMAND_BRIEFING = 3 --- @type number The command briefing controller enumeration

--- Called by the class constructor
--- @return nil
function AbstractBriefingController:init()
    self.CurrentVoiceHandle = nil --- @type audio_stream | nil The current voice handle for the current stage
    self.CurrentStage = 0 --- @type number The current stage index
    self.StageInstanceId = 0 --- @type number The current stage instance id
    self.Loaded = true --- @type boolean If the controller is loaded or not
	self.BriefState = AbstractBriefingController.CONTROLLER_BRIEFING --- @type number The current briefing state (briefing, command, fiction)
	self.Stages_List = {} --- @type briefing_stage[] | cmd_briefing_stage[] The stages of the briefing
	self.Document = nil --- @type Document The current RML document
	self.SubmittedChatValue = "" --- @type string the submitted value from the chat input

	--- @type execution_context The current UI active context
    self.UiActiveContext = async.context.combineContexts(async.context.captureGameState(),
        async.context.createLuaState(function()
            if not self.Loaded then
                return CONTEXT_INVALID
            end

            return CONTEXT_VALID
        end))

	--- @type scpui_brief_element_list List of ui element names for player control of the stages
    self.Element_Names = {
        PauseBtn = nil,
        LastBtn = nil,
        NextBtn = nil,
        PrevBtn = nil,
        FirstBtn = nil,
        TextEl = nil,
        StageTextEl = nil,
    }
end

--- Called by the RML document
--- @param document Document
function AbstractBriefingController:initialize(document)
	if AbstractMultiController and ScpuiSystem:inMultiGame()then
		AbstractMultiController.initialize(self, document)
		self.Subclass = AbstractMultiController.CTRL_BRIEFING
	end
    self.Document = document
    self.Loaded = true

	if ba.getCurrentGameState().Name == "GS_STATE_FICTION_VIEWER" then
		self.BriefState = self.CONTROLLER_FICTION_VIEWER
	end

	if ba.getCurrentGameState().Name == "GS_STATE_CMD_BRIEF" then
		self.BriefState = self.CONTROLLER_COMMAND_BRIEFING
	end

	self:startMusic()

	self:registerEventHandlers()

    local player = ba.getCurrentPlayer()

	if self.BriefState ~= self.CONTROLLER_FICTION_VIEWER then
		self.Document:GetElementById(self.Element_Names.PauseBtn):SetPseudoClass("checked", not player.AutoAdvance)
	end

	Topics.briefcommon.initialize:send(self)

end

--- Send the chat message to the server
--- @return nil
function AbstractBriefingController:sendChat()
	if AbstractMultiController then
		AbstractMultiController.sendChat(self)
	end
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function AbstractBriefingController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
		ScpuiSystem:stopMusic()
		ScpuiSystem.data.memory.CurrentMusicFile = nil
		ScpuiSystem.data.memory.briefing_map = nil
		ScpuiSystem.data.memory.CutscenePlayed = nil

		if self.BriefState == self.CONTROLLER_BRIEFING then
			LoadoutHandler:saveCurrentLoadout()
			LoadoutHandler:unloadAll(false)
		end
        event:StopPropagation()

		mn.unloadMission(true)
        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
	elseif keys.UP then
		self:scrollUp()
	elseif keys.DOWN then
		self:scrollDown()
	elseif self.BriefState ~= self.CONTROLLER_FICTION_VIEWER and keys.LEFT then
		self:goToPrevStage(element)
	elseif self.BriefState ~= self.CONTROLLER_FICTION_VIEWER and keys.RIGHT then
		self:goToNextStage(element)
	elseif self.BriefState == self.CONTROLLER_FICTION_VIEWER and keys.RETURN then
		self:acceptPressed()
    end
end

--- Scroll the text up by 10 pixels
--- @return nil
function AbstractBriefingController:scrollUp()
	ScpuiSystem:scrollUp(self.Document:GetElementById(self.Element_Names.TextEl))
end

--- Scroll the text down by 10 pixels
--- @return nil
function AbstractBriefingController:scrollDown()
	ScpuiSystem:scrollDown(self.Document:GetElementById(self.Element_Names.TextEl))
end

--- Advance to the next briefing stage, if possible
--- @return nil
function AbstractBriefingController:goToNextStage(element)
	if self.CurrentStage >= #self.Stages_List then
		ui.playElementSound(element, "click", "fail")
		return
	end

	if self.BriefState == self.CONTROLLER_BRIEFING then
		ui.Briefing.callNextMapStage()
		if self.Stages_List[self.CurrentStage].hasForwardCut then
			self:cutToStage()
		end
	end

	self:goToStage(self.CurrentStage + 1)
	ui.playElementSound(element, "click", "success")
end

--- Backup to the previous briefing stage, if possible
--- @return nil
function AbstractBriefingController:goToPrevStage(element)
	if self.CurrentStage <= 1 then
		ui.playElementSound(element, "click", "fail")
		return
	end

	if self.BriefState == self.CONTROLLER_BRIEFING then
		ui.Briefing.callPrevMapStage()
		if self.Stages_List[self.CurrentStage].hasBackwardCut then
			self:cutToStage()
		end
	end

	self:goToStage(self.CurrentStage - 1)
	ui.playElementSound(element, "click", "success")
end

--- Cuts to a briefing stage, showing static during the cut
--- @return nil
function AbstractBriefingController:cutToStage()
	ad.playInterfaceSound(42)
	ScpuiSystem.data.memory.briefing_map.Draw = false
	self.aniWrapper = self.Document:GetElementById("brief_grid_cut")
	ad.playInterfaceSound(42)
    local ani_el = self.Document:CreateElement("ani")
    ani_el:SetAttribute("src", "static.png")
	self.aniWrapper:ReplaceChild(ani_el, self.aniWrapper.first_child)

	async.run(function()
        async.await(AsyncUtil.wait_for(0.7))
        ScpuiSystem.data.memory.briefing_map.Draw = true
		self.aniWrapper:RemoveChild(self.aniWrapper.first_child)
    end, async.OnFrameExecutor, self.UiActiveContext)
end

--- Go to a specific briefing stage
--- @param stage_idx number The index of the stage to go to
--- @return nil
function AbstractBriefingController:goToStage(stage_idx)
	local old_stage = self.CurrentStage or 0
    self:stopCurrentVoicePlayback()

	local stage = self.Stages_List[stage_idx]

	if self.BriefState  == self.CONTROLLER_BRIEFING then
		if ScpuiSystem.data.memory.briefing_map == nil then
			ScpuiSystem.data.memory.briefing_map = {
				Texture = nil,
				RotationSpeed = 40
			}
		end

		ScpuiSystem.data.memory.briefing_map.Bg = ScpuiSystem:getBriefingBackground(mn.getMissionFilename(), tostring(stage_idx))

		local brief_img = Topics.briefing.brief_bg:send((mn.hasGoalsStage() and stage_idx == #self.Stages_List))

		if mn.hasGoalsStage() and stage_idx == #self.Stages_List then
			self:initializeStage(stage_idx, stage.Text, stage.AudioFilename)
			self.Document:GetElementById("briefing_goals"):SetClass("hidden", false)
			ScpuiSystem.data.memory.briefing_map.Goals = true
		else
			self:initializeStage(stage_idx, stage.Text, stage.AudioFilename)
			self.Document:GetElementById("briefing_goals"):SetClass("hidden", true)
			ScpuiSystem.data.memory.briefing_map.Goals = false
		end

		local brief_bg_src = self.Document:CreateElement("img")
		brief_bg_src:SetAttribute("src", brief_img)
		local brief_bg_el = self.Document:GetElementById("brief_grid_window")
		brief_bg_el:ReplaceChild(brief_bg_src, brief_bg_el.last_child)

		ui.Briefing.runBriefingStageHook(old_stage, stage_idx)
	elseif self.BriefState == self.CONTROLLER_COMMAND_BRIEFING then
		self:initializeStage(stage_idx, stage.Text, stage.AudioFilename)

		local ani_wrapper_el = self.Document:GetElementById("cmd_anim")
		if #stage.AniFilename > 0 then
			local Utils = require("lib_utils")
			local ani_el = self.Document:CreateElement("ani")

			local filename = stage.AniFilename
			-- For legacy.. we need to try to load default
			if string.lower(filename) == "<default>" then
				filename = "cb_default"
				if Utils.animExists("2_cb_default") then
					filename = "2_cb_default"
				end
			end

			if Utils.animExists(filename) then
				ani_el:SetAttribute("src", filename)
			end

			ani_wrapper_el:ReplaceChild(ani_el, ani_wrapper_el.first_child)
		else
			ani_wrapper_el:RemoveChild(ani_wrapper_el.first_child)
		end
	end
end

--- When the accept button is pressed or the correct key is pressed then go to the next state based on the current briefing state
--- @return nil
function AbstractBriefingController:acceptPressed()
	if self.BriefState == self.CONTROLLER_BRIEFING then
		if not Topics.mission.commit:send(self) then
			return
		end

		--Apply the loadout
		LoadoutHandler:SendAllToFSO_API()

		local error_value = ui.Briefing.commitToMission()

		if error_value == COMMIT_SUCCESS then
			--Save to the player file
			self.Commit = true
			LoadoutHandler:SaveInFSO_API()
			--Cleanup
			if ScpuiSystem.data.memory.briefing_map then
				ScpuiSystem.data.memory.briefing_map.Texture:unload()
				ScpuiSystem.data.memory.briefing_map.Texture = nil
				ScpuiSystem.data.memory.briefing_map = nil
			end
			ScpuiSystem:stopMusic()
			ScpuiSystem.data.memory.CurrentMusicFile = nil
			ScpuiSystem.data.memory.CutscenePlayed = nil
		end
	elseif self.BriefState == self.CONTROLLER_COMMAND_BRIEFING then
		ScpuiSystem.data.memory.CutscenePlayed = nil
		if mn.isRedAlertMission() then
			ba.postGameEvent(ba.GameEvents["GS_EVENT_RED_ALERT"])
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
		end
	elseif self.BriefState == self.CONTROLLER_FICTION_VIEWER then
		if Topics.fictionviewer.accept:send(self) then
			ScpuiSystem.data.memory.CutscenePlayed = nil
			if mn.hasCommandBriefing() then
				ba.postGameEvent(ba.GameEvents["GS_EVENT_CMD_BRIEF"])
			else
				if mn.isRedAlertMission() then
					ba.postGameEvent(ba.GameEvents["GS_EVENT_RED_ALERT"])
				else
					ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
				end
			end
		end
	end
end

--- Registers code methods to UI events listeners based on the current briefing state
--- @return nil
function AbstractBriefingController:registerEventHandlers()

	self.Document:GetElementById("accept_btn"):AddEventListener("click", function(_, el, _)
        self:acceptPressed()
        ui.playElementSound(el, "click", "commit")
    end)

	--- Fiction Viewer doesn't have any of the buttons below so just return early
	if self.BriefState == self.CONTROLLER_FICTION_VIEWER then
		return
	end

    self.Document:GetElementById(self.Element_Names.LastBtn):AddEventListener("click", function(_, el, _)
        if self.CurrentStage >= #self.Stages_List then
            ui.playElementSound(el, "click", "fail")
            return
        end

		if self.BriefState == self.CONTROLLER_BRIEFING then
			self:cutToStage()
			ui.Briefing.callLastMapStage()
		end

        self:goToStage(#self.Stages_List)
        ui.playElementSound(el, "click", "success")
    end)

    self.Document:GetElementById(self.Element_Names.NextBtn):AddEventListener("click", function(_, el, _)
        self:goToNextStage(el)
    end)

    self.Document:GetElementById(self.Element_Names.PrevBtn):AddEventListener("click", function(_, el, _)
        self:goToPrevStage(el)
    end)

    self.Document:GetElementById(self.Element_Names.FirstBtn):AddEventListener("click", function(_, el, _)
        if self.CurrentStage <= 1 then
            ui.playElementSound(el, "click", "fail")
            return
        end

		if self.BriefState == self.CONTROLLER_BRIEFING then
			self:cutToStage()
			ui.Briefing.callFirstMapStage()
		end

        self:goToStage(1)
        ui.playElementSound(el, "click", "success")
    end)

    self.Document:GetElementById("options_btn"):AddEventListener("click", function(_, _, _)
        ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
    end)

    self.Document:GetElementById(self.Element_Names.PauseBtn):AddEventListener("click", function(_, el)
        local plr = ba.getCurrentPlayer()
        local val = plr.AutoAdvance
        plr.AutoAdvance = not val

        el:SetPseudoClass("checked", not plr.AutoAdvance)
    end)
end

--- Called when the screen is being unloaded
--- @return nil
function AbstractBriefingController:unload()
    if self.CurrentVoiceHandle ~= nil and self.CurrentVoiceHandle:isValid() then
        self.CurrentVoiceHandle:close(false)
    end
	if ScpuiSystem.data.memory.briefing_map then
		ScpuiSystem.data.memory.briefing_map.Texture:unload()
		ScpuiSystem.data.memory.briefing_map.Texture = nil
		ScpuiSystem.data.memory.briefing_map = nil
	end

	if self.BriefState == self.CONTROLLER_BRIEFING then
		if self.Commit == true then
			LoadoutHandler:saveCurrentLoadout()
			LoadoutHandler:unloadAll(true)
			ScpuiSystem.data.memory.briefing_map = nil
			ScpuiSystem.data.memory.CutscenePlayed = nil
		end
		ui.Briefing.closeBriefing()
	end

    -- We need to keep track of if we are loaded or not to abort coroutines that still have references to this instance
    self.Loaded = false

	if self.BriefState == self.CONTROLLER_BRIEFING then
		Topics.briefing.unload:send(self)
	elseif self.BriefState == self.CONTROLLER_COMMAND_BRIEFING then
		Topics.cmdbriefing.unload:send(self)
	elseif self.BriefState == self.CONTROLLER_FICTION_VIEWER then
		Topics.fictionviewer.unload:send(self)
	end
end

--- Start playing the briefing music in SCPUI's music handle
--- @return nil
function AbstractBriefingController:startMusic()
	local filename = ui.Briefing.getBriefingMusicName()

	if self.BriefState == self.CONTROLLER_FICTION_VIEWER then
		filename = ui.FictionViewer.getFictionMusicName()
	end

    if #filename <= 0 then
        return
    end

	if filename ~= ScpuiSystem.data.memory.CurrentMusicFile then

		if ScpuiSystem.data.memory.MusicHandle ~= nil and ScpuiSystem.data.memory.MusicHandle:isValid() then
			ScpuiSystem.data.memory.MusicHandle:close(true)
		end

		ScpuiSystem.data.memory.MusicHandle = ad.openAudioStream(filename, AUDIOSTREAM_MENUMUSIC)
		async.run(function()
			async.await(AsyncUtil.wait_for(2.5))
			ScpuiSystem.data.memory.MusicHandle:play(ad.MasterEventMusicVolume, true)
			ScpuiSystem.data.memory.CurrentMusicFile = filename
		end, async.OnFrameExecutor, self.UiActiveContext)
	end
end

--- Waits for the current stage to finish playing the voice file or a set time based on the text length. The current formula is 'math.max(5.0, num_stage_lines * 3.5)'
--- @param num_stage_lines number The number of lines in the current stage
--- @return nil
function AbstractBriefingController:waitForStageFinishAsync(num_stage_lines)
    if self.CurrentVoiceHandle ~= nil and self.CurrentVoiceHandle:isValid() then
        while self.CurrentVoiceHandle:isPlaying() do
            async.await(async.yield())
        end
    else
        -- Estimate a wait time based on the briefing text. Formula is based on the retail way of computing this
        async.await(AsyncUtil.wait_for(math.max(5.0, num_stage_lines * 3.5)))
    end

    -- Voice part is done so wait for a bit before saying we are actually finished
    async.await(AsyncUtil.wait_for(1.0))
end

--- Stops any currently playing voice track
--- @return nil
function AbstractBriefingController:stopCurrentVoicePlayback()
    if self.CurrentVoiceHandle ~= nil and self.CurrentVoiceHandle:isValid() then
        self.CurrentVoiceHandle:stop()
        self.CurrentVoiceHandle = nil
    end
end

--- Initialize a briefing stage, add the text and play the voice file
--- @param stage_idx number The index of the stage to initialize
--- @param briefing_text string The briefing text to show
--- @param audio_filename string The name of the audio file to play
--- @return nil
function AbstractBriefingController:initializeStage(stage_idx, briefing_text, audio_filename)
    self.CurrentStage = stage_idx
    self.StageInstanceId = self.StageInstanceId + 1
	if not mn.hasNoBriefing() then
		ad.playInterfaceSound(20)
	end

    local text_el = self.Document:GetElementById(self.Element_Names.TextEl)
	text_el.parent_node.scroll_top = 0
    local num_stage_lines = ScpuiSystem:setBriefingText(text_el, briefing_text)

    local stage_indicator_el = self.Document:GetElementById(self.Element_Names.StageTextEl)
    stage_indicator_el.inner_rml = string.format(ba.XSTR("Stage %d of %d", 888283), self.CurrentStage, #self.Stages_List)

    local stage_id = self.StageInstanceId
    -- This will ensure that this coroutine only runs if we are still in the same briefing stage and in the same game state
    local execution_context = async.context.combineContexts(async.context.captureGameState(),
        self.UiActiveContext,
        async.context.createLuaState(function()
            if self.StageInstanceId ~= stage_id then
                return CONTEXT_INVALID
            end

            return CONTEXT_VALID
        end))

	ba.print("SCPUI: Initializing voice for stage: " .. stage_idx .. "\n")
    async.run(function()
        -- First, wait until the text has been shown fully
        async.await(AsyncUtil.wait_for(2.0))

        -- And now we can start playing the voice file
		if audio_filename then
			ba.print("SCPUI: Preparing to play voice file: " .. audio_filename .. "\n")
			if #audio_filename > 0 and string.lower(audio_filename) ~= "none" then
				self.CurrentVoiceHandle = ad.openAudioStream(audio_filename, AUDIOSTREAM_VOICE)
				ba.print("SCPUI: Current voice validity is: " .. tostring(self.CurrentVoiceHandle:isValid()) .. "\n")
				self.CurrentVoiceHandle:play(ad.MasterVoiceVolume)
				ba.print("SCPUI: Voice file '" .. audio_filename .. "' should be playing!\n")
			end
		end

        self:waitForStageFinishAsync(num_stage_lines)

        if ba.getCurrentPlayer().AutoAdvance and self.CurrentStage < #self.Stages_List then
            self:goToStage(self.CurrentStage + 1)
			if self.BriefState == self.CONTROLLER_BRIEFING then
				ui.Briefing.callNextMapStage()
			end
        end
    end, async.OnFrameExecutor, execution_context)

	Topics.briefcommon.stageChanged:send(self, stage_idx)
end

return AbstractBriefingController
