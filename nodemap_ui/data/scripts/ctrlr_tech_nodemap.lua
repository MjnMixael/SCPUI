-----------------------------------
--Controller for the Node Map UI
-----------------------------------

local DataSaver = require("lib_data_saver")
local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local TechNodeMapController = Class()

--- @type NodemapUi
local NodemapUi = ScpuiSystem.extensions.NodemapUi

--- Called by the class constructor
--- @return nil
function TechNodeMapController:init()
	self.Document = nil ---@type Document the RML document
	self.HelpShown = false ---@type boolean whether the help text is shown
	self.Nodes = {} ---@type node_map_line[] the lines between nodes
	self.Scale = 1 ---@type number the scale factor to fit the map on the screen
	self.Selected = "No Selection" ---@type string the currently selected node
	self.SelectedNodeBtn = nil ---@type Element the currently selected node button
	self.Width = 0 ---@type number the width of the map
	self.Height = 0 ---@type number the height of the map
	self.DrawLines = true ---@type boolean whether to draw lines between nodes
	self.LineWidth = 1.0 ---@type number the width of the node lines
	self.NodeDiameter = 4 ---@type number the diameter of the nodes
	self.SaveData = {} ---@type table<string, number> the save data for the nodes
	self.ShowAll = false ---@type boolean whether to show all nodes
	self.Texture = nil ---@type texture the texture for the map to draw lines to
	self.Url = "" ---@type string the URL of the texture for the map to send to librocket
	self.Key = 0 ---@type number the key for the game progression
	self.SelectedText = "Please make a selection." ---@type string the text of the selected node
	self.MainMapElement = nil ---@type Element the main map element

	ScpuiSystem.data.memory.model_rendering = nil
end

--- Called by the RML document
--- @param document Document
function TechNodeMapController:initialize(document)
    self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.SaveData = DataSaver:loadDataFromFile("nodemap", true) or {}

	--Get the key for the game progression
	self.Key = self:getPlayerProgress()

	Topics.nodemap.initialize:send(self)

	-- After all initialization is done we can generate the map on the next frame
	async.run(function()
        async.await(async.yield())

		self.MainMapElement = self.Document:GetElementById("map_view")
		self.Width = self.MainMapElement.client_width
		self.Height = self.MainMapElement.client_height

		self.Texture = gr.createTexture(self.Width, self.Height)
		self.Url = ui.linkTexture(self.Texture)

		self.Background = "mapgrid.png"

		if ba.inDebug() then
			NodemapUi:parseTables()
		end

		--Setup all the button data
		for k, v in pairs(NodemapUi.entries) do
			self:setupButton(v)
		end

		local mapEl = self.Document:CreateElement("img")
		mapEl:SetAttribute("src", self.Url)
		self.MainMapElement:AppendChild(mapEl)

		--Get the image size
		local sys_w = gr.getImageWidth(self.Background)
		local sys_h = gr.getImageHeight(self.Background)

		--Get the screen size
		local screen_w = gr.getCenterWidth()
		local screen_h = gr.getCenterHeight()

		--Get the scale factor
		if screen_w > screen_h then
			self.Scale = self:calculateScaleFactor(screen_w, sys_w)
		else
			self.Scale = self:calculateScaleFactor(screen_h, sys_h)
		end

        self:generateIconButtons(NodemapUi.entries)

		--Set the background
		self.DrawLines = true
		self.Document:GetElementById("oval_btn"):SetPseudoClass("checked", not self.DrawLines)
		self:updateBackground()

		Topics.nodemap.postMapBuild:send(self)

    end, async.OnFrameExecutor)

end

--- Get the player's current game progress.
--- @return number progress The player's current game progress
function TechNodeMapController:getPlayerProgress()
	return Topics.nodemap.progress:send()
end

