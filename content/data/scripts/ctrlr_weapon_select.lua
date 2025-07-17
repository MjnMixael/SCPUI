-----------------------------------
--Controller for the Weapon Select UI
-----------------------------------

local Dialogs = require("lib_dialogs")
local LoadoutHandler = require("lib_loadout_handler")
local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

--- Weapon Select Controller can be merged with the Multi Common Controller during multiplayer
local AbstractMultiController = nil
local WeaponSelectController = nil
if ScpuiSystem:inMultiGame() then
	AbstractMultiController = require("ctrlr_multi_common")
	WeaponSelectController = Class(AbstractMultiController)
else
	WeaponSelectController = Class()
end

WeaponSelectController.STATE_BRIEFING = 1 --- @type number The enumeration for the briefing game state
WeaponSelectController.STATE_SHIP_SELECT = 2 --- @type number The enumeration for the ship selection game state
WeaponSelectController.STATE_WEAPON_SELECT = 3 --- @type number The enumeration for the weapon selection game state

WeaponSelectController.WEAPON_EFFECT_OFF = 0 --- @type number The enumeration for the ship effect off
WeaponSelectController.WEAPON_EFFECT_NORMAL = 1 --- @type number The enumeration for the ship effect fs1 style
WeaponSelectController.WEAPON_EFFECT_GLOW = 2 --- @type number The enumeration for the ship effect fs2 style

WeaponSelectController.OVERHEAD_EFFECT_TOP = 0 --- @type number The enumeration for the overhead effect top view
WeaponSelectController.OVERHEAD_EFFECT_ROTATE = 1 --- @type number The enumeration for the overhead effect rotating view

--- Called by the class constructor
--- @return nil
function WeaponSelectController:init()
	self.Document = nil --- @type Document The RML document
	self.ChatEl = nil --- @type Element the chat window element
    self.ChatInputEl = nil --- @type Element the chat input element
	self.SubmittedChatValue = "" --- @type string the submitted value from the chat input
	self.HelpShown = false --- @type boolean Whether the help dialog has been shown
	self.Enabled = false --- @type boolean True if there are ships in the loadout, false on error
	self.Shipclass_Indexes = {} --- @type number[] The ship class indexes in the loadout
	self.Bank_Weapon_Classes = {} --- @type number[] The weapon indexes assigned to each bank
	self.Active_Slots = {} --- @type number[] The active slots in the loadout
	self.CurrentShipIndex = nil --- @type number The index of the currently selected ship class
	self.SelectedWeaponName = '' --- @type string The name of the currently selected weapon
	self.Commit = false --- @type boolean Whether the commit to the mission was successful
	self.OverheadElement = nil --- @type Element the element for the ship overhead image
	self.AnimEl = nil --- @type Element the element for the weapon animation
	self.Required_Weapons = {} --- @type string[] The required weapons for the mission, if any
	self.Weapon3d = false --- @type boolean Whether to render the weapon 3d models
	self.WeaponEffect = WeaponSelectController.WEAPON_EFFECT_OFF --- @type number The weapon effect style. Should be one of the WEAPON_EFFECT_ enumerations
	self.Icon3d = false --- @type boolean Whether to render the weapon icons in 3d
	self.Overhead3d = false --- @type boolean Whether to render the overhead ship in 3d
	self.OverheadStyle = WeaponSelectController.OVERHEAD_EFFECT_TOP --- @type number The overhead effect style. Should be one of the OVERHEAD_EFFECT_ enumerations
	self.Secondary_Amount_Elements = {} --- @type Element[] The elements for the secondary weapon amounts
	self.HeldWeaponIndex = 0 --- @type number The weapon index that is currently being held
	self.ReplacedElement = nil --- @type Element The bank slot element that is being replaced
	self.ActiveSlot = 0 --- @type number The active slot that is being dragged onto

	LoadoutHandler:init()
	ScpuiSystem.data.memory.model_rendering = {}
end

