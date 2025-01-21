-----------------------------------
--This file contains functions and methods for handling custom options for SCPUI
-----------------------------------

--Create the custom options table
ScpuiSystem.data.Custom_Options = {}

--- Init the custom options by sending the tbl and tbm files to the parser and initializing the global options cache from disk, if possible
--- @return nil
function ScpuiSystem:initCustomOptions()

	--Verfy that the mod has a proper title
	ScpuiSystem:getModTitle()

	if cf.fileExists('options.tbl', '', true) then
		self:parseOptions('options.tbl')
	end

	for _, v in ipairs(cf.listFiles("data/tables", "*-optn.tbm")) do
		self:parseOptions(v)
	end
end

--- Parse the options.tbl and *-optn.tbm files to get the custom options
--- @param data string The file to parse
--- @return nil
function ScpuiSystem:parseOptions(data)

	parse.readFileText(data, "data/tables")

	parse.requiredString("#Custom Options")

	while parse.optionalString("$Name:") do
		local entry = {}

		entry.Title = parse.getString()

		if parse.optionalString("+Description:") then
			entry.Description = parse.getString()
		end

		parse.requiredString("+Key:")
		entry.Key = parse.getString()

		--Warn if Key already exists for another option
		for _, v in pairs(ScpuiSystem.data.Custom_Options) do
			if v.Key == entry.Key then
				ba.error("SCPUI Custom Options Key '" .. entry.Key .. "' already exists. This needs to be fixed!")
			end
		end

		parse.requiredString("+Type:")
		entry.Type = self:verifyParsedType(parse.getString())

		if parse.optionalString("+Column:") then
			entry.Column = parse.getInt()
			if entry.Column < 1 then
				entry.Column = 1
			end
			if entry.Column > 4 then
				entry.Column = 4
			end
		else
			entry.Column = 1
		end

		if entry.Type ~= "Header" then

			local val_count = 0
			local name_count = 0

			if entry.Type == "Binary" or entry.Type == "Multi" then
				parse.requiredString("+Valid Values")

				entry.ValidValues = {}

				while parse.optionalString("+Val:") do
					local val = parse.getString()
					local save = true

					if val ~= nil then
						val_count = val_count + 1
						if entry.Type == "Binary" and val_count > 2 then
							parse.displayMessage("Option " .. entry.Title .. " is Binary but has more than 2 values. The rest will be ignored!", false)
							save = false
						end

						if entry.Type == "FivePoint" and val_count > 5 then
							parse.displayMessage("Option " .. entry.Title .. " is FivePoint but has more than 5 values. The rest will be ignored!", false)
							save = false
						end

						if save then
							entry.ValidValues[val_count] = val
						end
					end
				end

				if entry.Type == "Binary" and val_count < 2 then
					parse.displayMessage("Option " .. entry.Title .. " is Binary but only has " .. val_count .. "values! Binary types must have exactly 2 values.", true)
				end

				if entry.Type == "Multi" and val_count < 2 then
					parse.displayMessage("Option " .. entry.Title .. " is Multi but only has " .. val_count .. "values! Multi types must have at least 2 values.", true)
				end

				if entry.Type == "FivePoint" and val_count < 5 then
					parse.displayMessage("Option " .. entry.Title .. " is FivePoint but only has " .. val_count .. "values! FivePoint types must have exactly 5 values.", true)
				end

			end

			if entry.Type == "Binary" or entry.Type == "Multi" or entry.Type == "FivePoint" then

				parse.requiredString("+Display Names")

				entry.DisplayNames = {}

				while parse.optionalString("+Val:") do
					local val = parse.getString()
					local save = true

					if val ~= nil then
						name_count = name_count + 1
						if entry.Type == "Binary" and name_count > 2 then
							parse.displayMessage("Option " .. entry.Title .. " is Binary but has more than 2 display names. The rest will be ignored!", false)
							save = false
						end

						if entry.Type == "FivePoint" and name_count > 5 then
							parse.displayMessage("Option " .. entry.Title .. " is FivePoint but has more than 5 display names. The rest will be ignored!", false)
							save = false
						end

						if save then
							if entry.Type == "FivePoint" then
								entry.DisplayNames[name_count] = val
							else
								entry.DisplayNames[entry.ValidValues[name_count]] = val
							end
						end
					end
				end

				if entry.Type == "Binary" and name_count < 2 then
					parse.displayMessage("Option " .. entry.Title .. " is Binary but only has " .. name_count .. "display names! Binary types must have exactly 2 display names.", true)
				end

				if entry.Type == "Multi" and name_count < 2 then
					parse.displayMessage("Option " .. entry.Title .. " is Multi but only has " .. name_count .. "display names! Multi types must have at least 2 display names.", true)
				end

				if entry.Type == "FivePoint" and name_count < 5 then
					parse.displayMessage("Option " .. entry.Title .. " is FivePoint but only has " .. name_count .. "display names! FivePoint types must have exactly 5 display names.", true)
				end

				if entry.Type ~= "FivePoint" and val_count ~= name_count then
					parse.displayMessage("Option " .. entry.Title .. " has " .. val_count .. " values but only has " .. name_count .. " display names. There must be one display name for each value!", true)
				end
			end

			if entry.Type == "Range" then
				parse.requiredString("+Min:")
				entry.Min = parse.getFloat()

				if entry.Min < 0 then
					entry.Min = 0
				end

				parse.requiredString("+Max:")
				entry.Max = parse.getFloat()

				if entry.Max <= entry.Min then
					parse.displayMessage("Option " .. entry.Title .. " has a Max value that is less than or equal to its Min value!", true)
				end
			end

			parse.requiredString("+Default Value:")
			if entry.Type == "Binary" or entry.Type == "Multi" then
				entry.Value = parse.getString()
			elseif entry.Type == "Range" then
				local val = parse.getFloat()
				if val < entry.Min then
					val = entry.Min
				end
				if val > entry.Max then
					val = entry.Max
				end
				entry.Value = val
			elseif entry.Type == "FivePoint" or entry.Type == "TenPoint" then
				local val = parse.getInt()
				if val < 1 then
					val = 1
				end
				if entry.Type == "FivePoint" and val > 5 then
					val = 5
				end
				if entry.Type == "TenPoint" and val > 10 then
					val = 10
				end
				entry.Value = val
			end

			if parse.optionalString("+Force Selector:") then
				entry.ForceSelector = parse.getBoolean()
			else
				entry.ForceSelector = false
			end

			if parse.optionalString("+No Default:") then --this needs a better name
				entry.NoDefault = parse.getBoolean()
			else
				entry.NoDefault = false
			end
		end

		table.insert(ScpuiSystem.data.Custom_Options, entry)
	end

	parse.requiredString("#End")

	parse.stop()

