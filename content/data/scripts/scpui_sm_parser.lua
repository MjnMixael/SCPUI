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

		if parse.optionalString("$Show New In Database:") then
			ScpuiSystem.data.table_flags.DatabaseShowNew = parse.getBoolean()
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

			ScpuiSystem.data.Backgrounds_List[campaign] = classname
		end

	end

	end

	if parse.optionalString("#Background Replacement") then

		while parse.optionalString("$Campaign Background:") do
			parse.requiredString("+Campaign Filename:")
			local campaign = Utils.strip_extension(parse.getString())

			parse.requiredString("+RCSS Class Name:")
			local classname = parse.getString()

			ScpuiSystem.data.Backgrounds_List[campaign] = classname
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