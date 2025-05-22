-----------------------------------
--Controller for the System Map UI
-----------------------------------

local AsyncUtil = require("lib_async")
local Md = require("debugFunctions")
local SysMapUtils = require('lib_sysmap_utils')
local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local SystemMapController = Class()

--- @type SysmapUi
local SysmapUi = ScpuiSystem.extensions.SysmapUi

--- Called by the class constructor
--- @return nil
function SystemMapController:init()
	self.Document = nil ---@type Document the RML document

	self.MouseData = {
		Mx = 0, ---@type number the mouse x position
		My = 0, ---@type number the mouse y position
		Threshold = 25, ---@type number the threshold for scrolling
		Speed = 7, ---@type number the speed of scrolling
		Active = false ---@type boolean whether the mouse is active
	}

	self.Scale = 1 ---@type number the scale factor for the system map
	self.CloseupActive = false ---@type boolean whether the closeup is active
	self.MouseScrollDisabled = false ---@type boolean whether mouse scrolling is disabled
	self.ZoomLevel = 0 ---@type number the zoom level
	self.FocalWidth = 0.5 ---@type number the focal width
	self.FocalHeight = 0.5 ---@type number the focal height
	self.DoScale = nil ---@type boolean whether to zoom
	self.Url = nil ---@type string the url for the texture to pass to librocket
	self.Drag = nil ---@type table the drag data

	self.CurrentSystem = nil ---@type sysmap_entry the current system
	self.Objects = nil ---@type sysmap_object[] the objects
	self.Config = nil ---@type sysmap_campaign_config the config file data for the campaign
	self.Systems = nil ---@type sysmap_entry[] the systems
	self.MainMapElement = nil ---@type Element the main map element
	self.BackButtonElement = nil ---@type Element the back button element
	self.SystemNameElement = nil ---@type Element the name element
	self.ObjectDescriptionElement = nil ---@type Element the description element
	self.BackgroundTexture = nil ---@type texture the texture

end

--- Called by the RML document
--- @param document Document
function SystemMapController:initialize(document)
    self.Document = document
	ScpuiSystem.SystemMapContext = self

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.MainMapElement = self.Document:GetElementById("map")
	self.BackButtonElement = self.Document:GetElementById("top_panel_wrapper")

	self.Document:GetElementById("closeup_container").style.ultrawide = "false"

	self:doInitialLoad()

	Topics.systemmap.initialize:send(self)

end

--- Load the object data and then try to load a system
--- @return nil
function SystemMapController:doInitialLoad()

	local data = SysmapUi:loadSysMapTables()

	self.Objects = data.Objects

	self:LoadConfig(data)

	self:loadNewSystem(self:autoLoadSystem())

	--hide the closeup div by default
	self.Document:GetElementById("closeup_container"):SetClass("hidden", true)

end


--- load the config file based on the current campaign
--- @param data sysmap_data the data to load
--- @return nil
function SystemMapController:LoadConfig(data)

	self.Config = data.Configs[ba.getCurrentPlayer():getCampaignFilename()]
	if self.Config == nil then
		Md.warning("No config data found for campaign " .. ba.getCurrentPlayer():getCampaignFilename())
		self.Systems = {}
		return
	end
	self.Systems = data.Systems

end

--- Function to calculate the scale factor
--- @param screen_width number the width of the screen
--- @param image_width number the width of the image
--- @return number scale the scale factor
function SystemMapController:calculateScaleFactor(screen_width, image_width)
    --Ensure both inputs are positive numbers
    if screen_width <= 0 or image_width <= 0 then
		ba.warning("Screen width or image with was <= 0! Using scale factor of 1!")
        return 1
    end

    local scale_factor = screen_width / image_width

	--Add 7 percent because they are designed as 2048w images on a 1920w screen
	--which is basically 7% bigger than the screen. This ensures the way these are designed
	--is recreated on all screen sizes very closely.
    return scale_factor * 1.07
end

