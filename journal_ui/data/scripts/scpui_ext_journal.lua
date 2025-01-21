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
--- @field Visible boolean True if the journal entry is visible, false otherwise
--- @field Unread boolean True if the journal entry is unread, false otherwise

--- Scpui Journal Extension
--- @class JournalUi
--- @field parseJournalTable fun(self: JournalUi, filename: string): scpui_journal_data Parses a journal table from the specified file.
--- @field loadDataFromFile fun(self: JournalUi): table<number, scpui_journal_save_data[]> Loads the journal save data from disk.
--- @field saveDataToFile fun(self: JournalUi, data: table<number, scpui_journal_save_data[]>): nil Saves the journal data to disk.
--- @field checkNew fun(self: JournalUi): boolean Checks if there are new journal entries.
--- @field getTitle fun(self: JournalUi): string Returns the title of the journal.
--- @field doesConfigExist fun(self: JournalUi): boolean Checks if the journal configuration exists on disk.
--- @field lockEntry fun(self: JournalUi, section: string, ...: string[]): nil Locks the specified journal entries.
--- @field unlockEntry fun(self: JournalUi, section: string, ...: string[]): boolean Unlocks the specified journal entries.

--- Create the local JournalUi object
local JournalUi = {
	Name = "Journal",
	Version = "1.0.0",
	Key = "JournalUi"
}

JournalUi.SectionEnum = nil --- @type LuaEnum the enum for a journal section in the sexp operators
JournalUi.Enum_Lists = {} --- @type LuaEnum[] the enums for the journal entries in the sexp operators

--- Initialize the JournalUi object. Called after the journal extension is registered with SCPUI
--- @return nil
function JournalUi:init()

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
		ScpuiSystem:loadSubmodules("jrnl")

		-- Register journal-specific topics
		ScpuiSystem:registerExtensionTopics("journal", {
			initialize = function() return nil end,
			unload = function() return nil end
		})

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
				t.Key = parse.getString()
			else
				t.Key = new_index
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

			--t.Name = newIndex .. " - " .. t.GroupIndex .. " - " .. t.Name

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
		local language_file = filename:gsub(".txt", "") .. "-" .. language .. ".txt"
		if cf.fileExists(language_file, "data/fiction", true) then
			filename = language_file
		end
	end
	return filename

end

--These are only needed for FS2 and not FRED?

--- Load the journal data for the current player
--- @return scpui_journal_data? data the loaded journal data
function JournalUi:loadData()

	local player = ba.getCurrentPlayer()
	local campaign_filename = player:getCampaignFilename()

	self.Data = self:parseJournalTable(campaign_filename .. "-journal.tbl")

	if self.Data then
		self.SaveData = self:loadDataFromFile()
	end

end

--- Unload the journal data
--- @return nil
function JournalUi:unloadData()
	self.Data = nil
	self.SaveData = nil
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

	local save_location = "journal_" .. ba.getCurrentPlayer():getCampaignFilename()
	local Datasaver = require("lib_data_saver")
	local config = Datasaver:loadDataFromFile(save_location, true)

	if config == nil then
		config = self:createSaveData()
		self:saveDataToFile(config)
	end

	return config

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
	local t = {}

	local config = self:loadDataFromFile()

	if config ~= nil then
		t = config
	else
		self:loadData()
		if self.Data then
			return true
		else
			return false
		end
	end

	for i = 1, #t do
		for j, v in ipairs(t[i]) do
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

	local t = {}

	if not self.Data then
		self:loadData()
	end

	for i, section in ipairs(self.Data.Entry_List) do

		if not t[i] then t[i] = {} end
		local save_section = t[i]

		for j, entry in ipairs(section) do

			if not save_section[j] then

				local t = {}
				t.Key = string.lower(entry.Key)
				t.Unread = true
				t.Visible = entry.InitialVis

				save_section[j] = t

			end

		end
	end

	ba.print("Journal UI: Initial save data created!")

	return t

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
	self:loadData()
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
	--unload
	self:unloadData()

end

--- Unlock a journal entry
--- @param section string the section to unlock the entry in
--- @vararg string[] the key(s) of the entry to unlock
--- @return boolean unlocked whether the entry was unlocked
function JournalUi:unlockEntry(section, ...)
  local unlocked = false
	--load data
	self:loadData()
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
	--unload
	self:unloadData()
  return unlocked
end

--- Get the title of the journal UI
--- @return string title the title of the journal UI
function JournalUi:getTitle()
	local player = ba.getCurrentPlayer()
	local campaign_filename = player:getCampaignFilename()
	local data = self:parseJournalTable(campaign_filename .. "-journal.tbl")
	return data.Title
end

--- Clear all journal data and reset to default
--- @return nil
function JournalUi:clearAll()
	local config = self:createSaveData()
	self:saveDataToFile(config)
end

return JournalUi