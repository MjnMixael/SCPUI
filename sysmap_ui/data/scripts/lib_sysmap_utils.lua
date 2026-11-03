local Utils = require("lib_utils")

local SysMapUtils = {
	unseenChecked = {},
	unseenCache = {}
}

--- Get the current mission to use for the map to display
--- @return string mission the mission name
function SysMapUtils:getCurrentMission()
	local missionname

	--Get current mission
	local oldState = ""
	if hv.OldState ~= nil then
		oldState = hv.OldState.Name
	end
	if mn.getMissionFilename() ~= "" and oldState ~= "GS_STATE_MAIN_MENU" then
		missionname = mn.getMissionFilename() .. ".fs2"
	else
		missionname = ca.getNextMissionFilename()
	end

	return missionname
end

--- Get the config file for the current campaign
--- @return sysmap_campaign_config config the campaign config
function SysMapUtils:getCampaignConfig()

	--- @type SysmapUi
	local SysmapUi = ScpuiSystem.extensions.SysmapUi

	return SysmapUi:loadSysMapTables().Configs[ba.getCurrentPlayer():getCampaignFilename()]
end

--- Get all the data for the current system
--- @param config sysmap_campaign_config the campaign config
--- @param missionname string the mission name
--- @param systemname string the system name
--- @return sysmap_entry | nil systemdata the system data
function SysMapUtils:getSystemData(config, missionname, systemname)
	--- @type SysmapUi
	local SysmapUi = ScpuiSystem.extensions.SysmapUi

	local systemdata = SysmapUi:loadSysMapTables().Systems

	if systemname == nil then

		--Find a match
		if missionname ~= "" then
			for key, value in pairs(config.Missions) do
				if missionname == key then
					systemname = value
				end
			end
		end

		--Or just default
		if not systemname and config.Default then
			systemname = config.Default
		end

	end

	return systemdata[systemname]
end

--- Get the system name for the current mission
--- @param config sysmap_campaign_config the campaign config
--- @param missionname string the mission name
--- @return string | nil systemname the system name
function SysMapUtils:getSystemName(config, missionname)
	local systemname = nil

	--Find a match
	if missionname ~= "" then
		for key, value in pairs(config.Missions) do
			if missionname == key then
				systemname = value
			end
		end
	end

	--Or just default
	if not systemname and config.Default then
		systemname = config.Default
	end

	return systemname
end

--- Clear the system map cache
--- @return nil
function SysMapUtils:clearCache()
	self.unseenCache = {}
	self.unseenChecked = {}
end

--- Check if there are any unseen elements in the system map
--- @param systemname string the system name
--- @param systemdata sysmap_entry the system data
--- @return boolean hasUnseen whether there are any unseen elements
function SysMapUtils:hasUnseen(systemname, systemdata)
	for k, v in pairs(systemdata.Elements) do
		--Careful! This could end up looping forever!
		if v.ZoomTo then
			--This could recursively check itself forever, so limit it to 20 and warn to give an out
			if #self.unseenChecked > 20 then
				ba.warning("System Map has checked over 20 systems for new entries! Are you sure your map isn't recursive?")
			end

			local val = nil
			if not Utils.table.contains(self.unseenChecked, v.ZoomTo) then
				table.insert(self.unseenChecked, v.ZoomTo)
				val = self:checkNew(v.ZoomTo)
				self.unseenCache[v.ZoomTo] = val
			else
				val = self.unseenCache[v.ZoomTo]
			end

			if val == true then
				self:clearCache()
				return true
			end
		else
			if v.ShowNew == true or v.ShowNewPersist == true then
				if self:getIconSeen(systemname, v) ~= true then
					self:clearCache()
					return true
				end
			end
		end
	end
	self:clearCache()
	return false
end

--- Check if there are any unseen elements in a named system definition
--- @param systemname string | nil the system name
--- @return boolean hasUnseen whether there are any unseen elements
function SysMapUtils:checkNew(systemname)

	local config = self:getCampaignConfig()

	if config == nil then
		return false
	end

	local mission = self:getCurrentMission()

	if systemname == nil then
		systemname = self:getSystemName(config, mission)
	end

	if systemname == nil or mission == nil then
		return false
	end

	local systemdata = self:getSystemData(config, mission, systemname)

	if systemdata == nil then
		return false
	end

	return self:hasUnseen(systemname, systemdata)
