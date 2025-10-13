-----------------------------------
--This file contains the scpui.tbl parser methods
-----------------------------------

local Utils = require("lib_utils")

--- Parse the medals section of the scpui.tbl
--- @return nil
function ScpuiSystem:parseMedals()
	while parse.optionalString("$Medal:") do

		local id = parse.getString()

		ScpuiSystem.data.Medal_Info[id] = {}

		if parse.optionalString("+Alt Bitmap:") then
			ScpuiSystem.data.Medal_Info[id].AltBitmap = parse.getString()
		end

		if parse.optionalString("+Alt Debrief Bitmap:") then
			ScpuiSystem.data.Medal_Info[id].AltDebriefBitmap = parse.getString()
		end

		parse.requiredString("+Position X:")
		ScpuiSystem.data.Medal_Info[id].X = parse.getFloat()

		parse.requiredString("+Position Y:")
		ScpuiSystem.data.Medal_Info[id].Y = parse.getFloat()

		parse.requiredString("+Width:")
		ScpuiSystem.data.Medal_Info[id].W = parse.getFloat()

	end
end

--- Parse the scpui.tbl file
--- @param data string The file to parse
--- @return nil
function ScpuiSystem:parseScpuiTable(data)
    ba.print("SCPUI is parsing " .. data .. "\n")

	parse.readFileText(data, "data/tables")

	if parse.optionalString("#Settings") then

		if parse.optionalString("$Mod ID:") then
			local baseID = parse.getString()
			baseID = baseID:gsub("[^%w_]", "_")

			ScpuiSystem.data.table_flags.ModId = baseID
		end

		if parse.optionalString("$Default FSO Font Name:") then
			local font_name = parse.getString()
			local font = gr.Fonts[font_name]

			if font:isValid() then
				ScpuiSystem.data.DefaultFsoFont = font
			else
				ba.warning("SCPUI could not find FSO font with name '" .. font_name .. "'. Using default font instead.")
			end
		end

		if parse.optionalString("$Hide Multiplayer:") then
			ScpuiSystem.data.table_flags.HideMulti = parse.getBoolean()
		end

		if parse.optionalString("$Disable during Multiplayer:") then
			ScpuiSystem.data.table_flags.DisableInMulti = parse.getBoolean()
		end

		if parse.optionalString("$Data Saver Multiplier:") then
			ScpuiSystem.data.table_flags.DataSaverMultiplier = parse.getInt()
		end

		if parse.optionalString("$Ship Icon Width:") then
			ScpuiSystem.data.table_flags.IconDimensions.ship.Width = parse.getInt()
		end

		if parse.optionalString("$Ship Icon Height:") then
			ScpuiSystem.data.table_flags.IconDimensions.ship.Height = parse.getInt()
		end

		if parse.optionalString("$Weapon Icon Width:") then
			ScpuiSystem.data.table_flags.IconDimensions.weapon.Width = parse.getInt()
		end

		if parse.optionalString("$Weapon Icon Height:") then
			ScpuiSystem.data.table_flags.IconDimensions.weapon.Height = parse.getInt()
		end

		--- Sanitize the class name
		--- @param s string the string to sanitize
		--- @return string joined the sanitized string
		local function sanitizeClassList(s)
			s = tostring(s or "")
			s = s:match("^%s*(.-)%s*$") or "" -- trim
			if s == "" then return "" end

			-- keep only [A-Za-z0-9_-] tokens, allow spaces between classes
			local tokens = {}
			for token in s:gmatch("[%w_-]+") do
				tokens[#tokens+1] = token
			end
			-- dedupe while preserving order
			local seen, uniq = {}, {}
			for _, t in ipairs(tokens) do
				if not seen[t] then seen[t] = true; uniq[#uniq+1] = t end
			end

			local joined = table.concat(uniq, " ")
			return joined
		end

		if parse.optionalString("$Database Unread Show String Badge:") then
			ScpuiSystem.data.table_flags.DatabaseUnreadShowString = parse.getBoolean()
		end

		if parse.optionalString("$Database Unread String Badge Class:") then
			local raw = parse.getString()
			ScpuiSystem.data.table_flags.DatabaseUnreadStringClass = sanitizeClassList(raw)
		end

		if parse.optionalString("$Database Unread String Badge Text:") then
			ScpuiSystem.data.table_flags.DatabaseUnreadStringText = parse.getString()
		end

		if parse.optionalString("$Database Unread Show Icon Badge:") then
			ScpuiSystem.data.table_flags.DatabaseUnreadShowIcon = parse.getBoolean()
		end

		if parse.optionalString("$Database Unread Icon Badge Class:") then
			local raw = parse.getString()
			ScpuiSystem.data.table_flags.DatabaseUnreadIconClass = sanitizeClassList(raw)
		end

		if parse.optionalString("$Database Unread Icon Badge Filename:") then
			ScpuiSystem.data.table_flags.DatabaseUnreadIconFile = parse.getString()
		end

		if parse.optionalString("$Database Unread Badge Position:") then
			local raw = parse.getString()
			if raw:lower() == "right" then
				ScpuiSystem.data.table_flags.DatabaseUnreadBadgePosition = "right"
			elseif raw:lower() == "left" then
				ScpuiSystem.data.table_flags.DatabaseUnreadBadgePosition = "left"
			else
				ba.warning("SCPUI parsed invalid Database Unread Badge Position: " .. raw .. ". Defaulting to 'left'.")
				ScpuiSystem.data.table_flags.DatabaseUnreadBadgePosition = "left"
			end

			ba.warning("SCPUI Database Unread Badge Position parsing is currently not supported. Defaulting to 'left'.")
			ScpuiSystem.data.table_flags.DatabaseUnreadBadgePosition = "left"
		end

		if parse.optionalString("$Database Unread Item Class:") then
			local raw = parse.getString()
			ScpuiSystem.data.table_flags.DatabaseUnreadItemClass = sanitizeClassList(raw)
		end

		if parse.optionalString("$Minimum Splash Time:") then
			ScpuiSystem.data.table_flags.MinSplashTime = parse.getInt()
		end

		if parse.optionalString("$Fade Splash Images:") then
			ScpuiSystem.data.table_flags.FadeSplashImages = parse.getBoolean()
		end

		if parse.optionalString("$Draw Splash Images:") then
			ScpuiSystem.data.table_flags.DrawSplashImages = parse.getBoolean()
		end

		if parse.optionalString("$Draw Splash Text:") then
			ScpuiSystem.data.table_flags.DrawSplashText = parse.getBoolean()
		end

	end

	if parse.optionalString("#State Replacement") then

		while parse.optionalString("$State:") do
			local state = parse.getString()

			if state == "GS_STATE_SCRIPTING" or state == "GS_STATE_SCRIPTING_MISSION" then
				local mission_state = state == "GS_STATE_SCRIPTING_MISSION"
				parse.requiredString("+Substate:")
				state = parse.getString()
				parse.requiredString("+Markup:")
				local markup = parse.getString()
				ba.print("SCPUI found definition for script substate " .. state .. " : " .. markup .. "\n")
				ScpuiSystem.data.Replacements_List[state] = {
					Markup = markup
				}

				if mission_state then
					---@type LuaEnum
					local enum = mn.LuaEnums["SCPUI_Menus"]
					enum:addEnumItem(state)
					enum:removeEnumItem("<none>")
				end
			else
				parse.requiredString("+Markup:")
				local markup = parse.getString()
				ba.print("SCPUI found definition for game state " .. state .. " : " .. markup .. "\n")
				ScpuiSystem.data.Replacements_List[state] = {
					Markup = markup
				}
			end
		end

		if parse.optionalString("#Background Replacement") then

			while parse.optionalString("$Campaign Background:") do
				parse.requiredString("+Campaign Filename:")
				local campaign = Utils.strip_extension(parse.getString())

				parse.requiredString("+RCSS Class Name:")
				local classname = parse.getString()

				ScpuiSystem.data.Backgrounds_List_Campaign[campaign] = classname
			end

			while parse.optionalString("$Mainhall Background:") do
				parse.requiredString("+Mainhall Name:")
				local mainhall = Utils.strip_extension(parse.getString())

				parse.requiredString("+RCSS Class Name:")
				local classname = parse.getString()

				ScpuiSystem.data.Backgrounds_List_Mainhall[mainhall] = classname
			end

		end

	end

	if parse.optionalString("#Background Replacement") then

		while parse.optionalString("$Campaign Background:") do
			parse.requiredString("+Campaign Filename:")
			local campaign = Utils.strip_extension(parse.getString())

			parse.requiredString("+RCSS Class Name:")
			local classname = parse.getString()

			ScpuiSystem.data.Backgrounds_List_Campaign[campaign] = classname
		end

	end

	if parse.optionalString("#Briefing Stage Background Replacement") then

		while parse.optionalString("$Briefing Grid Background:") do

			parse.requiredString("+Mission Filename:")
			local mission = Utils.strip_extension(parse.getString())

			parse.requiredString("+Default Background Filename:")
			local default_file = parse.getString()

			if not Utils.hasExtension(default_file) then
				ba.warning("SCPUI parsed background file, " .. default_file .. ", that does not include an extension!")
			end

			ScpuiSystem.data.Brief_Backgrounds_List[mission] = {}

			ScpuiSystem.data.Brief_Backgrounds_List[mission]["default"] = default_file

			while parse.optionalString("+Stage Override:") do
				local stage = tostring(parse.getInt())

				parse.requiredString("+Background Filename:")
				local file = parse.getString()

				if not Utils.hasExtension(file) then
					ba.warning("SCPUI parsed background file, " .. default_file .. ", that does not include an extension!")
				end

				ScpuiSystem.data.Brief_Backgrounds_List[mission][stage] = file
			end

		end

	end

	if parse.optionalString("#Medal Placements") then
		ScpuiSystem:parseMedals()
	end


	parse.requiredString("#End")

	parse.stop()
end

--- Parses the scpui tbl and tbm files
--- @return nil
function ScpuiSystem:loadScpuiTables()
    if cf.fileExists("scpui.tbl", "", true) then
		self:parseScpuiTable("scpui.tbl")
	end
	for _, v in ipairs(cf.listFiles("data/tables", "*-ui.tbm")) do
		self:parseScpuiTable(v)
	end
end

ScpuiSystem:loadScpuiTables()