--- Load a new system. This is the money right here. It does it all.
--- @param system_name string|nil the name of the system to load
--- @param scale_only boolean|nil TWhether or not to only scale the current system
--- @return nil
function SystemMapController:loadNewSystem(system_name, scale_only)

	self.MouseScrollDisabled = false

	if system_name and self.Systems[system_name] then

		--first we try to clean up
		if self.BackgroundTexture ~= nil then
			self:cleanupBackground()
		end

		Md.printAlways("System Viewer loading system " .. system_name)

		if not scale_only then
			self.FocalWidth = 0.5
			self.FocalHeight = 0.5
			self.DoScale = nil
		end

		self.CurrentSystem = self.Systems[system_name]
		self.CurrentSystem.Key = system_name

		--Get the system size
		local sys_w = gr.getImageWidth(self.CurrentSystem.Background)
		local sys_h = gr.getImageHeight(self.CurrentSystem.Background)

		--Get the screen size
		local screen_w = gr.getCenterWidth()
		local screen_h = gr.getCenterHeight()

		--Get the scale factor
		if screen_w > screen_h then
			self.Scale = self:calculateScaleFactor(screen_w, sys_w) + self.ZoomLevel
		else
			self.Scale = self:calculateScaleFactor(screen_h, sys_h) + self.ZoomLevel
		end

		--Get important information about the background (and by extension the view)
		self.CurrentSystem.Width = sys_w * self.Scale
		self.CurrentSystem.Height = sys_h * self.Scale

		self.BackgroundTexture = gr.createTexture(self.CurrentSystem.Width, self.CurrentSystem.Height)
		self.Url = ui.linkTexture(self.BackgroundTexture)

		--Initialize any data
		self:initializeObjectData(self.CurrentSystem.Elements)

		--Set the background and titles
		self:setupSystem()

		--Generate the icon buttons
		self:GenerateIconButtons(self.CurrentSystem.Elements)

		--Handle the Back button
		if self.CurrentSystem.ZoomOutTo then
			self.BackButtonElement:SetClass("hidden", false)
		else
			self.BackButtonElement:SetClass("hidden", true)
		end

	else
		Md.warning("No system with name " .. system_name .. " was found!")
		local map_el = self.Document:CreateElement("div")
		map_el.inner_rml = Utils.xstr("No System Loaded", -1)
		map_el.id = "no_system_warning"
		self.MainMapElement:AppendChild(map_el)
		self.BackButtonElement:SetClass("hidden", true)
	end

end

--- Look through the config file stuff to see what we should load, first by mission name, then by "Default", if nothing then its nil
--- @return string system the name of the system to load
function SystemMapController:autoLoadSystem()

	local system_name
	local mission_name

	--Get current mission
	local old_state = ""
	if hv.OldState ~= nil then
		old_state = hv.OldState.Name
	end
	if mn.getMissionFilename() ~= "" and old_state ~= "GS_STATE_MAIN_MENU" then
		mission_name = mn.getMissionFilename() .. ".fs2"
	else
		mission_name = ca.getNextMissionFilename()
	end

	if mission_name ~= nil then
		Md.print("System Viewer detected next mission as " .. mission_name)
	else
		--It's possible to get here at the end of the campaign.. so for BtA, let's check if that's the case
        --If so we'll force load the last map because we're cool like that
        local previous_mission = ca.getPrevMissionFilename()
        if string.sub(previous_mission, -9) == "m4_01.fs2" then
            mission_name = previous_mission
            Md.print("System Viewer detected next mission as " .. mission_name)
        else
            Md.print("System Viewer could not detect the next mission. Loading default!")
        end
	end

	--Find a match
	if mission_name ~= "" then
		for key, value in pairs(self.Config) do
			if mission_name == key then
				system_name = value
			end
		end
	end

	--Or just default
	if not system_name and self.Config.Default then
		system_name = self.Config.Default
	end

	return system_name

end

