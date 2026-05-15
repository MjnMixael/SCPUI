-----------------------------------
--Controller for the Loading Screen UI
-----------------------------------

local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

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

	local mission_stem = mn.getMissionFilename():gsub('%.fs2$', '')

	---First set a generic bg
	self.Document:GetElementById("main_background"):SetClass("loadscreen_default", true)
	---Then try to set it using the mission filename
	self.Document:GetElementById("main_background"):SetClass(mission_stem, true)
	---Allow a Topic listener (e.g., the table-driven default) to replace it with a different class,
	---enabling random selection from a list or other per-mission strategies.
	local bg_class_override = Topics.loadscreen.bg_class:send(mission_stem)
	if bg_class_override then
		self.Document:GetElementById("main_background"):SetClass(mission_stem, false)
		self.Document:GetElementById("main_background"):SetClass(bg_class_override, true)
	end

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	local title_el = self.Document:GetElementById("title")
	title_el.inner_rml = mn.getMissionTitle()

	---Allow per-mission overrides for the title font/origin/offset/justify.
	local title_style = Topics.loadscreen.title_style:send(mission_stem)
	if title_style then
		if title_style.FontClass and title_style.FontClass ~= "" then
			title_el:SetClass("p2", false)
			title_el:SetClass(title_style.FontClass, true)
		end
		if title_style.Origin then
			title_el.style.left = tostring((title_style.Origin.x or 0) * 100) .. "%"
			title_el.style.top = tostring((title_style.Origin.y or 0) * 100) .. "%"
		end
		if title_style.Offset then
			title_el.style["margin-left"] = tostring(title_style.Offset.x or 0) .. "px"
			title_el.style["margin-top"] = tostring(title_style.Offset.y or 0) .. "px"
		end
		if title_style.Justify then
			title_el.style["text-align"] = title_style.Justify
			title_el.style.width = "auto"
		end
	end

	---Populate the tip element if a Topic listener provides one.
	local tip = Topics.loadscreen.tip_text:send(mission_stem)
	local tip_el = self.Document:GetElementById("loadscreen_tip")
	if tip and tip.Text and tip.Text ~= "" then
		tip_el.inner_rml = tip.Text
		tip_el.style.display = "block"
		if tip.FontClass and tip.FontClass ~= "" then
			tip_el:SetClass(tip.FontClass, true)
		end
		if tip.Color then
			local c = tip.Color
			tip_el.style["color"] = Utils.rgbaToHex(c[1] or 255, c[2] or 255, c[3] or 255, c[4] or 255)
		end
		if tip.Origin then
			tip_el.style.left = tostring((tip.Origin.x or 0) * 100) .. "%"
			tip_el.style.top = tostring((tip.Origin.y or 0) * 100) .. "%"
		end
		if tip.Offset then
			tip_el.style["margin-left"] = tostring(tip.Offset.x or 0) .. "px"
			tip_el.style["margin-top"] = tostring(tip.Offset.y or 0) .. "px"
		end
		if tip.Width then
			tip_el.style.width = tostring(tip.Width) .. "px"
		end
	end

	if not ScpuiSystem.data.memory.loading_bar.LoadProgress then
		ScpuiSystem.data.memory.loading_bar.LoadProgress = 0
	end

	local load_img = Topics.loadscreen.load_bar:send(mission_stem)
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

		local frames_left = ScpuiSystem.data.memory.loading_bar.ImageTexture:getFramesLeft() or 0

		-- Loop back to the first frame if we exceed the total frame count
		if index > frames_left then
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
