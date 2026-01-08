-----------------------------------
--This file extends SCPUI by adding the journal core methods and members
------------------------------------

--- SCPUI Journal Data
--- @class scpui_journal_data
--- @field Visible_List Element[] The list of visible entry elements
--- @field Section_List scpui_journal_section[] The sections of the journal
--- @field Entry_List scpui_journal_entry[] table The entries of the journal
--- @field Title string The title of the journal

--- SCPUI Journal Section
--- @class scpui_journal_section
--- @field Display string The display name of the section
--- @field Name string The name of the section

--- SCPUI Journal Entry
--- @class scpui_journal_entry
--- @field File string? The filename of the journal entry
--- @field Image string? The image filename of the journal entry
--- @field Caption string? The caption of the journal entry
--- @field Name string? The name of the journal entry
--- @field Display string? The display name of the journal entry
--- @field Key string? The element key of the journal entry
--- @field Group string? The group of the journal entry
--- @field GroupIndex number? The index of the group of the journal entry
--- @field InitialVis boolean? True if the journal entry is initially visible, false otherwise

--- SCPUI Journal Save Data
--- @class scpui_journal_save_data
--- @field Key string The key of the journal entry
--- @field Visible boolean True if the journal entry is visible, false otherwise
--- @field Unread boolean True if the journal entry is unread, false otherwise

--- Scpui Journal Extension
--- @class JournalUi
--- @field saveDataToFile fun(self: JournalUi, data: table<number, scpui_journal_save_data[]>): nil Saves the journal data to disk.
--- @field getData fun(self: JournalUi): scpui_journal_data? Gets the journal data.
--- @field getSaveData fun(self: JournalUi): table<number, scpui_journal_save_data[]>? Gets the journal save data.
--- @field checkNew fun(self: JournalUi): boolean Checks if there are new journal entries.
--- @field getTitle fun(self: JournalUi): string Returns the title of the journal.
--- @field doesConfigExist fun(self: JournalUi): boolean Checks if the journal configuration exists on disk.
--- @field lockEntry fun(self: JournalUi, section: string, ...: string[]): nil Locks the specified journal entries.
--- @field unlockEntry fun(self: JournalUi, section: string, ...: string[]): boolean Unlocks the specified journal entries.

--- Create the local JournalUi object
local JournalUi = {
	Name = "Journal",
	Version = "1.0.0",
	Submodule = "jrnl",
	Key = "JournalUi"
}

JournalUi.LoadedCampaign = nil --- @type string? the currently loaded campaign filename
JournalUi.SectionEnum = nil --- @type LuaEnum the enum for a journal section in the sexp operators
JournalUi.Enum_Lists = {} --- @type LuaEnum[] the enums for the journal entries in the sexp operators