--- Called by the RML to change to a new tech room state
--- @param state number The new state to change to. Should be one of the STATE_ enumerations
--- @return nil
function TechNodeMapController:change_tech_state(state)

	if state == self.STATE_ONE then
		Topics.techroom.btn1Action:send()
	end
	if state == self.STATE_TWO then
        --This is where we are already, so don't do anything
		--topics.techroom.btn2Action:send()
	end
	if state == self.STATE_THREE then
		Topics.techroom.btn3Action:send()
	end
	if state == self.STATE_FOUR then
		Topics.techroom.btn4Action:send()
	end

end

--- Get the progression override for a given entry, if any
--- @param entry node_map_entry The entry to get the progression override for
--- @return node_map_progression|nil The progression override, or nil if none
function TechNodeMapController:getProgressionOverride(entry)
	for i, v in pairs(entry.Progression) do
		if self.Key >= v.Key then
			return v
		end
	end

	return nil
end

--- Draw the nodes and the node lines to the map texture
--- @return nil
function TechNodeMapController:drawNodes()
	for _, v in pairs(NodemapUi.entries) do
		if #v.Nodes > 0 then
			for _, node in pairs(v.Nodes) do
				local diameter = self.NodeDiameter * self.Scale

				local center_x = (v.ButtonElement.client_width / 2) + v.BitmapX
				local center_y = (v.ButtonElement.client_height / 2) + v.BitmapY

				local x, y = self:polarToCoords(20 * self.Scale, node.Angle, center_x, center_y)
				--No idea why the x coord needs adjustment to be properly centered and Y does not!
				x = x - (diameter/self.NodeDiameter)

				--Get the current values
				local new_color = gr.createColor(node.Color[1], node.Color[2], node.Color[3], 255)
				local no_line = node.NoLine
				local enforce = node.EnforceColor

				--Check for not override data
				local override = self:getProgressionOverride(v)
				if override ~= nil then
					for _, n in pairs(override.Nodes) do
						if n.Name == node.Name then
							if n.Color then
								new_color = gr.createColor(n.Color[1], n.Color[2], n.Color[3], 255)
							end
							if n.NoLine then
								no_line = n.NoLine
							end
							if n.EnforceColor then
								enforce = n.EnforceColor
							end
						end
					end
				end

				gr.setColor(new_color)
				gr.drawCircle(diameter, x, y, true)

				if not no_line then
					local pair = self:getNodePair(v.Name, node.Name)

					if pair == nil then
						---@type node_map_line
						local entry = {
							Points = {v.Name, node.Name},
							First = {x, y, new_color, enforce},
							Second = nil
						}
						table.insert(self.Nodes, entry)
					else
						if pair.Second == nil then
							pair.Second = {x, y, new_color, enforce}
						else
							ba.warning("Nodemap.tbl suggests a duplicate node pair for " .. v.Name .. ": " .. node.Name)
						end
					end
				end
			end
		end
	end
end

--- Get a node pair
--- @param first string The first node name
--- @param second string The second node name
--- @return node_map_line|nil pair The node pair, or nil if not found
function TechNodeMapController:getNodePair(first, second)
	for _, v in pairs(self.Nodes) do
		if string.lower(v.Points[1]) == string.lower(first) then
			if string.lower(v.Points[2]) == string.lower(second) then
				return v
			end
		elseif string.lower(v.Points[2]) == string.lower(first) then
			if string.lower(v.Points[1]) == string.lower(second) then
				return v
			end
		end
	end

	return nil
end

--- Get the line color for a node pair
--- @param first node_map_point The first node in the pair
--- @param second node_map_point The second node in the pair
--- @return color color The color to use for the line
function TechNodeMapController:getLineColor(first, second)
	if first[4] == true then
		return first[3]
	else
		if second[4] == true then
			return second[3]
		else
			return first[3]
		end
	end
end