end

--- Verify the parsed option type is valid
--- @param val string The parsed option type
--- @return string type The valid option type
function ScpuiSystem:verifyParsedType(val)

	if string.lower(val) == "header" then
		return "Header"
	end

	if string.lower(val) == "binary" then
		return "Binary"
	end

	if string.lower(val) == "multi" then
		return "Multi"
	end

	if string.lower(val) == "range" then
		return "Range"
	end

	if string.lower(val) == "fivepoint" then
		return "FivePoint"
	end

	if string.lower(val) == "tenpoint" then
		return "TenPoint"
	end

	parse.displayMessage("Option type " .. val .. " is not valid!", true)

	--Unreachable
	return ""

end

--- Load the player's options file for the currently loaded mod
--- @return table? options The player's options data
function ScpuiSystem:loadOptionsFromFile()

	---@type json
	local Json = require('dkjson')

	local location = 'data/players'

	local file = nil
	local config = {}

	if cf.fileExists('scpui_options.cfg') then
		file = cf.openFile('scpui_options.cfg', 'r', location)
		config = Json.decode(file:read('*a'))
		file:close()
		if not config then
			config = {}
		end
	end

	if not config[ba.getCurrentPlayer():getName()] then
		config[ba.getCurrentPlayer():getName()] = {}
	end

	local mod = ScpuiSystem:getModTitle()

	if not config[ba.getCurrentPlayer():getName()][mod] then
		return nil
	else
		return config[ba.getCurrentPlayer():getName()][mod]
	end
