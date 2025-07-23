-----------------------------------
--Controller for the Multi PXO Help UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractMultiController = require("ctrlr_multi_common")

--- This multi controller is merged with the Multi Common Controller
local PXOHelpController = Class(AbstractMultiController)

--- Called by the class constructor
--- @return nil
function PXOHelpController:init()
	self.Document = nil --- @type Document the RML document
	self.HelpElement = nil --- @type Element the help element

	self.Subclass = AbstractMultiController.CTRL_PXO_HELP
end

--- Called by the RML document
--- @param document Document
function PXOHelpController:initialize(document)
	AbstractMultiController.initialize(self, document)
	ScpuiSystem.data.memory.multiplayer_general.Context = self

	self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	local text = ui.MultiPXO.getHelpText()
	local full_help = ""
	for i = 1, #text do
		full_help = full_help .. ScpuiSystem:replaceAngleBrackets(text[i]) .. "<br/>"
	end
	self.HelpElement = self.Document:GetElementById("help_div")
	self.HelpElement.inner_rml = full_help

	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
	ui.MultiGeneral.setPlayerState()

	Topics.multipxohelp.initialize:send(self)

end

--- Return to the PXO gamestate
--- @return nil
function PXOHelpController:exit()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PXO"])
end

--- Called by the RML when the accept button is pressed
function PXOHelpController:accept_pressed()
	self:exit()
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function PXOHelpController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
       self:exit()
	end
end

--- Called when the screen is being unloaded
--- @return nil
function PXOHelpController:unload()
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = false
	Topics.multipxohelp.unload:send(self)
end

return PXOHelpController
