-----------------------------------
--Controller for the Hotkey Config UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local HotkeyController = Class()

--- Called by the class constructor
--- @return nil
function HotkeyController:init()
	self.Document = nil --- @type Document The RML document
	self.Hotkeys_List = {} --- @type scpui_hotkey_setting[] The hotkey settings
	self.Index_List = {} --- @type table<integer, {Ship_List_Index: integer, Ship_Element: Element, Hotkey_Index: integer, Ship_Index: integer}> The list of hotkey entries, elements and indexes
	self.CurrentEntry = nil --- @type integer The current hotkey entry index
	self.SelectedIndex = nil --- @type integer The current selected hotkey index
	self.SelectedGroup = nil --- @type integer The current selected group index
	self.SelectedElement = nil --- @type integer The current selected element index
	self.CurrentKey = nil --- @type integer The current selected key index
	self.PreviousElement = nil --- @type Element The previous selected element
	self.TotalKeys = nil --- @type integer The total number of keys
	self.MAX_SHIPS_IN_WING = 6 --- @type integer The maximum number of ships in a wing... replace with globals library eventually!
end

--- Called by the RML document
--- @param document Document
function HotkeyController:initialize(document)

    self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)
	self.Document:GetElementById("current_key"):SetClass("h2", true)

	if mn.isInMission() then
		ScpuiSystem:pauseAllAudio(true)
	end

	ui.MissionHotkeys.initHotkeysList()

	self:initHotkeys()
	self:createHotkeysList()

	Topics.hotkeyconfig.initialize:send(self)

	self:changeKey(1)

	self.SelectedIndex = 1
	local entry = self.Index_List[self.SelectedIndex]

	if entry ~= nil then
		self:selectEntry(entry[1], entry[2], entry[3], entry[4], 1)
	end
end

--- Initialize the hotkeys tables and save all the data for later use
--- @return nil
function HotkeyController:initHotkeys()

	self.Hotkeys_List = {}
	self.Index_List = {}

	local section = 0
	local ship = 0

	for i = 1, #ui.MissionHotkeys.Hotkeys_List do
		local entry = ui.MissionHotkeys.Hotkeys_List[i]

		--maybe create a new section
		if entry.Type == HOTKEY_LINE_HEADING then
			section = #self.Hotkeys_List + 1
			self.Hotkeys_List[section] = {
				Heading = entry.Text,
				Ships_List = {}
			}

			ship = 0
		else
			ship = ship + 1
			self.Hotkeys_List[section].Ships_List[ship] = {
				Text = entry.Text,
				Type = entry.Type,
				Keys_List = {},
				Index = i
			}

			local ship_keys = entry.Keys

			--on first run lets save how many hotkeys we have total
			if self.TotalKeys == nil then
				self.TotalKeys = #ship_keys
			end

			for key = 1, #ship_keys do
				local keyText = "F" .. tostring(key + 4)
				if ship_keys[key] then
					self.Hotkeys_List[section].Ships_List[ship].Keys_List[key] = keyText
				else
					self.Hotkeys_List[section].Ships_List[ship].Keys_List[key] = "&nbsp;"
				end
			end
		end
	end
end

