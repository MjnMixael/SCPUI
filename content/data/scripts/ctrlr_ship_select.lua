-----------------------------------
--Controller for the Ship Select UI
-----------------------------------

local Dialogs = require("lib_dialogs")
local LoadoutHandler = require("lib_loadout_handler")
local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

--- Ship Select Controller can be merged with the Multi Common Controller during multiplayer
local AbstractMultiController = nil
local ShipSelectController = nil
if ScpuiSystem:inMultiGame() then
	AbstractMultiController = require("ctrlr_multi_common")
	ShipSelectController = Class(AbstractMultiController)
else
	ShipSelectController = Class()
end

ShipSelectController.STATE_BRIEFING = 1 --- @type number The enumeration for the briefing game state
ShipSelectController.STATE_SHIP_SELECT = 2 --- @type number The enumeration for the ship selection game state
ShipSelectController.STATE_WEAPON_SELECT = 3 --- @type number The enumeration for the weapon selection game state

ShipSelectController.SHIP_EFFECT_OFF = 0 --- @type number The enumeration for the ship effect off
ShipSelectController.SHIP_EFFECT_NORMAL = 1 --- @type number The enumeration for the ship effect fs1 style
ShipSelectController.SHIP_EFFECT_GLOW = 2 --- @type number The enumeration for the ship effect fs2 style

ScpuiSystem.data.memory.model_rendering = nil

--- Called by the class constructor
--- @return nil
function ShipSelectController:init()
	self.Document = nil --- @type Document the RML document
	self.ChatEl = nil --- @type Element the chat window element
    self.ChatInputEl = nil --- @type Element the chat input element
	self.SubmittedChatValue = "" --- @type string the submitted value from the chat input
	self.HelpShown = false --- @type boolean Whether the help text is shown or not
	self.Enabled = false --- @type boolean True if there are ships in the loadout, false on error
	self.Shipclass_Indexes = {} --- @type number[] The ship class indexes in the loadout
	self.Active_Slots = {} --- @type number[] The active slots in the loadout
	self.SelectedShipName = '' --- @type string The selected ship name
	self.AnimEl = nil --- @type Element the animation element
	self.Required_Weapons = {} --- @type string[] The required weapons for the mission, if any
	self.Ship3d = false --- @type boolean Whether the 3D ship view is enabled
	self.ShipEffect = self.SHIP_EFFECT_OFF --- @type number The ship effect choice for the 3D ship view
	self.Icon3d = false --- @type boolean Whether the 3D ship icons are enabled
	self.Commit = false --- @type boolean Whether the commit to the mission was successful

	LoadoutHandler:init()
	ScpuiSystem.data.memory.model_rendering = {}
end