--- Called by the RML document
--- @param document Document
function WeaponSelectController:initialize(document)
	if AbstractMultiController and ScpuiSystem:inMultiGame()then
		AbstractMultiController.initialize(self, document)
		self.Subclass = AbstractMultiController.CTRL_WEAPON_SELECT
	end

	self.Document = document
	self.OverheadElement = self.Document:CreateElement("img")
	self.AnimEl = self.Document:CreateElement("ani")
	ScpuiSystem.data.memory.model_rendering.Weapons_List = {}
	ScpuiSystem.data.memory.model_rendering.Bank_Elements_List = {
		self.Document:GetElementById("primary_one"),
		self.Document:GetElementById("primary_two"),
		self.Document:GetElementById("primary_three"),
		self.Document:GetElementById("secondary_one"),
		self.Document:GetElementById("secondary_two"),
		self.Document:GetElementById("secondary_three"),
		self.Document:GetElementById("secondary_four")
	}
	self.Secondary_Amount_Elements = {
		self.Document:GetElementById("secondary_amount_one"),
		self.Document:GetElementById("secondary_amount_two"),
		self.Document:GetElementById("secondary_amount_three"),
		self.Document:GetElementById("secondary_amount_four")
	}

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	self.ChatEl = self.Document:GetElementById("chat_window")
	self.ChatInputEl = self.Document:GetElementById("chat_input")

	self.Weapon3d, self.WeaponEffect, self.Icon3d = ui.ShipWepSelect.get3dWeaponChoices()

	self.Overhead3d, self.OverheadStyle = ui.ShipWepSelect.get3dOverheadChoices()

	--Get all the required weapons
	local j = 1
	while (j < #tb.WeaponClasses) do
		if tb.WeaponClasses[j]:isWeaponRequired() then
			self.Required_Weapons[#self.Required_Weapons + 1] = tb.WeaponClasses[j].Name
		end
		j = j + 1
	end

	--Create the anim here so that it can be restarted with each new selection
	local ship_view_wrapper = self.Document:GetElementById("ship_view")
	ship_view_wrapper:AppendChild(self.OverheadElement)

	local weapon_view_wrapper = self.Document:GetElementById("weapon_view")
	weapon_view_wrapper:ReplaceChild(self.AnimEl, weapon_view_wrapper.first_child)


	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.Document:GetElementById("brief_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("s_select_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("w_select_btn"):SetPseudoClass("checked", true)

	self.SelectedEntry = nil
	self.SelectedShip = nil

	self.Enabled = self:buildWingsElements()

	for i = 1, LoadoutHandler:GetNumSlots() do
		table.insert(self.Shipclass_Indexes, 0)
	end

	if ScpuiSystem:inMultiGame() then
		ScpuiSystem.data.memory.multiplayer_general.Context = self
		ScpuiSystem.data.memory.multiplayer_general.LoadoutContext = LoadoutHandler
		ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true

		self.Document:GetElementById("chat_wrapper"):SetClass("hidden", false)
		self.Document:GetElementById("c_panel_wrapper_multi"):SetClass("hidden", false)
		self.Document:GetElementById("c_panel_wrapper"):SetClass("hidden", true)
		self.Document:GetElementById("copy_to_wing_panel"):SetClass("hidden", true)
		ui.MultiGeneral.setPlayerState()
	end

	Topics.weaponselect.initialize:send(self)

	--Only create entries if there are any to create
	if LoadoutHandler:GetNumPrimaryWeapons() > 0 and self.Enabled == true then
		self:createPoolList(LoadoutHandler:GetPrimaryWeaponList())
	end
	if LoadoutHandler:GetNumSecondaryWeapons() > 0 and self.Enabled == true then
		self:createPoolList(LoadoutHandler:GetSecondaryWeaponList())
	end

	if self.Enabled == true then
		self:selectInitialItems()
	end

	self:startMusic()

end

--- Constructs the wings UI elements and each ship slot
--- @return boolean val true if the wings were built successfully, false on error
function WeaponSelectController:buildWingsElements()

	local slot_num = 1 -- Start with the first slot
	local wrapper_element = self.Document:GetElementById("wings_wrapper")
	ScpuiSystem:clearEntries(wrapper_element)

	--Check that we actually have wing slots
	if LoadoutHandler:GetNumWings() <= 0 then
		ba.warning("Mission has no loadout wings! Check the loadout in FRED!")
		return false
	end

	for i = 1, LoadoutHandler:GetNumWings(), 1 do
		--First create a wrapper for the whole wing
		local wing_element = self.Document:CreateElement("div")
		wing_element:SetClass("wing", true)
		wrapper_element:AppendChild(wing_element)

		--Add the wrapper for the slots
		local slots_wrapper_element = self.Document:CreateElement("div")
		slots_wrapper_element:SetClass("slot_wrapper", true)
		wing_element:ReplaceChild(slots_wrapper_element, wing_element.first_child)

		--Add the wing name
		local name_element = self.Document:CreateElement("div")
		name_element:SetClass("wing_name", true)
		name_element.inner_rml = LoadoutHandler:GetWingDisplayName(i)
		wing_element:AppendChild(name_element)

		--Check that the wing actually has valid ship slots
		if LoadoutHandler:GetNumWingSlots(i) <= 0 then
			ba.warning("Loadout wing '" .. LoadoutHandler:GetWingName(i) .. "' has no valid ship slots! Check the loadout in FRED!")
			return false
		end

		--Now we add the actual wing slots
		for j = 1, LoadoutHandler:GetNumWingSlots(i), 1 do
			local slot_info = LoadoutHandler:GetShipLoadout(slot_num)

			--This is really only used for multi to limit how often icons are changed
			self.Shipclass_Indexes[slot_num] = slot_info.ShipClassIndex

			local slot_element = self.Document:CreateElement("div")
			slot_element:SetClass("wing_slot", true)
			slots_wrapper_element:AppendChild(slot_element)

			--default to empty slot image for now, but don't show disabled slots
			local slot_icon = LoadoutHandler:getEmptyWingSlotIcon()[2]
			if slot_info.IsDisabled then
				slot_icon = LoadoutHandler:getEmptyWingSlotIcon()[1]
			end

			if slot_info.WingSlot == 1 then
				slot_element:SetClass("wing_one", true)
			elseif slot_info.WingSlot == 2 then
				slot_element:SetClass("wing_two", true)
			elseif slot_info.WingSlot == 3 then
				slot_element:SetClass("wing_three", true)
			elseif slot_info.WingSlot == 4 then
				slot_element:SetClass("wing_four", true)
			else
				ba.error("Got wing slot > 4! Need to add RCSS support!")
			end

			--Get the current ship in this slot
			local ship_index = slot_info.ShipClassIndex
			if ship_index > 0 then
				local entry = LoadoutHandler:GetShipInfo(ship_index)
				if entry == nil then
					--This reeeeaaaaallly shouldn't happen, but it is for some multi missions
					ba.warning("Could not find " .. tb.ShipClasses[ship_index].Name .. " in the loadout! Appending!")
					LoadoutHandler:AppendToShipInfo(ship_index)
					entry = LoadoutHandler:GetShipInfo(ship_index)
				end
				if entry then
					if slot_info.IsPlayer then
						slot_icon = entry.GeneratedIcon[1]
					elseif slot_info.IsWeaponLocked then
						slot_icon = entry.GeneratedIcon[4]
					elseif slot_info.IsShipLocked then
						slot_icon = entry.GeneratedIcon[6]
					else
						slot_icon = entry.GeneratedIcon[1]
					end
				else
					ba.error("Failed to generate data for " .. tb.ShipClasses[ship_index].Name .. " in the loadout!")
				end
			end

			local slot_img = self.Document:CreateElement("img")
			slot_img:SetAttribute("src", slot_icon)
			slot_element:AppendChild(slot_img)

			local slot_name = self.Document:CreateElement("div")
			slot_name.inner_rml = slot_info.DisplayName
			slot_name.id = "callsign_" .. slot_num
			slot_name:SetClass("slot_name", true)
			slot_element:AppendChild(slot_name)

			--This is here so that the event listeners use the correct slot index!
			local index = slot_num

			slot_element.id = "slot_" .. slot_num

			self:activateSlot(index)

			slot_num = slot_num + 1
		end
	end

	return true

end

--- Attempt to activate a slot's drag and click events. Will not activate disabled slots or slots that are not active
--- @param slot number The slot index to activate
--- @return nil
function WeaponSelectController:activateSlot(slot)
	local slot_info = LoadoutHandler:GetShipLoadout(slot)

	--Don't activate disabled slots
	if slot_info.IsDisabled == true then
		return
	end

	--Don't activate already active slots
	if Utils.table.contains(self.Active_Slots, slot) then
		return
	end

	table.insert(self.Active_Slots, slot)

	local element = self.Document:GetElementById("slot_" .. slot)

	--Abort if the slot was never created
	if not element then
		return
	end

	if slot_info.ShipClassIndex > 0 then
		if not slot_info.IsShipLocked then

			if self.Icon3d then
				element:SetClass("available", true)
			end
		else
			if self.Icon3d then
				element:SetClass("locked", true)
			end
		end

		--Add click detection
		element:SetClass("button_3", true)
		element:AddEventListener("click", function(_, _, _)
			self:clickOnSlot(slot)
		end)
	end
end

--- Selects the first ship and weapon that are available
--- @return nil
function WeaponSelectController:selectInitialItems()

	local select_slot = 0
	for i = 1, LoadoutHandler:GetNumSlots() do
		if LoadoutHandler:GetShipLoadout(i).ShipClassIndex > 0 then
			select_slot = i
			break
		end
	end

	if select_slot > 0 then
		local ship = LoadoutHandler:GetShipLoadout(select_slot)

		self:selectShip(ship.ShipClassIndex, ship.Name, select_slot)

		if LoadoutHandler:GetNumPrimaryWeapons() > 0 then
			self:selectWeapon(LoadoutHandler:GetPrimaryWeaponList()[1])
		end

		if LoadoutHandler:GetNumSecondaryWeapons() > 0 then
			self:selectWeapon(LoadoutHandler:GetSecondaryWeaponList()[1])
		end
	end

end

--- Reloads the ship and weapon lists and rebuilds the entire ship selection UI
--- @return nil
function WeaponSelectController:reloadInterface()

	ScpuiSystem.data.memory.model_rendering.Class = nil
	ScpuiSystem.data.memory.model_rendering.OverheadClass = nil
	local list_items_el = self.Document:GetElementById("primary_icon_list_ul")
	ScpuiSystem:clearEntries(list_items_el)
	local list_items_el = self.Document:GetElementById("secondary_icon_list_ul")
	ScpuiSystem:clearEntries(list_items_el)
	self.SelectedEntry = nil
	self.SelectedShip = nil
	self.Active_Slots = {}
	if LoadoutHandler:GetNumPrimaryWeapons() > 0 then
		self:createPoolList(LoadoutHandler:GetPrimaryWeaponList())
	end
	if LoadoutHandler:GetNumSecondaryWeapons() > 0 then
		self:createPoolList(LoadoutHandler:GetSecondaryWeaponList())
	end
	self:buildWingsElements()
	self:selectInitialItems()
	self:updateUiElements()
end

--- Goes through the weapon pool and updates the icons to show which are compatible with the current ship
--- @param shipIndex number The index of the ship class to check compatibility with
--- @return nil
function WeaponSelectController:setWeaponPoolIcons(shipIndex)

	--- Primary weapons
	for i, v in pairs(LoadoutHandler:GetPrimaryWeaponList()) do
		local icon_element = self.Document:GetElementById(v.Key).first_child.first_child.next_sibling
		if tb.ShipClasses[shipIndex]:isWeaponAllowedOnShip(v.Index) then
			icon_element:SetClass("drag", true)
			if self.Icon3d then
				--iconEl:SetClass("available", true)
				--iconEl:SetClass("locked", false)
			end
			icon_element:SetAttribute("src", v.GeneratedIcon[1])
		else
			icon_element:SetClass("drag", false)
			if self.Icon3d then
				--iconEl:SetClass("available", false)
				--iconEl:SetClass("locked", true)
			end
			icon_element:SetAttribute("src", v.GeneratedIcon[6])
		end
	end
	--- Secondary weapons
	for i, v in pairs(LoadoutHandler:GetSecondaryWeaponList()) do
		local icon_element = self.Document:GetElementById(v.Key).first_child.first_child.next_sibling
		if tb.ShipClasses[shipIndex]:isWeaponAllowedOnShip(v.Index) then
			icon_element:SetClass("drag", true)
			if self.Icon3d then
				--iconEl:SetClass("available", true)
				--iconEl:SetClass("locked", false)
			end
			icon_element:SetAttribute("src", v.GeneratedIcon[1])
		else
			icon_element:SetClass("drag", false)
			if self.Icon3d then
				--iconEl:SetClass("available", false)
				--iconEl:SetClass("locked", true)
			end
			icon_element:SetAttribute("src", v.GeneratedIcon[6])
		end
	end

end

--- Creates a list item element for the specified weapon in the weapon pool
--- @param entry weapon_loadout_info The weapon entry to create the list item for
--- @param idx number The index of the weapon in the list. UNUSED
--- @return Element li_el The list item element
function WeaponSelectController:createWeaponPoolListItem(entry, idx)

	local li_el = self.Document:CreateElement("li")
	local icon_wrapper = self.Document:CreateElement("div")
	icon_wrapper.id = entry.Name
	icon_wrapper:SetClass("select_item", true)

	li_el:AppendChild(icon_wrapper)

	local count_element = self.Document:CreateElement("div")
	count_element.inner_rml = tostring(LoadoutHandler:GetWeaponPoolAmount(entry.Index))
	count_element:SetClass("amount", true)
	count_element.id = entry.Name .. "_count"

	icon_wrapper:AppendChild(count_element)

	--local aniWrapper = self.Document:GetElementById(entry.Icon)
	local icon_element = self.Document:CreateElement("img")
	icon_element:SetAttribute("src", entry.GeneratedIcon[1])
	icon_wrapper:AppendChild(icon_element)
	--iconWrapper:ReplaceChild(iconEl, iconWrapper.first_child)
	li_el.id = entry.Name

	--iconEl:SetClass("shiplist_element", true)
	icon_element:SetClass("button_3", true)
	icon_element:SetClass("icon", true)
	icon_element:SetClass("drag", true)
	icon_element:AddEventListener("click", function(_, _, _)
		self:selectWeapon(entry)
	end)
	icon_element:AddEventListener("dragend", function(_, _, _)
		self:dragWeaponFromPoolToSlot(icon_element, entry, entry.Index)
	end)
	icon_element:AddEventListener("dragstart", function(_,_,_)
		self.HeldWeaponIndex = entry.Index
		self.drag = true
	end)
	entry.Key = li_el.id

	return li_el
end

--- Creates all the weapon pool list items for the provided list. Will automatically determine between the primary and secondary lists
--- @param list weapon_loadout_info[] The list of weapons to create the list items for
--- @return nil
function WeaponSelectController:createPoolList(list)

	local list_names_el = nil

	if tb.WeaponClasses[list[1].Index]:isPrimary() then
		list_names_el = self.Document:GetElementById("primary_icon_list_ul")
	elseif tb.WeaponClasses[list[1].Index]:isSecondary() then
		list_names_el = self.Document:GetElementById("secondary_icon_list_ul")
	end

	if list_names_el ~= nil then
		ScpuiSystem:clearEntries(list_names_el)

		for i, v in pairs(list) do
			list_names_el:AppendChild(self:createWeaponPoolListItem(v, i))
		end
	end
end

--- Called by the RML to show the current weapon's description in a dialog box
--- @return nil
function WeaponSelectController:show_breakout_reader()
	local text = Topics.weapons.description:send(tb.WeaponClasses[self.SelectedWeaponName])
	local title = "<span style=\"color:white;\">" .. Topics.weapons.name:send(tb.WeaponClasses[self.SelectedWeaponName]) .. "</span>"
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

--- Sets the weapon as the selected weapon
--- @param entry? weapon_loadout_info The weapon entry to select
--- @param slot? number The slot that was selected, if any
--- @return nil
function WeaponSelectController:selectWeapon(entry, slot)
	if entry ~= nil then
		ScpuiSystem.data.memory.model_rendering.Hover = slot
		if entry.Key ~= self.SelectedEntry then

			self.SelectedEntry = entry.Key
			self.SelectedWeaponName = entry.Name

			self:highlightCompatibleWeapons()

			self:setupWeaponInfo(entry)

			if self.Weapon3d or entry.Anim == nil then
				ScpuiSystem.data.memory.model_rendering.Class = entry.Index
				ScpuiSystem.data.memory.model_rendering.Element = self.Document:GetElementById("weapon_view_window")
				ScpuiSystem.data.memory.model_rendering.Start = true

				self:refreshOverheadSlot()
			else
				--the anim is already created so we only need to remove and reset the src
				self.AnimEl:RemoveAttribute("src")
				self.AnimEl:SetAttribute("src", entry.Anim)
			end

		end
	end
end

--- Called by the RML to select the weapon assigned to a particular bank slot
--- @param element Element The element that was clicked
--- @param slot number The slot that was clicked
--- @return nil
function WeaponSelectController:select_assigned_entry(element, slot)

	local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)
	local weapon = ship.Weapons_List[slot]

	local selected_entry = nil

	if slot < 4 then
		selected_entry = LoadoutHandler:GetPrimaryInfo(weapon)
	else
		selected_entry = LoadoutHandler:GetSecondaryInfo(weapon)
	end

	self:selectWeapon(selected_entry, slot)

end

--- Goes through the primary and secondary weapon lists and updates the icons to show which are compatible with the current ship
--- @return nil
function WeaponSelectController:highlightCompatibleWeapons()
	local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)

	for i, v in pairs(LoadoutHandler:GetPrimaryWeaponList()) do
		local icon_element = self.Document:GetElementById(v.Key).first_child.first_child.next_sibling
		if tb.ShipClasses[ship.ShipClassIndex]:isWeaponAllowedOnShip(v.Index) then
			if v.Key == self.SelectedEntry then
				if self.Icon3d then
					icon_element:SetClass("highlighted", true)
				end
				icon_element:SetAttribute("src", v.GeneratedIcon[3])
			else
				if self.Icon3d then
					icon_element:SetClass("highlighted", false)
				end
				icon_element:SetAttribute("src", v.GeneratedIcon[1])
			end
		end
	end

	for i, v in pairs(LoadoutHandler:GetSecondaryWeaponList()) do
		local icon_element = self.Document:GetElementById(v.Key).first_child.first_child.next_sibling
		if tb.ShipClasses[ship.ShipClassIndex]:isWeaponAllowedOnShip(v.Index) then
			if v.Key == self.SelectedEntry then
				if self.Icon3d then
					icon_element:SetClass("highlighted", true)
				end
				icon_element:SetAttribute("src", v.GeneratedIcon[3])
			else
				if self.Icon3d then
					icon_element:SetClass("highlighted", false)
				end
				icon_element:SetAttribute("src", v.GeneratedIcon[1])
			end
		end
	end

	for i, v in pairs(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List) do
		local index = string.sub(i, -1)

		local weapon = ship.Weapons_List[index]
		if weapon ~= nil and weapon > 0 then
			local this_entry = LoadoutHandler:GetWeaponInfo(weapon)
			if not this_entry then
				ba.error("Could not find weapon " .. tb.WeaponClasses[weapon].Name .. " in the loadout!")
			else
				if v.first_child ~= nil then
					if tb.WeaponClasses[weapon].Name == self.SelectedEntry then
						v.first_child:SetAttribute("src", this_entry.GeneratedIcon[3])
					else
						v.first_child:SetAttribute("src", this_entry.GeneratedIcon[1])
					end
				end
			end
		end
	end

end

--- Go through all the ship slots to highlight the selected one and unhighlight the others
--- @param slot number The slot to highlight
--- @return boolean true if the slot was highlighted, false if the slot was not found
function WeaponSelectController:highlightShipInSlot(slot)

	local return_val = false
	for i = 1, LoadoutHandler:GetNumSlots(), 1 do
		local slot_element = self.Document:GetElementById("slot_" .. i)
		local ship = LoadoutHandler:GetShipLoadout(i)
		local ship_idx = ship.ShipClassIndex
		local this_entry = LoadoutHandler:GetShipInfo(ship_idx)
		if this_entry ~= nil then
			local icon = nil
			if slot == i then
				if ship.IsWeaponLocked then
					icon = this_entry.GeneratedIcon[6] -- could be 4 (orange)
				elseif ship.IsShipLocked then
					icon = this_entry.GeneratedIcon[6]
				else
					icon = this_entry.GeneratedIcon[3]
				end
				return_val = true
			else
				if ship.IsWeaponLocked then
					icon = this_entry.GeneratedIcon[5] -- could be 4 (orange)
				elseif ship.IsShipLocked then
					icon = this_entry.GeneratedIcon[5]
				else
					icon = this_entry.GeneratedIcon[1]
				end
			end

			slot_element.first_child:SetAttribute("src", icon)

		end
	end

	return return_val

end

--- When a ship slot is clicked on, set the ship as the selected ship
--- @param slot number The slot that was clicked
--- @return nil
function WeaponSelectController:clickOnSlot(slot)
	local ship_info = LoadoutHandler:GetShipLoadout(slot)

	self:selectShip(ship_info.ShipClassIndex, ship_info.Name, slot)
end

--- Set the selected ship slot and update the UI accordingly
--- @param ship_index number The index of the ship class to select
--- @param callsign string The callsign of the ship to select
--- @param slot number The slot that was selected
--- @return nil
function WeaponSelectController:selectShip(ship_index, callsign, slot)

	if callsign ~= self.SelectedShip then

		self.SelectedShip = callsign
		self.currentShipSlot = slot

		self.Document:GetElementById("ship_name").inner_rml = callsign

		local this_entry = LoadoutHandler:GetShipInfo(ship_index)

		--This really shouldn't be possible but just in case
		if not this_entry then
			return
		end

		--If we have an error highlighting the ship then the rest will fail, so bail
		if self:highlightShipInSlot(slot) == false then
			return
		end

		local overhead = this_entry.Overhead

		self:setupWeaponSlots(ship_index)
		self.CurrentShipIndex = ship_index

		self:setWeaponPoolIcons(ship_index)

		self:highlightCompatibleWeapons()

		Topics.weaponselect.selectShip:send({self, ship_index})

		if self.Overhead3d then
			ScpuiSystem.data.memory.model_rendering.OverheadClass = ship_index
			ScpuiSystem.data.memory.model_rendering.OverheadElement = self.Document:GetElementById("ship_view_wrapper")
			ScpuiSystem.data.memory.model_rendering.overheadEffect = self.OverheadStyle

			self:refreshOverheadSlot()
		else
			--the anim is already created so we only need to remove and reset the src
			self.OverheadElement:RemoveAttribute("src")
			self.OverheadElement:SetAttribute("src", overhead)
		end

	end

end

--- Clear the weapon bank slots
--- @return nil
function WeaponSelectController:clearAllWeaponSlots()
	for _, v in pairs(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List) do
		ScpuiSystem:clearEntries(v)
	end

	self.Bank_Weapon_Classes = {}

	for i = 1, LoadoutHandler:GetMaxBanks() do
		table.insert(self.Bank_Weapon_Classes, 0)
	end

	for i, v in pairs(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List) do
		v:SetClass("slot_3d", false)
		v:SetClass("button_3", false)
		v:SetClass("weapon_locked", false)
	end

	for i, v in pairs(self.Secondary_Amount_Elements) do
		v.inner_rml = ""
	end
end

--- Fill in all the weapon slots according to the current ship class
--- @param ship_idx number The index of the ship class to build the slots for
--- @return nil
function WeaponSelectController:setupWeaponSlots(ship_idx)

	if not ship_idx then
		return
	end

	if self.CurrentShipIndex ~= ship_idx then
		self:clearAllWeaponSlots()
	end

	if tb.ShipClasses[ship_idx].numPrimaryBanks > 0 then
		self:setupBankSlot(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[1], 1)
		if self.Overhead3d then
			ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[1]:SetClass("slot_3d", true)
		end
	end

	if tb.ShipClasses[ship_idx].numPrimaryBanks > 1 then
		self:setupBankSlot(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[2], 2)
		if self.Overhead3d then
			ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[2]:SetClass("slot_3d", true)
		end
	end

	if tb.ShipClasses[ship_idx].numPrimaryBanks > 2 then
		self:setupBankSlot(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[3], 3)
		if self.Overhead3d then
			ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[3]:SetClass("slot_3d", true)
		end
	end

	if tb.ShipClasses[ship_idx].numSecondaryBanks > 0 then
		self:setupBankSlot(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[4], 4)
		if self.Overhead3d then
			ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[4]:SetClass("slot_3d", true)
		end
	end

	if tb.ShipClasses[ship_idx].numSecondaryBanks > 1 then
		self:setupBankSlot(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[5], 5)
		if self.Overhead3d then
			ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[5]:SetClass("slot_3d", true)
		end
	end

	if tb.ShipClasses[ship_idx].numSecondaryBanks > 2 then
		self:setupBankSlot(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[6], 6)
		if self.Overhead3d then
			ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[6]:SetClass("slot_3d", true)
		end
	end

	if tb.ShipClasses[ship_idx].numSecondaryBanks > 3 then
		self:setupBankSlot(ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[7], 7)
		if self.Overhead3d then
			ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[7]:SetClass("slot_3d", true)
		end
	end

end

--- Setup a specific weapon slot based on the current ship's loadout
--- @param parent_element Element The element to build the slot in
--- @param bank number The bank to build the slot for
--- @return nil
function WeaponSelectController:setupBankSlot(parent_element, bank)
	local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)

	--Maybe show slot as locked
	if ship.IsWeaponLocked == true then
		parent_element:SetClass("weapon_locked", true)
	else
		parent_element:SetClass("weapon_locked", false)
	end

	--Get the weapon currently loaded in the slot
	local weapon = ship.Weapons_List[bank] or 0
	---@type integer | string
	local amount = ship.Amounts_List[bank] or 0
	if amount < 1 then amount = "" end
	if bank > 3 then
		self.Secondary_Amount_Elements[bank - 3].inner_rml = tostring(amount)
	end

	if self.Bank_Weapon_Classes[bank] == weapon then
		return
	end

	self.Bank_Weapon_Classes[bank] = weapon

	ScpuiSystem:clearEntries(parent_element)

	local slot_img_element = self.Document:CreateElement("img")

	local slot_icon = nil
	if weapon > 0 then
		if ship.IsWeaponLocked == false then
			slot_icon = LoadoutHandler:GetWeaponInfo(weapon).GeneratedIcon[1]
			slot_img_element:SetClass("drag", true)
		else
			slot_icon = LoadoutHandler:GetWeaponInfo(weapon).GeneratedIcon[4]
		end
		--slotIcon = tb.WeaponClasses[weapon].SelectIconFilename
		slot_img_element:SetClass("button_3", true)
		slot_img_element:SetAttribute("src", slot_icon)
		parent_element:AppendChild(slot_img_element)
	end
