-----------------------------------
--Controller for the Red Alert UI
-----------------------------------

local AsyncUtil = require("lib_async")
local LoadoutHandler = require("lib_loadout_handler")
local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local RedAlertController = Class()

--- Called by the class constructor
--- @return nil
function RedAlertController:init()

	--- Check if we should play a cutscene before the briefing
	if not ScpuiSystem.data.memory.CutscenePlayed then
		ScpuiSystem:maybePlayCutscene(MOVIE_PRE_BRIEF)
	end
	ScpuiSystem.data.memory.CutscenePlayed = true

	self.AlertFlashSpeed = 0.5 --- @type number How often, in seconds, the alert should flash
	self.Document = nil --- @type Document the RML document
	self.CurrentVoiceHandle = nil --- @type audio_stream the current voice handle

	LoadoutHandler:init()
end

--- Called by the RML document
--- @param document Document
function RedAlertController:initialize(document)
	self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    local alert_info = ui.RedAlert.getRedAlert()

	if alert_info ~= nil then
		local text_el = self.Document:GetElementById("red_alert_text")
		ScpuiSystem:setBriefingText(text_el, alert_info.Text)

		if alert_info.AudioFilename then
			self.CurrentVoiceHandle = ad.openAudioStream(alert_info.AudioFilename, AUDIOSTREAM_VOICE)
			self.CurrentVoiceHandle:play(ad.MasterVoiceVolume)
		end
	end

	--Whenever we start a new mission, we reset the log ui to goals
	ScpuiSystem.data.memory.LogSection = 1

	ScpuiSystem.data.memory.alert_memory = {
		AlertElement = self.Document:GetElementById("incoming_transmission"),
		AlertFlashState = true,
		AlertFlashSpeed = self.AlertFlashSpeed
	}
	self:blink()

	Topics.redalert.initialize:send(self)

end

--- Blink the alert element on and off
--- @return nil
function RedAlertController:blink()

	async.run(function()
        async.await(AsyncUtil.wait_for(ScpuiSystem.data.memory.alert_memory.AlertFlashSpeed))
		if ScpuiSystem.data.memory.alert_memory.AlertFlashState then
			ScpuiSystem.data.memory.alert_memory.AlertElement:SetClass("hidden", true)
			ScpuiSystem.data.memory.alert_memory.AlertFlashState = false
			RedAlertController:blink()
		else
			ScpuiSystem.data.memory.alert_memory.AlertElement:SetClass("hidden", false)
			ScpuiSystem.data.memory.alert_memory.AlertFlashState = true
			RedAlertController:blink()
		end
    end, async.OnFrameExecutor, async.context.captureGameState())

end

--- Called by the RML when the player presses the commit button
--- @return nil
function RedAlertController:commit_pressed()
	if not Topics.mission.commit:send(self) then
		return
	end
	LoadoutHandler:unloadAll(true)
	Topics.redalert.commit:send(self)
	ba.postGameEvent(ba.GameEvents["GS_EVENT_ENTER_GAME"])
end

--- Called by the RML when the player presses the replay button
--- @return nil
function RedAlertController:replay_pressed()
    if ui.RedAlert.replayPreviousMission() and mn.isInCampaign() then
		LoadoutHandler:unloadAll(false)
		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME"])
	end
end

--- Called when the screen is being unloaded
--- @return nil
function RedAlertController:unload()
    if self.CurrentVoiceHandle ~= nil and self.CurrentVoiceHandle:isValid() then
        self.CurrentVoiceHandle:close(false)
    end
	ScpuiSystem.data.memory.alert_memory = nil
	ScpuiSystem.data.memory.CutscenePlayed = nil
	Topics.redalert.unload:send(self)
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function RedAlertController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
		event:StopPropagation()
		LoadoutHandler:unloadAll(false)

		mn.unloadMission(true)
        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    end
end

return RedAlertController
