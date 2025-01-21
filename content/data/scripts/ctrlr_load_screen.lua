-----------------------------------
--Controller for the Loading Screen UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local LoadScreenController = Class()

--- Called by the class constructor
--- @return nil
function LoadScreenController:init()
	self.Document = nil --- @type Document The RML document
	self.PreviousProgress = 0 --- @type number The previous progress of the loading bar
	self.LoopLoadBar = false --- @type boolean Whether the loading bar should loop
	self.ImageTexture = nil --- @type texture The texture for the loading bar image
	self.Texture = nil --- @type texture The texture the loading bar should draw to
	self.Url = nil --- @type string The URL of the texture
end

--- Called by the RML document
--- @param document Document
function LoadScreenController:initialize(document)

    self.Document = document

	---First set a generic bg
	self.Document:GetElementById("main_background"):SetClass("loadscreen_default", true)
	---Then try to set it using the mission filename
	self.Document:GetElementById("main_background"):SetClass(mn.getMissionFilename():gsub('.fs2', ''))

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.Document:GetElementById("title").inner_rml = mn.getMissionTitle()

	if not ScpuiSystem.data.memory.loading_bar.LoadProgress then
		ScpuiSystem.data.memory.loading_bar.LoadProgress = 0
	end

	local load_img = Topics.loadscreen.load_bar:send(self)
	ScpuiSystem.data.memory.loading_bar.ImageTexture = gr.loadTexture(load_img, true)
	ScpuiSystem.data.memory.loading_bar.Texture = gr.createTexture(ScpuiSystem.data.memory.loading_bar.ImageTexture:getWidth(), ScpuiSystem.data.memory.loading_bar.ImageTexture:getHeight())
	ScpuiSystem.data.memory.loading_bar.Url = ui.linkTexture(ScpuiSystem.data.memory.loading_bar.Texture)

	local ani_el = self.Document:CreateElement("img")
    ani_el:SetAttribute("src", ScpuiSystem.data.memory.loading_bar.Url)
	self.Document:GetElementById("loadingbar"):AppendChild(ani_el)

	--Draw loading bar frame 0
	gr.setTarget(ScpuiSystem.data.memory.loading_bar.Texture)
	gr.clearScreen(0,0,0,0)
	if ScpuiSystem.data.memory.loading_bar.ImageTexture and ScpuiSystem.data.memory.loading_bar.ImageTexture:isValid() then
		gr.drawImage(ScpuiSystem.data.memory.loading_bar.ImageTexture[0], 0, 0)
	end
	gr.setTarget()

	Topics.loadscreen.initialize:send(self)

end

--- Set the loading bar image and draw a frame of it to the texture target
--- @return nil
function LoadScreenController:setLoadingBar()
	gr.setTarget(ScpuiSystem.data.memory.loading_bar.Texture)
	gr.clearScreen(0,0,0,0)

	--find out which frame to draw
	--progress is between 0 and 1

	local index = 1

	if ScpuiSystem.data.memory.loading_bar.LoopLoadBar then
		-- Get the last frame or start at 1
		index = ScpuiSystem.data.memory.loading_bar.LastProgress or 1

		-- Loop back to the first frame if we exceed the total frame count
		if index > ScpuiSystem.data.memory.loading_bar.ImageTexture:getFramesLeft() then
			index = 1
		end

		-- Store the updated frame index
		ScpuiSystem.data.memory.loading_bar.LastProgress = index + 1
	elseif ScpuiSystem.data.memory.loading_bar.ImageTexture:getFramesLeft() then
		if not ScpuiSystem.data.memory.loading_bar.LastProgress or ScpuiSystem.data.memory.loading_bar.LastProgress < (ScpuiSystem.data.memory.loading_bar.LoadProgress * ScpuiSystem.data.memory.loading_bar.ImageTexture:getFramesLeft()) then
			index = math.floor(ScpuiSystem.data.memory.loading_bar.LoadProgress * ScpuiSystem.data.memory.loading_bar.ImageTexture:getFramesLeft())
			ScpuiSystem.data.memory.loading_bar.LastProgress = index
		else
			index = ScpuiSystem.data.memory.loading_bar.LastProgress
		end

		if index == 0 then index = 1 end
	end

	--then draw the loading bar
	if ScpuiSystem.data.memory.loading_bar.ImageTexture and ScpuiSystem.data.memory.loading_bar.ImageTexture:isValid() then
		gr.drawImage(ScpuiSystem.data.memory.loading_bar.ImageTexture[index], 0, 0)
	end

	gr.setTarget()
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function LoadScreenController:global_keydown(element, event)
	--- Loading screen has no keydown events
end

--- Called when the screen is being unloaded
--- @return nil
function LoadScreenController:unload()
	ScpuiSystem.data.memory.loading_bar.ImageTexture:unload()
	ScpuiSystem.data.memory.loading_bar.ImageTexture:destroyRenderTarget()
	ScpuiSystem.data.memory.loading_bar.ImageTexture = nil
	ScpuiSystem.data.memory.loading_bar.Texture:unload()
	ScpuiSystem.data.memory.loading_bar.Texture:destroyRenderTarget()
	ScpuiSystem.data.memory.loading_bar.Texture = nil
	ScpuiSystem.data.memory.loading_bar.Url = nil
	ScpuiSystem.data.memory.loading_bar = {}

	Topics.loadscreen.unload:send(self)
end

--- For each load screen frame, set and draw the loading bar
ScpuiSystem:addHook("On Load Screen", function()
	if ScpuiSystem.data.LoadDoc ~= nil then
		LoadScreenController:setLoadingBar()
	end
end)

return LoadScreenController