end

--- Setup the weapon info panel with the current weapon's data
--- @param entry weapon_loadout_info The weapon entry to display
--- @return nil
function WeaponSelectController:setupWeaponInfo(entry)

	self.Document:GetElementById("weapon_name").inner_rml = entry.Title

	local info_element = self.Document:GetElementById("weapon_stats")

	ScpuiSystem:clearEntries(info_element)

	local power = entry.Power
	local rof = entry.RoF
	local velocity = Utils.round(entry.Velocity)
	local range = Utils.round(entry.Range)
	local cargoSize = Utils.round(entry.CargoSize, 2)

	local desc_el = self.Document:CreateElement("p")
	desc_el.inner_rml = entry.Description
	desc_el:SetClass("white", true)

	local stats1_el = self.Document:CreateElement("p")
	stats1_el.inner_rml = ba.XSTR("Velocity", 888430) .. ": " .. velocity .. "m/s, " .. ba.XSTR("Range", 888431) .. ": " .. range .. "m"
	stats1_el:SetClass("green", true)

	local stats2_el = self.Document:CreateElement("p")
	stats2_el:SetClass("info", true)

	local volley = entry.VolleySize or 1

	if entry.Type == "secondary" and entry.FireWait >= 1 then
		local hull = Utils.round(entry.HullDamage * volley)
		local shield = Utils.round(entry.ShieldDamage * volley)
		local subsystem = Utils.round(entry.SubsystemDamage * volley)
		local label = (volley == 1) and ba.XSTR("Damage per missile", 888432) or ba.XSTR("Damage per volley", 888433)
		stats2_el.inner_rml = label .. ": " .. hull .. " " .. ba.XSTR("Hull", 888434) .. ", " .. shield .. " " .. ba.XSTR("Shield", 888435) .. ", " .. subsystem .. " " .. ba.XSTR("Subsystem", 888436)
	else
		local hull = Utils.round(entry.HullDamage * volley / entry.FireWait)
		local shield = Utils.round(entry.ShieldDamage * volley / entry.FireWait)
		local subsystem = Utils.round(entry.SubsystemDamage * volley / entry.FireWait)
		stats2_el.inner_rml = ba.XSTR("Damage per second", 888437) .. ": " .. hull .. " " .. ba.XSTR("Hull", 888434) .. ", " .. shield .. " " .. ba.XSTR("Shield", 888435) .. ", " .. subsystem .. " " .. ba.XSTR("Subsystem", 888436)
	end
	stats2_el:SetClass("red", true)

	local stats3_el = self.Document:CreateElement("p")
	stats3_el:SetClass("info", true)
	if entry.Type == "secondary" then
		stats3_el.inner_rml = ba.XSTR("Cargo Size", 888558) .. ": " .. cargoSize .. ", " .. ba.XSTR("Rate of Fire", 888443) .. ": " .. rof .. "/s"
	else
		stats3_el.inner_rml = ba.XSTR("Power Use", 888441) .. ": " .. power .. ba.XSTR("W", 888442) .. ", " .. ba.XSTR("Rate of Fire", 888443) .. ": " .. rof .. "/s"
	end
	stats3_el:SetClass("blue", true)

	info_element:AppendChild(desc_el)
	info_element:AppendChild(stats1_el)
	info_element:AppendChild(stats2_el)
	info_element:AppendChild(stats3_el)

	Topics.weaponselect.entryInfo:send({entry, info_element})

