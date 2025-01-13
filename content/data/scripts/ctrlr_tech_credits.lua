-----------------------------------
--Controller for the Tech Credits UI
-----------------------------------

local AsyncUtil = require("lib_async")
local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local TechCreditsController = Class()

TechCreditsController.STATE_DATABASE = 0 --- @type number The enumeration for the database state
TechCreditsController.STATE_SIMULATOR = 1 --- @type number The enumeration for the simulator state
TechCreditsController.STATE_CUTSCENE = 2 --- @type number The enumeration for the cutscene state
TechCreditsController.STATE_CREDITS = 3 --- @type number The enumeration for the credits state

--- Called by the class constructor
--- @return nil
function TechCreditsController:init()
	self.Document = nil --- @type Document the RML document
	self.CurrentScrollPosition = 0 --- @type number the current scroll position of the credits
	self.ScrollRate = 0 --- @type number the rate at which the credits scroll
	self.CreditsMusicHandle = nil --- @type audio_stream the handle for the credits music
	self.CreditsTextElement = nil --- @type Element the element containing the credits text

	ScpuiSystem.data.memory.credits_memory = {
		X1 = 0,
		Y1 = 0,
		X2 = 0,
		Y2 = 0,
		Index = 0,
		Alpha = 0,
		FadeAmount = 0,
		Timer = 0,
		FadeTimer = 0,
		ImageFile1 = nil,
		ImageFile2 = nil
	}
end

--- Called by the RML document
--- @param document Document
function TechCreditsController:initialize(document)
    self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	ui.TechRoom.buildCredits()

	self.ScrollRate = ui.TechRoom.Credits.ScrollRate

	ad.stopMusic(0, true, "mainhall")
	ui.MainHall.stopAmbientSound()
	self:startMusic()

	self.CreditsTextElement = self.Document:GetElementById("credits_text")

	local complete_credits = string.gsub(ui.TechRoom.Credits.Complete,"\n","<br></br>")

	--We need to calculate how much empty space to add before and after the credits
	--so that we can cleanly loop the text. Get the height of the div, the height of
	--a line, and do some math. Add that number of line breaks before and after!
	local credits_height = self.CreditsTextElement.offset_height
	local line_height = self.Document:GetElementById("bullet_img").next_sibling.offset_height
	local num_breaks = (math.ceil((credits_height / line_height) + ((10 - ScpuiSystem:getFontPixelSize()) * 1.3)))
	local credits_bookend = ""

	while(num_breaks > 0) do
		credits_bookend = credits_bookend .. "<br></br>"
		num_breaks = num_breaks - 1
	end

	--Append new lines to the top and bottom of Credits so we can loop it later seamlessly
	complete_credits = credits_bookend .. complete_credits .. credits_bookend
	self.CreditsTextElement.inner_rml = complete_credits

	Topics.techroom.initialize:send(self)
	Topics.techcredits.initialize:send(self)

	self:scrollCredits()

	local image_el = self.Document:GetElementById("credits_image")
	local image_x1 = image_el.offset_left + image_el.parent_node.offset_left
	local image_y1 = image_el.offset_top + image_el.parent_node.offset_top

	ScpuiSystem.data.memory.credits_memory = {
		X1 = image_x1,
		Y1 = image_y1,
		X2 = image_x1 + image_el.offset_width,
		Y2 = image_y1 + image_el.offset_height,
		Index = ui.TechRoom.Credits.StartIndex,
		Alpha = 0,
		FadeAmount = 0.01 / ui.TechRoom.Credits.FadeTime,
		Timer = ui.TechRoom.Credits.DisplayTime,
		FadeTimer = ui.TechRoom.Credits.FadeTime,
		ImageFile1 = nil,
		ImageFile2 = nil
	}

	self:chooseImage()
	self:timeImages()


	self.Document:GetElementById("tech_btn_1"):SetPseudoClass("checked", false)
	self.Document:GetElementById("tech_btn_2"):SetPseudoClass("checked", false)
	self.Document:GetElementById("tech_btn_3"):SetPseudoClass("checked", false)
	self.Document:GetElementById("tech_btn_4"):SetPseudoClass("checked", true)

end

--- Called by the RML to change to a different tech room state
--- @param element Element The element that was clicked
--- @param state number Should be one of the STATE_ enumerations
--- @return nil
function TechCreditsController:change_tech_state(element, state)

	if state == self.STATE_DATABASE then
		if Topics.techroom.btn1Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end
	if state == self.STATE_SIMULATOR then
		if Topics.techroom.btn2Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end
	if state == self.STATE_CUTSCENE then
		if Topics.techroom.btn3Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end
	if state == self.STATE_CREDITS then
		--This is where we are already, so don't do anything
		--if Topics.techroom.btn4Action:send() == false then
			--ui.playElementSound(element, "click", "error")
		--end
	end

end