--- Iterates through all map objects and sets up any data that's necessary
--- @param iconTable sysmap_element[] the table of objects to initialize
--- @return nil
function SystemMapController:initializeObjectData(iconTable)
	for _, value in pairs(iconTable) do

		--Do we have any visibility override data?
		local vis = SysMapUtils:getIconVisibility(value.ObjectName)

		if vis ~= nil then
			value.Visible = vis
		end

		if value.ZoomTo then
			value.Seen = not SysMapUtils:checkNew(value.ZoomTo)
		else
			if value.ShowNew == true or value.ShowNewPersist == true then
				value.Seen = SysMapUtils:getIconSeen(self.CurrentSystem.Key, value)
			else
				value.Seen = true
			end
		end

		--Do we have object data? If so use that.
		if self.Objects ~= nil then
			if value.ObjectName then
				local obj = self.Objects[value.ObjectName]

				if obj ~= nil then
					value.Name = obj.Name
					value.Bitmap = obj.Bitmap
					value.LargeBitmap = obj.LargeBitmap
					value.ShipClass = obj.ShipClass
					value.Description = obj.Description
					value.UseTechDescription = obj.UseTechDescription
				end
			end
		end

		--Do we have an icon override? If so use that.
		if value.IconOverride then
			value.Bitmap = value.IconOverride
		end

		--Same for name override
		if value.NameOverride then
			value.Name = value.NameOverride
		end

		--Do we have a parent orbit? We should intialize it even if we don't.
		if not value.ParentOrbit then
			value.ParentOrbit = {
				Distance = nil,
				Angle = nil
			}
		end

		--Specify a parent orbit
		if value.Orbits then
			value.ParentOrbit.Distance = iconTable[value.Orbits].Orbit.Distance
			value.ParentOrbit.Angle = iconTable[value.Orbits].Orbit.Angle
		end

		--If orbit is missing, we should slap in some dumb settings
		if not value.Orbit then
			value.Orbit = {}
			value.Orbit.Distance = 0
			value.Orbit.Angle = 0
		end

		if not value.Orbit.Color then --If there's no color set up, make one
			value.Orbit.Color = {128, 128, 128, 255}
		end

		--Same here
		if not value.Offset then
			value.Offset = {
				X = 0,
				Y = 0
			}
		end
	end
end

--- Set up the system map by creating the background and setting the titles
--- @return nil
function SystemMapController:setupSystem()

	--Set the background
	self:updateBackground()

	local mapEl = self.Document:CreateElement("img")
	mapEl:SetAttribute("src", self.Url)
	self.MainMapElement:AppendChild(mapEl)

	self.totalWidth = self.CurrentSystem.Width - gr.getCenterWidth()
	self.totalHeight = self.CurrentSystem.Height - gr.getScreenHeight()

	self.MainMapElement.scroll_left = self.totalWidth * self.FocalWidth
	self.MainMapElement.scroll_top = self.totalHeight * self.FocalHeight

	local title_el = self.Document:GetElementById("system_title")

	--clean out any old titles
	while title_el:HasChildNodes() do
		title_el:RemoveChild(title_el.first_child)
	end

	--create new titles
	self.SystemNameElement = self.Document:CreateElement("p")
	self.ObjectDescriptionElement = self.Document:CreateElement("p")

	self.SystemNameElement.inner_rml = self.CurrentSystem.Name
	self.ObjectDescriptionElement.inner_rml = self.CurrentSystem.Description
	self.ObjectDescriptionElement:SetClass("title_desc", true)

	self.SystemNameElement:SetClass("h1", true)
	self.ObjectDescriptionElement:SetClass("p2", true)

	title_el:AppendChild(self.SystemNameElement)
	title_el:AppendChild(self.ObjectDescriptionElement)

end

--- Update the background texture
--- @return nil
function SystemMapController:updateBackground()

	gr.setTarget(self.BackgroundTexture)

	gr.clearScreen(0,0,0,255)
	gr.drawImage(self.CurrentSystem.Background, 0, 0, self.CurrentSystem.Width, self.CurrentSystem.Height)

	self:drawOrbits()

	gr.setTarget()