end

--- Called by the RML to change the game briefing state
--- @param state number The state to change to. Should be one of the STATE_ enumerations
--- @return nil
function WeaponSelectController:change_brief_state(state)
	if state == self.STATE_BRIEFING then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
	elseif state == self.STATE_SHIP_SELECT then
		if mn.isScramble() then
			ad.playInterfaceSound(10)
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_SHIP_SELECTION"])
		end
	elseif state == self.STATE_WEAPON_SELECT then
		--Do nothing because we're this is the current state!
	end
end

--- Called by the RML when a dragged element is dropped onto another element
--- @param element Element The element that was dropped onto
--- @param slot number The slot number that this element represents
--- @return nil
function WeaponSelectController:on_drag_drop(element, slot)
	self.ReplacedElement = element
	self.ActiveSlot = slot
	element:SetPseudoClass("valid", false)
	element:SetPseudoClass("invalid", false)
end

--- Called by the RML when an element is dragged over another element
--- @param element Element The element that is being dragged over
--- @param slot number The slot number that this element represents
--- @return nil
function WeaponSelectController:on_drag_over(element, slot)
	local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)
	local amount = ship.Weapons_List[slot]

	if not LoadoutHandler:ShipHasBank(ship.ShipClassIndex, slot) then
		return
	end

	local allowed = false

	if self.drag and not ship.IsWeaponLocked then
		if LoadoutHandler:IsWeaponAllowedInBank(ship.ShipClassIndex, self.HeldWeaponIndex, slot) then
			allowed = true
		end
	end

	if allowed then
		element:SetPseudoClass("valid", true)
		if amount ~= nil then
			if amount > 0 then
				ScpuiSystem.data.memory.model_rendering.Hover = slot
			end
		end
	else
		element:SetPseudoClass("invalid", true)
	end
