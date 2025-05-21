-----------------------------------
--Controller for the Tech Database UI
-----------------------------------

local AsyncUtil = require("lib_async")
local Dialogs = require("lib_dialogs")
local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local TechDatabaseController = Class()

TechDatabaseController.STATE_DATABASE = 0 --- @type number The enumeration for the database state
TechDatabaseController.STATE_SIMULATOR = 1 --- @type number The enumeration for the simulator state
TechDatabaseController.STATE_CUTSCENE = 2 --- @type number The enumeration for the cutscene state
TechDatabaseController.STATE_CREDITS = 3 --- @type number The enumeration for the credits state

TechDatabaseController.SECTION_SHIPS = 1 --- @type number The enumeration for the ships section
TechDatabaseController.SECTION_WEAPONS = 2 --- @type number The enumeration for the weapons section
TechDatabaseController.SECTION_INTEL = 3 --- @type number The enumeration for the intel section

--- Called by the class constructor
--- @return nil
function TechDatabaseController:init()
	self.Document = nil --- @type Document The RML document
	self.ShowAll = false --- @type boolean Whether to show all entries
	self.Counter = 0 --- @type number The counter for the number of entries
	self.HelpShown = false --- @type boolean Whether the help dialog is being shown
	self.FirstRun = false --- @type boolean If true the angle and speed slider values will be saved to disk
	self.Ships_List = {} --- @type scpui_tech_database_entry[] The list of ships
	self.Weapons_List = {} --- @type scpui_tech_database_entry[] The list of weapons
	self.Intel_List = {} --- @type scpui_tech_database_entry[] The list of intel
	self.Ship_Types = {} --- @type string[] The list of ship types
	self.Weapon_Types = {} --- @type string[] The list of weapon types
	self.Intel_Types = {} --- @type string[] The list of intel types
	self.SelectedEntry = nil --- @type scpui_tech_database_entry The currently selected entry
	self.SelectedSection = nil --- @type string The currently selected section
	self.Current_List = {} --- @type scpui_tech_database_entry[] The current list of entries
	self.Visible_List = {} --- @type scpui_tech_database_entry[] The list of visible entries
	self.SectionIndex = nil --- @type number The index of the section. Should be one of the SECTION_ enumerations
	self.CurrentSort = nil --- @type string The current sort method
	self.CurrentSortCategory = nil --- @type string The current sort category
	self.CurrentCategory = nil --- @type string The current category
	self.ItemSort = nil --- @type function The current item sort function
	self.Sort_Functions = {} --- @type table<string, function> The table of sort functions
	self.Seen_Data = {} --- @type table<string, table<string, boolean>> Keeps track of what tech descriptions have been seen

	ScpuiSystem.data.memory.model_rendering = {
		Mx = 0,
		My = 0,
		Sx = 0,
		Sy = 0
	}
end

--- Called by the RML document
--- @param document Document
function TechDatabaseController:initialize(document)
    self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.Document:GetElementById("tech_btn_1"):SetPseudoClass("checked", true)
	self.Document:GetElementById("tech_btn_2"):SetPseudoClass("checked", false)
	self.Document:GetElementById("tech_btn_3"):SetPseudoClass("checked", false)
	self.Document:GetElementById("tech_btn_4"):SetPseudoClass("checked", false)

	Topics.techroom.initialize:send(self)
	Topics.techdatabase.initialize:send(self)

	self:InitSortFunctions()

	--Get all the table data fresh each time in case there are changes
	self:LoadData()

	self:change_section(self.SECTION_SHIPS)

	local a_slider_el = self.Document:GetElementById("angle_range_cont").first_child
	local a_range_el = Element.As.ElementFormControlInput(a_slider_el)
	a_range_el.value = ScpuiSystem.data.ScpuiOptionValues.Database_Model_Angle or 0.5

	local s_slider_el = self.Document:GetElementById("speed_range_cont").first_child
	local s_range_el = Element.As.ElementFormControlInput(s_slider_el)
	s_range_el.value = ScpuiSystem.data.ScpuiOptionValues.Database_Model_Speed or 0.5

end

