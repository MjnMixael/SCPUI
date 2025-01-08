-----------------------------------
--This file contains miscellaneous functions used by SCPUI generally
--related to ui manipulation but also contains some other utility functions
-----------------------------------

--- Helper function to parse a table
--- @param parserObject table The context/target object that owns the `parseFunction`.
--- @param parseFunction function The function to call to parse the table.
--- @param tblName string The name of the table to parse.
--- @param tbmName string The suffix string of the tbm files to parse.
--- @return nil
function ScpuiSystem:parseTable(parserObject, parseFunction, tblName, tbmName)
    ba.print("Beginning parse of " .. tblName .. ".tbl...\n")

    -- Check if the base table exists and parse it
    if cf.fileExists(tblName .. '.tbl', '', true) then
        parseFunction(parserObject, tblName .. '.tbl')
    end

    -- Parse any associated .tbm files
    for _, v in ipairs(cf.listFiles("data/tables", "*-" .. tbmName .. ".tbm")) do
        parseFunction(parserObject, v)
    end
end

--- Replace angle brackets in a string with their HTML entity equivalents
--- @param inputString string The string to replace angle brackets in.
--- @return string
function ScpuiSystem:replaceAngleBrackets(inputString)
    local result = string.gsub(inputString, "<", "&lt;")
    result = string.gsub(result, ">", "&gt;")
    return result
end

--- Frees all model data only if a mission is not loaded
--- @return nil
function ScpuiSystem:freeAllModels()
	if ScpuiSystem.data.memory.MissionLoaded == false then
		ba.print("SCPUI is freeing all models!\n")
		gr.freeAllModels()
	end
end

--- Pauses or unpauses all audio channels
--- @param toggle boolean Whether to pause or unpause the audio channels.
--- @return nil
function ScpuiSystem:pauseAllAudio(toggle)
	local topics = require("lib_ui_topics")

	ad.pauseMusic(-1, toggle)
	ad.pauseWeaponSounds(toggle)
	ad.pauseVoiceMessages(toggle)
	topics.Scpui.pauseAudio:send(toggle)
end

--- Gets the absolute left position of an element
--- @param element table The element to get the absolute left position of.
--- @return number
function ScpuiSystem:getAbsoluteLeft(element)
	local val = element.offset_left
	local parent = element.parent_node
	while parent ~= nil do
		val = val + parent.offset_left
		parent = parent.parent_node
	end

	return val
end

--- Gets the absolute top position of an element
--- @param element table The element to get the absolute top position of.
--- @return number
function ScpuiSystem:getAbsoluteTop(element)
	local val = element.offset_top
	local parent = element.parent_node
	while parent ~= nil do
		val = val + parent.offset_top
		parent = parent.parent_node
	end

	return val
end

--- Stops the music contained in the SCPUI music handle, if any
--- @return nil
function ScpuiSystem:stopMusic()
	if ScpuiSystem.data.memory.MusicHandle ~= nil and ScpuiSystem.data.memory.MusicHandle:isValid() then
		ScpuiSystem.data.memory.MusicHandle:close(true)
	end
	ScpuiSystem.data.memory.MusicHandle = nil
end

--- Checks if a cutscene should be played for the current scene. Will pause any currently playing music, play the cutscene, and then resume the music.
--- @param scene enumeration The scene to check if a cutscene should be played for. Should be one of MOVIE_PRE_FICTION, MOVIE_PRE_CMD_BRIEF, MOVIE_PRE_BRIEF, MOVIE_PRE_GAME, MOVIE_PRE_DEBRIEF, MOVIE_POST_DEBRIEF, MOVIE_END_CAMPAIGN
--- @return nil
function ScpuiSystem:maybePlayCutscene(scene)
	local topics = require("lib_ui_topics")
	topics.playcutscene.start:send(self)
	if ScpuiSystem.data.memory.MusicHandle ~= nil then
		ScpuiSystem.data.memory.MusicHandle:pause()
	end

	--Stop rendering SCPUI during the cutscene
	ScpuiSystem.data.Render = false

	--Setting this to false so it doesn't try to restart music
	--that SCPUI handles internally
	ui.maybePlayCutscene(scene, false, 0)
	ScpuiSystem.data.Render = true
	if ScpuiSystem.data.memory.MusicHandle ~= nil then
		ScpuiSystem.data.memory.MusicHandle:unpause()
	end
	topics.playcutscene.finish:send(self)