end

--- Clean up the background elements and texture
function SystemMapController:cleanupBackground()

	while self.MainMapElement:HasChildNodes() do
		self.MainMapElement:RemoveChild(self.MainMapElement.first_child)
	end

	self.BackgroundTexture:unload()
	self.BackgroundTexture = nil

end

--- Draw the orbits of the system to the background texture
--- @return nil
function SystemMapController:drawOrbits()
	--Draw all the orbits first, sure its an additional for loop but it prevents bad drawing
	for key, value in pairs(self.CurrentSystem.Elements) do
		if value.ShowOrbit and value.Visible then

			--Let's set the color and width
			if value.Orbit.Color == nil then
				value.Orbit.Color = {128, 128, 128, 255}
			end
			if value.Orbit.Width == nil then
				value.Orbit.Width = 3
			end
			gr.setColor(value.Orbit.Color[1], value.Orbit.Color[2], value.Orbit.Color[3], value.Orbit.Color[4])
			gr.setLineWidth(value.Orbit.Width)

			--Is the center in the middle of the system or...
			local x, y = self.CurrentSystem.Width/2, self.CurrentSystem.Height/2

			--Do we have a parent orbit?
			if value.ParentOrbit then
				if value.ParentOrbit.Distance and value.ParentOrbit.Angle then
					x, y = self:polarToCoords(value.ParentOrbit.Distance * self.Scale, value.ParentOrbit.Angle, nil, nil)
				end
			end

			gr.drawCircle(value.Orbit.Distance * self.Scale, x, y, false)
			gr.setLineWidth(1)

		end
	end
end

--- Convert polar coordinates to rectangular coordinates. By default uses the middle of the background as an origin point.
--- @param r number the radius
--- @param theta number the angle in degrees
--- @param origin_x number? the x origin point
--- @param origin_y number? the y origin point
--- @return number, number result the x and y coordinates
function SystemMapController:polarToCoords(r, theta, origin_x, origin_y)

	theta = math.rad(theta)

	if not origin_x or not origin_y then
		origin_x = self.CurrentSystem.Width/2
		origin_y = self.CurrentSystem.Height/2
	end

	local x, y = (r * math.cos(theta)) + origin_x, (r * math.sin(theta)) + origin_y

	return x, y

end

--- Sets coordinates for a button according to its specified polar coordinates
--- @param button sysmap_element the button to set up
--- @return nil
function SystemMapController:SetupButton(button)

	local px, py = nil, nil

	--If we have a parent orbit, calculate its coordinates first
	if button.ParentOrbit.Distance and button.ParentOrbit.Angle then
		px, py = self:polarToCoords(button.ParentOrbit.Distance * self.Scale, button.ParentOrbit.Angle, nil, nil)
	end

	--Its ok if px and py are nil. Don't worry, I'm a doctor.
	local x, y = self:polarToCoords(button.Orbit.Distance * self.Scale, button.Orbit.Angle, px, py)

	--Set up the bitmap and text positions
	button.BitmapX = x - ((gr.getImageWidth(button.Bitmap)/2) * self.Scale) + (button.Offset.X * self.Scale)
	button.BitmapY = y - ((gr.getImageHeight(button.Bitmap)/2) * self.Scale)  + (button.Offset.Y * self.Scale)

end