--- Called by the RML document
--- @param document Document
function ShipSelectController:initialize(document)
	if AbstractMultiController and ScpuiSystem:inMultiGame()then
		AbstractMultiController.initialize(self, document)
		self.Subclass = AbstractMultiController.CTRL_SHIP_SELECT
	end

	self.Document = document
	self.AnimEl = self.Document:CreateElement("ani")

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	self.ChatEl = self.Document:GetElementById("chat_window")
	self.ChatInputEl = self.Document:GetElementById("chat_input")

	self.Ship3d, self.ShipEffect, self.Icon3d = ui.ShipWepSelect.get3dShipChoices()

	--Get all the required weapons
	local j = 1
	while (j < #tb.WeaponClasses) do
		if tb.WeaponClasses[j]:isWeaponRequired() then
			self.Required_Weapons[#self.Required_Weapons + 1] = tb.WeaponClasses[j].Name
		end
		j = j + 1
	end

	--Create the anim here so that it can be restarted with each new selection
	local aniWrapper = self.Document:GetElementById("ship_view")
	aniWrapper:ReplaceChild(self.AnimEl, aniWrapper.first_child)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.Document:GetElementById("brief_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("s_select_btn"):SetPseudoClass("checked", true)
	self.Document:GetElementById("w_select_btn"):SetPseudoClass("checked", false)

	self.SelectedEntry = nil

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
		ui.MultiGeneral.setPlayerState()
	end

	Topics.shipselect.initialize:send(self)

	--Only create entries if there are any to create
	if LoadoutHandler:GetNumShips() > 0 and self.Enabled == true then
		self:createPoolList(LoadoutHandler:GetShipList())
	end

	if LoadoutHandler:GetNumShips() > 0 and self.Enabled == true then
		self:selectShip(LoadoutHandler:GetShipList()[1])
	end

	self:startMusic()

end

--- Constructs the wings UI elements and each ship slot
--- @return boolean val true if the wings were built successfully, false on error
function ShipSelectController:buildWingsElements()

	local slot_num = 1 -- Start with the first slot
	local wrapper_element = self.Document:GetElementById("wings_wrapper")
	ScpuiSystem:clearEntries(wrapper_element)

	--Check that we actually have wing slots
	if LoadoutHandler:GetNumWings() <= 0 then
		ba.warning("Mission has no loadout wings! Check the loadout in FRED!")
		return false
	end

	--- For each wing, create a wrapper and the slots
	for i = 1, LoadoutHandler:GetNumWings() do

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
		if LoadoutHandler:GetNumWingSlots(slot_num) <= 0 then
			ba.warning("Loadout wing '" .. LoadoutHandler:GetWingName(i) .. "' has no valid ship slots! Check the loadout in FRED!")
			return false
		end

		--Now we add each actual wing slots
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
					if slot_info.IsShipLocked then
						slot_icon = entry.GeneratedIcon[5]
					else
						slot_icon = entry.GeneratedIcon[1]
					end
				else
					ba.error("Failed to generate ship info for " .. tb.ShipClasses[ship_index].Name .. "!")
				end
			end

			local slot_img = self.Document:CreateElement("img")
			slot_img:SetAttribute("src", slot_icon)
			slot_element:AppendChild(slot_img)

			local slot_name_element = self.Document:CreateElement("div")
			slot_name_element.inner_rml = slot_info.DisplayName
			slot_name_element.id = "callsign_" .. slot_num
			slot_name_element:SetClass("slot_name", true)
			slot_element:AppendChild(slot_name_element)

			--This is here so that the event listeners use the correct slot index!
			local index = slot_num

			slot_element.id = "slot_" .. index

			if ScpuiSystem:inMultiGame() then
				self:activateNameDrag(slot_name_element, index)
			end

			self:activateShipSlot(index)

			slot_num = slot_num + 1
		end
	end

	return true

end

--- In multiplayer games, this allows dragging players to different slots
--- @param name_el Element the element to drag
--- @param slot number the slot number
--- @return nil
function ShipSelectController:activateNameDrag(name_el, slot)
	name_el:SetClass("drag", true)
	name_el:SetClass("available", true)
	name_el:SetClass("name_slot", true)
	name_el.id = "callsign_drag"

	--Add dragover detection
	name_el:AddEventListener("dragdrop", function(_, _, _)
		self:dragNameOverSlot(name_el, slot)
	end)

	name_el:AddEventListener("dragend", function(_, _, _)
		self:dragNameToSlot(name_el, slot)
	end)
end

--- Attempt to activate user controls on a slot to allow dragging and clicking. Does nothing for disabled or inactive slots
--- @param slot number the slot number
--- @return nil
function ShipSelectController:activateShipSlot(slot)
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

	--If we're in multi and we're activating then we need to deactivate name dragging
	if ScpuiSystem:inMultiGame() then
		local name_el = element.first_child.next_sibling
		name_el:SetClass("drag", false)
		name_el:SetClass("available", false)
		name_el.id = "callsign_" .. slot
	end

	--Add dragover detection
	element:AddEventListener("dragdrop", function(_, _, _)
		self:on_drag_overSlot(element, slot)
	end)

	if slot_info.ShipClassIndex > 0 then
		local this_entry = LoadoutHandler:GetShipInfo(slot_info.ShipClassIndex)
		if this_entry == nil then
			ba.warning("Ship Info did not exist! How? Who knows! Get Mjn!")
			this_entry = LoadoutHandler:AppendToShipInfo(slot_info.ShipClassIndex)
		end

		if not slot_info.IsShipLocked then

			--Add drag detection
			element:SetClass("drag", true)
			element:AddEventListener("dragend", function(_, _, _)
				self.drag = false
				self:dragFromSlotToSlotOrPool(element, this_entry, slot)
			end)

			--Add dragstart detection
			element:AddEventListener("dragstart", function(_,_,_)
				self.drag = true
			end)

			--Add mouseover detection
			element:AddEventListener("mouseover", function(_, _, _)
				if self.drag then
					element:SetPseudoClass("valid", true)
				end
			end)

			--Add mouseout detection
			element:AddEventListener("mouseout", function(_, _, _)
				element:SetPseudoClass("valid", false)
			end)

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
			self:selectShipInSlot(this_entry, slot)
		end)
	end
end

--- Reloads the ship list and rebuilds the entire ship selection UI
--- @return nil
function ShipSelectController:reloadInterface()
	ScpuiSystem.data.memory.model_rendering.Class = nil
	local list_items_el = self.Document:GetElementById("ship_icon_list_ul")
	ScpuiSystem:clearEntries(list_items_el)
	self.SelectedEntry = nil
	self:createPoolList(LoadoutHandler:GetShipList())
	self:buildWingsElements()
	if LoadoutHandler:GetShipInfo(1) then
		self:selectShip(LoadoutHandler:GetShipInfo(1))
	end
end

--- Create a list item for the ship selection pool list
--- @param entry ship_loadout_info the ship entry
--- @param idx number the index of the ship entry
--- @return Element li_el the list item element
function ShipSelectController:createPoolListItem(entry, idx)

	local li_el = self.Document:CreateElement("li")
	local icon_wrapper_element = self.Document:CreateElement("div")
	icon_wrapper_element.id = entry.Name
	icon_wrapper_element:SetClass("select_item", true)

	li_el:AppendChild(icon_wrapper_element)

	local count_element = self.Document:CreateElement("div")
	count_element.inner_rml = tostring(LoadoutHandler:GetShipPoolAmount(entry.Index))
	count_element:SetClass("amount", true)

	icon_wrapper_element:AppendChild(count_element)

	--local aniWrapper = self.Document:GetElementById(entry.Icon)
	local icon_element = self.Document:CreateElement("img")
	icon_element:SetAttribute("src", entry.GeneratedIcon[1])
	icon_wrapper_element:AppendChild(icon_element)
	--iconWrapper:ReplaceChild(iconEl, iconWrapper.first_child)
	li_el.id = entry.Name
	entry.Key = li_el.id

	--iconEl:SetClass("shiplist_element", true)
	icon_element:SetClass("icon", true)
	icon_element:SetClass("button_3", true)
	icon_element:AddEventListener("click", function(_, _, _)
		self:selectShip(entry)
	end)

	if Topics.shipselect.poolentry:send({self, icon_element, entry}) then
		icon_element:SetClass("drag", true)
		icon_element:AddEventListener("dragend", function(_, _, _)
			self.drag = false
			self:dragFromPoolToSlot(icon_element, entry, entry.Index)
		end)

		--Add dragstart detection
		icon_element:AddEventListener("dragstart", function(_,_,_)
			self.drag = true
		end)
	end

	return li_el
end

--- Create the ship selection pool list
--- @param list ship_loadout_info[] the list of ships
--- @return nil
function ShipSelectController:createPoolList(list)

	local list_names_el = self.Document:GetElementById("ship_icon_list_ul")

	ScpuiSystem:clearEntries(list_names_el)

	for i, v in pairs(list) do
		list_names_el:AppendChild(self:createPoolListItem(v, i))
	end
end

--- Called by the RML to show the current ship's description in a popup window
--- @return nil
function ShipSelectController:show_breakout_reader()
	local text = Topics.ships.description:send(tb.ShipClasses[self.SelectedShipName])
	local title = "<span style=\"color:white;\">" .. Topics.ships.name:send(tb.ShipClasses[self.SelectedShipName]) .. "</span>"
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

--- Change a ship's pool icon to the highlighted version and also do the same for the ship slots
--- @param entry ship_loadout_info the ship entry
--- @param slot? number the slot number
--- @return nil
function ShipSelectController:highlightShipClass(entry, slot)

	local list = LoadoutHandler:GetShipList()

	for i, v in pairs(list) do
		local icon_element = self.Document:GetElementById(v.Key).first_child.first_child.next_sibling
		if v.Key == entry.Key then
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

	-- No ship slot to highlight!
	if slot == nil then
		return
	end

	for i = 1, LoadoutHandler:GetNumSlots() do
		local ship = LoadoutHandler:GetShipLoadout(i)
		local element = self.Document:GetElementById("slot_" .. i)
		local ship_index = ship.ShipClassIndex
		local this_entry = LoadoutHandler:GetShipInfo(ship_index)
		if this_entry ~= nil then
			if slot == i then
				if ship.IsShipLocked then
					element.first_child:SetAttribute("src", this_entry.GeneratedIcon[6])
				else
					element.first_child:SetAttribute("src", this_entry.GeneratedIcon[3])
				end
			else
				if ship.IsShipLocked then
					element.first_child:SetAttribute("src", this_entry.GeneratedIcon[5])
				else
					element.first_child:SetAttribute("src", this_entry.GeneratedIcon[1])
				end
			end
		end
	end

end

--- Sets the entry as the currently seelcted ship, changes the animation and data, and highlights the ship class
--- @param entry? ship_loadout_info the ship entry
--- @param slot? number the slot number if a ship slot is being selected
--- @return nil
function ShipSelectController:selectShip(entry, slot)

	assert(entry, "No entry provided to selectShip!")

	--No issue to just re-highlight things
	--This allows all ship slots to highlight themselves when clicked
	self:highlightShipClass(entry, slot)

	if entry.Key ~= self.SelectedEntry then

		self.SelectedEntry = entry.Key
		self.SelectedShipName = entry.Name

		self:displayShipInfo(entry)

		if self.Ship3d or entry.Anim == nil then
			ScpuiSystem.data.memory.model_rendering.Class = entry.Index
			ScpuiSystem.data.memory.model_rendering.Element = self.Document:GetElementById("ship_view_wrapper")
			ScpuiSystem.data.memory.model_rendering.Start = true
		else
			--the anim is already created so we only need to remove and reset the src
			self.AnimEl:RemoveAttribute("src")
			self.AnimEl:SetAttribute("src", entry.Anim)
		end

	end

end

--- Builds the ship stats info for the selected ship and displays it
--- @param entry ship_loadout_info the ship entry
--- @return nil
function ShipSelectController:displayShipInfo(entry)

	local info_element = self.Document:GetElementById("ship_stats_info")

	self.Document:GetElementById("ship_stats_wrapper").scroll_top = 0

	ScpuiSystem:clearEntries(info_element)

	local midString = "</p><p class=\"info\">"

	--Setup the hitpoints string
	local hitpointsString = ''
	for i = 1, Utils.round(entry.Hitpoints / 50) do
		hitpointsString = hitpointsString .. '++'
	end

	--Setup the shield hitpoints string
	local ShieldhitpointsString = ''
	for i = 1, Utils.round(entry.ShieldHitpoints / 50) do
		ShieldhitpointsString = ShieldhitpointsString .. '++'
	end

	local array    = {
		{ba.XSTR("Class", 888414), entry.Name},
		{ba.XSTR("Type", 888116), entry.Type},
		{ba.XSTR("Length", 888416), entry.Length},
		{ba.XSTR("Max Velocity", 888417), entry.Velocity .. ' (' .. entry.AfterburnerVelocity .. ba.XSTR(" m/s with afterburner", 888418) .. ')'},
		{ba.XSTR("Maneuverability", 888419), entry.Maneuverability},
		--{ba.XSTR("Armor", 888420), entry.Armor}, --Removed because it doesn't usually offer much useful information
		{ba.XSTR("Hull Strength", 888421), hitpointsString},
		{ba.XSTR("Shield Strength", 888422), ShieldhitpointsString},
		{ba.XSTR("Gun Mounts", 888423), entry.GunMounts},
		{ba.XSTR("Missile Banks", 888424), entry.MissileBanks},
		{ba.XSTR("Manufacturer", 888425), entry.Manufacturer}
	}

	for _, v in ipairs(array) do
		info_element:AppendChild(self:buildInfoTitle(v[1]))
		info_element:AppendChild(self:buildInfoStat(v[2]))
	end

	Topics.shipselect.entryInfo:send({entry, info_element})

end

--- Builds the title for the ship stats info
--- @param text string the text to display
--- @return Element element the title element
function ShipSelectController:buildInfoTitle(text)
	local element = self.Document:CreateElement("p")
	element.inner_rml = text
	return element
end

--- Builds the stat for the ship stats info
--- @param text string the text to display
--- @return Element element the stat element
function ShipSelectController:buildInfoStat(text)
	local element = self.Document:CreateElement("p")
	element:SetClass("info", true)
	element.inner_rml = text
	return element
end

--- Called by the RML to change loadout game states
--- @param state number the state to change to. Should be one of the the STATE_* enums
--- @return nil
function ShipSelectController:change_brief_state(state)
	if state == self.STATE_BRIEFING then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
	elseif state == self.STATE_SHIP_SELECT then
		--Do nothing because we're this is the current state!
	elseif state == self.STATE_WEAPON_SELECT then
		if mn.isScramble() then
			ad.playInterfaceSound(10)
		else
			ba.postGameEvent(ba.GameEvents["GS_EVENT_WEAPON_SELECTION"])
		end
	end
end

--- Called when a ship is dragged over a slot
--- @param element Element the element being dragged
--- @param slot number the slot number
--- @return nil
function ShipSelectController:on_drag_overSlot(element, slot)
	self.replace = element
	self.activeSlot = slot
	element:SetPseudoClass("valid", false)
end

--- Called when a slot name is dragged over a slot
--- @param element Element the element being dragged
--- @param slot number the slot number
--- @return nil
function ShipSelectController:dragNameOverSlot(element, slot)
	self.NameReplace = element
	self.NameActiveSlot = slot
end

--- Updates a slot based on the current loadout
--- @param slot number the slot number to update
--- @return nil
function ShipSelectController:updateSlot(slot)
	local slot_info = LoadoutHandler:GetShipLoadout(slot)

	local replace_el = self.Document:GetElementById("slot_" .. slot)

	--If the slot doesn't exist then bail
	if not replace_el then
		return
	end

	self:activateShipSlot(slot)

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
		if entry == nil then
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

--- Updates all slots based on the current loadout
--- @return nil
function ShipSelectController:updateSlots()
	for i = 1, LoadoutHandler:GetNumSlots() do
		self:updateSlot(i)
	end
end

--- Updates the ship pool based on the current loadout
--- @return nil
function ShipSelectController:updateShipPool()
	local list = LoadoutHandler:GetShipList()

	for i, v in pairs(list) do
		self:updatePoolEntryCount(v.Name, LoadoutHandler:GetShipPoolAmount(v.Index))
	end
end

--- Updates the pool count for a specific ship class
--- @param id string the ship class element id
--- @param count number the new count
--- @return nil
function ShipSelectController:updatePoolEntryCount(id, count)
	local parent = self.Document:GetElementById(id)
	if not parent then
		return
	end
	local count_element = parent.first_child.first_child
	count_element.inner_rml = tostring(count)
end

--- Updates the ship image for a specific slot element
--- @param element Element the slot element
--- @param img string the new image source
--- @return nil
function ShipSelectController:updateSlotImage(element, img)
	local image_element = self.Document:CreateElement("img")
	image_element:SetAttribute("src", img)

	element:RemoveChild(element.first_child)
	element:InsertBefore(image_element, element.first_child)
	element:SetClass("drag", true)
	element:SetClass("button_3", true)
end

--- Called when a ship slot is clicked on. Sets the selected ship to the slot's ship
--- @param entry ship_loadout_info the ship entry. Currently unused as it seems unreliable
--- @param slot number the slot number
--- @return nil
function ShipSelectController:selectShipInSlot(entry, slot)
	local current_slot = LoadoutHandler:GetShipLoadout(slot)

	if current_slot.ShipClassIndex > 0 then
		self:selectShip(LoadoutHandler:GetShipInfo(current_slot.ShipClassIndex), slot)
	end
end

--- Called when a ship is dragged from the pool over an active ship slot. Tries to replace the slot's ship with the dragged ship.
--- @param element Element the element being dragged
--- @param entry ship_loadout_info the ship entry
--- @param shipIndex number the ship index
--- @return nil
function ShipSelectController:dragFromPoolToSlot(element, entry, shipIndex)
	--No changes if wing positions are not locked!
	if ScpuiSystem:inMultiGame() and ui.MultiGeneral.getNetGame().Locked == false then
		return
	end

	if (self.replace ~= nil) and (self.activeSlot > 0) then
		if ScpuiSystem:inMultiGame() then
			ui.ShipWepSelect.sendShipRequestPacket(2, 0, shipIndex, self.activeSlot, shipIndex)
			self.replace = nil
			return
		end

		--Get the pool amount of the ship we're dragging
		local count = LoadoutHandler:GetShipPoolAmount(shipIndex)

		--If the pool count is 0 then abort!
		if count < 1 then
			self.replace = nil
			return
		end

		local target_slot = LoadoutHandler:GetShipLoadout(self.activeSlot)

		if target_slot.IsShipLocked then
			return
		end

		--If the target slot already has this ship, then abort!
		if target_slot.ShipClassIndex == shipIndex then
			return
		end

		if count > 0 then
			if target_slot.ShipClassIndex == -1 then
				LoadoutHandler:TakeShipFromPool(shipIndex)
			else
				--Get the amount of the ship we're sending back
				local key = LoadoutHandler:GetShipInfo(target_slot.ShipClassIndex).Name
				self:updatePoolEntryCount(key, LoadoutHandler:GetShipPoolAmount(target_slot.ShipClassIndex) + 1)

				LoadoutHandler:TakeShipFromPool(shipIndex)
				LoadoutHandler:ReturnShipToPool(self.activeSlot)
			end

			self:updatePoolEntryCount(entry.Name, count - 1)

			local replace_el = self.Document:GetElementById(self.replace.id)
			self:updateSlotImage(replace_el, element:GetAttribute("src"))

			LoadoutHandler:SetFilled(self.activeSlot, true)

			--Now set the new ship and weapons
			LoadoutHandler:AddShipToSlot(self.activeSlot, shipIndex)

			self.replace = nil
		end
	end
end

--- Called when a ship is dragged from a slot over another slot or the ship pool. Tries to replace the target slot's ship with the dragged ship or return the dragged ship to the pool.
--- @param element Element the element being dragged
--- @param entry ship_loadout_info the ship entry. Currently unused.
--- @param slot number the slot number
--- @return nil
function ShipSelectController:dragFromSlotToSlotOrPool(element, entry, slot)
	--No changes if wing positions are not locked!
	if ScpuiSystem:inMultiGame() and ui.MultiGeneral.getNetGame().Locked == false then
		return
	end

	if (self.replace ~= nil) and (self.activeSlot > 0) then
		local target_slot = LoadoutHandler:GetShipLoadout(self.activeSlot)
		local current_slot = LoadoutHandler:GetShipLoadout(slot)

		if ScpuiSystem:inMultiGame() then
			ui.ShipWepSelect.sendShipRequestPacket(0, 0, slot, self.activeSlot, current_slot.ShipClassIndex)
			self.replace = nil
			return
		end

		--If the target slot already has this ship, then abort!
		if target_slot.ShipClassIndex == current_slot.ShipClassIndex then
			return
		end

		--If the target slot has a ship in it then return it
		if target_slot.ShipClassIndex > 0 then
			--Get the amount of the ship we're sending back
			local key = LoadoutHandler:GetShipInfo(target_slot.ShipClassIndex).Name
			self:updatePoolEntryCount(key, LoadoutHandler:GetShipPoolAmount(target_slot.ShipClassIndex) + 1)
			LoadoutHandler:ReturnShipToPool(self.activeSlot)
		end

		local replace_el = self.Document:GetElementById(self.replace.id)
		self:updateSlotImage(replace_el, element.first_child:GetAttribute("src"))

		element.first_child:SetAttribute("src", LoadoutHandler:getEmptyWingSlotIcon()[2])
		element:SetClass("drag", false)

		LoadoutHandler:SetFilled(self.activeSlot, true)

		--Now set the new ship and weapons
		LoadoutHandler:AddShipToSlot(self.activeSlot, current_slot.ShipClassIndex)

		--empty the old slot
		LoadoutHandler:TakeShipFromSlot(slot)

		self.replace = nil

	--If we're dragging into the pool
	elseif (self.replace ~= nil) and (self.activeSlot == 0) then
		local source_slot = LoadoutHandler:GetShipLoadout(slot)

		if ScpuiSystem:inMultiGame() then
			ui.ShipWepSelect.sendShipRequestPacket(0, 2, slot, source_slot.ShipClassIndex, source_slot.ShipClassIndex)
			self.replace = nil
			return
		end

		--If the target slot has a ship in it then return it
		if source_slot.ShipClassIndex > 0 then
			--Get the amount of the ship we're sending back
			local key = LoadoutHandler:GetShipInfo(source_slot.ShipClassIndex).Name
			self:updatePoolEntryCount(key, LoadoutHandler:GetShipPoolAmount(source_slot.ShipClassIndex) + 1)
			LoadoutHandler:ReturnShipToPool(slot)
		end
		element:SetClass("drag", false)

		element.first_child:SetAttribute("src", LoadoutHandler:getEmptyWingSlotIcon()[2])
		LoadoutHandler:TakeShipFromSlot(slot)

		self.replace = nil
	end
end

--- Called when a slot name is dragged over another slot. Tries to replace the target slot's ship with the dragged ship.
function ShipSelectController:dragNameToSlot(element, slot)
	--No changes if not in multi
	if not ScpuiSystem:inMultiGame() then
		return
	end
	--No changes if wing positions are locked!
	if ui.MultiGeneral.getNetGame().Locked == true then
		return
	end

	if (self.NameReplace ~= nil) and (self.NameActiveSlot > 0) then
		ui.ShipWepSelect.sendShipRequestPacket(1, 1, slot, self.NameActiveSlot, -1)
		self.NameReplace = nil
	end
end

--- Shows a dialog box. Here it's only used to show the ship's description
--- @param text string the text to display
--- @param title string the title of the dialog
--- @param buttons dialog_button[] the buttons to display
--- @return nil
function ShipSelectController:showDialog(text, title, buttons)
	--Create a simple dialog box with the text and title

	ScpuiSystem.data.memory.model_rendering.SavedIndex = ScpuiSystem.data.memory.model_rendering.Class
	ScpuiSystem.data.memory.model_rendering.Class = nil

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
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.Document.context)
end

--- Called when the reset button is pressed. Resets the loadout to the default
--- @param element Element the element that was clicked
--- @return nil
function ShipSelectController:reset_pressed(element)
	if self.Enabled == true then
		ui.playElementSound(element, "click", "success")
		LoadoutHandler:resetLoadout()
		self:reloadInterface()
	end
end

--- Called when the accept button is pressed. Commits the loadout to the mission, if possible, and starts the mission
--- @return nil
function ShipSelectController:accept_pressed()

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

--- Called when the options button is pressed. Opens the options menu
--- @param element Element the element that was clicked
--- @return nil
function ShipSelectController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- Called when the help button is pressed. Toggles the help text
--- @param element Element the element that was clicked
--- @return nil
function ShipSelectController:help_clicked(element)
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
function ShipSelectController:global_keydown(element, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
        event:StopPropagation()

		ba.postGameEvent(ba.GameEvents["GS_EVENT_START_BRIEFING"])
        --ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
	--elseif event.parameters.key_identifier == rocket.key_identifier.UP and event.parameters.ctrl_key == 1 then
	--	self:change_tech_state(3)
	--elseif event.parameters.key_identifier == rocket.key_identifier.DOWN and event.parameters.ctrl_key == 1 then
	--	self:change_tech_state(1)
	end
end

--- Called when the screen is being unloaded
--- @return nil
function ShipSelectController:unload()

	LoadoutHandler:saveCurrentLoadout()
	ScpuiSystem.data.memory.model_rendering.Class = nil

	if self.Commit == true then
		LoadoutHandler:unloadAll(true)
		ScpuiSystem.data.memory.briefing_map = nil
		ScpuiSystem.data.memory.CutscenePlayed = nil
		ScpuiSystem:stopMusic()
	end

	Topics.shipselect.unload:send(self)
end

--- Starts the briefing music if it is not already playing
--- @return nil
function ShipSelectController:startMusic()
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

--- Draws the currently selected ship class in the ship class viewer. Is run every frame
--- @return nil
function ShipSelectController:drawSelectModel()

	if ScpuiSystem.data.memory.model_rendering.Class and ba.getCurrentGameState().Name == "GS_STATE_SHIP_SELECT" then  --Haaaaaaacks

		--local thisItem = tb.ShipClasses(modelDraw.Class)

		local model_view = ScpuiSystem.data.memory.model_rendering.Element

		--If the modelView is not valid then abort this frame
		if not model_view then
			return
		end

		local model_x = model_view.parent_node.offset_left + model_view.offset_left --This is pretty messy, but it's functional
		local model_y = model_view.parent_node.offset_top + model_view.parent_node.parent_node.offset_top + model_view.offset_top
		local model_w = model_view.offset_width
		local model_h = model_view.offset_height

		--This is just a multiplier to make the rendered model a little bigger
		--renderSelectModel() has forced centering, so we need to calculate
		--the screen size so we can move it slightly left and up while we
		--multiple it's size
		local val = 0.15
		local ratio = (gr.getScreenWidth() / gr.getScreenHeight()) * 2

		--Increase by percentage and move slightly left and up.
		model_x = model_x * (1 - (val/ratio))
		model_y = model_y * (1 - val)
		model_w = model_w * (1 + val)
		model_h = model_h * (1 + val)

		tb.ShipClasses[ScpuiSystem.data.memory.model_rendering.Class]:renderSelectModel(ScpuiSystem.data.memory.model_rendering.Start, model_x, model_y, model_w, model_h, -1, 1.3)

		ScpuiSystem.data.memory.model_rendering.Start = false

	end

end

--- Called by the RML in multiplayer when the lock is pressed.
--- @return nil
function ShipSelectController:lock_pressed()
	ui.MultiGeneral.getNetGame().Locked = true
end

--- Called by the RML in multiplayer when the send chat button is pressed
--- @return nil
function ShipSelectController:submit_pressed()
	assert(AbstractMultiController, "AbstractMultiController is not loaded!")
	if self.SubmittedChatValue then
		AbstractMultiController.sendChat(self)
	end
end

--- Called by the RML when the chat input loses focus
--- @return nil
function ShipSelectController:input_focus_lost()
	--do nothing
end

--- Called by the RML when the chat input accepts a keypress
--- @param event Event the event that was triggered
--- @return nil
function ShipSelectController:input_change(event)
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

--- Add a hook to draw the currently selected ship every frame
ScpuiSystem:addHook("On Frame", function()
	ShipSelectController:drawSelectModel()
end, {State="GS_STATE_SHIP_SELECT"}, function()
    return false
end)

return ShipSelectController