end

--- Sets the base pixel font size for SCPUI to use. Attempts to replicate the font size as it would appear on a 1080p screen.
--- @param val? number The multiplier to adjust the font size by. If nil, the stored value will be used.
--- @return string size The font size to use as a string
function ScpuiSystem:getFontPixelSize(val)
	local vmin = math.min(gr.getScreenWidth(), gr.getScreenHeight())
	local size = vmin * 0.012 --Gets roughly 12px font on 1080p
	-- Lua has no math.round(); math.floor(x + 0.5) is the idiomatic replacement.
	local pixelSize = math.floor(size + 0.5)

	local function convert(value)
		if not value then return nil end
		local clamped_value = math.max(0, math.min(1, value))
	    local scaled_value = (clamped_value - 0.5) * 20
		return math.floor(scaled_value + 0.5)
	end

	if not val then
		val = convert(ScpuiSystem.data.ScpuiOptionValues.Font_Adjustment or 0.5)
	else
		val = convert(val)
	end

	local finalSize = math.max(1, math.min(ScpuiSystem.data.NumFontSizes, pixelSize + val))

	return tostring(finalSize)
end

--- DEPRECATED: Use getFontPixelSize instead.
--- Gets the font size to use for SCPUI based on the font adjustment value.
--- @param val? number The multiplier to adjust the font size by. If nil, the stored value will be used.
--- @param default? number The default font size to use if val is nil.
--- @return number
function ScpuiSystem:getFontSize(val, default)
	if default == nil then
		default = 5
	end
	-- If we have don't have val, then get the stored one
	if val == nil then
		if ScpuiSystem.data.ScpuiOptionValues == nil then
			ba.warning("Cannot get font size before SCPUI is initialized! Using default.")
			return default
		else
			val = ScpuiSystem.data.ScpuiOptionValues.Font_Adjustment

			-- If value is not set then use default
			if val == nil then
				return default
			end
		end
	end

	-- Make sure val is a number
	val = tonumber(val)
	if val == nil then
		ba.warning("SCPUI got invalid data for Font Multiplier! Using default.")
		return default
	end

	-- If value is greater than 1, then it's an old style and we can just return it directly
	-- But math.floor it just in case.
	if val > 1.0 then
		return math.floor(val)
	end

	-- Range check
	if val < 0.0 then
        val = 0.0
    elseif val > 1.0 then
        val = 1.0
    end

    -- Perform the conversion
    local convertedValue = 1 + (val * 19)
    return math.floor(convertedValue)
end

--- Gets the background rcss class to use based on the current campaign. Returns "general_bg" if no class is found.
--- @return string class The rcss class to use to set the background image
function ScpuiSystem:getBackgroundClass()
	local campaignfilename = ba.getCurrentPlayer():getCampaignFilename()
	local bgclass = self.data.Backgrounds_List[campaignfilename]

	if not bgclass then
		bgclass = "general_bg"
	end

	return bgclass
end

--- Gets background file to use for the briefing map. Returns "br-black.png" if no file is found.
--- @param mission string The mission to get the background for.
--- @param stage string The stage to get the background for.
--- @return string file The file to use as the briefing background
function ScpuiSystem:getBriefingBackground(mission, stage)

	local file = nil

	if self.data.Brief_Backgrounds_List[mission] ~= nil then
		file = self.data.Brief_Backgrounds_List[mission][stage]

		if file == nil then
			file = self.data.Brief_Backgrounds_List[mission]["default"]
		end
	end

	--double check
	if file == nil then
		file = "br-black.png"
	end

	return file
end