--- Iterate over all the ships, weapons, and intel but only grab the necessary data
--- @return nil
function TechDatabaseController:LoadData()

	--Initialize the lists
	self.Ships_List = {}
	self.Weapons_List = {}
	self.Intel_List = {}

	--Initialize the category tables
	self.Ship_Types = {}
	self.Weapon_Types = {}
	self.Intel_Types = {}

	--Load seen data and verify tables
	self.Seen_Data = self:loadSeenDataFromFile()
	if self.Seen_Data["ships"] == nil then
		self.Seen_Data["ships"] = {}
	end
	if self.Seen_Data["weapons"] == nil then
		self.Seen_Data["weapons"] = {}
	end
	if self.Seen_Data["intel"] == nil then
		self.Seen_Data["intel"] = {}
	end

	Topics.techdatabase.beginDataLoad:send(self)

	local list_ships = tb.ShipClasses
	local i = 1
	while (i < #list_ships) do
		if list_ships[i]:hasCustomData() and list_ships[i].CustomData["HideInTechRoom"] == "true" then
			ba.print("Skipping ship " .. list_ships[i].Name .. " in the tech room list!\n")
		else
			--- @type scpui_tech_database_entry
			local ship = {
				Name = tostring(list_ships[i].Name),
				FsoIndex = list_ships[i]:getShipClassIndex(),
				DisplayName = Topics.ships.name:send(list_ships[i]),
				Description = Topics.ships.description:send(list_ships[i]),
				Type = tostring(list_ships[i].TypeString),
				Visible = Topics.ships.filter:send(list_ships[i]),
				Key = '',
				Selectable = true,
				Index = 0,
			}

			--build the category tables
			if not Utils.table.contains(self.Ship_Types, ship.Type) then
				table.insert(self.Ship_Types, ship.Type)
			end

			Topics.techdatabase.initShipData:send({self, ship})

			table.insert(self.Ships_List, ship)
		end
		i = i + 1
	end

	local list_weapons = tb.WeaponClasses
	local j = 1
	while (j < #list_weapons) do
		if list_weapons[j]:hasCustomData() and list_weapons[j].CustomData["HideInTechRoom"] == "true" then
			ba.print("Skipping weapon " .. list_weapons[j].Name .. " in the tech room list!\n")
		else
			local t_string = Utils.xstr("Primary", 888551)
			if list_weapons[j]:isSecondary() then
				t_string = Utils.xstr("Secondary", 888552)
			end
			--- @type scpui_tech_database_entry
			local weapon = {
				Name = tostring(list_weapons[j].Name),
				FsoIndex = list_weapons[j]:getWeaponClassIndex(),
				DisplayName = Topics.weapons.name:send(list_weapons[j]),
				Description = Topics.weapons.description:send(list_weapons[j]),
				Anim = tostring(list_weapons[j].TechAnimationFilename),
				Type = t_string,
				Visible = Topics.weapons.filter:send(list_weapons[j]),
				Key = '',
				Selectable = true,
				Index = 0,
			}

			--build the category tables
			if not Utils.table.contains(self.Weapon_Types, weapon.Type) then
				table.insert(self.Weapon_Types, weapon.Type)
			end

			Topics.techdatabase.initWeaponData:send({self, weapon})

			table.insert(self.Weapons_List, weapon)
		end
		j = j + 1
	end

	local list_intel = tb.IntelEntries
	local k = 1
	while (k < #list_intel) do
		--- @type scpui_tech_database_entry
		local intel = {
			Name = tostring(list_intel[k].Name),
			FsoIndex = k,
			DisplayName = Topics.intel.name:send(list_intel[k]),
			Type = Topics.intel.type:send(list_intel[k]),
			Description = Topics.intel.description:send(list_intel[k]),
			Anim = tostring(list_intel[k].AnimFilename),
			Visible = Topics.intel.filter:send(list_intel[k]),
			Key = '',
			Selectable = true,
			Index = 0,
		}

		--build the category tables
		if not Utils.table.contains(self.Intel_Types, intel.Type) then
			table.insert(self.Intel_Types, intel.Type)
		end

		Topics.techdatabase.initIntelData:send({self, intel})

		table.insert(self.Intel_List, intel)
		k = k + 1
	end

end

--- Called by the RML to set the sort type
--- @param sort string The sort type
--- @return nil
function TechDatabaseController:set_sort_type(sort)
	if sort == "name" then
		if self.CurrentSort == "name_asc" then
			self.CurrentSort = "name_des"
		else
			self.CurrentSort = "name_asc"
		end
	elseif sort == "index" then
		if self.CurrentSort == "index_asc" then
			self.CurrentSort = "index_des"
		else
			self.CurrentSort = "index_asc"
		end
	else --catch unhandled
		sort = "index_asc"
	end
	self:sortList()
	self:reloadList()
end

--- Called by the RML to set the sort category
--- @param category string The sort category
--- @return nil
function TechDatabaseController:set_sort_category(category)
	if category == "type" then
	    if self.CurrentSortCategory == "type_asc_alph" then
		    self.CurrentSortCategory = "type_des_alph"
		elseif self.CurrentSortCategory == "type_des_alph" then
		    self.CurrentSortCategory = "type_asc_idx"
		elseif self.CurrentSortCategory == "type_asc_idx" then
		    self.CurrentSortCategory = "type_des_idx"
		else
		    self.CurrentSortCategory = "type_asc_alph"
		end
	else --catch unhandled
		if Topics.techdatabase.setSortCat:send({self, category}) == false then
			self.CurrentSortCategory = "none"
		end
	end
	self:sortList()
	self:reloadList()
end

--- Initialize all the sort functions and save them for later use
--- @return nil
function TechDatabaseController:InitSortFunctions()

	self.Sort_Functions = {}

	--Item Sorters
	local function sortByIndexAsc(a, b)
		return a.FsoIndex < b.FsoIndex
	end
	self.Sort_Functions.sortByIndexAsc = sortByIndexAsc

	local function sortByIndexDes(a, b)
		return a.FsoIndex > b.FsoIndex
	end
	self.Sort_Functions.sortByIndexDes = sortByIndexDes

	local function sortByNameAsc(a, b)
		return a.Name < b.Name
	end
	self.Sort_Functions.sortByNameAsc = sortByNameAsc

	local function sortByNameDes(a, b)
		return a.Name > b.Name
	end
	self.Sort_Functions.sortByNameDes = sortByNameDes

	--Category Sorters
	local function sortByTypeAsc_Alph(a, b)
		if a.Type == b.Type then
			return self.ItemSort(a, b)
		else
			return a.Type < b.Type
		end
	end
	self.Sort_Functions.sortByTypeAsc_Alph = sortByTypeAsc_Alph

	local function sortByTypeDes_Alph(a, b)
		if a.Type == b.Type then
			return self.ItemSort(a, b)
		else
			return a.Type > b.Type
		end
	end
	self.Sort_Functions.sortByTypeDes_Alph = sortByTypeDes_Alph

	local function sortByTypeAsc_Idx(a, b)
		local tbl
		if self.SelectedSection == "ships" then
			tbl = self.Ship_Types
		elseif self.SelectedSection == "weapons" then
			tbl = self.Weapon_Types
		elseif self.SelectedSection == "intel" then
			tbl = self.Intel_Types
		end

		local a_idx = Utils.table.ifind(tbl, a.Type)
		local b_idx = Utils.table.ifind(tbl, b.Type)
		if a.Type == b.Type then
			return self.ItemSort(a, b)
		else
			return a_idx < b_idx
		end
	end
	self.Sort_Functions.sortByTypeAsc_Idx = sortByTypeAsc_Idx

	local function sortByTypeDes_Idx(a, b)
		local tbl
		if self.SelectedSection == "ships" then
			tbl = self.Ship_Types
		elseif self.SelectedSection == "weapons" then
			tbl = self.Weapon_Types
		elseif self.SelectedSection == "intel" then
			tbl = self.Intel_Types
		end

		local a_idx = Utils.table.ifind(tbl, a.Type)
		local b_idx = Utils.table.ifind(tbl, b.Type)
		if a.Type == b.Type then
			return self.ItemSort(a, b)
		else
			return a_idx > b_idx
		end
	end
	self.Sort_Functions.sortByTypeDes_Idx = sortByTypeDes_Idx

	Topics.techdatabase.initSortFuncs:send(self)
end

--- Sort the current list using the current sort method and category and save the sort method to the player file
--- @return nil
function TechDatabaseController:sortList()

	self.ItemSort = nil
	--loadstring(v.func .. '()' )()

	self:uncheckAllSortButtons()

	if self.CurrentSort == nil then
		self.CurrentSort = "index_asc"
	end

	if self.CurrentSortCategory == nil then
		self.CurrentSortCategory = "none"
	end

	--Check item sort
	if self.CurrentSort == "index_asc" then
		if self.CurrentSortCategory == "none" then
			table.sort(self.Current_List, self.Sort_Functions.sortByIndexAsc)
		else
			self.ItemSort = self.Sort_Functions.sortByIndexAsc
		end
		self.Document:GetElementById("default_sort_btn"):SetPseudoClass("checked", true)
	elseif self.CurrentSort == "index_des" then
		if self.CurrentSortCategory == "none" then
			table.sort(self.Current_List, self.Sort_Functions.sortByIndexDes)
		else
			self.ItemSort = self.Sort_Functions.sortByIndexDes
		end
		self.Document:GetElementById("default_sort_btn"):SetPseudoClass("checked", true)
	elseif self.CurrentSort == "name_asc" then
		if self.CurrentSortCategory == "none" then
			table.sort(self.Current_List, self.Sort_Functions.sortByNameAsc)
		else
			self.ItemSort = self.Sort_Functions.sortByNameAsc
		end
		self.Document:GetElementById("name_sort_btn"):SetPseudoClass("checked", true)
	elseif self.CurrentSort == "name_des" then
		if self.CurrentSortCategory == "none" then
			table.sort(self.Current_List, self.Sort_Functions.sortByNameDes)
		else
			self.ItemSort = self.Sort_Functions.sortByNameDes
		end
		self.Document:GetElementById("name_sort_btn"):SetPseudoClass("checked", true)
	else
		if Topics.techdatabase.sortItems:send(self) == false then
			ba.warning("Got invalid sort method! Using Default.")

			self.CurrentSort = "index_asc"
			return self:sortList()
		end
	end

	--Check categorization
	if self.CurrentSortCategory ~= "none" then
		if self.CurrentSortCategory == "type_asc_alph" then
			table.sort(self.Current_List, self.Sort_Functions.sortByTypeAsc_Alph)
			self.Document:GetElementById("type_cat_btn"):SetPseudoClass("checked", true)
		elseif self.CurrentSortCategory == "type_des_alph" then
			table.sort(self.Current_List, self.Sort_Functions.sortByTypeDes_Alph)
			self.Document:GetElementById("type_cat_btn"):SetPseudoClass("checked", true)
		elseif self.CurrentSortCategory == "type_asc_idx" then
			table.sort(self.Current_List, self.Sort_Functions.sortByTypeAsc_Idx)
			self.Document:GetElementById("type_cat_btn"):SetPseudoClass("checked", true)
		elseif self.CurrentSortCategory == "type_des_idx" then
			table.sort(self.Current_List, self.Sort_Functions.sortByTypeDes_Idx)
			self.Document:GetElementById("type_cat_btn"):SetPseudoClass("checked", true)
		else
			if Topics.techdatabase.sortCategories:send(self) == false then
				ba.warning("Got invalid sort category! Using Default.")
				self.CurrentSortCategory = "none"
				return self:sortList()
			end
		end
	else
		self.Document:GetElementById("default_cat_btn"):SetPseudoClass("checked", true)
	end

	--save the choice to the player file
	if ScpuiSystem.data.ScpuiOptionValues.Database_Sort_Method == nil then
		ScpuiSystem.data.ScpuiOptionValues.Database_Sort_Method = {}
			ScpuiSystem.data.ScpuiOptionValues.Database_Sort_Method["ships"] = "index_asc"
			ScpuiSystem.data.ScpuiOptionValues.Database_Sort_Method["weapons"] = "index_asc"
			ScpuiSystem.data.ScpuiOptionValues.Database_Sort_Method["intel"] = "index_asc"
	end
	if ScpuiSystem.data.ScpuiOptionValues.Database_Category == nil then
		ScpuiSystem.data.ScpuiOptionValues.Database_Category = {}
			ScpuiSystem.data.ScpuiOptionValues.Database_Category["ships"] = "none"
			ScpuiSystem.data.ScpuiOptionValues.Database_Category["weapons"] = "none"
			ScpuiSystem.data.ScpuiOptionValues.Database_Category["intel"] = "none"
	end
	ScpuiSystem.data.ScpuiOptionValues.Database_Sort_Method[self.SelectedSection] = self.CurrentSort
	ScpuiSystem.data.ScpuiOptionValues.Database_Category[self.SelectedSection] = self.CurrentSortCategory
	ScpuiSystem:saveOptionsToFile(ScpuiSystem.data.ScpuiOptionValues)
end

--- Uncheck all the sort buttons in the UI
--- @return nil
function TechDatabaseController:uncheckAllSortButtons()
	self.Document:GetElementById("default_sort_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("name_sort_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("default_cat_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("type_cat_btn"):SetPseudoClass("checked", false)

	Topics.techdatabase.uncheckSorts:send(self)
end

--- Get the first valied index for the list given the current sort category. 1 generally, but 2 if we have a category
--- This is because the header is not selectable in category mode
--- @return number val The first valid index
function TechDatabaseController:getFirstIndex()
	if self.CurrentSortCategory ~= "none" then
	    return 2
	else
		return 1
	end
end

--- Completely reloads the list of entries
--- @return nil
function TechDatabaseController:reloadList()

	local list_items_el = self.Document:GetElementById("list_items_ul")
	ScpuiSystem:clearEntries(list_items_el)
	self:ClearData()
	self.SelectedEntry = nil
	self.Visible_List = {}
	self.Counter = 0
	self:createListItemEntries(self.Current_List)
	self:selectEntry(self.Visible_List[self:getFirstIndex()])

end

--- Checks if the entry has been seen (is in the seen data table)
--- @param name string The name of the entry
--- @return boolean? seen The seen status or nil if not in the list
function TechDatabaseController:isSeen(name)
	if name ~= nil then
		return self.Seen_Data[self.SelectedSection][name]
	else
		return nil
	end
end

--- Sets the entry as seen
--- @param name string The name of the entry
--- @return nil
function TechDatabaseController:setSeen(name)
	if name ~= nil then
		self.Seen_Data[self.SelectedSection][name] = true
	end
end

--- Called by the RML to change to a different tech room state
--- @param element Element The element that was clicked
--- @param state number The state to change to. Should be one of the STATE_ enumerations
--- @return nil
function TechDatabaseController:change_tech_state(element, state)

	if state == self.STATE_DATABASE then
		--This is where we are already, so don't do anything
		--if Topics.techroom.btn1Action:send() == false then
			--ui.playElementSound(element, "click", "error")
		--end
	end
	if state == self.STATE_SIMULATOR then
		if Topics.techroom.btn2Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end
	if state == self.STATE_CUTSCENE then
		if Topics.techroom.btn3Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end
	if state == self.STATE_CREDITS then
		if Topics.techroom.btn4Action:send() == false then
			ui.playElementSound(element, "click", "error")
		end
	end

end

--- Called by the RML to change the current section between ships, weapons, and intel
--- @param section number The section to change to. Should be one of the SECTION_ enumerations
--- @return nil
function TechDatabaseController:change_section(section)

	self.SectionIndex = section
	local section_name = ''
	if section == self.SECTION_SHIPS then section_name = "ships" end
	if section == self.SECTION_WEAPONS then section_name = "weapons" end
	if section == self.SECTION_INTEL then section_name = "intel" end

	self.ShowAll = false
	self.Counter = 0

	if section_name ~= self.SelectedSection then

		self.Current_List = {}

		if section_name == "ships" then
			self.Current_List = self.Ships_List
		elseif section_name == "weapons" then
			self.Current_List = self.Weapons_List
		elseif section_name == "intel" then
			self.Current_List = self.Intel_List
		end

		if self.SelectedEntry then
			self:clearCurrentEntry()
		end

		--If we had an old section on, remove the active class
		if self.SelectedSection then
			local previous_bullet = self.Document:GetElementById(self.SelectedSection.."_btn")
			previous_bullet:SetPseudoClass("checked", false)
		end

		self.SelectedSection = section_name
		ScpuiSystem.data.memory.model_rendering.Section = section_name

		--Check for last sort type
		if ScpuiSystem.data.ScpuiOptionValues.Database_Sort_Method ~= nil then
			self.CurrentSort = ScpuiSystem.data.ScpuiOptionValues.Database_Sort_Method[section_name]
		else
			self.CurrentSort = "index_asc"
		end

		if ScpuiSystem.data.ScpuiOptionValues.Database_Category ~= nil then
			self.CurrentSortCategory = ScpuiSystem.data.ScpuiOptionValues.Database_Category[section_name]
		else
			self.CurrentSortCategory = "none"
		end

		self:sortList()

		Topics.techdatabase.selectSection:send({self, section_name})

		--Only create entries if there are any to create
		if self.Current_List[1] then
			self.Visible_List = {}
			self:createListItemEntries(self.Current_List)
			self:selectEntry(self.Visible_List[self:getFirstIndex()])
		else
			local list_items_el = self.Document:GetElementById("list_items_ul")
			ScpuiSystem:clearEntries(list_items_el)
			self:ClearData()
		end

		local new_bullet = self.Document:GetElementById(self.SelectedSection.."_btn")
		new_bullet:SetPseudoClass("checked", true)

		--Scroll to the top of the list
		self.Document:GetElementById("tech_list").scroll_top = 0
	end
end

--- Create a new entry itemelement for the list
--- @param entry scpui_tech_database_entry The entry to create the element for
--- @param index number The index of the entry
--- @param selectable boolean Whether the entry is selectable
--- @param heading boolean Whether the entry is a heading
--- @return Element li_el The created element
function TechDatabaseController:createListItemElement(entry, index, selectable, heading)

	self.Counter = self.Counter + 1

	entry.Selectable = selectable
	entry.Heading = heading

	local li_el = self.Document:CreateElement("li")

	local new_el = "<span style=\"color:red;margin-right:10;\">NEW!</span>"
	local vis_name = "<span>" .. entry.DisplayName .. "</span>"

	--Maybe append "NEW!" to non-heading entries
	if ScpuiSystem.data.table_flags.DatabaseShowNew then
		if heading == false and not self:isSeen(entry.Name) then
			vis_name = new_el .. vis_name
		end
	end

	li_el.inner_rml = vis_name
	li_el.id = entry.Name

	if heading == true then
		if selectable == true then
			li_el:SetClass("list_heading", true)
		else
			li_el:SetClass("list_heading_plain", true)
		end
	else
		li_el:SetClass("list_element", true)
	end
	if selectable == true then
		li_el:SetClass("button_1", true)
		li_el:AddEventListener("click", function(_, _, _)
			self:selectEntry(entry)
		end)
		li_el:AddEventListener("dblclick", function(_, _, _)
			self:selectEntry(entry)
			self:show_breakout_reader()
		end)
	end
	self.Visible_List[self.Counter] = entry
	entry.Key = li_el.id

	self.Visible_List[self.Counter].Index = self.Counter

	return li_el
end

--- Create the full list of entries for the current section
--- @param list scpui_tech_database_entry[] The list of entries to create
--- @return nil
function TechDatabaseController:createListItemEntries(list)

	local list_names_el = self.Document:GetElementById("list_items_ul")

	ScpuiSystem:clearEntries(list_names_el)

	self.CurrentCategory = nil

	for i, v in ipairs(list) do

		--maybe create a category header
		if Utils.extractString(self.CurrentSortCategory, "_") == "type" then
			if v.Visible or self.ShowAll then
				if v.Type ~= self.CurrentCategory then
					self.CurrentCategory = v.Type
					local entry = {
						Name = v.Type,
						DisplayName = v.Type
					}
					list_names_el:AppendChild(self:createListItemElement(entry, i, false, true))
				end
			end
		else
			Topics.techdatabase.createHeader:send({self, v})
		end

		if self.ShowAll or v.Visible then
			list_names_el:AppendChild(self:createListItemElement(v, i, true, false))
		end
	end
end

--- Select an entry and update the UI
--- @param entry scpui_tech_database_entry The entry to select
--- @return nil
function TechDatabaseController:selectEntry(entry)

	if entry == nil then
		return
	end

	if (self.SelectedEntry == nil) or (entry.Key ~= self.SelectedEntry.Key) then
		self.Document:GetElementById(entry.Key):SetPseudoClass("checked", true)

		self.SelectedIndex = entry.Index

		ScpuiSystem.data.memory.model_rendering.RotationSpeed = 40

		local ani_wrapper_element = self.Document:GetElementById("tech_view")
		if ani_wrapper_element.first_child ~= nil then
			ani_wrapper_element.first_child:RemoveChild(ani_wrapper_element.first_child.first_child) --yo dawg
		end
		ani_wrapper_element:RemoveChild(ani_wrapper_element.first_child)

		if self.SelectedEntry then
			local previous_entry = self.Document:GetElementById(self.SelectedEntry.Key)
			if previous_entry then
				previous_entry:SetPseudoClass("checked", false)
				previous_entry.inner_rml = "<span>" .. self.SelectedEntry.DisplayName .. "</span>"
				self:setSeen(self.SelectedEntry.Name)
			end
		end

		local this_entry = self.Document:GetElementById(entry.Key)
		self.SelectedEntry = entry
		this_entry:SetPseudoClass("checked", true)

		--Headings can be made selectable. If so, then custom code is required
		if entry.Heading == true then
			Topics.techdatabase.selectHeader:send({self, entry})
			return
		end

		--Set the description text
		self.Document:GetElementById("tech_desc").inner_rml = entry.Description or ''
		self.Document:GetElementById("tech_desc").scroll_top = 0

		ScpuiSystem.data.memory.model_rendering.Class = nil

		--Decide if item is a weapon or a ship
		if self.SelectedSection == "ships" then

			async.run(function()
				async.await(AsyncUtil.wait_for(0.001))
				ScpuiSystem.data.memory.model_rendering.Class = entry.Name
				ScpuiSystem.data.memory.model_rendering.Element = self.Document:GetElementById("tech_view")
				self.FirstRun = true
			end, async.OnFrameExecutor)

			self:toggleSliders(true)

		elseif self.SelectedSection == "weapons" then

			if entry.Anim ~= "" and Utils.animExists(entry.Anim) then

				local aniEl = self.Document:CreateElement("ani")
				aniEl:SetAttribute("src", entry.Anim)
				aniEl:SetClass("anim", true)
				ani_wrapper_element:ReplaceChild(aniEl, ani_wrapper_element.first_child)

				self:toggleSliders(false)
			else --If we don't have an anim, then draw the tech model

				async.run(function()
					async.await(AsyncUtil.wait_for(0.001))
					ScpuiSystem.data.memory.model_rendering.Class = entry.Name
					ScpuiSystem.data.memory.model_rendering.Element = self.Document:GetElementById("tech_view")
					self.FirstRun = true
				end, async.OnFrameExecutor)

				self:toggleSliders(true)
			end
		elseif self.SelectedSection == "intel" then
			self:toggleSliders(false)

			if entry.Anim then

				local anim_element = self.Document:CreateElement("ani")

				if Utils.animExists(entry.Anim) then
					anim_element:SetAttribute("src", entry.Anim)
				end
				anim_element:SetClass("anim", true)
				ani_wrapper_element:ReplaceChild(anim_element, ani_wrapper_element.first_child)
			else
				--Do nothing because we have nothing to do!
			end
		end

		Topics.techdatabase.selectEntry:send(self)
	end
end

--- Show a dialog box
--- @param text string The text to display
--- @param title string The title of the dialog
--- @param buttons dialog_button[] The buttons to display
function TechDatabaseController:showDialog(text, title, buttons)
	--Create a simple dialog box with the text and title

	ScpuiSystem.data.memory.model_rendering.SavedIndex = ScpuiSystem.data.memory.model_rendering.Class
	ScpuiSystem.data.memory.model_rendering.Class = nil

	local dialog = Dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:escape("")
		dialog:clickescape(true)
		for i = 1, #buttons do
			dialog:button(buttons[i].Type, buttons[i].Text, buttons[i].Value, buttons[i].Keypress)
		end
		dialog:background("#00000080")
		dialog:show(self.Document.context)
		:continueWith(function(response)
			ScpuiSystem.data.memory.model_rendering.Class = ScpuiSystem.data.memory.model_rendering.SavedIndex
			ScpuiSystem.data.memory.model_rendering.SavedIndex = nil
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.Document.context)
end

--- Show the current entry's description in a dialog box
--- @return nil
function TechDatabaseController:show_breakout_reader()
	local text = self.SelectedEntry.Description
	local title = "<span style=\"color:white;\">" .. self.SelectedEntry.DisplayName .. "</span>"
	--- @type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = Dialogs.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Close", 888110),
		Value = "",
		Keypress = string.sub(ba.XSTR("Close", 888110), 1, 1)
	}
	self:showDialog(text, title, buttons)
end

--- Called by the RML when the mouse moves over the tech model preview element
--- @param element Element The element that the mouse is over
--- @param event Event The event that triggered this call
--- @return nil
function TechDatabaseController:mouse_move(element, event)
	if ScpuiSystem.data.memory.model_rendering ~= nil then
		ScpuiSystem.data.memory.model_rendering.Mx = event.parameters.mouse_x
		ScpuiSystem.data.memory.model_rendering.My = event.parameters.mouse_y
	end
end

--- Called by the RML when the mouse button is released
--- @param element Element The element that the mouse is over
--- @param event Event The event that triggered this call
--- @return nil
function TechDatabaseController:mouse_up(element, event)
	if ScpuiSystem.data.memory.model_rendering ~= nil then
		ScpuiSystem.data.memory.model_rendering.Click = false
	end
end

--- Called by the RML when the mouse button is pressed
--- @param element Element The element that the mouse is over
--- @param event Event The event that triggered this call
--- @return nil
function TechDatabaseController:mouse_down(element, event)
	if ScpuiSystem.data.memory.model_rendering ~= nil then
		ScpuiSystem.data.memory.model_rendering.Click = true
		ScpuiSystem.data.memory.model_rendering.Sx = event.parameters.mouse_x
		ScpuiSystem.data.memory.model_rendering.Sy = event.parameters.mouse_y
	end
end

--- Toggle the model speed and angle sliders on or off
--- @param toggle boolean Whether to show or hide the sliders
--- @return nil
function TechDatabaseController:toggleSliders(toggle)
	self.Document:GetElementById("angle_slider"):SetClass("hidden", not toggle)
	self.Document:GetElementById("speed_slider"):SetClass("hidden", not toggle)
end

--- Called by the RML when the angle slider is updated
--- @param element Element The element that triggered the event
--- @param event Event The event that triggered this call
function TechDatabaseController:update_angle(element, event)
	if self.FirstRun == true then
		ScpuiSystem.data.ScpuiOptionValues.Database_Model_Angle = event.parameters.value
	end
	self:updateAngleSlider(event.parameters.value)
end

--- Update the angle of the model based on the slider value
--- @param val number The value of the slider
--- @return nil
function TechDatabaseController:updateAngleSlider(val)
	local angle = (val * 3) - 1.5
	ScpuiSystem.data.memory.model_rendering.Angle = angle
end

--- Called by the RML when the speed slider is updated
--- @param element Element The element that triggered the event
--- @param event Event The event that triggered this call
--- @return nil
function TechDatabaseController:update_speed(element, event)
	if self.FirstRun == true then
		ScpuiSystem.data.ScpuiOptionValues.Database_Model_Speed = event.parameters.value
	end
	self:updateSpeedSlider(event.parameters.value)
end

--- Update the speed of the model based on the slider value
--- @param val number The value of the slider
--- @return nil
function TechDatabaseController:updateSpeedSlider(val)
	local speed = (val * 2)
	ScpuiSystem.data.memory.model_rendering.Speed = speed
end

--- Draw a frame of the current entry's model, if it exists
--- @return nil
function TechDatabaseController:drawModel()

	if ScpuiSystem.data.memory.model_rendering.Class and ba.getCurrentGameState().Name == "GS_STATE_TECH_MENU" then  --Haaaaaaacks

		local this_item = nil
		if ScpuiSystem.data.memory.model_rendering.Section == "ships" then
			this_item = tb.ShipClasses[ScpuiSystem.data.memory.model_rendering.Class]
		elseif ScpuiSystem.data.memory.model_rendering.Section == "weapons" then
			this_item = tb.WeaponClasses[ScpuiSystem.data.memory.model_rendering.Class]
		end

		--- If we somehow have a class that's not valid then we can't draw
		if not this_item then
			return
		end

		if not ScpuiSystem.data.memory.model_rendering.Click then
			ScpuiSystem.data.memory.model_rendering.RotationSpeed = ScpuiSystem.data.memory.model_rendering.RotationSpeed + (ScpuiSystem.data.memory.model_rendering.Speed * ba.getRealFrametime())
		end

		if ScpuiSystem.data.memory.model_rendering.RotationSpeed >= 100 then
			ScpuiSystem.data.memory.model_rendering.RotationSpeed = ScpuiSystem.data.memory.model_rendering.RotationSpeed - 100
		end

		local model_view = ScpuiSystem.data.memory.model_rendering.Element

		--- If the modelView is not found, then we can't draw the model this frame
		if not model_view then
			return
		end

		-- Get screen coordinates from the SCPUI element position/offset
		local model_x = ScpuiSystem:getAbsoluteLeft(model_view)
		local model_y = ScpuiSystem:getAbsoluteTop(model_view) - model_view.offset_top + 2 --Does not include modelView.offset_top because that element's padding is set for anims
		local model_w = model_view.offset_width
		local model_h = model_view.offset_height + 10

		-- Sx/Sy are the mouse coordinates when the left button was clicked. Mx/My are the mouse coordinates right now.
		-- Get the difference to get how far the mouse has been dragged and invert the direction because otherwise it's wrong
		local calculated_x = (ScpuiSystem.data.memory.model_rendering.Sx - ScpuiSystem.data.memory.model_rendering.Mx) * -1
		local calculated_y = (ScpuiSystem.data.memory.model_rendering.Sy - ScpuiSystem.data.memory.model_rendering.My) * -1

		-- Get the model's current orientation
		local orient = ba.createOrientation(ScpuiSystem.data.memory.model_rendering.Angle, 0, ScpuiSystem.data.memory.model_rendering.RotationSpeed)

		--Move model based on mouse coordinates
		if ScpuiSystem.data.memory.model_rendering.Click then
			local dx = calculated_x
			local dy = calculated_y
			local radius = 100

			--reverse this one
			dx = dx * -1

			local dr = dx*dx+dy+dy

			if dr < 0 then
				dr = dr * -1
			end

			if dr < 1 then
				dr = 1
			end

			dr = math.sqrt(dr)

			local denom = math.sqrt(radius*radius+dr*dr)

			local cos_theta = radius/denom
			local sin_theta = dr/denom

			local cos_theta1 = 1 - cos_theta

			local dxdr = dx/dr
			local dydr = dy/dr

			local fvec = ba.createVector((dxdr*sin_theta), (dydr*sin_theta), cos_theta)
			local uvec = ba.createVector(((dxdr*dydr)*cos_theta1), (cos_theta + ((dxdr*dxdr)*cos_theta1)), 1)
			local rvec = ba.createVector((cos_theta + (dydr*dydr)*cos_theta1), 1, 1)

			ScpuiSystem.data.memory.model_rendering.ClickOrientation = ba.createOrientationFromVectors(fvec, uvec, rvec)

			orient = ScpuiSystem.data.memory.model_rendering.ClickOrientation * orient
		end

		this_item:renderTechModel2(model_x, model_y, model_x + model_w, model_y + model_h, orient, 1.1)

	end

end

--- Sets the current element as unchecked
--- @return nil
function TechDatabaseController:clearCurrentEntry()
	self.Document:GetElementById(self.SelectedEntry.Key):SetPseudoClass("checked", false)
	self.SelectedEntry = nil
end

--- Clears the current data from the UI
--- @return nil
function TechDatabaseController:ClearData()
	ScpuiSystem.data.memory.model_rendering.Class = nil
	local ani_wrapper_element = self.Document:GetElementById("tech_view")
	ani_wrapper_element:RemoveChild(ani_wrapper_element.first_child)
	self.Document:GetElementById("tech_desc").inner_rml = "<p></p>"
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function TechDatabaseController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    elseif event.parameters.key_identifier == rocket.key_identifier.S and event.parameters.ctrl_key == 1 and event.parameters.shift_key == 1 then
		self.ShowAll = not self.ShowAll
		self:reloadList()
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
		self:change_tech_state(element, self.STATE_CREDITS)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
		self:change_tech_state(element, self.STATE_SIMULATOR)
	elseif event.parameters.key_identifier == rocket.key_identifier.TAB then
		local new_section = self.SectionIndex + 1
		if new_section == 4 then
			new_section = 1
		end
		self:change_section(new_section)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.shift_key == 1 then
		self:scrollList(self.Document:GetElementById("tech_list"), 0)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.shift_key == 1 then
		self:scrollList(self.Document:GetElementById("tech_list"), 1)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP then
		self:scrollDescriptionText(self.Document:GetElementById("tech_desc"), 0)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN then
		self:scrollDescriptionText(self.Document:GetElementById("tech_desc"), 1)
	elseif event.parameters.key_identifier == rocket.key_identifier.LEFT then
		self:select_prev(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.RIGHT then
		self:select_next(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.RETURN then
		--self:commit_pressed(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F1 then
		self:help_clicked(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F2 then
		self:options_button_clicked(element)
	end
end

--- Scroll the list up or down
--- @param element Element The element to scroll
--- @param direction number The direction to scroll in
--- @return nil
function TechDatabaseController:scrollList(element, direction)
	if direction == 0 then
		element.scroll_top = element.scroll_top - 15
	else
		element.scroll_top = element.scroll_top + 15
	end
end

--- Scroll the text up or down
--- @param element Element The element to scroll
--- @param direction number The direction to scroll in
--- @return nil
function TechDatabaseController:scrollDescriptionText(element, direction)
	if direction == 0 then
		element.scroll_top = (element.scroll_top - 5)
	else
		element.scroll_top = (element.scroll_top + 5)
	end
end

--- Called by the RML to select the next entry in the list
--- @param element Element The element that triggered the event
--- @return nil
function TechDatabaseController:select_next(element)
    local num = #self.Visible_List

	if self.SelectedIndex == num then
		ui.playElementSound(element, "click", "error")
	else
		local count = 1
		while self.Visible_List[self.SelectedIndex + count] ~= nil and self.Visible_List[self.SelectedIndex + count].Selectable == false do
			count = count + 1
		end

		if (self.SelectedIndex + count) > num then
			ui.playElementSound(element, "click", "error")
		elseif self.Visible_List[self.SelectedIndex + count].Selectable == false then
			ui.playElementSound(element, "click", "error")
		else
			self:selectEntry(self.Visible_List[self.SelectedIndex + count])
		end
	end
end

--- Called by the RML to select the previous entry in the list
--- @param element Element The element that triggered the event
--- @return nil
function TechDatabaseController:select_prev(element)
	if self.SelectedIndex == 1 then
		ui.playElementSound(element, "click", "error")
	else
		local count = 1
		while self.Visible_List[self.SelectedIndex - count] ~= nil and self.Visible_List[self.SelectedIndex - count].Selectable == false do
			count = count + 1
		end

		if (self.SelectedIndex - count) < 1 then
			ui.playElementSound(element, "click", "error")
		elseif self.Visible_List[self.SelectedIndex - count].Selectable == false then
			ui.playElementSound(element, "click", "error")
		else
			self:selectEntry(self.Visible_List[self.SelectedIndex - count])
		end
	end
end

--- Called by the RML when the exit button is pressed
--- @param element Element The element that triggered the event
--- @return nil
function TechDatabaseController:exit_pressed(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

--- Called by the RML when the options button is pressed
--- @param element Element The element that triggered the event
--- @return nil
function TechDatabaseController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- Called by the RML when the help button is pressed
--- @param element Element The element that triggered the event
--- @return nil
function TechDatabaseController:help_clicked(element)
    ui.playElementSound(element, "click", "success")

	self.HelpShown  = not self.HelpShown

    local help_texts = self.Document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.HelpShown)
    end
end

--- Load the 'seen' data from the player file, if it exists
--- @return table values The seen data
function TechDatabaseController:loadSeenDataFromFile()

	---@type json
	local Json = require('dkjson')

	local location = 'data/players'

	local file = nil
	local config = {}

	if cf.fileExists('scpui_seen_tech.cfg') then
		file = cf.openFile('scpui_seen_tech.cfg', 'r', location)
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
		config[ba.getCurrentPlayer():getName()][mod] = {}
	end

	return config[ba.getCurrentPlayer():getName()][mod]
end

--- Save the 'seen' data to the player file
--- @param data table The data to save
--- @return nil
function TechDatabaseController:saveSeenDataToFile(data)

	---@type json
	local Json = require('dkjson')

	local location = 'data/players'

	local file = nil
	local config = {}

	if cf.fileExists('scpui_seen_tech.cfg') then
		file = cf.openFile('scpui_seen_tech.cfg', 'r', location)
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

	file = cf.openFile('scpui_seen_tech.cfg', 'w', location)
	file:write(Json.encode(config))
	file:close()
end

--- Called when the screen is being unloaded
--- @return nil
function TechDatabaseController:unload()
	ScpuiSystem:saveOptionsToFile(ScpuiSystem.data.ScpuiOptionValues)
	self:saveSeenDataToFile(self.Seen_Data)
    ScpuiSystem:freeAllModels()

	Topics.techdatabase.unload:send(self)
end

--- Every frame try to draw the current entry's model, if possible
ScpuiSystem:addHook("On Frame", function()
	if ScpuiSystem.data.Render then
		TechDatabaseController:drawModel()
	end
end, {State="GS_STATE_TECH_MENU"}, function()
	return false
end)

return TechDatabaseController