--- Draw the lines between the nodes on the map texture
--- @return nil
function TechNodeMapController:drawNodeLines()
	for i, v in ipairs(self.Nodes) do
		if v.First == nil or v.Second == nil then
			--ba.warning("NodeMap UI got command to draw a node line for nodes '" .. v.Points[1] .. ":" .. v.Points[2] .. "' that has an incomplete pair! Skipping!")
		else
			local color = self:getLineColor(v.First, v.Second)
			color.Alpha = 128
			gr.setColor(color)
			gr.setLineWidth(self.LineWidth)
			gr.drawLine(v.First[1], v.First[2], v.Second[1], v.Second[2])
			gr.setLineWidth(1.0)
		end
	end
end

--- Called by the RML to toggle drawing of node lines
--- @return nil
function TechNodeMapController:toggle_node_lines()
	self.DrawLines = not self.DrawLines
	self.Nodes = {}
	self:updateBackground()
	self.Document:GetElementById("oval_btn"):SetPseudoClass("checked", not self.DrawLines)
end

--- Update the background of the map
--- @return nil
function TechNodeMapController:updateBackground()

	--save the color
	local color = gr.getColor(true)
	gr.setLineWidth(1.0)

	gr.setTarget(self.Texture)

	if Topics.nodemap.renderBackground:send(self) then
		gr.clearScreen(0,0,0,255)
		gr.drawImage(self.Background, 0, 0, self.Width, self.Height)
	end

	self:drawNodes()

	if self.DrawLines then
		self:drawNodeLines()
	end

	gr.setTarget()

	--reset the color
	gr.setColor(color)

end

--- Cleans up the map background, removing all child elements, and unloading the texture
--- @return nil
function TechNodeMapController:cleanupBackground()

	while self.MainMapElement:HasChildNodes() do
		self.MainMapElement:RemoveChild(self.MainMapElement.first_child)
	end

	self.Texture:unload()
	self.Texture = nil

end

--- Sets coordinates for a button according to its specified polar coordinates
--- @param button node_map_entry The button to set the coordinates for
--- @return nil
function TechNodeMapController:setupButton(button)

	--Convert floats to coords
	button.ConvertedX = button.X * self.Width
	button.ConvertedY = button.Y * self.Height

	--Set up the bitmap and text positions
	button.BitmapX = button.ConvertedX - ((gr.getImageWidth(button.Bitmap)/2) * self.Scale)-- + (button.Offset.X * self.scale)
	button.BitmapY = button.ConvertedY - ((gr.getImageHeight(button.Bitmap)/2) * self.Scale)--  + (button.Offset.Y * self.scale)

end

--- Format a system name to an element id
--- @param name string The name to format
--- @param suffix string The suffix to append to the formatted name
--- @return string formattedName The formatted name
function TechNodeMapController:formatNameToId(name, suffix)
	local lowerName = name:lower()
	local formattedName = lowerName:gsub("%s", "_")
	return formattedName .. suffix
end