--- Unsets all child elements of a parent class from pseudo class "checked"
--- @param parent Element The parent element to unset children from.
--- @return nil
function ScpuiSystem:uncheckChildren(parent)
	local el = parent.first_child
	while el ~= nil do
		el:SetPseudoClass("checked", false)
		el = el.next_sibling
	end
end

--- Clears an element of all children
--- @param parent Element The parent element to clear children from.
--- @return nil
function ScpuiSystem:clearEntries(parent)
	while parent:HasChildNodes() do
		parent:RemoveChild(parent.first_child)
	end
end

--- Sets the value of a specific attribute for an element
--- @param parent Element The parent element to set the attribute for.
--- @param attribute string The attribute to set.
--- @param value string The value to set the attribute to.
function ScpuiSystem:setStyle(parent, attribute, value)
	if parent ~= nil then
		parent.style[attribute] = value
	end
end

--- Scrolls an element up by 10 pixels
--- @param element Element The element to scroll.
--- @return nil
function ScpuiSystem:scrollUp(element)
	element.scroll_top = element.scroll_top - 10
end

--- Scrolls an element down by 10 pixels
--- @param element Element The element to scroll.
--- @return nil
function ScpuiSystem:scrollDown(element)
	element.scroll_top = element.scroll_top + 10
end

--- Clears a dropdown list
--- @param element ElementFormControlSelect The dropdown element to clear.
--- @return nil
function ScpuiSystem:clearDropdown(element)
	while element.options[0] ~= nil do
		element:Remove(0)
	end
end

--- Add all table elements to a dropdown as selections
--- @param element ElementFormControlSelect The dropdown element to add selections to.
--- @param list table The list of elements to add to the dropdown.
--- @return nil
function ScpuiSystem:buildSelectList(element, list)
	for i, v in ipairs(list) do
		element:Add(v, v, i)
	end
end

--- Creates an element of the specified type and with the specified id
--- @param context scpui_context The context to create the element in.
--- @param t string The type of element to create like "div" or "p".
--- @param id string The id to assign to the element.
--- @return Element
function ScpuiSystem:makeElement(context, t, id)
	local el = context.Document:CreateElement(t)
	if id ~= nil then
		el.id = id
	end
	return el
end

--- Creates a panel element with an image with the specified id
--- @param context scpui_context The context to create the element in.
--- @param id string The id to assign to the element.
--- @param img string The image to use for the panel.
--- @return Element
function ScpuiSystem:makeElementPanel(context, id, img)
	if id == nil then
		ba.error("SCPUI: ID is required to make an element panel!")
	end

	local el = context.Document:CreateElement("div")
	el.id = tostring(id)

	local img_el = ScpuiSystem:makeImg(context, img)
	img_el.style.display = "block"
	img_el.style.width = "100%"
	img_el.style.height = "auto"

	local inner_el = ScpuiSystem:makeElement(context, "div", id .. "_inner")
	inner_el.style.position = "absolute"
	inner_el.style.top = "0"
	inner_el.style.left = "0"

	el:AppendChild(inner_el)
	el:AppendChild(img_el)

	return el
end

--- Makes an image element
--- @param context scpui_context The context to create the element in.
--- @param file string The file to use for the image.
--- @param animated? boolean Whether the image is animated or not.
--- @return Element
function ScpuiSystem:makeImg(context, file, animated)
	local t = "img"
	if animated == true then
		t = "ani"
	end
	local el = context.Document:CreateElement(t)
	el:SetAttribute("src", file)
	return el
end

--- Makes a text-only button and returns the elements
--- @param context scpui_context The context to create the element in.
--- @param cont_id string The id to assign to the container element.
--- @param button_id string The id to assign to the button element.
--- @param button_classes table The classes to assign to the button element.
--- @param text_id string The id to assign to the text element.
--- @param text_classes table The classes to assign to the text element.
--- @param text string The text to display on the button.
--- @return Element, Element elements The container and button elements.
function ScpuiSystem:makeTextButton(context, cont_id, button_id, button_classes, text_id, text_classes, text)
	local cont_el = context.Document:CreateElement("div")
	cont_el.id = cont_id

	local button_el = context.Document:CreateElement("button")
	button_el.id = button_id
	for _, v in ipairs(button_classes) do
		button_el:SetClass(v, true)
	end

	local button_text_el = context.Document:CreateElement("span")
	button_text_el.id = text_id
	for _, v in ipairs(text_classes) do
		button_text_el:SetClass(v, true)
	end

	local button_text = context.Document:CreateElement("p")
	button_text.inner_rml = text

	button_text_el:AppendChild(button_text)
	button_el:AppendChild(button_text_el)
	cont_el:AppendChild(button_el)

	return cont_el, button_el
