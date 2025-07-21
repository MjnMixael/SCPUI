-----------------------------------
--Controller for the Fiction Viewer UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractBriefingController = require("ctrlr_briefing_common")

--- Briefing controller is merged with the Briefing Common Controller
local FictionViewerController = Class(AbstractBriefingController)

--- Called by the class constructor
--- @return nil
function FictionViewerController:init()
	--- Check if we should play a cutscene before the command briefing
	if not ScpuiSystem.data.memory.CutscenePlayed then
		ScpuiSystem:maybePlayCutscene(MOVIE_PRE_FICTION)
	end
	ScpuiSystem.data.memory.CutscenePlayed = true

	--- Now initialize all our variables
	self.Document = nil --- @type Document The RML document
	self.TextFile = nil --- @type string The text file to display
	self.VoiceFile = nil --- @type string The voice file to play
	self.Text = nil --- @type string The text to display
	self.CurrentVoiceHandle = nil --- @type audio_stream The current voice handle
end

--- Called by the RML document
--- @param document Document
function FictionViewerController:initialize(document)
	AbstractBriefingController.initialize(self, document)

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	local stage = ui.FictionViewer.getFiction()

	self.TextFile = stage.TextFile

	local file = cf.openFile(self.TextFile, 'r', '')
	self.Text = file:read('*a')
	file:close()

	local text_el = self.Document:GetElementById("fiction_text")

	local color_text = ScpuiSystem:setBriefingText(text_el, self.Text)

	local font = gr.Fonts[stage.FontFile]

	if font:isValid() then
		text_el.style.font = font.FamilyName
	end

	Topics.fictionviewer.initialize:send(self)

	self.CurrentVoiceHandle = ad.openAudioStream(ui.FictionViewer.getFiction().VoiceFile, AUDIOSTREAM_VOICE)

	---If we got a valid voice file then play it
	if self.CurrentVoiceHandle:isValid() then
		self.CurrentVoiceHandle:play(ad.MasterVoiceVolume)
	end

end

--- Scroll the text up by 10 pixels
--- @return nil
function FictionViewerController:scrollUp()
	ScpuiSystem:scrollUp(self.Document:GetElementById("fiction_text"))
end

--- Scroll the text down by 10 pixels
--- @return nil
function FictionViewerController:scrollDown()
	ScpuiSystem:scrollDown(self.Document:GetElementById("fiction_text"))
end

return FictionViewerController