--- Create the hotkeys list in the RML document
--- @return nil
function HotkeyController:createHotkeysList()

	local parent_el = self.Document:GetElementById("log_text_wrapper")

	for i = 1, #self.Hotkeys_List do

		local group_el = self.Document:CreateElement("div")
		group_el.id = "group_" .. i
		group_el:SetClass("hotkey_group", true)
		parent_el:AppendChild(group_el)

		--create the header for the group
		local header_el = self.Document:CreateElement("div")
		header_el.id = "header_" .. i
		header_el:SetClass("hotkey_header", true)
		header_el:SetClass("brightblue", true)
		header_el.inner_rml = self.Hotkeys_List[i].Heading
		group_el:AppendChild(header_el)

		--create the entry list
		local list_el = self.Document:CreateElement("ul")
		list_el.id = "hotkey_list"
		group_el:AppendChild(list_el)

		for entry = 1, #self.Hotkeys_List[i].Ships_List do
			local li_el = self.Document:CreateElement("li")
			li_el.id = "line_" .. i .. "_" .. entry
			local entry_html = ""

			--insert key texts into divs
			for key = 1, #self.Hotkeys_List[i].Ships_List[entry].Keys_List do
				local keyID = "key_" .. i .. "_" .. entry .. "_" .. key
				entry_html = entry_html .. "<div id=\"" .. keyID .. "\" class=\"key_display\">" .. self.Hotkeys_List[i].Ships_List[entry].Keys_List[key] .. "</div>"
			end

			--insert the wing icon div
			local wing_html = ""
			if self.Hotkeys_List[i].Ships_List[entry].Type == HOTKEY_LINE_WING then
				wing_html = "<div class=\"wing_icon wing_icon_vis\"><img src=\"multiplayer-h.png\" class=\"psuedo_img\"></img></div>"
			else
				wing_html = "<div class=\"wing_icon\"><img src=\"multiplayer-h.png\" class=\"psuedo_img\"></img></div>"
			end
			entry_html = entry_html .. wing_html

			--ships in a wing get a little indent
			local ship_class = "<div class=\"ship_name\">"
			if self.Hotkeys_List[i].Ships_List[entry].Type == HOTKEY_LINE_SUBSHIP then
				ship_class = "<div class=\"ship_name wing_item\">"
			end
			--insert the ship name div
			entry_html = entry_html .. ship_class .. self.Hotkeys_List[i].Ships_List[entry].Text .. "</div>"

			li_el.inner_rml = entry_html
			li_el:SetClass("hotkeylist_element", true)
			li_el:SetClass("button_1", true)
			li_el:AddEventListener("click", function(_, _, _)
				self:selectEntry(self.Hotkeys_List[i].Ships_List[entry].Index, li_el, i, entry, #self.Index_List + 1)
			end)
			li_el:AddEventListener("dblclick", function(_, _, _)
				self:toggleKey(self.Hotkeys_List[i].Ships_List[entry].Index, li_el, i, entry)
			end)

			local t = {self.Hotkeys_List[i].Ships_List[entry].Index, li_el, i, entry}
			table.insert(self.Index_List, t)

			list_el:AppendChild(li_el)
		end
	end

end

--- Set an item as selected when clicked on
--- @param idx integer The index of the selected item
--- @param element Element The element that was clicked on
--- @param group integer The group index of the selected item
--- @param item integer The item index of the selected item
--- @param listIdx integer The index of the selected item in the list
--- @return nil
function HotkeyController:selectEntry(idx, element, group, item, listIdx)

	self.CurrentEntry = idx
	self.SelectedIndex = listIdx

	if self.PreviousElement == nil then
		self.PreviousElement = element
	else
		self.PreviousElement:SetPseudoClass("checked", false)
		self.PreviousElement = element
	end

	element:SetPseudoClass("checked", true)

	self.SelectedGroup = group
	self.SelectedElement = item

end

--- Toggles a key on or off for the selected item
--- @param idx integer The index of the selected item
--- @param element Element The element that was clicked on
--- @param group integer The group index of the selected item
--- @param item integer The item index of the selected item
--- @param key? integer The key index of the selected item. If nil then CurrentKey will be used
--- @return nil
function HotkeyController:toggleKey(idx, element, group, item, key)

	self:selectEntry(idx, element, group, item, self.SelectedIndex)

	if key == nil then
		key = self.CurrentKey
	end

	local key_id = "key_" .. self.SelectedGroup .. "_" .. self.SelectedElement .. "_" .. key
	local key_el = self.Document:GetElementById(key_id)

	local key_text = "F" .. tostring(key + 4)
	if key_el.inner_rml == key_text then
		self:removeKey(key)
	else
		self:addKey(key)
	end

end

--- Adds a key to the currently selected item
--- @param key integer The key index of the selected item
--- @return nil
function HotkeyController:addKey(key)

	if key == nil then
		ba.warning("How did that happen? Get Mjn")
		return
	end

	if self.CurrentEntry == nil then
		--nothing to do!
		return
	end

	ui.MissionHotkeys.Hotkeys_List[self.CurrentEntry]:addHotkey(key)

	local key_id = "key_" .. self.SelectedGroup .. "_" .. self.SelectedElement .. "_" .. key
	local key_el = self.Document:GetElementById(key_id)

	local key_text = "F" .. tostring(key + 4)
	key_el.inner_rml = key_text

	self:checkWings(key, key_text)
end

--- Removes a key from the currently selected item
--- @param key integer The key index of the selected item
--- @return nil
function HotkeyController:removeKey(key)

	if key == nil then
		ba.warning("How did that happen? Get Mjn")
		return
	end

	if self.CurrentEntry == nil then
		--nothing to do!
		return
	end

	ui.MissionHotkeys.Hotkeys_List[self.CurrentEntry]:removeHotkey(key)

	local key_id = "key_" .. self.SelectedGroup .. "_" .. self.SelectedElement .. "_" .. key
	local key_el = self.Document:GetElementById(key_id)

	local key_text = "&nbsp;"
	key_el.inner_rml = key_text

	self:checkWings(key, key_text)
end

--- Select the next item in the list, if possible
--- @return nil
function HotkeyController:selectNext()

    if self.SelectedIndex >= #self.Index_List then
		return
	end

	self.SelectedIndex = self.SelectedIndex + 1

	local entry = self.Index_List[self.SelectedIndex]

	self:selectEntry(entry[1], entry[2], entry[3], entry[4], self.SelectedIndex)

end

--- Select the previous item in the list, if possible
--- @return nil
function HotkeyController:selectPrev()

	if self.SelectedIndex <= 1 then
		return
	end

	self.SelectedIndex = self.SelectedIndex - 1

	local entry = self.Index_List[self.SelectedIndex]

	self:selectEntry(entry[1], entry[2], entry[3], entry[4], self.SelectedIndex)

end

--- Check all ships in the current wing, if it is a wing, and update their key text
--- @param key integer The key to use to find the key element
--- @param text string The text to set
function HotkeyController:checkWings(key, text)

	if ui.MissionHotkeys.Hotkeys_List[self.CurrentEntry].Type == HOTKEY_LINE_WING then
		local idx = self.SelectedElement
		--Max 6 ships in a wing so check all six following items in the list
		for i = self.CurrentEntry + 1, self.CurrentEntry + self.MAX_SHIPS_IN_WING do
			idx = idx + 1
			if ui.MissionHotkeys.Hotkeys_List[i].Type == HOTKEY_LINE_SUBSHIP then
				local key_id = "key_" .. self.SelectedGroup .. "_" .. idx .. "_" .. key
				local key_el = self.Document:GetElementById(key_id)
				key_el.inner_rml = text
			end
		end

	end

end

--- Change the current key index and update the UI
--- @param key integer The key index to change to
function HotkeyController:changeKey(key)
	self.CurrentKey = key
	local key_el = self.Document:GetElementById("current_key")
	local key_text = "F" .. tostring(self.CurrentKey + 4)

	key_el.inner_rml = key_text
end

--- Called by the RML to decrement the current key by one
--- @param element Element The element that was clicked on
--- @return nil
function HotkeyController:decrement_key(element)

    if self.CurrentKey == 1 then
		self:changeKey(8)
	else
		self:changeKey(self.CurrentKey - 1)
	end

end

--- Called by the RML to increment the current key by one
--- @param element Element The element that was clicked on
--- @return nil
function HotkeyController:increment_key(element)

    if self.CurrentKey == 8 then
		self:changeKey(1)
	else
		self:changeKey(self.CurrentKey + 1)
	end

end

--- Called by the RML to reset all keys to their default values
--- @param element Element The element that was clicked on
--- @return nil
function HotkeyController:reset_keys(element)

    ui.playElementSound(element, "click", "success")
	ui.MissionHotkeys.resetHotkeys()

	local parent_el = self.Document:GetElementById("log_text_wrapper")
	ScpuiSystem:clearEntries(parent_el)
	self:createHotkeysList()

end

--- Called by the RML to clear the current key setting
--- @param element Element The element that was clicked on
--- @return nil
function HotkeyController:clear_key(element)

    ui.playElementSound(element, "click", "success")
	self:removeKey(self.CurrentKey)

end

--- Called by the RML to reset everything to the default values
--- @param element Element The element that was clicked on
--- @return nil
function HotkeyController:set_defaults(element)

    ui.playElementSound(element, "click", "success")
	ui.MissionHotkeys.resetHotkeysDefault()

	local parent_el = self.Document:GetElementById("log_text_wrapper")
	ScpuiSystem:clearEntries(parent_el)
	self:createHotkeysList()

end

--- Called by the RML to exit the hotkey config UI
--- @param element Element The element that was clicked on
--- @return nil
function HotkeyController:exit(element)

    ui.playElementSound(element, "click", "success")
	if mn.isInMission() then
		ScpuiSystem:pauseAllAudio(false)
	end
	ui.MissionHotkeys.saveHotkeys()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])