end

--- Called by the RML when a draggable element is picked up
--- @param element Element The element that was picked up
--- @param slot number The slot number that this element represents
--- @return nil
function WeaponSelectController:on_drag_start(element, slot)
	local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)
	self.HeldWeaponIndex = ship.Weapons_List[slot]
	self.drag = true
end

--- Called by the RML when a draggable element is no longer being dragged over another element
--- @param element Element The element that was dragged out
--- @param slot number The slot number that this element represents
--- @return nil
function WeaponSelectController:on_drag_out(element, slot)
	ScpuiSystem.data.memory.model_rendering.Hover = -1
	element:SetPseudoClass("valid", false)
	element:SetPseudoClass("invalid", false)
end

--- Apply a weapon to a specific slot
--- @param element Element The element to apply the weapon to
--- @param slot number The slot number to apply the weapon to. UNUSED
--- @param bank number The bank number to. UNUSED
--- @param weapon number The weapon index to apply
function WeaponSelectController:ApplyWeaponToSlot(element, slot, bank, weapon)

	local entry = LoadoutHandler:GetWeaponInfo(weapon)
	if not entry then
		ba.error("Could not find weapon " .. tb.WeaponClasses[weapon].Name .. " in the loadout!")
	else
		local slotIcon = nil
		slotIcon = entry.GeneratedIcon[1]
		if element.first_child == nil then
			local slotEl = self.Document:CreateElement("img")
			element:AppendChild(slotEl)
		end
		element.first_child:SetAttribute("src", slotIcon)
		element.first_child:SetClass("drag", true)
	end

end

