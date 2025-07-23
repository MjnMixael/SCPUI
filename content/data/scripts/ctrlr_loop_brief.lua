-----------------------------------
--Controller for the Loop Briefing UI
-----------------------------------

local Topics = require("lib_ui_topics")
local Dialogs = require("lib_dialogs")

local Class = require("lib_class")

local LoopBriefController = Class()

--- Called by the class constructor
--- @return nil
function LoopBriefController:init()
	self.Document = nil --- @type Document The RML document
	self.VoiceHandle = nil --- @type audio_stream The audio stream handle for the voice file
end

--- Called by the RML document
--- @param document Document
function LoopBriefController:initialize(document)
	self.Document = document
    --AbstractLoopBriefController.initialize(self, document)

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    local loop = ui.LoopBrief.getLoopBrief()

	local text_el = self.Document:GetElementById("loop_text")

	ScpuiSystem:setBriefingText(text_el, loop.Text)

	if loop.AudioFilename then
		ba.print("SCPUI got loop briefing audio filename as " .. loop.AudioFilename)
		self.VoiceHandle = ad.openAudioStream(loop.AudioFilename, AUDIOSTREAM_VOICE)
		self.VoiceHandle:play(ad.MasterVoiceVolume)
	end

	local ani_wrapper_el = self.Document:GetElementById("loop_anim")
    if loop.AniFilename then
        local aniEl = self.Document:CreateElement("ani")
        aniEl:SetAttribute("src", loop.AniFilename)

        ani_wrapper_el:ReplaceChild(aniEl, ani_wrapper_el.first_child)
    end

	Topics.loopbrief.initialize:send(self)

end

--- Called by the RML to accept the optional mission
--- @return nil
function LoopBriefController:accept_pressed()
    ui.LoopBrief.setLoopChoice(true)
	if self.VoiceHandle then
		self.VoiceHandle:close()
	end
	ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME"])
end

--- Called by the RML to decline the optional mission
--- @return nil
function LoopBriefController:deny_pressed()
    ui.LoopBrief.setLoopChoice(false)
	if self.VoiceHandle then
		self.VoiceHandle:close()
	end
	ba.postGameEvent(ba.GameEvents["GS_EVENT_START_GAME"])
end

--- Show a dialog box
--- @param text string The text to display in the dialog box
--- @param title string The title of the dialog box
function LoopBriefController:showDialog(text, title)
	--Create a simple dialog box with the text and title

	Dialogs.new()
		:title(title)
		:text(text)
		:button(Dialogs.BUTTON_TYPE_POSITIVE, ba.XSTR("Accept", 888014), true, string.sub(ba.XSTR("Accept", 888014), 1, 1))
		:button(Dialogs.BUTTON_TYPE_NEGATIVE, ba.XSTR("Decline", 888354), false, string.sub(ba.XSTR("Decline", 888354), 1, 1))
		:show(self.Document.context)
		:continueWith(function(accepted)
        if not accepted then
            self:deny_pressed()
            return
        end
        self:accept_pressed()
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.Document.context)
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function LoopBriefController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
		local text = ba.XSTR("You must either Accept or Decline before returning to the Main Hall", 888356)
		local title = ""
		self:showDialog(text, title)
    end
end

--- Called when the screen is being unloaded
--- @return nil
function LoopBriefController:unload()
	Topics.loopbrief.unload:send(self)
end

return LoopBriefController
