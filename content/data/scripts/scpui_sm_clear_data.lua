-----------------------------------
--This file adds hooks used to clear loadouts in specific cases
-----------------------------------

--- Clears all the current loadout if F12 is detected during mission load
--- @return nil
local function clearLoadoutWithKeypress()
	local LoadoutHandler = require("lib_loadout_handler")

	local key = LoadoutHandler:getMissionKey()
	ba.print("SCPUI got command to delete loadout file '" .. key .. "'!\n")

	local data = LoadoutHandler:loadLoadoutsFromFile()

	if data == nil then return end

	data[key] = nil

	LoadoutHandler:saveLoadoutsToFile(data)
end

--- Clears all campaign related loadout save data on campaign start or restart
--- @return nil
local function clearLoadoutOnCampaignStart()
	ba.print("SCPUI got command to delete all campaign loadouts!\n")

	local LoadoutHandler = require("lib_loadout_handler")
	local data = LoadoutHandler:loadLoadoutsFromFile()

	if data == nil then return end

	---@param k string
	for k, _ in pairs(data) do
		if k:sub(-1) == "c" then
			data[k] = nil
		end
	end

	LoadoutHandler:saveLoadoutsToFile(data)
end

--- Do not create engine hookes if we're in FRED
if ba.inMissionEditor() then
	return
end

ScpuiSystem:addHook("On Key Pressed", function()
	clearLoadoutWithKeypress()
end,
{State="GS_STATE_START_GAME", KeyPress="F12"})

ScpuiSystem:addHook("On Campaign Begin", function()
	clearLoadoutOnCampaignStart()
end)