--- Empties a specific slot of all weapons
--- @param element Element The element to empty
--- @param slot number The slot number to empty
--- @return nil
function WeaponSelectController:emptySlot(element, slot)
	element:RemoveChild(element.first_child)
	if slot > 3 then
		self:updateSecondaryBankCount(slot)
	end
end

--- Updates a ship slot based on the current loadout
--- @param slot number The slot to update
--- @return nil
function WeaponSelectController:updateShipSlot(slot)
	local slot_info = LoadoutHandler:GetShipLoadout(slot)

	local replace_el = self.Document:GetElementById("slot_" .. slot)

	--If the slot doesn't exist then bail
	if not replace_el then
		return
	end

	self:activateSlot(slot)

	replace_el.first_child.next_sibling.inner_rml = slot_info.Name

	if self.Shipclass_Indexes[slot] == slot_info.ShipClassIndex then
		return
	end

	self.Shipclass_Indexes[slot] = slot_info.ShipClassIndex

	local slot_icon = LoadoutHandler:getEmptyWingSlotIcon()[2]
	if slot_info.IsDisabled then
		slot_icon = LoadoutHandler:getEmptyWingSlotIcon()[1]
	end

	--Get the current ship in this slot
	local ship_index = slot_info.ShipClassIndex
	if ship_index > 0 then
		local entry = LoadoutHandler:GetShipInfo(ship_index)
		if not entry then
			ba.error("Could not find " .. tb.ShipClasses[ship_index].Name .. " in the loadout!")
		else
			if slot_info.IsShipLocked then
				slot_icon = entry.GeneratedIcon[5]
			else
				slot_icon = entry.GeneratedIcon[1]
			end
		end
	end

	self:updateSlotImage(replace_el, slot_icon)
end

--- Updates all ship slots based on the current loadout
--- @return nil
function WeaponSelectController:updateShipSlots()
	for i = 1, LoadoutHandler:GetNumSlots() do
		self:updateShipSlot(i)
	end
end

--- Updates all pool counts based on the current loadout
--- @return nil
function WeaponSelectController:updateAllPoolCounts()
	local primary_list = LoadoutHandler:GetPrimaryWeaponList()
	for i = 1, #primary_list do
		self:updatePoolWeaponCount(primary_list[i])
	end
	local secondary_list = LoadoutHandler:GetSecondaryWeaponList()
	for i = 1, #secondary_list do
		self:updatePoolWeaponCount(secondary_list[i])
	end
end

--- Updates a slots image with the provided image
--- @param element Element The element to update
--- @param img string The image to update the element with
--- @return nil
function WeaponSelectController:updateSlotImage(element, img)
	local img_element = self.Document:CreateElement("img")
	img_element:SetAttribute("src", img)

	element:RemoveChild(element.first_child)
	element:InsertBefore(img_element, element.first_child)
	element:SetClass("button_3", true)
end

--- Updates a specific weapon's count in the pool based on the current loadout
--- @param data weapon_loadout_info The weapon entry to update the count for
--- @return nil
function WeaponSelectController:updatePoolWeaponCount(data)
	local count_element = self.Document:GetElementById(data.Key .. "_count")

	if count_element == nil then return end

	count_element.inner_rml = tostring(LoadoutHandler:GetWeaponPoolAmount(data.Index))
end

--- Updates all UI elements based on the current loadout
--- @return nil
function WeaponSelectController:updateUiElements()
	self:updateAllPoolCounts()
	if self.currentShipSlot == nil then
		return
	end
	self:updateSecondaryBankCounts()
	self:setupWeaponSlots(LoadoutHandler:GetShipLoadout(self.currentShipSlot).ShipClassIndex)
	self:refreshOverheadSlot()
end

--- Update all secondary bank weapon counts based on the current loadout
--- @return nil
function WeaponSelectController:updateSecondaryBankCounts()
	for i = 1, #self.Secondary_Amount_Elements do
		local bank = i + LoadoutHandler:GetMaxPrimaries()

		self:updateSecondaryBankCount(bank)
	end
end

--- Updates a specific secondary bank weapon count based on the current loadout
--- @param bank number The bank to update
--- @return nil
function WeaponSelectController:updateSecondaryBankCount(bank)
	local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)
	---@type integer | string
	local amount = ship.Amounts_List[bank]

	if amount == nil or amount < 1 then
		amount = ""
	end

	local element = self.Secondary_Amount_Elements[bank - 3]
	element.inner_rml = tostring(amount)
end

--- When a weapon is dragged from the pool to a slot, try to apply it to that bank slot
--- @param element Element The element that was dragged
--- @param entry weapon_loadout_info The weapon entry that was dragged
--- @param weapon_index number The weapon index that was dragged
--- @return nil
function WeaponSelectController:dragWeaponFromPoolToSlot(element, entry, weapon_index)
	self.HeldWeaponIndex = nil

	--No changes if wing positions are not locked!
	if ScpuiSystem:inMultiGame() and ui.MultiGeneral.getNetGame().Locked == false then
		return
	end

	if (self.ReplacedElement ~= nil) and (self.ActiveSlot > 0) then

		--Get the slot information: ship, weapon, and amount
		local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)
		local ship_idx = ship.ShipClassIndex
		local slot_weapon = ship.Weapons_List[self.ActiveSlot]
		local slot_amount = ship.Amounts_List[self.ActiveSlot]

		if ScpuiSystem:inMultiGame() then
			ui.ShipWepSelect.sendWeaponRequestPacket(0, self.ActiveSlot, weapon_index, 0, self.currentShipSlot)
			self.ReplacedElement = nil
			return
		end

		--Get the amount of the weapon we're dragging
		local count = LoadoutHandler:GetWeaponPoolAmount(weapon_index)

		--If the pool count is 0 then abort!
		if count < 1 then
			self.ReplacedElement = nil
			return
		end

		--If the ship is weapon locked then abort!
		if ship.IsWeaponLocked then
			self.ReplacedElement = nil
			return
		end

		--If the slot can't accept the weapon then abort!
		if not LoadoutHandler:IsWeaponAllowedInBank(ship_idx, weapon_index, self.ActiveSlot) then
			self.ReplacedElement = nil
			local text = ba.XSTR("That weapon slot can't accept that weapon type", 888444)
			local title = ""
			---@type dialog_button[]
			local buttons = {}
			buttons[1] = {
				Type = Dialogs.BUTTON_TYPE_POSITIVE,
				Text = ba.XSTR("Okay", 888290),
				Value = "",
				Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1)
			}

			self:showDialog(text, title, buttons)
			return
		end

		--If the slot already has that weapon then abort!
		if weapon_index == slot_weapon then
			self.ReplacedElement = nil
			return
		end

		--If slot doesn't exist on current ship then abort!
		if not LoadoutHandler:ShipHasBank(ship_idx, self.ActiveSlot) then
			self.ReplacedElement = nil
			return
		end

		if count > 0 then

			--return weapons to pool if appropriate
			LoadoutHandler:EmptyWeaponBank(self.currentShipSlot, self.ActiveSlot)

			--Apply to the actual loadout
			LoadoutHandler:AddWeaponToBank(self.currentShipSlot, self.ActiveSlot, weapon_index)

			self:ApplyWeaponToSlot(self.ReplacedElement, self.currentShipSlot, self.ActiveSlot, weapon_index)

			self.ReplacedElement = nil
		end

		self:updateUiElements()
	end
end