end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function HotkeyController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()
		if mn.isInMission() then
			ScpuiSystem:pauseAllAudio(false)
		end
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
	elseif keys.UP then
		self:selectPrev()
	elseif keys.DOWN then
		self:selectNext()
	elseif keys.RETURN then
		local entry = self.Index_List[self.SelectedIndex]
		self:toggleKey(entry[1], entry[2], entry[3], entry[4])
    elseif keys.F5 then
		if keys.Shift then
			local entry = self.Index_List[self.SelectedIndex]
			self:toggleKey(entry[1], entry[2], entry[3], entry[4], 1)
		else
			self:changeKey(1)
		end
	elseif keys.F6 then
		if keys.Shift then
			local entry = self.Index_List[self.SelectedIndex]
			self:toggleKey(entry[1], entry[2], entry[3], entry[4], 2)
		else
			self:changeKey(2)
		end
	elseif keys.F7 then
		if keys.Shift then
			local entry = self.Index_List[self.SelectedIndex]
			self:toggleKey(entry[1], entry[2], entry[3], entry[4], 3)
		else
			self:changeKey(3)
		end
	elseif keys.F8 then
		if keys.Shift then
			local entry = self.Index_List[self.SelectedIndex]
			self:toggleKey(entry[1], entry[2], entry[3], entry[4], 4)
		else
			self:changeKey(4)
		end
	elseif keys.F9 then
		if keys.Shift then
			local entry = self.Index_List[self.SelectedIndex]
			self:toggleKey(entry[1], entry[2], entry[3], entry[4], 5)
		else
			self:changeKey(5)
		end
	elseif keys.F10 then
		if keys.Shift then
			local entry = self.Index_List[self.SelectedIndex]
			self:toggleKey(entry[1], entry[2], entry[3], entry[4], 6)
		else
			self:changeKey(6)
		end
	elseif keys.F11 then
		if keys.Shift then
			local entry = self.Index_List[self.SelectedIndex]
			self:toggleKey(entry[1], entry[2], entry[3], entry[4], 7)
		else
			self:changeKey(7)
		end
	elseif keys.F12 then
		if keys.Shift then
			local entry = self.Index_List[self.SelectedIndex]
			self:toggleKey(entry[1], entry[2], entry[3], entry[4], 8)
		else
			self:changeKey(8)
		end
	end
end

--- Called when the screen is being unloaded
--- @return nil
function HotkeyController:unload()
	Topics.hotkeyconfig.unload:send(self)
end

return HotkeyController
