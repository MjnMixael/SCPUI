local dialogs = require("dialogs")
local class = require("class")
local utils = require("utils")
local async_util = require("async_util")
local topics = require("ui_topics")

local TechDatabaseController = class()

ScpuiSystem.modelDraw = nil

function TechDatabaseController:init()
	self.show_all = false
	ScpuiSystem.modelDraw = {
		mx = 0,
		my = 0,
		sx = 0,
		sy = 0
	}
	self.Counter = 0
	self.help_shown = false
	self.first_run = false
end

--Iterate over all the ships, weapons, and intel but only grab the necessary data
function TechDatabaseController:LoadData()
	
	--Initialize the lists
	self.ships = {}
	self.weapons = {}
	self.intel = {}
	
	--Initialize the category tables
	self.s_types = {}
	self.w_types = {}
	self.i_types = {}
	
	--Load seen data and verify tables
	self.seenData = self:loadSeenDataFromFile()
	if self.seenData["ships"] == nil then
		self.seenData["ships"] = {}
	end
	if self.seenData["weapons"] == nil then
		self.seenData["weapons"] = {}
	end
	if self.seenData["intel"] == nil then
		self.seenData["intel"] = {}
	end
	
	topics.techdatabase.beginDataLoad:send(self)
	
	local list_ships = tb.ShipClasses
	local i = 1
	while (i < #list_ships) do
		if list_ships[i]:hasCustomData() and list_ships[i].CustomData["HideInTechRoom"] == "true" then
			ba.print("Skipping ship " .. list_ships[i].Name .. " in the tech room list!\n")
		else
			local ship = {
				Name = tostring(list_ships[i].Name),
				DefaultPos = list_ships[i]:getShipClassIndex(),
				DisplayName = topics.ships.name:send(list_ships[i]),
				Description = topics.ships.description:send(list_ships[i]),
				Type = tostring(list_ships[i].TypeString),
				Visibility = topics.ships.filter:send(list_ships[i])
			}
			
			--build the category tables
			if not utils.table.contains(self.s_types, ship.Type) then
				table.insert(self.s_types, ship.Type)
			end
			
			topics.techdatabase.initShipData:send({self, ship})
			
			table.insert(self.ships, ship)
		end
		i = i + 1
	end
	
	local list_weapons = tb.WeaponClasses
	local j = 1
	while (j < #list_weapons) do
		if list_weapons[j]:hasCustomData() and list_weapons[j].CustomData["HideInTechRoom"] == "true" then
			ba.print("Skipping weapon " .. list_weapons[j].Name .. " in the tech room list!\n")
		else
			local t_string = utils.xstr("Primary", 888551)
			if list_weapons[j]:isSecondary() then
				t_string = utils.xstr("Secondary", 888552)
			end
			
			local weapon = {
				Name = tostring(list_weapons[j].Name),
				DefaultPos = list_weapons[j]:getWeaponClassIndex(),
				DisplayName = topics.weapons.name:send(list_weapons[j]),
				Description = topics.weapons.description:send(list_weapons[j]),
				Anim = tostring(list_weapons[j].TechAnimationFilename),
				Type = t_string,
				Visibility = topics.weapons.filter:send(list_weapons[j])
			}
			
			--build the category tables
			if not utils.table.contains(self.w_types, weapon.Type) then
				table.insert(self.w_types, weapon.Type)
			end
			
			topics.techdatabase.initWeaponData:send({self, weapon})
			
			table.insert(self.weapons, weapon)
		end
		j = j + 1
	end
	
	local list_intel = tb.IntelEntries
	local k = 1
	while (k < #list_intel) do
		local intel = {
			Name = tostring(list_intel[k].Name),
			DefaultPos = k,
			DisplayName = topics.intel.name:send(list_intel[k]),
			Type = topics.intel.type:send(list_intel[k]),
			Description = topics.intel.description:send(list_intel[k]),
			Anim = tostring(list_intel[k].AnimFilename),
			Visibility = topics.intel.filter:send(list_intel[k])
		}
		
		--build the category tables
		if not utils.table.contains(self.i_types, intel.Type) then
			table.insert(self.i_types, intel.Type)
		end
		
		topics.techdatabase.initIntelData:send({self, intel})
		
		table.insert(self.intel, intel)
		k = k + 1
	end

end

function TechDatabaseController:initialize(document)
    self.document = document
    self.elements = {}
    self.section = 1
	
	---Load background choice
	self.document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)
	
	self.document:GetElementById("tech_btn_1"):SetPseudoClass("checked", true)
	self.document:GetElementById("tech_btn_2"):SetPseudoClass("checked", false)
	self.document:GetElementById("tech_btn_3"):SetPseudoClass("checked", false)
	self.document:GetElementById("tech_btn_4"):SetPseudoClass("checked", false)
	
	topics.techroom.initialize:send(self)
	topics.techdatabase.initialize:send(self)
	
	self:InitSortFunctions()
	
	--Get all the table data fresh each time in case there are changes
	self:LoadData()
	
	self.SelectedEntry = nil
	
	self.SelectedSection = nil
	
	self:ChangeSection(1)
	
	local a_slider_el = self.document:GetElementById("angle_range_cont").first_child
	local a_range_el = Element.As.ElementFormControlInput(a_slider_el)
	a_range_el.value = ScpuiOptionValues.databaseModelAngle or 0.5

	local s_slider_el = self.document:GetElementById("speed_range_cont").first_child
	local s_range_el = Element.As.ElementFormControlInput(s_slider_el)
	s_range_el.value = ScpuiOptionValues.databaseModelSpeed or 0.5
	
end

function TechDatabaseController:setSortType(sort)
	if sort == "name" then
		if self.currentSort == "name_asc" then
			self.currentSort = "name_des"
		else
			self.currentSort = "name_asc"
		end
	elseif sort == "index" then
		if self.currentSort == "index_asc" then
			self.currentSort = "index_des"
		else
			self.currentSort = "index_asc"
		end
	else --catch unhandled
		sort = "index_asc"
	end
	self:SortList()
	self:ReloadList()
end

function TechDatabaseController:setSortCategory(category)
	if category == "type" then
	    if self.currentSortCategory == "type_asc_alph" then
		    self.currentSortCategory = "type_des_alph"
		elseif self.currentSortCategory == "type_des_alph" then
		    self.currentSortCategory = "type_asc_idx"
		elseif self.currentSortCategory == "type_asc_idx" then
		    self.currentSortCategory = "type_des_idx"
		else
		    self.currentSortCategory = "type_asc_alph"
		end
	else --catch unhandled
		if topics.techdatabase.setSortCat:send({self, category}) == false then
			self.currentSortCategory = "none"
		end
	end
	self:SortList()
	self:ReloadList()
end

function TechDatabaseController:InitSortFunctions()

	self.sortFunctions = {}
	

	--Item Sorters
	local function sortByIndexAsc(a, b)
		return a.DefaultPos < b.DefaultPos
	end
	self.sortFunctions.sortByIndexAsc = sortByIndexAsc
	
	local function sortByIndexDes(a, b)
		return a.DefaultPos > b.DefaultPos
	end
	self.sortFunctions.sortByIndexDes = sortByIndexDes

	local function sortByNameAsc(a, b)
		return a.Name < b.Name
	end
	self.sortFunctions.sortByNameAsc = sortByNameAsc
	
	local function sortByNameDes(a, b)
		return a.Name > b.Name
	end
	self.sortFunctions.sortByNameDes = sortByNameDes
	
	--Category Sorters
	local function sortByTypeAsc_Alph(a, b)
		if a.Type == b.Type then
			return self.ItemSort(a, b)
		else
			return a.Type < b.Type
		end
	end
	self.sortFunctions.sortByTypeAsc_Alph = sortByTypeAsc_Alph
	
	local function sortByTypeDes_Alph(a, b)
		if a.Type == b.Type then
			return self.ItemSort(a, b)
		else
			return a.Type > b.Type
		end
	end
	self.sortFunctions.sortByTypeDes_Alph = sortByTypeDes_Alph
	
	local function sortByTypeAsc_Idx(a, b)
		local tbl = nil
		if self.SelectedSection == "ships" then
			tbl = self.s_types
		elseif self.SelectedSection == "weapons" then
			tbl = self.w_types
		elseif self.SelectedSection == "intel" then
			tbl = self.i_types
		end
		
		local a_idx = utils.table.ifind(tbl, a.Type)
		local b_idx = utils.table.ifind(tbl, b.Type)
		if a.Type == b.Type then
			return self.ItemSort(a, b)
		else
			return a_idx < b_idx
		end
	end
	self.sortFunctions.sortByTypeAsc_Idx = sortByTypeAsc_Idx
	
	local function sortByTypeDes_Idx(a, b)
		local tbl = nil
		if self.SelectedSection == "ships" then
			tbl = self.s_types
		elseif self.SelectedSection == "weapons" then
			tbl = self.w_types
		elseif self.SelectedSection == "intel" then
			tbl = self.i_types
		end
		
		local a_idx = utils.table.ifind(tbl, a.Type)
		local b_idx = utils.table.ifind(tbl, b.Type)
		if a.Type == b.Type then
			return self.ItemSort(a, b)
		else
			return a_idx > b_idx
		end
	end
	self.sortFunctions.sortByTypeDes_Idx = sortByTypeDes_Idx
	
	topics.techdatabase.initSortFuncs:send(self)
end

	

function TechDatabaseController:SortList()
	
	self.ItemSort = nil
	--loadstring(v.func .. '()' )()
	
	self:UncheckAllSortButtons()
	
	if self.currentSort == nil then
		self.currentSort = "index_asc"
	end
	
	if self.currentSortCategory == nil then
		self.currentSortCategory = "none"
	end
	
	--Check item sort
	if self.currentSort == "index_asc" then
		if self.currentSortCategory == "none" then
			table.sort(self.currentList, self.sortFunctions.sortByIndexAsc)
		else
			self.ItemSort = self.sortFunctions.sortByIndexAsc
		end
		self.document:GetElementById("default_sort_btn"):SetPseudoClass("checked", true)
	elseif self.currentSort == "index_des" then
		if self.currentSortCategory == "none" then
			table.sort(self.currentList, self.sortFunctions.sortByIndexDes)
		else
			self.ItemSort = self.sortFunctions.sortByIndexDes
		end
		self.document:GetElementById("default_sort_btn"):SetPseudoClass("checked", true)
	elseif self.currentSort == "name_asc" then
		if self.currentSortCategory == "none" then
			table.sort(self.currentList, self.sortFunctions.sortByNameAsc)
		else
			self.ItemSort = self.sortFunctions.sortByNameAsc
		end
		self.document:GetElementById("name_sort_btn"):SetPseudoClass("checked", true)
	elseif self.currentSort == "name_des" then
		if self.currentSortCategory == "none" then
			table.sort(self.currentList, self.sortFunctions.sortByNameDes)
		else
			self.ItemSort = self.sortFunctions.sortByNameDes
		end
		self.document:GetElementById("name_sort_btn"):SetPseudoClass("checked", true)
	else
		if topics.techdatabase.sortItems:send(self) == false then
			ba.warning("Got invalid sort method! Using Default.")
			
			self.currentSort = "index_asc"
			return self:SortList()
		end
	end
	
	--Check categorization
	if self.currentSortCategory ~= "none" then
		if self.currentSortCategory == "type_asc_alph" then
			table.sort(self.currentList, self.sortFunctions.sortByTypeAsc_Alph)
			self.document:GetElementById("type_cat_btn"):SetPseudoClass("checked", true)
		elseif self.currentSortCategory == "type_des_alph" then
			table.sort(self.currentList, self.sortFunctions.sortByTypeDes_Alph)
			self.document:GetElementById("type_cat_btn"):SetPseudoClass("checked", true)
		elseif self.currentSortCategory == "type_asc_idx" then
			table.sort(self.currentList, self.sortFunctions.sortByTypeAsc_Idx)
			self.document:GetElementById("type_cat_btn"):SetPseudoClass("checked", true)
		elseif self.currentSortCategory == "type_des_idx" then
			table.sort(self.currentList, self.sortFunctions.sortByTypeDes_Idx)
			self.document:GetElementById("type_cat_btn"):SetPseudoClass("checked", true)
		else
			if topics.techdatabase.sortCategories:send(self) == false then
				ba.warning("Got invalid sort category! Using Default.")
				self.currentSortCategory = "none"
				return self:SortList()
			end
		end
	else
		self.document:GetElementById("default_cat_btn"):SetPseudoClass("checked", true)
	end
	
	--save the choice to the player file
	if ScpuiOptionValues.databaseSort == nil then
		ScpuiOptionValues.databaseSort = {}
			ScpuiOptionValues.databaseSort["ships"] = "index_asc"
			ScpuiOptionValues.databaseSort["weapons"] = "index_asc"
			ScpuiOptionValues.databaseSort["intel"] = "index_asc"
	end
	if ScpuiOptionValues.databaseCategory == nil then
		ScpuiOptionValues.databaseCategory = {}
			ScpuiOptionValues.databaseCategory["ships"] = "none"
			ScpuiOptionValues.databaseCategory["weapons"] = "none"
			ScpuiOptionValues.databaseCategory["intel"] = "none"
	end
	ScpuiOptionValues.databaseSort[self.SelectedSection] = self.currentSort
	ScpuiOptionValues.databaseCategory[self.SelectedSection] = self.currentSortCategory
	ScpuiSystem:saveOptionsToFile(ScpuiOptionValues)
end

function TechDatabaseController:UncheckAllSortButtons()
	self.document:GetElementById("default_sort_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("name_sort_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("default_cat_btn"):SetPseudoClass("checked", false)
	self.document:GetElementById("type_cat_btn"):SetPseudoClass("checked", false)
	
	topics.techdatabase.uncheckSorts:send(self)
end

function TechDatabaseController:getFirstIndex()
	if self.currentSortCategory ~= "none" then
	    return 2
	else
		return 1
	end
end

function TechDatabaseController:ReloadList()

	local list_items_el = self.document:GetElementById("list_items_ul")
	ScpuiSystem:ClearEntries(list_items_el)
	self:ClearData()
	self.SelectedEntry = nil
	self.visibleList = {}
	self.Counter = 0
	self:CreateEntries(self.currentList)
	self:SelectEntry(self.visibleList[self:getFirstIndex()])

end

function TechDatabaseController:isSeen(name)
	if name ~= nil then
		return self.seenData[self.SelectedSection][name]
	else
		return nil
	end
end

function TechDatabaseController:setSeen(name)
	if name ~= nil then
		self.seenData[self.SelectedSection][name] = true
	end
end

function TechDatabaseController:ChangeTechState(state)

	if state == 1 then
		--This is where we are already, so don't do anything
		--topics.techroom.btn1Action:send()
	end
	if state == 2 then
		topics.techroom.btn2Action:send()
	end
	if state == 3 then
		topics.techroom.btn3Action:send()
	end
	if state == 4 then
		topics.techroom.btn4Action:send()
	end
	
end

function TechDatabaseController:ChangeSection(section)

	self.sectionIndex = section
	
	if section == 1 then section = "ships" end
	if section == 2 then section = "weapons" end
	if section == 3 then section = "intel" end
	
	self.show_all = false
	self.Counter = 0

	if section ~= self.SelectedSection then
	
		self.currentList = {}
	
		if section == "ships" then
			self.currentList = self.ships
		elseif section == "weapons" then
			self.currentList = self.weapons
		elseif section == "intel" then
			self.currentList = self.intel
		end
		
		if self.SelectedEntry then
			self:ClearEntry()
		end
		
		--If we had an old section on, remove the active class
		if self.SelectedSection then
			local oldbullet = self.document:GetElementById(self.SelectedSection.."_btn")
			oldbullet:SetPseudoClass("checked", false)
		end
		
		self.SelectedSection = section
		ScpuiSystem.modelDraw.section = section
		
		--Check for last sort type
		if ScpuiOptionValues.databaseSort ~= nil then
			self.currentSort = ScpuiOptionValues.databaseSort[section]
		else
			self.currentSort = "index_asc"
		end
		
		if ScpuiOptionValues.databaseCategory ~= nil then
			self.currentSortCategory = ScpuiOptionValues.databaseCategory[section]
		else
			self.currentSortCategory = "none"
		end		

		self:SortList()
		
		topics.techdatabase.selectSection:send({self, section})
		
		--Only create entries if there are any to create
		if self.currentList[1] then
			self.visibleList = {}
			self:CreateEntries(self.currentList)
			self:SelectEntry(self.visibleList[self:getFirstIndex()])
		else
			local list_items_el = self.document:GetElementById("list_items_ul")
			ScpuiSystem:ClearEntries(list_items_el)
			self:ClearData()
		end

		local newbullet = self.document:GetElementById(self.SelectedSection.."_btn")
		newbullet:SetPseudoClass("checked", true)
		
		--Scroll to the top of the list
		self.document:GetElementById("tech_list").scroll_top = 0
		
	end
	
end

function TechDatabaseController:CreateEntryItem(entry, index, selectable, heading)

	self.Counter = self.Counter + 1
	
	entry.Selectable = selectable
	entry.Heading = heading
	
	local li_el = self.document:CreateElement("li")
	
	local new_el = "<span style=\"color:red;margin-right:10;\">NEW!</span>"
	local vis_name = "<span>" .. entry.DisplayName .. "</span>"

	--Maybe append "NEW!" to non-heading entries
	if ScpuiSystem.databaseShowNew then
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
			self:SelectEntry(entry)
		end)
		li_el:AddEventListener("dblclick", function(_, _, _)
			self:SelectEntry(entry)
			self:BreakoutReader()
		end)
	end
	self.visibleList[self.Counter] = entry
	entry.key = li_el.id
	
	self.visibleList[self.Counter].Index = self.Counter

	return li_el
end

function TechDatabaseController:CreateEntries(list)

	local list_names_el = self.document:GetElementById("list_items_ul")

	ScpuiSystem:ClearEntries(list_names_el)
	
	self.cur_category = nil

	for i, v in ipairs(list) do
	
		--maybe create a category header
		if utils.extractString(self.currentSortCategory, "_") == "type" then
			if v.Visibility or self.show_all then
				if v.Type ~= self.cur_category then
					self.cur_category = v.Type
					local entry = {
						Name = v.Type,
						DisplayName = v.Type
					}
					list_names_el:AppendChild(self:CreateEntryItem(entry, i, false, true))
				end
			end
		else
			topics.techdatabase.createHeader:send({self, v})
		end
					
		if self.show_all or v.Visibility then
			list_names_el:AppendChild(self:CreateEntryItem(v, i, true, false))
		end
	end
end

function TechDatabaseController:SelectEntry(entry)

	if entry == nil then
		return
	end

	if (self.SelectedEntry == nil) or (entry.key ~= self.SelectedEntry.key) then
		self.document:GetElementById(entry.key):SetPseudoClass("checked", true)

		self.SelectedIndex = entry.Index

		ScpuiSystem.modelDraw.Rot = 40
		
		local aniWrapper = self.document:GetElementById("tech_view")
		if aniWrapper.first_child ~= nil then
			aniWrapper.first_child:RemoveChild(aniWrapper.first_child.first_child) --yo dawg
		end
		aniWrapper:RemoveChild(aniWrapper.first_child)
	
		if self.SelectedEntry then
			local oldEntry = self.document:GetElementById(self.SelectedEntry.key)
			if oldEntry then
				oldEntry:SetPseudoClass("checked", false)
				oldEntry.inner_rml = "<span>" .. self.SelectedEntry.DisplayName .. "</span>"
				self:setSeen(self.SelectedEntry.Name)
			end
		end
		
		local thisEntry = self.document:GetElementById(entry.key)
		self.SelectedEntry = entry
		thisEntry:SetPseudoClass("checked", true)
		
		--Headings can be made selectable. If so, then custom code is required
		if entry.Heading == true then
			topics.techdatabase.selectHeader:send({self, entry})
			return
		end
		
		--Set the description text
		self.document:GetElementById("tech_desc").inner_rml = entry.Description or ''
		self.document:GetElementById("tech_desc").scroll_top = 0
		
		ScpuiSystem.modelDraw.class = nil
		
		--Decide if item is a weapon or a ship
		if self.SelectedSection == "ships" then

			async.run(function()
				async.await(async_util.wait_for(0.001))
				ScpuiSystem.modelDraw.class = entry.Name
				ScpuiSystem.modelDraw.element = self.document:GetElementById("tech_view")
				self.first_run = true
			end, async.OnFrameExecutor)
			
			self:toggleSliders(true)

		elseif self.SelectedSection == "weapons" then			
			
			if entry.Anim ~= "" and utils.animExists(entry.Anim) then

				local aniEl = self.document:CreateElement("ani")
				aniEl:SetAttribute("src", entry.Anim)
				aniEl:SetClass("anim", true)
				aniWrapper:ReplaceChild(aniEl, aniWrapper.first_child)
				
				self:toggleSliders(false)
			else --If we don't have an anim, then draw the tech model
			
				async.run(function()
					async.await(async_util.wait_for(0.001))
					ScpuiSystem.modelDraw.class = entry.Name
					ScpuiSystem.modelDraw.element = self.document:GetElementById("tech_view")
					self.first_run = true
				end, async.OnFrameExecutor)

				self:toggleSliders(true)
			end
		elseif self.SelectedSection == "intel" then			
			self:toggleSliders(false)
			
			if entry.Anim then

				local aniEl = self.document:CreateElement("ani")
				
				if utils.animExists(entry.Anim) then
					aniEl:SetAttribute("src", entry.Anim)
				end
				aniEl:SetClass("anim", true)
				aniWrapper:ReplaceChild(aniEl, aniWrapper.first_child)
			else
				--Do nothing because we have nothing to do!
			end
		end
		
		topics.techdatabase.selectEntry:send(self)

	end	


end

function TechDatabaseController:Show(text, title, buttons)
	--Create a simple dialog box with the text and title

	ScpuiSystem.modelDraw.save = ScpuiSystem.modelDraw.class
	ScpuiSystem.modelDraw.class = nil
	
	local dialog = dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:escape("")
		dialog:clickescape(true)
		for i = 1, #buttons do
			dialog:button(buttons[i].b_type, buttons[i].b_text, buttons[i].b_value, buttons[i].b_keypress)
		end
		dialog:background("#00000080")
		dialog:show(self.document.context)
		:continueWith(function(response)
			ScpuiSystem.modelDraw.class = ScpuiSystem.modelDraw.save
			ScpuiSystem.modelDraw.save = nil
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.document.context)
end

function TechDatabaseController:BreakoutReader()
	local text = self.SelectedEntry.Description
	local title = "<span style=\"color:white;\">" .. self.SelectedEntry.DisplayName .. "</span>"
	local buttons = {}
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Close", 888110),
		b_value = "",
		b_keypress = string.sub(ba.XSTR("Close", 888110), 1, 1)
	}
	self:Show(text, title, buttons)
end

function TechDatabaseController:mouse_move(element, event)

	if ScpuiSystem.modelDraw ~= nil then
		ScpuiSystem.modelDraw.mx = event.parameters.mouse_x
		ScpuiSystem.modelDraw.my = event.parameters.mouse_y
	end

end

function TechDatabaseController:mouse_up(element, event)

	if ScpuiSystem.modelDraw ~= nil then
		ScpuiSystem.modelDraw.click = false
	end

end

function TechDatabaseController:mouse_down(element, event)

	if ScpuiSystem.modelDraw ~= nil then
		ScpuiSystem.modelDraw.click = true
		ScpuiSystem.modelDraw.sx = event.parameters.mouse_x
		ScpuiSystem.modelDraw.sy = event.parameters.mouse_y
	end

end

function TechDatabaseController:toggleSliders(toggle)
	self.document:GetElementById("angle_slider"):SetClass("hidden", not toggle)
	self.document:GetElementById("speed_slider"):SetClass("hidden", not toggle)
end

function TechDatabaseController:update_angle(element, event)
	if self.first_run == true then
		ScpuiOptionValues.databaseModelAngle = event.parameters.value
	end
	self:update_angle_slider(event.parameters.value)
end

function TechDatabaseController:update_angle_slider(val)
	local angle = (val * 3) - 1.5
	ScpuiSystem.modelDraw.angle = angle
end

function TechDatabaseController:update_speed(element, event)
	if self.first_run == true then
		ScpuiOptionValues.databaseModelSpeed = event.parameters.value
	end
	self:update_speed_slider(event.parameters.value)
end

function TechDatabaseController:update_speed_slider(val)
	local speed = (val * 2)
	ScpuiSystem.modelDraw.speed = speed
end

function TechDatabaseController:DrawModel()

	if ScpuiSystem.modelDraw.class and ba.getCurrentGameState().Name == "GS_STATE_TECH_MENU" then  --Haaaaaaacks

		local thisItem = nil
		if ScpuiSystem.modelDraw.section == "ships" then
			thisItem = tb.ShipClasses[ScpuiSystem.modelDraw.class]
		elseif ScpuiSystem.modelDraw.section == "weapons" then
			thisItem = tb.WeaponClasses[ScpuiSystem.modelDraw.class]
		end
		
		if not ScpuiSystem.modelDraw.click then
			ScpuiSystem.modelDraw.Rot = ScpuiSystem.modelDraw.Rot + (ScpuiSystem.modelDraw.speed * ba.getRealFrametime())
		end

		if ScpuiSystem.modelDraw.Rot >= 100 then
			ScpuiSystem.modelDraw.Rot = ScpuiSystem.modelDraw.Rot - 100
		end
		
		local modelView = ScpuiSystem.modelDraw.element
						
		local modelLeft = modelView.offset_left + modelView.parent_node.offset_left + modelView.parent_node.parent_node.offset_left --This is pretty messy, but it's functional
		local modelTop = modelView.parent_node.offset_top + modelView.parent_node.parent_node.offset_top + 2 --Does not include modelView.offset_top because that element's padding is set for anims
		local modelWidth = modelView.offset_width
		local modelHeight = modelView.offset_height + 10
		
		local calcX = (ScpuiSystem.modelDraw.sx - ScpuiSystem.modelDraw.mx) * -1
		local calcY = (ScpuiSystem.modelDraw.sy - ScpuiSystem.modelDraw.my) * -1
		
		local orient = ba.createOrientation(ScpuiSystem.modelDraw.angle, 0, ScpuiSystem.modelDraw.Rot)
		
		--Move model based on mouse coordinates
		if ScpuiSystem.modelDraw.click then
			local dx = calcX * 1
			local dy = calcY * 1
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
			
			ScpuiSystem.modelDraw.clickOrient = ba.createOrientationFromVectors(fvec, uvec, rvec)
		
			orient = ScpuiSystem.modelDraw.clickOrient * orient
		end
		
		--thisItem:renderTechModel(modelLeft, modelTop, modelLeft + modelWidth, modelTop + modelHeight, modelDraw.Rot, -15, 0, 1.1)
		thisItem:renderTechModel2(modelLeft, modelTop, modelLeft + modelWidth, modelTop + modelHeight, orient, 1.1)
		
	end

end

function TechDatabaseController:ClearEntry()

	self.document:GetElementById(self.SelectedEntry.key):SetPseudoClass("checked", false)
	self.SelectedEntry = nil

end

function TechDatabaseController:ClearData()

	ScpuiSystem.modelDraw.class = nil
	local aniWrapper = self.document:GetElementById("tech_view")
	aniWrapper:RemoveChild(aniWrapper.first_child)
	self.document:GetElementById("tech_desc").inner_rml = "<p></p>"
	
end

function TechDatabaseController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    elseif event.parameters.key_identifier == rocket.key_identifier.S and event.parameters.ctrl_key == 1 and event.parameters.shift_key == 1 then
		self.show_all = not self.show_all
		self:ReloadList()
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(4)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
		self:ChangeTechState(2)
	elseif event.parameters.key_identifier == rocket.key_identifier.TAB then
		local newSection = self.sectionIndex + 1
		if newSection == 4 then
			newSection = 1
		end
		self:ChangeSection(newSection)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.shift_key == 1 then
		self:ScrollList(self.document:GetElementById("tech_list"), 0)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.shift_key == 1 then
		self:ScrollList(self.document:GetElementById("tech_list"), 1)
	elseif event.parameters.key_identifier == rocket.key_identifier.UP then
		self:ScrollText(self.document:GetElementById("tech_desc"), 0)
	elseif event.parameters.key_identifier == rocket.key_identifier.DOWN then
		self:ScrollText(self.document:GetElementById("tech_desc"), 1)
	elseif event.parameters.key_identifier == rocket.key_identifier.LEFT then
		self:select_prev()
	elseif event.parameters.key_identifier == rocket.key_identifier.RIGHT then
		self:select_next()
	elseif event.parameters.key_identifier == rocket.key_identifier.RETURN then
		--self:commit_pressed(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F1 then
		self:help_clicked(element)
	elseif event.parameters.key_identifier == rocket.key_identifier.F2 then
		self:options_button_clicked(element)
	end
end

function TechDatabaseController:ScrollList(element, direction)
	if direction == 0 then
		element.scroll_top = element.scroll_top - 15
	else
		element.scroll_top = element.scroll_top + 15
	end
end

function TechDatabaseController:ScrollText(element, direction)
	if direction == 0 then
		element.scroll_top = (element.scroll_top - 5)
	else
		element.scroll_top = (element.scroll_top + 5)
	end
end

function TechDatabaseController:select_next()
    local num = #self.visibleList
	
	if self.SelectedIndex == num then
		ui.playElementSound(nil, "click", "error")
	else
		local count = 1
		while self.visibleList[self.SelectedIndex + count] ~= nil and self.visibleList[self.SelectedIndex + count].Selectable == false do
			count = count + 1
		end
		
		if (self.SelectedIndex + count) > num then
			ui.playElementSound(nil, "click", "error")
		elseif self.visibleList[self.SelectedIndex + count].Selectable == false then
			ui.playElementSound(nil, "click", "error")
		else
			self:SelectEntry(self.visibleList[self.SelectedIndex + count])
		end
	end
end

function TechDatabaseController:select_prev()	
	if self.SelectedIndex == 1 then
		ui.playElementSound(nil, "click", "error")
	else
		local count = 1
		while self.visibleList[self.SelectedIndex - count] ~= nil and self.visibleList[self.SelectedIndex - count].Selectable == false do
			count = count + 1
		end
		
		if (self.SelectedIndex - count) < 1 then
			ui.playElementSound(nil, "click", "error")
		elseif self.visibleList[self.SelectedIndex - count].Selectable == false then
			ui.playElementSound(nil, "click", "error")
		else
			self:SelectEntry(self.visibleList[self.SelectedIndex - count])
		end
	end
end

function TechDatabaseController:commit_pressed(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

function TechDatabaseController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

function TechDatabaseController:help_clicked(element)
    ui.playElementSound(element, "click", "success")
    
	self.help_shown  = not self.help_shown

    local help_texts = self.document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.help_shown)
    end
end

function TechDatabaseController:loadSeenDataFromFile()

	local json = require('dkjson')
  
	local location = 'data/players'
  
	local file = nil
	local config = {}
  
	if cf.fileExists('scpui_seen_tech.cfg') then
		file = cf.openFile('scpui_seen_tech.cfg', 'r', location)
		config = json.decode(file:read('*a'))
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

function TechDatabaseController:saveSeenDataToFile(data)

	local json = require('dkjson')
  
	local location = 'data/players'
  
	local file = nil
	local config = {}
  
	if cf.fileExists('scpui_seen_tech.cfg') then
		file = cf.openFile('scpui_seen_tech.cfg', 'r', location)
		config = json.decode(file:read('*a'))
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
	
	local utils = require('utils')
	config = utils.cleanPilotsFromSaveData(config)
  
	file = cf.openFile('scpui_seen_tech.cfg', 'w', location)
	file:write(json.encode(config))
	file:close()
end

function TechDatabaseController:unload()
	ScpuiSystem:saveOptionsToFile(ScpuiOptionValues)
	self:saveSeenDataToFile(self.seenData)
    ScpuiSystem:freeAllModels()
	
	topics.techdatabase.unload:send(self)
end

engine.addHook("On Frame", function()
	if (ba.getCurrentGameState().Name == "GS_STATE_TECH_MENU") and (ScpuiSystem.render == true) then
		TechDatabaseController:DrawModel()
	end
end, {}, function()
	return false
end)

return TechDatabaseController