--- Look through the Icons Table and generate buttons
--- @param iconTable sysmap_element[] the table of icons to generate
--- @return nil
function SystemMapController:GenerateIconButtons(iconTable)

	local parent_el = self.MainMapElement

	for key, value in pairs(iconTable) do

		if value.Visible then

			local button_el = nil
			if value.Selectable then
				button_el = self.Document:CreateElement("button")
				button_el:SetClass("button_1", true)
			else
				button_el = self.Document:CreateElement("div")
			end
			button_el:SetClass("icon", true)
			button_el:SetClass("icon_button", true)

			local span_el = self.Document:CreateElement("span")
			span_el:SetClass("icon", true)

			local img_el = self.Document:CreateElement("img")
			img_el:SetClass("pseudo_img", true)
			if not value.Bitmap then
				ba.warning("Icon '" .. value.ObjectName .. "' has no bitmap defined!")
			end
			img_el:SetAttribute("src", value.Bitmap)
			img_el.style.width = math.floor(gr.getImageWidth(value.Bitmap) * self.Scale) .. "px"

			local seen_el = nil
			if value.Seen == false then
				seen_el = self.Document:CreateElement("div")
				seen_el:SetClass("icon", true)
				seen_el:SetClass("exclamation", true)

				local seen_img_el = self.Document:CreateElement("img")
				seen_img_el:SetClass("pseudo_img", true)
				seen_img_el:SetAttribute("src", "nav_new.png")
				seen_img_el.style.width = math.floor(gr.getImageWidth("nav_new.png") * self.Scale) .. "px"

				seen_el:AppendChild(seen_img_el)

				value.SeenElement = seen_el
			end

			span_el:AppendChild(img_el)
			button_el:AppendChild(span_el)
			parent_el:AppendChild(button_el)

			if seen_el ~= nil then
				button_el:AppendChild(seen_el)
			end

			if value.Selectable then

				button_el:AddEventListener("mouseover", function(_, _, _)
					img_el:SetAttribute("src", value.Bitmap .. "_h")
				end)

				button_el:AddEventListener("mouseout", function(_, _, _)
					img_el:SetAttribute("src", value.Bitmap)
				end)

				button_el:AddEventListener("mousedown", function(_, _, _)
					img_el:SetAttribute("src", value.Bitmap .. "_c")
				end)

				button_el:AddEventListener("mouseup", function(_, _, _)
					img_el:SetAttribute("src", value.Bitmap .. "_h")
				end)

				button_el:AddEventListener("click", function(_, _, _)
					self:displayObjectInfo(value)
				end)

				button_el:SetClass("select", true)

			else
				button_el:SetClass("noselect", true)
				if value.ShowNew == true or value.ShowNewPersist == true then
					SysMapUtils:setIconSeen(self.CurrentSystem.Key, value, true)
				end
			end

			--Set the text
			value.Text = value.Name or ""

			local text_el = self.Document:CreateElement("span")
			text_el:SetClass("button_text_bottom", true)
			text_el:SetClass("pos", true)
			text_el:SetClass("icon_text", true)
			text_el.inner_rml = "<p>" .. value.Text .. "</p>"
			button_el:AppendChild(text_el)

			--Setup the button position
			self:SetupButton(value)
			button_el.style.top = value.BitmapY .. "px"
			button_el.style.left = value.BitmapX .. "px"
			button_el.style.width = math.floor(gr.getImageWidth(value.Bitmap) * self.Scale) .. "px"
		end
	end

end