--- Look through the Icons Table and generate buttons
--- @param iconTable node_map_entry[] The table of icons to generate buttons for
--- @return nil
function TechNodeMapController:generateIconButtons(iconTable)

	local parent_el = self.MainMapElement

	for key, value in pairs(iconTable) do

		if value.Visible then

			--Set the values
			local bitmap = value.Bitmap
			local override = self:getProgressionOverride(value)
			if override ~= nil then
				if override.Bitmap then
					bitmap = override.Bitmap
				end
			end

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
			if not bitmap then
				ba.warning("Icon '" .. value.Name .. "' has no bitmap defined!")
			end
			img_el:SetAttribute("src", bitmap)
			img_el.style.width = math.floor(gr.getImageWidth(tostring(bitmap)) * self.Scale) .. "px"

			span_el:AppendChild(img_el)
			button_el:AppendChild(span_el)
			parent_el:AppendChild(button_el)

			if not value.HideLabel then
				local text_el = self.Document:CreateElement("span")
				text_el:SetClass("button_text_bottom", true)
				text_el:SetClass("pos", true)
				text_el:SetClass("icon_text", true)
				text_el.inner_rml = "<p>" .. value.DisplayName .. "</p>"
				button_el:AppendChild(text_el)
			end

			if value.Selectable then

				button_el:AddEventListener("mouseover", function(_, _, _)
					img_el:SetAttribute("src", bitmap .. "_h")
				end)

				button_el:AddEventListener("mouseout", function(_, _, _)
					if self.Selected ~= value.Name then
						img_el:SetAttribute("src", bitmap)
					end
				end)

				button_el:AddEventListener("mousedown", function(_, _, _)
					img_el:SetAttribute("src", bitmap .. "_c")
				end)

				button_el:AddEventListener("mouseup", function(_, _, _)
					img_el:SetAttribute("src", bitmap .. "_h")
				end)

				button_el:AddEventListener("click", function(_, _, _)
					self:selectEntry(value, button_el)
				end)

				button_el:AddEventListener("dblclick", function(_, _, _)
					self:selectEntry(value, button_el)
					self:breakout_reader()
				end)

				local lastRead = self.SaveData[value.Name]

				local new_el = self.Document:CreateElement("div")
				new_el.id = self:formatNameToId(value.Name, "_new")
				new_el:SetClass("new", true)
				new_el.inner_rml = "!"
				button_el:AppendChild(new_el)
				if not lastRead or  (lastRead < self.Key and override) then
					new_el:SetClass("hidden", false)
				else
					new_el:SetClass("hidden", true)
				end

			end

			--Setup the button position
			button_el.style.top = value.BitmapY .. "px"
			button_el.style.left = value.BitmapX .. "px"
			button_el.style.width = math.floor(gr.getImageWidth(tostring(bitmap)) * self.Scale) .. "px"
			value.ButtonElement = button_el
			value.ImageElement = img_el
		end
	end

end

--- Deselect all node map buttons
--- @return nil
function TechNodeMapController:deselectAll()
	for k, v in pairs(NodemapUi.entries) do
		--Set the values
		local bitmap = v.Bitmap
		--Check for an override
		local override = self:getProgressionOverride(v)
		if override ~= nil then
			if override.Bitmap then
				bitmap = override.Bitmap
			end
		end
		v.ImageElement:SetAttribute("src", bitmap)
	end

	if self.SelectedNodeBtn ~= nil then
		self.SelectedNodeBtn:SetPseudoClass("checked", false)
	end
end

--- Select a system entry
--- @param entry node_map_entry The entry to select
--- @param button Element The button element to select
--- @return nil
function TechNodeMapController:selectEntry(entry, button)
	self.Selected = entry.Name
	self:deselectAll()
	button:SetPseudoClass("checked", true)
	self.SelectedNodeBtn = button

	self.SaveData[entry.Name] = self.Key
	DataSaver:saveDataToFile("nodemap", self.SaveData, true)

	local new_el = self.Document:GetElementById(self:formatNameToId(entry.Name, "_new"))
	new_el:SetClass("hidden", true)

	--Set the values
	local bitmap = entry.Bitmap
	local faction = entry.Faction
	local description = entry.Description

	--Check for overrides
	local override = self:getProgressionOverride(entry)
	if override ~= nil then
		if override.Bitmap then
			bitmap = override.Bitmap
		end
		if override.Faction then
			faction = override.Faction
		end
		if override.Description then
			description = override.Description
		end
	end

	if faction == "" then
		faction = Utils.xstr("Ungoverned", -1)
	end

	entry.ImageElement:SetAttribute("src", bitmap .. "_h")
	local text_name = "<span class=\"white\">System: </span>" .. entry.DisplayName .. "<br/>"
	local text_type = "<span class=\"white\">Type of System: </span>" .. entry.SysType .. "<br/>"
	local text_faction = "<span class=\"white\">Controlling Faction: </span>" .. faction .. "<br/><br/>"
	local text = "<p>" .. text_name .. text_type .. text_faction .. description .. "</p>"
	self.Document:GetElementById("map_desc").inner_rml = text
	self.Document:GetElementById("map_desc").scroll_top = 0

	--For the Read in Window option
	self.SelectedText = text_type .. text_faction .. description

	--Hide the make a selection text
	self.Document:GetElementById("make_a_selection"):SetClass("hidden", true)

	Topics.nodemap.selectEntry:send(self)