--- Choose a credits image to display and begin fading it in
--- @return nil
function TechCreditsController:chooseImage()
	---@type integer | string
	local image_index = ScpuiSystem.data.memory.credits_memory.Index

	if ScpuiSystem.data.memory.credits_memory.Timer <= 0 then
		if not ScpuiSystem.data.memory.credits_memory.ImageFile2 then
			ScpuiSystem.data.memory.credits_memory.Index = ScpuiSystem.data.memory.credits_memory.Index + 1
			ScpuiSystem.data.memory.credits_memory.ImageFile2 = ScpuiSystem.data.memory.credits_memory.ImageFile1
			ScpuiSystem.data.memory.credits_memory.Alpha = 1.0
		end
		if ScpuiSystem.data.memory.credits_memory.FadeTimer > 0 then
			ScpuiSystem.data.memory.credits_memory.FadeTimer = ScpuiSystem.data.memory.credits_memory.FadeTimer - 0.01
			ScpuiSystem.data.memory.credits_memory.Alpha = ScpuiSystem.data.memory.credits_memory.Alpha - ScpuiSystem.data.memory.credits_memory.FadeAmount
		else
			ScpuiSystem.data.memory.credits_memory.FadeTimer = ui.TechRoom.Credits.FadeTime
			ScpuiSystem.data.memory.credits_memory.Timer = ui.TechRoom.Credits.DisplayTime
			ScpuiSystem.data.memory.credits_memory.ImageFile2 = nil
			ScpuiSystem.data.memory.credits_memory.Alpha = 0
		end
	end

	if ScpuiSystem.data.memory.credits_memory.Index >= ui.TechRoom.Credits.NumImages then
		ScpuiSystem.data.memory.credits_memory.Index = 0
	end

	if ScpuiSystem.data.memory.credits_memory.Index < 10 then
		image_index = "0" .. ScpuiSystem.data.memory.credits_memory.Index
	end

	ScpuiSystem.data.memory.credits_memory.ImageFile1 = "2_Crim" .. image_index .. ".png"
end

--- Runs every 0.01 seconds to update the credits image timer
--- @return nil
function TechCreditsController:timeImages()
	async.run(function()
        async.await(AsyncUtil.wait_for(0.01))
        ScpuiSystem.data.memory.credits_memory.Timer = ScpuiSystem.data.memory.credits_memory.Timer - 0.01
		self:chooseImage()
		self:timeImages()
    end, async.OnFrameExecutor)
end

--- Draw the credits image for a frame
--- @return nil
function TechCreditsController:drawImage()
	if not ScpuiSystem.data.memory.credits_memory then return end
	if ScpuiSystem.data.memory.credits_memory.ImageFile2 then
		gr.drawImage(ScpuiSystem.data.memory.credits_memory.ImageFile2, ScpuiSystem.data.memory.credits_memory.X1, ScpuiSystem.data.memory.credits_memory.Y1, ScpuiSystem.data.memory.credits_memory.X2, ScpuiSystem.data.memory.credits_memory.Y2, 0, 0 , 1, 1, ScpuiSystem.data.memory.credits_memory.Alpha)
	end
	if ScpuiSystem.data.memory.credits_memory.ImageFile1 then
		gr.drawImage(ScpuiSystem.data.memory.credits_memory.ImageFile1, ScpuiSystem.data.memory.credits_memory.X1, ScpuiSystem.data.memory.credits_memory.Y1, ScpuiSystem.data.memory.credits_memory.X2, ScpuiSystem.data.memory.credits_memory.Y2, 0, 0 , 1, 1, (1.0 - ScpuiSystem.data.memory.credits_memory.Alpha))
	end
end

--- Start the credits music
--- @return nil
function TechCreditsController:startMusic()

	local filename = ui.TechRoom.Credits.Music

    self.CreditsMusicHandle = ad.openAudioStream(filename, AUDIOSTREAM_MENUMUSIC)
    async.run(function()
        async.await(AsyncUtil.wait_for(1.5))
        self.CreditsMusicHandle:play(ad.MasterEventMusicVolume, true)
    end, async.OnFrameExecutor)
end

--- Runs every 0.01 seconds to scroll the credits automatically
--- @return nil
function TechCreditsController:scrollCredits()
	if self.CurrentScrollPosition >= self.CreditsTextElement.scroll_height then
		self.CurrentScrollPosition = 0
	else
		self.CurrentScrollPosition = self.CurrentScrollPosition + self.ScrollRate / 50
	end
	self.CreditsTextElement.scroll_top = self.CurrentScrollPosition

	async.run(function()
        async.await(AsyncUtil.wait_for(0.01))
        self:scrollCredits()
    end, async.OnFrameExecutor)
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function TechCreditsController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    elseif event.parameters.key_identifier == rocket.key_identifier.TAB then
		self.ScrollRate = ui.TechRoom.Credits.ScrollRate * 10
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
		self:change_tech_state(element, 3)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
		self:change_tech_state(element, 1)
	end
end

--- Global keyup function handles all key releases
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function TechCreditsController:global_keyup(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.TAB then
		self.ScrollRate = ui.TechRoom.Credits.ScrollRate
	end
end

--- Called by the RML when the exit button is pressed
--- @param element Element The element that was clicked
--- @return nil
function TechCreditsController:exit_pressed(element)
    ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

--- Called when the screen is being unloaded
--- @return nil
function TechCreditsController:unload()
	if self.CreditsMusicHandle ~= nil and self.CreditsMusicHandle:isValid() then
        self.CreditsMusicHandle:close(true)
    end
	ui.MainHall.startAmbientSound()
	ui.MainHall.startMusic()

	Topics.techcredits.unload:send(self)
end

--- Every frame check if we are in the credits state and if so, draw the image
engine.addHook("On Frame", function()
	TechCreditsController:drawImage()
end, {State="GS_STATE_CREDITS"}, function()
    return false
end)

return TechCreditsController