--- Initialize the JournalUi object. Called after the journal extension is registered with SCPUI
--- @return nil
function JournalUi:init()

	self.LoadedCampaign = nil

	mn.LuaSEXPs["lua-journal-unlock-article"].Action = function(section, ...)

		--Remove the first part of the parent enum name so we can unlock using the actual section name
		local function removeJournalPrefix(inputString)
			local prefix = "Journal "
			if string.sub(inputString, 1, #prefix) == prefix then
				return string.sub(inputString, #prefix + 1)
			else
				return inputString
			end
		end

		if mn.isInCampaign() then
			self:unlockEntry(removeJournalPrefix(section), ...)
		end
	end

	-- Register journal-specific topics
	ScpuiSystem:registerExtensionTopics("journal", {
		initialize = function() return nil end,
		unload = function() return nil end
	})

	--- If we're in FRED then create all the enums
	if ba.inMissionEditor() then
		local journal_files = cf.listFiles("data/tables", "*journal.tbl")

		for _, v in pairs(journal_files) do
			local data = self:parseJournalTable(v)

			if #data.Section_List > 0 then
				local name = "Journal Sections"
				self.SectionEnum = mn.LuaEnums[name]
				self.SectionEnum:removeEnumItem("<none>")
			end
			for i = 1, #data.Section_List do
				local name = "Journal " .. data.Section_List[i].Display
				mn.addLuaEnum(name)
				self.SectionEnum:addEnumItem(name)
				self.Enum_Lists[i] = mn.LuaEnums[name]
			end

			for i = 1, #data.Entry_List do
				for _, entry in ipairs(data.Entry_List[i]) do
					self.Enum_Lists[i]:addEnumItem(entry.Key)
				end
			end
		end
	else
		--- On campaign begin, clear the journal data
		ScpuiSystem:addHook("On Campaign Begin", function()
			self:clearAll()
		end)
	end

end

--- Get the index for a specific section in a list of sections
--- @param section_name string the name of the section to find
--- @param sections scpui_journal_section the list of sections to search
--- @return number? index the index of the section in the list
function JournalUi:getGroupIndex(section_name, sections)

	section_name = string.lower(section_name)

	for i, v in ipairs(sections) do
		if string.lower(v.Name) == section_name then
			return i
		end
	end

	ba.error("Journal: Undefined group defined! Could not find " .. section_name .. " group! Add or check spelling!")

	return nil

end

--- Parse a journal table file
--- @param file string the file to parse
--- @param entries_only? boolean whether to only parse the entries
--- @return scpui_journal_data data the parsed journal data
function JournalUi:parseJournalTable(file, entries_only)

	---@type scpui_journal_data
	local new_data = {
		Visible_List = {},
		Section_List = {},
		Entry_List = {},
		Title = ba.XSTR("Journal", 888550),
	}

	if not parse.readFileText(file, "data/tables") then
		return new_data
	end

	if (not entries_only) and parse.optionalString("#Journal Options") then
		if parse.optionalString("$Title:") then
			new_data.Title = parse.getString()
		end
		parse.requiredString("#End")
	end

	 if (not entries_only) and parse.optionalString("#Journal Sections") then

		while parse.optionalString("$Name:") and (#new_data.Section_List < 3) do

			local t = {}

			t.Name = parse.getString()

			if parse.requiredString("$XSTR:") then
				t.Display = ba.XSTR(t.Name, parse.getInt())
			end

		new_data.Section_List[#new_data.Section_List+1] = t

		end

		parse.requiredString("#End")

	end

	if parse.optionalString("#Journal Entries") then

		local function normalizeKey(s)
			s = string.lower(s)
			s = s:gsub("[^a-z0-9]+", "_")
			s = s:gsub("_+", "_")
			s = s:gsub("^_+", ""):gsub("_+$", "")
			return s
		end

		while parse.optionalString("$Name:") do

			---@type scpui_journal_entry
			local t = {}
			local new_index

			t.Name = parse.getString()

			if parse.requiredString("$XSTR:") then
				t.Display = ba.XSTR(t.Name, parse.getInt())
			end

			if parse.requiredString("$Group:") then
				t.Group = parse.getString()
				t.GroupIndex = self:getGroupIndex(t.Group, new_data.Section_List)
			end

			if parse.optionalString("$Visible by Default:") then
				t.InitialVis = parse.getBoolean()
			else
				t.InitialVis = false
			end

			if parse.optionalString("$Short Title:") then
				t.Key = normalizeKey(parse.getString())
			else
				-- Generate key from Name
				t.Key = normalizeKey(t.Name)
			end

			if parse.requiredString("$File:") then
				t.File = self:checkLanguage(parse.getString())
			end

			if parse.optionalString("$Image:") then
				t.Image = parse.getString()
			end

			if parse.optionalString("$Caption:") then
				local caption = parse.getString()
				if parse.requiredString("$Caption XSTR:") then
					t.Caption = ba.XSTR(caption, parse.getInt())
				end
			end

			if not new_data.Entry_List[t.GroupIndex] then new_data.Entry_List[t.GroupIndex] = {} end

			new_index = #new_data.Entry_List[t.GroupIndex] + 1

			--- Ensure key is not empty in rare edge cases
			if t.Key == "" then
				t.Key = "entry_" .. tostring(new_index)
			end

			new_data.Entry_List[t.GroupIndex][new_index] = t

		end

		parse.requiredString("#End")

	end

	parse.stop()

	return new_data

end

--- Check for a language specific file
--- @param filename string the file to check
--- @return string filename the filename to use
function JournalUi:checkLanguage(filename)

	local language = ba.getCurrentLanguageExtension()
	if language ~= "" then
		local language_file = filename:gsub("%.txt", "") .. "-" .. language .. ".txt"
		if cf.fileExists(language_file, "data/fiction", true) then
			filename = language_file
		end
	end
	return filename

end

--These are only needed for FS2 and not FRED?

--- Ensure the journal data table is loaded
--- @return boolean loaded whether the journal data is loaded
function JournalUi:ensureLoaded()
  if not self:ensureTableLoaded() then
    return false
  end

  self.SaveData = self:loadDataFromFile()
  return true
end

--- Ensure the journal data table is loaded
--- @return boolean loaded whether the journal data is loaded
function JournalUi:ensureTableLoaded()
  local player = ba.getCurrentPlayer()
  local campaign_filename = player:getCampaignFilename()

  if self.Data and self.LoadedCampaign == campaign_filename then
    return true
  end

  self.Data = self:parseJournalTable(campaign_filename .. "-journal.tbl")
  self.LoadedCampaign = campaign_filename

  return self.Data ~= nil
end


--- Unload the journal data
--- @return nil
function JournalUi:unloadData()
	self.Data = nil
	self.SaveData = nil
	self.LoadedCampaign = nil
end

--- Check if the journal table exists
--- @return boolean exists whether the journal table exists
function JournalUi:doesConfigExist()

	local player = ba.getCurrentPlayer()
	local campaign_filename = player:getCampaignFilename()

	if cf.fileExists(campaign_filename .. "-journal.tbl", "data/tables", true) then
		return true
	else
		return false
	end

end

--- Load the journal data from a file
--- @return table<number, scpui_journal_save_data[]> config the loaded journal data
function JournalUi:loadDataFromFile()

	if not self.Data then
		ba.error("JournalUi:loadDataFromFile called before table was loaded.")
		return {}
	end

	local save_location = "journal_" .. ba.getCurrentPlayer():getCampaignFilename()
	local Datasaver = require("lib_data_saver")
	local config = Datasaver:loadDataFromFile(save_location, true)

	if config == nil then
		config = self:createSaveData()
		self:saveDataToFile(config)
		return config
	end

	if self:reconcileSaveData(config) then
		self:saveDataToFile(config)
	end

	return config

end

--- Get the journal data
--- @return scpui_journal_data? data the journal data
function JournalUi:getData()
	if not self:ensureTableLoaded() then
		return nil
	end
	return self.Data
end

--- Get the journal save data
--- @return table<number, scpui_journal_save_data[]>? data the journal save data
function JournalUi:getSaveData()
	if not self:ensureLoaded() then
		return nil
	end
	return self.SaveData
end

--- Clear the new flag for all entries and save it
--- @return nil
function JournalUi:clearNew()

	local t = {}

	local save_location = "journal_" .. ba.getCurrentPlayer():getCampaignFilename()
	local Datasaver = require("lib_data_saver")
	Datasaver:saveDataToFile(save_location, t, true)

end

--- Check if there are any new entries
--- @return boolean new whether there are new entries
function JournalUi:checkNew()
	if not self:ensureLoaded() then
		return false
	end

	local t = self.SaveData or {}

	for i = 1, #t do
		for j = 1, #t[i] do
			local item = t[i][j]
			if item and item.Visible == true and item.Unread == true then
				return true
			end
		end
	end

	return false
end

--- Create the journal save data
--- @return table<number, scpui_journal_save_data[]> t the created save data
function JournalUi:createSaveData()

	if not self.Data then
		ba.error("JournalUi:createSaveData called before table was loaded.")
		return {}
	end

	local t = {}

	for i, section in ipairs(self.Data.Entry_List) do

		if not t[i] then t[i] = {} end
		local save_section = t[i]

		for j, entry in ipairs(section) do

			if not save_section[j] then

				local item = {}
				item.Key = string.lower(entry.Key)
				item.Unread = true
				item.Visible = entry.InitialVis

				save_section[j] = item

			end

		end
	end

	ba.print("Journal UI: Initial save data created!")

	return t

end

--- Reconcile existing journal save data with the current parsed table.
--- Adds new entries, preserves existing Visible/Unread, and rebuilds in current table order.
--- Returns true if config was modified.
--- @param config table<number, scpui_journal_save_data[]>
--- @return boolean changed
function JournalUi:reconcileSaveData(config)

  if not self.Data or not self.Data.Entry_List then
    return false
  end

  local changed = false

  for section_index, section_entries in ipairs(self.Data.Entry_List) do
    if config[section_index] == nil then
      config[section_index] = {}
      changed = true
    end

    -- Lookup existing saved items by key
    local saved_by_key = {}
    for _, saved in ipairs(config[section_index]) do
      if saved and saved.Key then
        saved_by_key[string.lower(saved.Key)] = saved
      end
    end

    -- Rebuild saved list to match current table ordering
    local rebuilt = {}

    for entry_index, entry in ipairs(section_entries) do
		local key = string.lower(entry.Key or "")
		if key == "" then
			key = "entry_" .. tostring(entry_index)
			changed = true
		end
		local saved = saved_by_key[key]

		if saved == nil then
			saved = {
				Key = key,
				Unread = true,
				Visible = entry.InitialVis == true
			}
			changed = true
		else
			-- Ensure required fields exist
			if saved.Key == nil then
				saved.Key = key
				changed = true
			end
			if saved.Unread == nil then
				saved.Unread = true
				changed = true
			end
			if saved.Visible == nil then
				saved.Visible = entry.InitialVis == true
				changed = true
			end
		end

		rebuilt[entry_index] = saved
    end

    config[section_index] = rebuilt
  end

  return changed
end

--- Save the journal data to disk
--- @param t table<number, scpui_journal_save_data[]> the data to save
--- @return nil
function JournalUi:saveDataToFile(t)

	local save_location = "journal_" .. ba.getCurrentPlayer():getCampaignFilename()
	local Datasaver = require("lib_data_saver")
	Datasaver:saveDataToFile(save_location, t, true)

end

--- Lock a journal entry
--- @param section string the section to lock the entry in
--- @vararg string[] the key(s) of the entry to lock
--- @return nil
function JournalUi:lockEntry(section, ...)

	--load data
	if not self:ensureLoaded() then return end
	--get section
	local section = self:getGroupIndex(section, self.Data.Section_List)
	--get key(s)
	for _, v in ipairs(arg) do
		for _, entry in ipairs(self.SaveData[section] or {}) do
			if string.lower(v[1] or v) == entry.Key then
				entry.Visible = false
				break
			end
		end
	end
	--save
	self:saveDataToFile(self.SaveData)

end

--- Unlock a journal entry
--- @param section string the section to unlock the entry in
--- @vararg string[] the key(s) of the entry to unlock
--- @return boolean unlocked whether the entry was unlocked
function JournalUi:unlockEntry(section, ...)
  local unlocked = false
	--load data
	if not self:ensureLoaded() then return false end
	--get section
	local section = self:getGroupIndex(section, self.Data.Section_List)
	--get key(s)
	for _, v in ipairs(arg) do
		for _, entry in ipairs(self.SaveData[section] or {}) do
			if string.lower(v[1] or v) == entry.Key then
        unlocked = not entry.Visible
				entry.Visible = true
				break
			end
		end
	end
	--save
	self:saveDataToFile(self.SaveData)
  return unlocked
end

--- Get the title of the journal UI
--- @return string title the title of the journal UI
function JournalUi:getTitle()
	if not self:ensureTableLoaded() then
		return ba.XSTR("Journal", 888550)
	end
	return self.Data.Title
end

--- Clear all journal data and reset to default
--- @return nil
function JournalUi:clearAll()
	if not self:ensureTableLoaded() then
    	return
	end
	local config = self:createSaveData()
	self:saveDataToFile(config)
end

return JournalUi