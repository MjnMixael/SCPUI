-----------------------------------
--This file contains the scpui.tbl parser methods
-----------------------------------

local Utils = require("lib_utils")

--- Parse a "x, y, z, ..." list of numbers from a single parsed string.
--- @param raw string the comma-separated value list
--- @return number[] values the parsed numbers (silently drops non-numeric tokens)
local function parseCsvNumbers(raw)
	local values = {}
	for token in tostring(raw or ""):gmatch("[^,%s]+") do
		local n = tonumber(token)
		if n then values[#values+1] = n end
	end
	return values
end

--- Parse the load-screen tip / screen-profile / mission-screen sections of the scpui.tbl.
--- These power the table-driven defaults bound in scpui_sm_def_topics.lua. Modders can
--- override any of these declaratively per-mod or programmatically by binding higher-priority
--- listeners on the Topics.loadscreen.* topics.
--- @return nil
function ScpuiSystem:parseLoadScreens()

	--- Named tip strings referenced by load-screen profiles.
	if parse.optionalString("#Loading Text") then
		while parse.optionalString("$Name:") do
			local name = parse.getString()

			parse.requiredString("$Text:")
			local text = parse.getString()

			local font_class = nil
			if parse.optionalString("+Font Class:") then
				font_class = parse.getString()
			end

			ScpuiSystem.data.LoadScreens.Tips[name] = {
				Text = text,
				FontClass = font_class,
			}
		end
	end

	--- Named load-screen profiles describing how a given screen should render.
	if parse.optionalString("#Loading Screens") then
		while parse.optionalString("$Name:") do
			local name = parse.getString()

			local profile = {
				LoadingBarImage = nil,
				BackgroundClasses = {},
				Tips = {},
				TipStyle = nil,
				TitleStyle = nil,
			}

			if parse.optionalString("$Loading Bar Image:") then
				profile.LoadingBarImage = parse.getString()
			end

			while parse.optionalString("+Background Class:") do
				profile.BackgroundClasses[#profile.BackgroundClasses+1] = parse.getString()
			end

			if parse.optionalString("$Tip Style:") then
				profile.TipStyle = {}

				if parse.optionalString("+Font Class:") then
					profile.TipStyle.FontClass = parse.getString()
				end

				if parse.optionalString("+Color:") then
					profile.TipStyle.Color = parseCsvNumbers(parse.getString())
				end

				if parse.optionalString("+Origin:") then
					local o = parseCsvNumbers(parse.getString())
					profile.TipStyle.Origin = { x = o[1] or 0, y = o[2] or 0 }
				end

				if parse.optionalString("+Offset:") then
					local o = parseCsvNumbers(parse.getString())
					profile.TipStyle.Offset = { x = o[1] or 0, y = o[2] or 0 }
				end

				if parse.optionalString("+Width:") then
					profile.TipStyle.Width = parse.getInt()
				end
			end

			if parse.optionalString("$Title Style:") then
				profile.TitleStyle = {}

				if parse.optionalString("+Font Class:") then
					profile.TitleStyle.FontClass = parse.getString()
				end

				if parse.optionalString("+Origin:") then
					local o = parseCsvNumbers(parse.getString())
					profile.TitleStyle.Origin = { x = o[1] or 0, y = o[2] or 0 }
				end

				if parse.optionalString("+Offset:") then
					local o = parseCsvNumbers(parse.getString())
					profile.TitleStyle.Offset = { x = o[1] or 0, y = o[2] or 0 }
				end

				if parse.optionalString("+Justify:") then
					local raw = parse.getString():lower()
					if raw == "left" or raw == "center" or raw == "right" then
						profile.TitleStyle.Justify = raw
					else
						ba.warning("SCPUI Loading Screens: profile '" .. name .. "' has invalid +Justify: '" .. raw .. "'. Expected left|center|right. Defaulting to left.")
						profile.TitleStyle.Justify = "left"
					end
				end
			end

			while parse.optionalString("$Tip:") do
				profile.Tips[#profile.Tips+1] = parse.getString()
			end

			ScpuiSystem.data.LoadScreens.Profiles[name] = profile
		end
	end

	--- Mission-filename → profile-name mapping.
	if parse.optionalString("#Mission Screens") then
		while parse.optionalString("$Filename:") do
			local mission = Utils.strip_extension(parse.getString())

			parse.requiredString("$Loading Screen:")
			local profile = parse.getString()

			ScpuiSystem.data.LoadScreens.Missions[mission] = profile
		end
	end
end

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

		if parse.optionalString("$Use Legacy Slider For Volume:") then
			ScpuiSystem.data.table_flags.UseLegacyVolumeSlider = parse.getBoolean()
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

	ScpuiSystem:parseLoadScreens()

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