end

--- Save the player's options file for the currently loaded mod
--- @param data table The player's options data
--- @return nil
function ScpuiSystem:saveOptionsToFile(data)

	---@type json
	local Json = require('dkjson')

	local location = 'data/players'

	local file = nil
	local config = {}

	if cf.fileExists('scpui_options.cfg') then
		file = cf.openFile('scpui_options.cfg', 'r', location)
		config = Json.decode(file:read('*a'))
		file:close()
		if not config then
			config = {}
		end
	end

	if not config[ba.getCurrentPlayer():getName()] then
		config[ba.getCurrentPlayer():getName()] = {}
	end

	local mod = ScpuiSystem:getModTitle()

	config[ba.getCurrentPlayer():getName()][mod] = data

	local Utils = require("lib_utils")
	config = Utils.cleanPilotsFromSaveData(config)

	file = cf.openFile('scpui_options.cfg', 'w', location)
	file:write(Json.encode(config))
	file:close()
end

--- Load and apply any custom options after a pilot is selected
--- @return nil
function ScpuiSystem:applyCustomOptions()
	--Here we load the mod options save data for the selected player
	ScpuiSystem.data.ScpuiOptionValues = {}
	local utils = require("lib_utils")
	ScpuiSystem.data.ScpuiOptionValues = ScpuiSystem:loadOptionsFromFile()

	--load defaults if we have bad data
	if type(ScpuiSystem.data.ScpuiOptionValues) ~= "table" then
		ba.print("SCPUI: Got bad ScpuiSystem.data.ScpuiOptionValues data! Loading defaults!")
		ScpuiSystem.data.ScpuiOptionValues = {}
		for i, v in ipairs(ScpuiSystem.data.Custom_Options) do
			ScpuiSystem.data.ScpuiOptionValues[v.Key] = v.Value
		end
		ScpuiSystem:saveOptionsToFile(ScpuiSystem.data.ScpuiOptionValues)
	end
end

ScpuiSystem:initCustomOptions()

--- Do not create engine hookes if we're in FRED
if ba.inMissionEditor() then
	return
end

--Here we load the global mod options or the defaults for use before a player is selected
local saveFilename = 'scpui_options_global.cfg'
if cf.fileExists(saveFilename, 'data/players', true) then

	---@type json
	local Json = require('dkjson')
	local file = cf.openFile(saveFilename, 'r', 'data/players')
	local config = Json.decode(file:read('*a'))
	file:close()
	if not config then
		config = {}
	end

	ScpuiSystem.data.ScpuiOptionValues = config
else
	ScpuiSystem.data.ScpuiOptionValues = {}
	for i, v in ipairs(ScpuiSystem.data.Custom_Options) do
		ScpuiSystem.data.ScpuiOptionValues[v.Key] = v.Value
	end
	---@type json
	local Json = require('dkjson')
	local file = cf.openFile(saveFilename, 'w', 'data/players')
	file:write(Json.encode(ScpuiSystem.data.ScpuiOptionValues))
	file:close()
end

ScpuiSystem:addHook("On State End", function()
	if (hv.NewState.Name == "GS_STATE_MAIN_MENU") then
		ScpuiSystem:applyCustomOptions()
	end
end, {State="GS_STATE_INITIAL_PLAYER_SELECT"})

ScpuiSystem:addHook("On State End", function()
	ScpuiSystem:applyCustomOptions()
end, {State="GS_STATE_BARRACKS_MENU"})