--- When a weapon is dragged from a slot to another slot or to the pool, try to apply it to that bank slot or return it to the pool
--- @param element Element The element that was dragged
--- @param slot number The slot that was dragged
--- @return nil
function WeaponSelectController:drag_from_slot_to_slot_or_pool(element, slot)
	self.HeldWeaponIndex = nil

	--No changes if wing positions are not locked!
	if ScpuiSystem:inMultiGame() and ui.MultiGeneral.getNetGame().Locked == false then
		return
	end

	if (self.ReplacedElement ~= nil) and (self.ActiveSlot > -1) then

		local drop_slot = self.ActiveSlot

		--Get the slot information of what's being dragged: ship, weapon, and amount
		local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)
		local ship_idx = ship.ShipClassIndex
		local slot_weapon = ship.Weapons_List[slot]
		local slot_amount = ship.Amounts_List[slot]

		if ScpuiSystem:inMultiGame() then
			local wep_idx = slot_weapon
			if drop_slot > 0 then
				wep_idx = 0
			end
			ui.ShipWepSelect.sendWeaponRequestPacket(slot, self.ActiveSlot, 0, wep_idx, self.currentShipSlot)
			self.ReplacedElement = nil
			return
		end

		--If the ship is weapon locked then abort!
		if ship.IsWeaponLocked then
			self.ReplacedElement = nil
			return
		end

		--Get the slot information of what's being dropped onto: weapon, and amount
		local active_weapon
		local active_amount
		if drop_slot > 0 then
			active_weapon = ship.Weapons_List[drop_slot]
			--activeAmount = ship.Amounts[dropSlot] --unused ATM
		else
			--If we're just returning something to the pool then empty the slot and abort!
			LoadoutHandler:EmptyWeaponBank(self.currentShipSlot, slot)
			self:emptySlot(element, slot)

			self.ReplacedElement = nil
			self:updateUiElements()
			return
		end

		--If the slot can't accept the weapon then abort!
		if not LoadoutHandler:IsWeaponAllowedInBank(ship_idx, slot_weapon, drop_slot) then
			self.ReplacedElement = nil
			local text = ba.XSTR("That weapon slot can't accept that weapon type", 888444)
			local title = ""
			---@type dialog_button[]
			local buttons = {}
			buttons[1] = {
				Type = Dialogs.BUTTON_TYPE_POSITIVE,
				Text = ba.XSTR("Okay", 888290),
				Value = "",
				Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1)
			}

			self:showDialog(text, title, buttons)
			return
		end

		--If the slot already has that weapon then abort!
		if active_weapon == slot_weapon then
			self.ReplacedElement = nil
			return
		end

		--If slot doesn't exist on current ship then abort!
		if not LoadoutHandler:ShipHasBank(ship_idx, drop_slot) then
			self.ReplacedElement = nil
			return
		end

		--If what is being dragged has an amount greater than 0
		if slot_amount > 0 then

			--return weapons to pool if appropriate
			LoadoutHandler:EmptyWeaponBank(self.currentShipSlot, drop_slot)
			LoadoutHandler:EmptyWeaponBank(self.currentShipSlot, slot)

			--Apply to the actual loadout
			LoadoutHandler:AddWeaponToBank(self.currentShipSlot, drop_slot, slot_weapon, slot_amount)

			self:emptySlot(element, slot)
			self:ApplyWeaponToSlot(self.ReplacedElement, self.currentShipSlot, drop_slot, slot_weapon)

			self.ReplacedElement = nil
		end

		self:updateUiElements()
	end
end

--- Try to copy the current ship loadout to the ship's entire wing
--- @return nil
function WeaponSelectController:copy_to_wing()
	if self.Enabled == true then
		LoadoutHandler:CopyToWing(self.currentShipSlot)
		self:updateUiElements()
	end
end

--- Show a dialog box
--- @param text string The text to display in the dialog
--- @param title string The title of the dialog
--- @param buttons dialog_button[] The buttons to display in the dialog
function WeaponSelectController:showDialog(text, title, buttons)
	--Create a simple dialog box with the text and title

	ScpuiSystem.data.memory.model_rendering.Class = nil
	ScpuiSystem.data.memory.model_rendering.OverheadSave = ScpuiSystem.data.memory.model_rendering.OverheadClass
	ScpuiSystem.data.memory.model_rendering.OverheadClass = nil

	local dialog = Dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:escape("")
		for i = 1, #buttons do
			dialog:button(buttons[i].Type, buttons[i].Text, buttons[i].Value, buttons[i].Keypress)
		end
		dialog:show(self.Document.context)
		:continueWith(function(response)
			ScpuiSystem.data.memory.model_rendering.Class = ScpuiSystem.data.memory.model_rendering.SavedIndex
			ScpuiSystem.data.memory.model_rendering.SavedIndex = nil
			ScpuiSystem.data.memory.model_rendering.OverheadClass = ScpuiSystem.data.memory.model_rendering.OverheadSave
			ScpuiSystem.data.memory.model_rendering.OverheadSave = nil
        --do nothing
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.Document.context)
end

--- Called by the RML when the reset button is pressed
--- @param element Element The element that was pressed
--- @return nil
function WeaponSelectController:reset_pressed(element)
    if self.Enabled == true then
		ui.playElementSound(element, "click", "success")
		LoadoutHandler:resetLoadout()
		self:reloadInterface()
	end
end

--- Called by the RML when the accept button is pressed
--- @return nil
function WeaponSelectController:accept_pressed()

	if not Topics.mission.commit:send(self) then
		return
	end

	--Apply the loadout
	LoadoutHandler:SendAllToFSO_API()

	local error_value = ui.Briefing.commitToMission()

	if error_value == COMMIT_SUCCESS then
		--Save to the player file
		self.Commit = true
		LoadoutHandler:SaveInFSO_API()
		--Cleanup
		if ScpuiSystem.data.memory.MusicHandle ~= nil and ScpuiSystem.data.memory.MusicHandle:isValid() then
			ScpuiSystem.data.memory.MusicHandle:close(true)
		end
		ScpuiSystem.data.memory.MusicHandle = nil
		ScpuiSystem.data.memory.CurrentMusicFile = nil
	end

end

--- Called by the RML when the options button is pressed
--- @param element Element The element that was pressed
--- @return nil
function WeaponSelectController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- Called by the RML when the help button is pressed
--- @param element Element The element that was pressed
--- @return nil
function WeaponSelectController:help_clicked(element)
    ui.playElementSound(element, "click", "success")

	self.HelpShown  = not self.HelpShown

    local help_texts = self.Document:GetElementsByClassName("tooltip")
    for _, v in ipairs(help_texts) do
        v:SetPseudoClass("shown", self.HelpShown)
    end
end


--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function WeaponSelectController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
	end
end

--- Called when the screen is being unloaded
--- @return nil
function WeaponSelectController:unload()

	LoadoutHandler:saveCurrentLoadout()
	ScpuiSystem.data.memory.model_rendering.Class = nil

	if self.Commit == true then
		ScpuiSystem.data.memory.briefing_map = nil
		ScpuiSystem.data.memory.CutscenePlayed = nil
		LoadoutHandler:unloadAll(true)
		ScpuiSystem:stopMusic()
	end

	Topics.weaponselect.unload:send(self)

end

--- Starts the briefing music if it's not already playing
function WeaponSelectController:startMusic()
	local filename = ui.Briefing.getBriefingMusicName()

    if #filename <= 0 then
        return
    end

	if filename ~= ScpuiSystem.data.memory.CurrentMusicFile then

		if ScpuiSystem.data.memory.MusicHandle ~= nil and ScpuiSystem.data.memory.MusicHandle:isValid() then
			ScpuiSystem.data.memory.MusicHandle:close(true)
		end

		ScpuiSystem.data.memory.MusicHandle = ad.openAudioStream(filename, AUDIOSTREAM_MENUMUSIC)
		ScpuiSystem.data.memory.MusicHandle:play(ad.MasterEventMusicVolume, true)
		ScpuiSystem.data.memory.CurrentMusicFile = filename
	end
