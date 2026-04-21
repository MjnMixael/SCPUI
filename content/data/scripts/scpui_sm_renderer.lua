-----------------------------------
--SCPUI Render Texture Helpers
-----------------------------------

--- Ensure the render slot table exists
--- @return table<string, table>
local function getRenderSlots()
	ScpuiSystem.data.render_slots = ScpuiSystem.data.render_slots or {}
	return ScpuiSystem.data.render_slots
end

--- Create or resize a render slot texture and optionally bind it to an element child image
--- @param slot_id string A unique slot identifier
--- @param element Element The element to size/bind against
--- @param document Document|nil The owning document (needed to create an img child)
--- @param opts table|nil Optional settings. Supports HeightOffset and BindElement
--- @return table|nil slot The slot data or nil if size is invalid
function ScpuiSystem:ensureRenderSlot(slot_id, element, document, opts)
	assert(slot_id and slot_id ~= "", "Render slot id is required")
	if not element then
		return nil
	end

	local options = opts or {}
	local height_offset = options.HeightOffset or 0
	local bind_element = options.BindElement or element

	local width = element.offset_width
	local height = element.offset_height + height_offset

	if width <= 0 or height <= 0 then
		return nil
	end

	local slots = getRenderSlots()
	local slot = slots[slot_id] or {}

	if not slot.Texture or slot.Width ~= width or slot.Height ~= height then
		slot.Texture = gr.createTexture(width, height)
		slot.Url = ui.linkTexture(slot.Texture)
		slot.Width = width
		slot.Height = height
	end

	slot.Element = element
	slots[slot_id] = slot

	if document and bind_element then
		if bind_element.first_child == nil then
			local img_el = document:CreateElement("img")
			img_el:SetAttribute("src", slot.Url)
			bind_element:AppendChild(img_el)
		else
			bind_element.first_child:SetAttribute("src", slot.Url)
		end
	end

	return slot
end

--- Begin rendering to a slot texture
--- @param slot_id string
--- @return boolean success
function ScpuiSystem:beginRenderSlot(slot_id)
	local slots = getRenderSlots()
	local slot = slots[slot_id]
	if not slot or not slot.Texture then
		return false
	end

	gr.setTarget(slot.Texture)
	return true
end

--- End rendering to any slot texture and restore default render target
--- @return nil
function ScpuiSystem:endRenderSlot()
	gr.setTarget()
end