end

--- Called by the RML to show the description in a dialog box
--- @return nil
function TechNodeMapController:breakout_reader()
	local text = self.SelectedText
	local title = "<span style=\"color:white;\">" .. self.Selected .. "</span>"
	---@type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Close", 11625),
		Value = "",
		Keypress = string.sub(ba.XSTR("Close", 11625), 1, 1)
	}

	---@type dialog_setup
	local params = {
		Title = title,
		Text = text,
		Buttons = buttons,
		Input = false,
		EscapeValue = "",
		ClickEscape = true,
		BackgroundColor = "#00000080"
	}

	-- originally ran this also.. dialog:background("#00000080").. but ScpuiSystem's show dialog does not support it
	ScpuiSystem:showDialog(self, params)
end

--- Clear the description element of all text
--- @return nil
function TechNodeMapController:clearData()
	self.Document:GetElementById("tech_desc").inner_rml = "<p></p>"
end

--- Convert polar coordinates to rectangular coordinates. By default uses the middle of the background as an origin point.
--- @param r number The radius of the polar coordinates
--- @param theta number The angle of the polar coordinates
--- @param origin_x number The x coordinate of the origin point
--- @param origin_y number The y coordinate of the origin point
--- @return number, number coords The x and y coordinates of the rectangular coordinates
function TechNodeMapController:polarToCoords(r, theta, origin_x, origin_y)

	theta = math.rad(theta)

	local x, y = (r * math.cos(theta)) + origin_x, (r * math.sin(theta)) + origin_y

	return x, y

end

--- Function to calculate the scale factor
--- @param screen_width number The width of the screen
--- @param image_width number The width of the image
--- @return number scaleFactor The scale factor to use
function TechNodeMapController:calculateScaleFactor(screen_width, image_width)
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

--- Function to exit the node map screen
--- @return nil
function TechNodeMapController:exit()
	if Topics.nodemap.exit:send(self) then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
	end
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function TechNodeMapController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
	if not Topics.nodemap.keydown:send(event) then
		if keys.ESCAPE then
			event:StopPropagation()

			self:exit()
		elseif keys.S and keys.Ctrl and keys.Shift then
			self.ShowAll  = not self.ShowAll
			self:ReloadList()
		elseif keys.UP then
			self:scrollText(self.Document:GetElementById("map_desc"), 0)
		elseif keys.DOWN then
			self:scrollText(self.Document:GetElementById("map_desc"), 1)
		elseif keys.RETURN then
			--self:commit_pressed(element)
		elseif keys.F1 then
			self:help_clicked(element)
		elseif keys.F2 then
			self:options_button_clicked(element)
		end
	end
end

--- Scroll the descriptoin text up or down
--- @param element Element The element to scroll
--- @param direction number The direction to scroll in
--- @return nil
function TechNodeMapController:scrollText(element, direction)
	if direction == 0 then
		element.scroll_top = (element.scroll_top - 5)
	else
		element.scroll_top = (element.scroll_top + 5)
	end
end

--- Called by the RML to exit the tech room
--- @param element Element The element that was clicked
--- @return nil
function TechNodeMapController:accept_pressed(element)
    ui.playElementSound(element, "click", "success")
    self:exit()
end

--- Called by the RML to open the options menu
--- @param element Element The element that was clicked
--- @return nil
function TechNodeMapController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- Called by the RML to toggle showing the help text
--- @param element Element The element that was clicked
--- @return nil
function TechNodeMapController:help_clicked(element)
    ui.playElementSound(element, "click", "success")

	self.HelpShown  = not self.HelpShown

    local help_texts = self.Document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.HelpShown)
    end
end

--- Run all the frame functions
--- @return nil
function TechNodeMapController:unload()
    if self.Texture ~= nil then
		self.Texture:destroyRenderTarget()
		self.Texture:unload()
	end
	Topics.nodemap.unload:send(self)
end

return TechNodeMapController