end

--- Makes an image button and returns the elements
--- @param context scpui_context The context to create the element in.
--- @param cont_id string The id to assign to the container element.
--- @param button_id string The id to assign to the button element.
--- @param button_classes table The classes to assign to the button element.
--- @param img_base string The base class to assign to the image element.
--- @param img_file string The file to use for the image.
--- @param text_id string The id to assign to the text element.
--- @param text_classes table The classes to assign to the text element.
--- @param text string The text to display on the button.
--- @return Element, Element elements The container and button elements.
function ScpuiSystem:makeButton(context, cont_id, button_id, button_classes, img_base, img_file, text_id, text_classes, text)
	local cont_el = context.Document:CreateElement("div")
	cont_el.id = cont_id

	local button_el = context.Document:CreateElement("button")
	button_el.id = button_id
	for _, v in ipairs(button_classes) do
		button_el:SetClass(v, true)
	end

	local button_img_el = context.Document:CreateElement("span")
	button_img_el.id = img_base .. "_img"
	button_img_el:SetClass(img_base, true)
	button_img_el:SetClass("button_img", true)

	local button_img = context.Document:CreateElement("img")
	button_img:SetAttribute("src", img_file)
	button_img:SetClass("psuedo_img", true)

	local button_text_el = context.Document:CreateElement("span")
	button_text_el.id = text_id
	for _, v in ipairs(text_classes) do
		button_text_el:SetClass(v, true)
	end

	local button_text = context.Document:CreateElement("p")
	button_text.inner_rml = text

	button_text_el:AppendChild(button_text)
	button_img_el:AppendChild(button_img)
	button_el:AppendChild(button_img_el)
	button_el:AppendChild(button_text_el)
	cont_el:AppendChild(button_el)

	return cont_el, button_el
end