end

--- Load the save data for the current player
--- @return sysmap_save_data data the save data
function SysMapUtils:loadSaveData()
	local DataSaver = require("lib_data_saver")

	local saveLocation = "sysmap_" .. ba.getCurrentPlayer():getCampaignFilename()
	local saveData = DataSaver:loadDataFromFile(saveLocation, true)

	if saveData == nil then
		saveData = self:createSave()
	end

	return saveData
end

--- Save the data for the current player
--- @param data sysmap_save_data? data the save data
--- @return nil
function SysMapUtils:saveData(data)
	if data == nil then
		data = self:createSave()
	end

	local saveLocation = "sysmap_" .. ba.getCurrentPlayer():getCampaignFilename()
	local datasaver = require("lib_data_saver")
	datasaver:saveDataToFile(saveLocation, data, true)
end

--- Reset the save data for the current player to default
--- @return nil
function SysMapUtils:resetData()
	self:saveData(self:createSave())
end

--- Create a new save data object
--- @return sysmap_save_data t the save data
function SysMapUtils:createSave()
	---@type sysmap_save_data
	local t = {
		Visbility = {},
		Maps = {},
		Persistent = {}
	}

	return t
end

--- Set the icon as seen or unseen
--- @param map string the map name
--- @param icon sysmap_element the icon to set
--- @param seen boolean whether the icon is seen
--- @return nil
function SysMapUtils:setIconSeen(map, icon, seen)
	SysMapUtils:setIconsSeen(map, {icon}, seen)
end

--- Set multiple icons as seen or unseen with a single load and save. Only writes to disk if something changed
--- @param map string the map name
--- @param icons sysmap_element[] the icons to set
--- @param seen boolean whether the icons are seen
--- @return nil
function SysMapUtils:setIconsSeen(map, icons, seen)
	if #icons == 0 then
		return
	end

	local data = SysMapUtils:loadSaveData()

	if data.Maps[map] == nil then
		data.Maps[map] = {}
	end

	if data.Persistent == nil then
		data.Persistent = {}
	end

	--only save a boolean
	if seen ~= true then
		seen = false
	end

	local changed = false
	for _, icon in ipairs(icons) do
		local target = data.Maps[map]
		if icon.ShowNewPersist == true then
			target = data.Persistent
		end

		if target[icon.ObjectName] ~= seen then
			target[icon.ObjectName] = seen
			changed = true
		end
	end

	if changed then
		SysMapUtils:saveData(data)
	end
end

--- Get the seen status of an icon
--- @param map string the map name
--- @param icon sysmap_element the icon to check
--- @param data? sysmap_save_data already loaded save data to use instead of loading it from disk
--- @return boolean val whether the icon is seen
function SysMapUtils:getIconSeen(map, icon, data)
	data = data or SysMapUtils:loadSaveData()

	if data.Maps[map] == nil then
		data.Maps[map] = {}
	end

	if data.Persistent == nil then
		data.Persistent = {}
	end

	local val
	if icon.ShowNewPersist == true then
		val = data.Persistent[icon.ObjectName]

	else
		val = data.Maps[map][icon.ObjectName]
	end

	if val == nil then
		val = false
	end

	return val
end

--- Set the icon as visible or invisible
--- @param icon string the icon name
--- @param visibility boolean whether the icon is visible
--- @return nil
function SysMapUtils:setIconVisibility(icon, visibility)
	local data = SysMapUtils:loadSaveData()

	data.Visbility[icon] = visibility

	SysMapUtils:saveData(data)
end

--- Get the visibility status of an icon
--- @param icon string the icon name
--- @param data? sysmap_save_data already loaded save data to use instead of loading it from disk
--- @return boolean | nil whether the icon is visible
function SysMapUtils:getIconVisibility(icon, data)
	data = data or SysMapUtils:loadSaveData()

	if data.Visbility[icon] ~= nil then
		return data.Visbility[icon]
	end

	return nil
end

return SysMapUtils