end

--- Draws the current weapon model for a frame, if possible
--- @return nil
function WeaponSelectController:drawSelectModel()

	if ScpuiSystem.data.memory.model_rendering.Class and (ba.getCurrentGameState().Name == "GS_STATE_WEAPON_SELECT") and (ScpuiSystem.data.memory.model_rendering.Element ~= nil) then  --Haaaaaaacks

		--local thisItem = tb.ShipClasses(modelDraw.Class)
		local model_view = ScpuiSystem.data.memory.model_rendering.Element

		--If the modelView is nil then bail this frame
		if not model_view then
			return
		end

		local model_x = ScpuiSystem:getAbsoluteLeft(model_view) --This is pretty messy, but it's functional
		local model_y = ScpuiSystem:getAbsoluteTop(model_view)
		local model_w = model_view.offset_width
		local model_h = model_view.offset_height

		--This is just a multiplier to make the rendered model a little bigger
		--renderSelectModel() has forced centering, so we need to calculate
		--the screen size so we can move it slightly left and up while it
		--multiple it's size
		local val = -0.3
		local ratio = (gr.getScreenWidth() / gr.getScreenHeight()) * 2

		--Increase by percentage and move slightly left and up.
		model_x = model_x * (1 - (val/ratio))
		model_y = model_y * (1 - val)
		model_w = model_w * (1 + val)
		model_h = model_h * (1 + val)

		tb.WeaponClasses[ScpuiSystem.data.memory.model_rendering.Class]:renderSelectModel(ScpuiSystem.data.memory.model_rendering.Start, model_x, model_y, model_w, model_h, -1, 1.3)

		ScpuiSystem.data.memory.model_rendering.Start = false

	end

end

--- Refreshes the overhead view info based on the current loadout
--- @return nil
function WeaponSelectController:refreshOverheadSlot()
	if self.Overhead3d then
		local ship = LoadoutHandler:GetShipLoadout(self.currentShipSlot)
		ScpuiSystem.data.memory.model_rendering.Weapons_List = ship.Weapons_List
	end
end

--- Draws the overhead model for a frame, if possible
--- @return nil
function WeaponSelectController:drawOverheadModel()

	if ScpuiSystem.data.memory.model_rendering.OverheadClass and ba.getCurrentGameState().Name == "GS_STATE_WEAPON_SELECT" then  --Haaaaaaacks

		if ScpuiSystem.data.memory.model_rendering.Class == nil then ScpuiSystem.data.memory.model_rendering.Class = -1 end
		if ScpuiSystem.data.memory.model_rendering.Hover == nil then ScpuiSystem.data.memory.model_rendering.Hover = -1 end

		--local thisItem = tb.ShipClasses(modelDraw.Class)
		local model_view = ScpuiSystem.data.memory.model_rendering.OverheadElement

		--If the modelView is nil then bail this frame
		if not model_view then
			return
		end

		local model_x = ScpuiSystem:getAbsoluteLeft(model_view)
		local model_y = ScpuiSystem:getAbsoluteTop(model_view)
		local model_w = model_view.offset_width
		local model_h = model_view.offset_height

		--Get bank coords. This is all super messy but it's the best we can do
		--without absolute coords available in the librocket Lua API
		local primary_offset = 15
		local secondary_offset = -15

		local bank1_x = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[1].offset_left + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[1].parent_node.offset_left + model_x + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[1].offset_width + primary_offset
		local bank1_y = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[1].offset_top + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[1].parent_node.offset_top + model_y + (ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[1].offset_height / 2)

		local bank2_x = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[2].offset_left + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[2].parent_node.offset_left + model_x + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[2].offset_width + primary_offset
		local bank2_y = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[2].offset_top + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[2].parent_node.offset_top + model_y + (ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[2].offset_height / 2)

		local bank3_x = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[3].offset_left + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[3].parent_node.offset_left + model_x + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[3].offset_width + primary_offset
		local bank3_y = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[3].offset_top + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[3].parent_node.offset_top + model_y + (ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[3].offset_height / 2)

		local bank4_x = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[4].offset_left + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[4].parent_node.offset_left + model_x + secondary_offset
		local bank4_y = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[4].offset_top + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[4].parent_node.offset_top + model_y + (ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[4].offset_height / 2)

		local bank5_x = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[5].offset_left + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[5].parent_node.offset_left + model_x + secondary_offset
		local bank5_y = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[5].offset_top + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[5].parent_node.offset_top + model_y + (ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[5].offset_height / 2)

		local bank6_x = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[6].offset_left + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[6].parent_node.offset_left + model_x + secondary_offset
		local bank6_y = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[6].offset_top + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[6].parent_node.offset_top + model_y + (ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[6].offset_height / 2)

		local bank7_x = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[7].offset_left + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[7].parent_node.offset_left + model_x + secondary_offset
		local bank7_y = ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[7].offset_top + ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[7].parent_node.offset_top + model_y + (ScpuiSystem.data.memory.model_rendering.Bank_Elements_List[7].offset_height / 2)

		--This is just a multiplier to make the rendered model a little bigger
		--renderSelectModel() has forced centering, so we need to calculate
		--the screen size so we can move it slightly left and up while it
		--multiple it's size
		local val = 0.0
		local ratio = (gr.getScreenWidth() / gr.getScreenHeight()) * 2

		--Increase by percentage and move slightly left and up.
		model_x = model_x * (1 - (val/ratio))
		model_y = model_y * (1 - val)
		model_w = model_w * (1 + val)
		model_h = model_h * (1 + val)

		tb.ShipClasses[ScpuiSystem.data.memory.model_rendering.OverheadClass]:renderOverheadModel(model_x, model_y, model_w, model_h, ScpuiSystem.data.memory.model_rendering.Weapons_List, ScpuiSystem.data.memory.model_rendering.Class, ScpuiSystem.data.memory.model_rendering.Hover, bank1_x, bank1_y, bank2_x, bank2_y, bank3_x, bank3_y, bank4_x, bank4_y, bank5_x, bank5_y, bank6_x, bank6_y, bank7_x, bank7_y, ScpuiSystem.data.memory.model_rendering.overheadEffect)

		ScpuiSystem.data.memory.model_rendering.Start = false

	end

end

--- Called by the RML when the lock button is pressed
--- @return nil
function WeaponSelectController:lock_pressed()
	ui.MultiGeneral.getNetGame().Locked = true
end

--- Called by the RML in multiplayer when the send chat button is pressed
--- @return nil
function WeaponSelectController:submit_pressed()
	assert(AbstractMultiController, "AbstractMultiController is not loaded!")
	if self.SubmittedChatValue then
		AbstractMultiController.sendChat(self)
	end
end

--- Called by the RML when the chat input loses focus
--- @return nil
function WeaponSelectController:input_focus_lost()
	--do nothing
end

--- Called by the RML when the chat input accepts a keypress
--- @param event Event the event that was triggered
--- @return nil
function WeaponSelectController:input_change(event)
	if event.parameters.linebreak ~= 1 then
		local val = self.ChatInputEl:GetAttribute("value")
		self.SubmittedChatValue = val
	else
		local submit_id = self.Document:GetElementById("submit_btn")
		ui.playElementSound(submit_id, "click")
		assert(AbstractMultiController, "AbstractMultiController is not loaded!")
		AbstractMultiController.sendChat(self)
	end
end

--- Every frame draw the current weapon model and overhead model
ScpuiSystem:addHook("On Frame", function()
	WeaponSelectController:drawSelectModel()
	WeaponSelectController:drawOverheadModel()
end, {State="GS_STATE_WEAPON_SELECT"}, function()
    return false
end)

return WeaponSelectController