--- Display a large image, across the entire screen and centered
--- @param object sysmap_element the object to display
--- @return nil
function SystemMapController:displayObjectInfo(object)

	local closeup_el = self.Document:GetElementById("closeup_container")

	if object == nil then
		return
	end

	closeup_el:SetClass("hidden", false)

	self.CloseupActive = true

	--create the visible object
	local object_el = self.Document:GetElementById("object_view")

	if object.LargeBitmap then
		local img_el = self.Document:CreateElement("img")
		img_el:SetAttribute("src", object.LargeBitmap)
		object_el:AppendChild(img_el)
	elseif object.ShipClass then
		ScpuiSystem.SysMap = {}

		ScpuiSystem.SysMap.Ship = object.ShipClass

		if object.ModelOrientation then
			ScpuiSystem.SysMap.TechModelOri = ba.createOrientation(math.rad(object.ModelOrientation[1]),math.rad(object.ModelOrientation[2]), math.rad(object.ModelOrientation[3]))
		else
			ScpuiSystem.SysMap.TechModelOri = ba.createOrientation(0.3,0,math.pi)
		end

		if object.RotationSpeed then
			ScpuiSystem.SysMap.RotationRate = math.rad(object.RotationSpeed)
		else
			ScpuiSystem.SysMap.RotationRate = 0.5
		end

		if object.ZoomLevel then
			ScpuiSystem.SysMap.z = object.ZoomLevel
		else
			ScpuiSystem.SysMap.z = 0.8
		end

		ScpuiSystem.SysMap.ObjectElement = object_el
	end


	--Maybe show the zoom in button
	local zoom_el = self.Document:GetElementById("zoom_panel")
	if object.ZoomTo then
		zoom_el:SetClass("hidden", false)
		self.ZoomInTo = object.ZoomTo
	else
		zoom_el:SetClass("hidden", true)
	end

	--Now set the description text
	local desc_el = self.Document:GetElementById("desc_text_wrapper")

	local text = nil
	if object.UseTechDescription == true then
		text = string.upper(object.Name) .. ": " .. tb.ShipClasses[object.ShipClass].TechDescription
	else
		text = object.Description or ""
	end

	desc_el.inner_rml = text
	desc_el.scroll_top = 0

	if object.Seen == false then
		if not object.ZoomTo then
			SysMapUtils:setIconSeen(self.CurrentSystem.Key, object, true)
			object.SeenElement.inner_rml = ""
		end
	end

end

--- Close the object info
--- @return nil
function SystemMapController:closeObjectInfo()

	if self.CloseupActive == false then
		return
	end

	local closeup_el = self.Document:GetElementById("closeup_container")

	--clear the object info
	self.ZoomInTo = nil
	local desc_el = self.Document:GetElementById("desc_text_wrapper")
	desc_el.inner_rml = ""
	local object_el = self.Document:GetElementById("object_view")
	while object_el:HasChildNodes() do
		object_el:RemoveChild(object_el.first_child)
	end

	ScpuiSystem.SysMap = nil

	--hide the closeup container
	closeup_el:SetClass("hidden", true)

	self.CloseupActive = false

end

--- Called by the RML when the close button is pressed
--- @param element Element the element that was pressed
--- @return nil
function SystemMapController:close_pressed(element)
	self:closeObjectInfo()
end

--- Called by the RML when the zoom button is pressed
--- @param element Element the element that was pressed
--- @return nil
function SystemMapController:zoom_pressed(element)

	if self.ZoomInTo ~= nil then

		local zoom = self.ZoomInTo

		self:closeObjectInfo()

		self:loadNewSystem(zoom)
	end

end

--- Reload the system map entirely
--- @return nil
function SystemMapController:reload()
	self:closeObjectInfo()
	self:doInitialLoad()
end

--- Called by the RML when the back button is pressed
--- @param element Element the element that was pressed
--- @return nil
function SystemMapController:back_pressed(element)
	self:closeObjectInfo()
	self:loadNewSystem(self.CurrentSystem.ZoomOutTo)
end

--- Called by the RML when the accept button is pressed
--- @param element Element the element that was pressed
--- @return nil
function SystemMapController:accept_pressed(element)
    ui.playElementSound(element, "click", "success")
	self:exit()
end

--- Scroll the map up
--- @return nil
function SystemMapController:scrollUp()
	if self.CloseupActive == true then
		return
	end
	self.MainMapElement.scroll_top = self.MainMapElement.scroll_top - self.MouseData.Speed
end

--- Scroll the map down
--- @return nil
function SystemMapController:scrollDown()
	if self.CloseupActive == true then
		return
	end
	self.MainMapElement.scroll_top = self.MainMapElement.scroll_top + self.MouseData.Speed
end

--- Scroll the map left
--- @return nil
function SystemMapController:scrollLeft()
	if self.CloseupActive == true then
		return
	end
	self.MainMapElement.scroll_left = self.MainMapElement.scroll_left - self.MouseData.Speed
end