--- Sets the briefing text of a parent element. This will remove all children of the parent element and replace them
--- This also colors the briefing text and applies any tooltips
--- @param parent Element The parent element to set the briefing text on
--- @param brief_text string The briefing text to set
--- @param recommendation? string The recommendation text to set, if any
--- @return number lines The number of lines added
function ScpuiSystem:setBriefingText(parent, brief_text, recommendation)
	local utils = require("lib_utils")

	--- Local function to add a text element to a parent element
	--- @param parent Element The parent element to add the text element to
	--- @param document Document The document to create the text element in
	--- @param text string The text to add
	--- @param color_tag string The color tag to use for the text
	--- @param colorTable table The table of color tags to use
	--- @return number | nil lines The number of lines added
	local function add_text_element(parent, document, text, color_tag, colorTable)
		if #text == 0 then
			-- If no text, do not output anything
			return
		end

		local colorVal = colorTable[color_tag]

		if not colorVal then
			--FSO already has a warning for malformed color tags so let's just try to keep going
			text = ' ' .. color_tag .. text --try to preserve the original text
		end

		local spanEl = document:CreateElement("span")
		local textEl = document:CreateTextNode(text)

		if colorVal then
			spanEl.style.color = ("rgba(%d, %d, %d, %d)"):format(colorVal.Red, colorVal.Green, colorVal.Blue, colorVal.Alpha)
		end

		spanEl:AppendChild(textEl)

		parent:AppendChild(spanEl)
	end

	--- Local function to add line elements to a parent element, setting color tags or color classes as required
	--- @param document Document The document to create the elements in
	--- @param paragraph Element The parent element to add the line elements to
	--- @param line string The line to add elements for
	--- @param defaultColorTag string The default color tag to use
	--- @param colorTags table The table of color tags to use
	--- @return nil
	local function add_line_elements(document, paragraph, line, defaultColorTag, colorTags)
		local searchIndex = 1
		local colorStack = { defaultColorTag }

		while true do
			local startIdx, endIdx, colorChar, groupChar = line:find("%$(%a?)([{}]?)%s*", searchIndex)
			if startIdx == nil then
				break
			end

			if #colorChar == 0 and groupChar ~= "}" then
				ba.error(string.format("Color block error in line %q", line))
			end

			-- Flush out text that was before our tag
			local pendingText = line:sub(searchIndex, startIdx - 1)
			add_text_element(paragraph, document, pendingText, colorStack[#colorStack], colorTags)

			searchIndex = endIdx + 1

			if #colorChar == 0 then
				-- This must be the end of a color group. Remove the last color from the stack and continue
				table.remove(colorStack)
			else
				table.insert(colorStack, colorChar)

				if groupChar == "{" then
					-- The start of a group so there is nothing for us to do here at the moment
				else
					-- We need to know if our word was terminated by white space or an explicit break so we store the whitespace
					-- in a group and check that later
					local rangeEndStart, rangeEndEnd, whitespace = utils.find_first_either(line, { "(%s)", "%$|" }, searchIndex)

					local coloredText
					if whitespace then
						-- If we broke on whitespace then we still need to include those characters in the colored range
						-- to ensure the spacing is correct. To do that, we build the substring until the end of the range
						coloredText = line:sub(endIdx + 1, rangeEndEnd)
					elseif rangeEndEnd == nil then
						-- If we did not find the end then we ended the line with a color sequence
						coloredText = line:sub(endIdx + 1)
					else
						coloredText = line:sub(endIdx + 1, rangeEndStart - 1)
					end
					add_text_element(paragraph, document, coloredText, colorStack[#colorStack], colorTags)

					table.remove(colorStack)

					if rangeEndEnd ~= nil then
						searchIndex = rangeEndEnd + 1
					else
						-- Still need to update this so that the final text element will not be shown twice
						searchIndex = #line
					end
				end
			end
		end

		local remainingText = line:sub(searchIndex)
		add_text_element(paragraph, document, remainingText, colorStack[#colorStack], colorTags)
	end

	-- First, clear all the children of this element
    ScpuiSystem:clearEntries(parent)

    local document = parent.owner_document

    local colorTags = ui.ColorTags
    local defaultColorTag = ui.DefaultTextColorTag(2)

	local tooltipRegister = {}

    local rml_mode = false
    local escapeStart, escapeEnd = brief_text:find("^%s*!html%s*")
    if escapeStart then
        brief_text = brief_text:sub(escapeEnd + 1)
        rml_mode = true
    end

    local lines = utils.split(brief_text, "\n\n")
    local first = true
    ---@param line string
    for _, line in ipairs(lines) do
        if not first then
            local newLine = document:CreateElement("br")
            parent:AppendChild(newLine)
        else
            first = false
        end

        local paragraph = document:CreateElement("p")

        if rml_mode then
            -- In HTML mode, we just use the text unescaped as the inner RML after running
			-- it through the keyword system
            paragraph.inner_rml, tooltipRegister = ScpuiSystem:applyKeywordClasses(ba.replaceVariables(line))
        else
            add_line_elements(document, paragraph, ba.replaceVariables(line), defaultColorTag, colorTags)
        end

        parent:AppendChild(paragraph)
		for key, value in pairs(tooltipRegister) do
			ScpuiSystem:addTooltip(document, key, value)
		end
    end

	if recommendation then
		local paragraph = document:CreateElement("p")
		paragraph.inner_rml = recommendation
		parent:AppendChild(paragraph)
	end

    -- Try to estimate the amount of lines this will get. The value 130 is chosen based on the original width of the
    -- text window in retail FS2
    local paragraphLines = utils.table.map(lines, function(line)
        return #line / 130
    end)

    return utils.table.sum(paragraphLines) + #lines
end