-----------------------------------
--Controller for the Barracks UI
-----------------------------------

local Utils = require("lib_utils")
local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local GamePausedController = Class()

--- Called by the class constructor
--- @return nil
function GamePausedController:init()
	self.PausedText = {"GAME IS PAUSED", 888347} ---@type table<string, number> The text to display when the game is paused
	self.ScreenRender = nil --- @type string The screen render blob of the game when it is paused
	self.Document = nil --- @type Document The RML document
end

--- Called by the RML document
--- @param document Document
function GamePausedController:initialize(document)

	ui.PauseScreen.initPause()

	if self.ScreenRender == nil then
		self.ScreenRender = gr.screenToBlob()
	end

    self.Document = document

	if mn.isInMission() then
		ui.PauseScreen.initPause()
	end

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	local main_bg = self.Document:GetElementById("screenrender")
	local img_el = self.Document:CreateElement("img")
	main_bg:AppendChild(img_el)
	img_el:RemoveAttribute("src")
	img_el:SetAttribute("src", self.ScreenRender)

	self.Document:GetElementById("text").inner_rml = Utils.xstr(self.PausedText)

	Topics.gamepaused.initialize:send(self)

end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function GamePausedController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE or keys.PAUSE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
	end
end

--- Called when the screen is being unloaded
--- @return nil
function GamePausedController:unload()
	if mn.isInMission() then
		ui.PauseScreen.closePause()
	end

	ui.PauseScreen.closePause()

	self.ScreenRender = nil

	Topics.gamepaused.unload:send(self)
end

return GamePausedController