--- Scroll the map right
--- @return nil
function SystemMapController:scrollRight()
	if self.CloseupActive == true then
		return
	end
	self.MainMapElement.scroll_left = self.MainMapElement.scroll_left + self.MouseData.Speed
end

--- Check the mouse position and scroll if necessary. Runs every 0.01 seconds
--- @return nil
function SystemMapController:checkMouse()

	--Mouse scrolling is disabled if the mouse is over the Back button.
	if self.MouseScrollDisabled == false then
		if self.MouseData.Mx <= self.MouseData.Threshold then
			self:scrollLeft()
		end

		if self.MouseData.Mx >= gr.getCenterWidth() - self.MouseData.Threshold then
			self:scrollRight()
		end

		if self.MouseData.My <= self.MouseData.Threshold then
			self:scrollUp()
		end

		if self.MouseData.My >= gr.getScreenHeight() - self.MouseData.Threshold then
			self:scrollDown()
		end
	end

	async.run(function()
        async.await(AsyncUtil.wait_for(0.01))
        self:checkMouse()
    end, async.OnFrameExecutor)

end

--- Toggle mouse scrolling on or off
--- @param val boolean whether to disable mouse scrolling
--- @return nil
function SystemMapController:toggle_mouse_scroll(val)
	self.MouseScrollDisabled = val
end

--- Whenever the mouse moves over the map, grab the coordinates and maybe move the map
--- @param element Element the element that was moved
--- @param event Event the event that was triggered
--- @return nil
function SystemMapController:mouse_move(element, event)
	if self.Drag ~= nil then

		local xdiff = self.Drag.x - event.parameters.mouse_x
		local ydiff = self.Drag.y - event.parameters.mouse_y

		self.MainMapElement.scroll_left = self.MainMapElement.scroll_left + xdiff
		self.MainMapElement.scroll_top = self.MainMapElement.scroll_top + ydiff

		self.Drag = {
			x = event.parameters.mouse_x,
			y = event.parameters.mouse_y
		}
	else

		self.MouseData.Mx = event.parameters.mouse_x
		self.MouseData.My = event.parameters.mouse_y

		if not self.MouseData.Active then
			self:checkMouse()
			self.MouseData.Active = true
		end

	end

end

--- Handle whenever the mouse wheel is scrolled
--- @param element Element the element that was scrolled
--- @param event Event the event that was triggered
--- @return nil
function SystemMapController:mouse_scroll(element, event)
	if self.CloseupActive == true then return end
	if event.parameters.wheel_delta < 0 then
		self.ZoomLevel = self.ZoomLevel + 0.02
		if self.ZoomLevel > 0.7 then
			self.ZoomLevel = 0.7
		else
			self.FocalWidth = self.MainMapElement.scroll_left / self.totalWidth
			self.FocalHeight = self.MainMapElement.scroll_top / self.totalHeight
		end
	else
		self.ZoomLevel = self.ZoomLevel - 0.02
		if self.ZoomLevel < -0.04 then
			self.ZoomLevel = -0.04
		else
			self.FocalWidth = self.MainMapElement.scroll_left / self.totalWidth
			self.FocalHeight = self.MainMapElement.scroll_top / self.totalHeight
		end
	end
	self:loadNewSystem(self.CurrentSystem.Key, true)
end

--- Handle whenever the mouse is clicked on the map
--- @param element Element the element that was clicked
--- @param event Event the event that was triggered
--- @return nil
function SystemMapController:mouse_down(element, event)
	if self.CloseupActive == true then return end
	self.Drag = {
		x = event.parameters.mouse_x,
		y = event.parameters.mouse_y
	}
end

--- Handle whenever the mouse is released on the map
--- @param element Element the element that was released
--- @param event Event the event that was triggered
--- @return nil
function SystemMapController:mouse_up(element, event)
	self.Drag = nil
end

--- Exit the system map and cleanup
--- @return nil
function SystemMapController:exit()
	ScpuiSystem:returnToState(ScpuiSystem.data.LastState)
	if self.BackgroundTexture ~= nil then
		self.BackgroundTexture:destroyRenderTarget()
		self.BackgroundTexture:unload()
	end
	self.Document:Close()
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function SystemMapController:global_keydown(element, event)
	if not Topics.systemmap.keydown:send(event) then
		if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
			if self.CloseupActive == true then
				self:closeObjectInfo()
			elseif self.CurrentSystem ~= nil then
				if self.CurrentSystem.ZoomOutTo then
					self:closeObjectInfo()
					self:loadNewSystem(self.CurrentSystem.ZoomOutTo)
				else
					event:StopPropagation()
					self:exit()
				end
			else
				event:StopPropagation()
				self:exit()
			end
		elseif event.parameters.key_identifier == rocket.key_identifier.UP then
			self:scrollUp()
		elseif event.parameters.key_identifier == rocket.key_identifier.DOWN then
			self:scrollDown()
		elseif event.parameters.key_identifier == rocket.key_identifier.LEFT then
			self:scrollLeft()
		elseif event.parameters.key_identifier == rocket.key_identifier.RIGHT then
			self:scrollRight()
		elseif event.parameters.key_identifier == rocket.key_identifier.P and event.parameters.ctrl_key == 1 and event.parameters.shift_key == 1 then
			self:reload()
		elseif event.parameters.key_identifier == rocket.key_identifier.Z then
			if event.parameters.shift_key == 1 then
				self.ZoomLevel = self.ZoomLevel + 0.02
				if self.ZoomLevel > 0.7 then
					self.ZoomLevel = 0.7
				else
					self.FocalWidth = self.MainMapElement.scroll_left / self.totalWidth
					self.FocalHeight = self.MainMapElement.scroll_top / self.totalHeight
					self:loadNewSystem(self.CurrentSystem.Key, true)
				end
			else
				self.ZoomLevel = self.ZoomLevel - 0.02
				if self.ZoomLevel < -0.04 then
					self.ZoomLevel = -0.04
				else
					self:loadNewSystem(self.CurrentSystem.Key, true)
				end
			end
		end
	end
end

--- Draw the model on the screen every frame if closeup is active and the object has a model
--- @return nil
function SystemMapController:drawModel()

	if ScpuiSystem.SysMap ~= nil then
		local thisShipClass = tb.ShipClasses[ScpuiSystem.SysMap.Ship]

		ScpuiSystem.SysMap.TechModelOri = SystemMapController:changeTechModelOrientation(ScpuiSystem.SysMap.TechModelOri)

		local object_el = ScpuiSystem.SysMap.ObjectElement

		local x = ScpuiSystem:getAbsoluteLeft(object_el)
		local y = ScpuiSystem:getAbsoluteTop(object_el)
		local w = object_el.offset_width
		local h = object_el.offset_height

		thisShipClass:renderTechModel2(x, y, x + w, y + h, ScpuiSystem.SysMap.TechModelOri, ScpuiSystem.SysMap.z)
	end
end

--- And here's where we change the rotation
--- @param orientation orientation the current orientation
--- @return orientation value the new orientation
function SystemMapController:changeTechModelOrientation(orientation)

	return ba.createOrientation(orientation.p, orientation.b, orientation.h + (ba.getRealFrametime() * ScpuiSystem.SysMap.RotationRate * -1))

end

--- Run all the frame functions
--- @return nil
function SystemMapController:unload()
	ScpuiSystem.SystemMapContext = nil
	ScpuiSystem.SysMap = nil
	ScpuiSystem:freeAllModels()

	Topics.systemmap.unload:send(self)
end

ScpuiSystem:addHook("On Frame", function()
	if ScpuiSystem.SystemMapContext then
		if ScpuiSystem.data.Substate == "SystemMap" then
			ScpuiSystem.SystemMapContext:drawModel()
		end
	end
end, {State="GS_STATE_SCRIPTING"})

return SystemMapController
