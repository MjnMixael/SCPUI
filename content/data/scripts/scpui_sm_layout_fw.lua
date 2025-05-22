-- scpui_sm_layout_fw.lua
-- Submodule: Fix layout scaling on ultra-wide displays

local baseline_aspect = 16 / 9
local aspect_threshold = 2.0

--- Get the scale based on the actual aspect ratio of the screen.
--- @param actual_aspect number The actual aspect ratio of the screen (width / height).
--- @return number scale The scale factor to apply based on the aspect ratio.
local function getResponsiveScale(actual_aspect)
	if actual_aspect <= baseline_aspect then
		return 1.0
	end

	-- scale factor: 1.0 at 16:9, 0.85 at 21:9, etc.
	local scale = baseline_aspect / actual_aspect
	return scale
end

--- Adjusts a style property if it is a percentage-based value and the screen aspect ratio is too wide.
---
--- This function is intended to scale down layout-affecting style fields such as
--- `width`, `margin_top`, `padding_left`, etc., when the current screen's aspect ratio
--- exceeds the configured threshold (e.g., 21:9).
---
--- The style value must be in the form `"NN%"` or `"NN.NN%"` to be matched and adjusted.
---
--- @param styleTable table The Rocket style table associated with an element (e.g., `element.style`)
--- @param key string The name of the style field to check and potentially modify (e.g. `"width"`, `"padding_top"`)
--- @return nil
local function fixPercentStyle(styleTable, key)

	if styleTable.ultrawide == "false" then return end

	local value = styleTable[key]
	if not value then return end

	local pct = tonumber(value:match("^(%d+%.?%d*)%s*%%"))
	if not pct then return end

    -- Skip 100% values – these are often full-width containers
	--if pct >= 100 then return end

	local scale = getResponsiveScale(gr.getScreenWidth() / gr.getScreenHeight())
    local new_pct = pct * scale

    ba.print(string.format("Resizing %s: %.2f%% -> %.2f%%\n", key, pct, new_pct))
    styleTable[key] = string.format("%.2f%%", new_pct)
end

--- Fixes only margin/padding on an element
--- @param element Element
--- @param opts? table
--- @return nil
local function fixLayoutSpacingOnly(element, opts)
	if not element or not element.style then return end

	ba.print(string.format("Fixing layout spacing for %s\n", element.id))

	for _, key in ipairs({
		"margin_top", "margin_bottom", "margin_left", "margin_right",
		"padding_top", "padding_bottom", "padding_left", "padding_right"
	}) do
		fixPercentStyle(element.style, key)
	end
end

--- Fixes width + margin/padding for top-level children of main_background
--- @param element Element The UI element to adjust
--- @param opts? table Optional parameters: { maxPercent, minPercent, scale }
--- @return nil
local function fixLayoutWidth(element, opts)
	if not element or not element.style then return end

	ba.print(string.format("Fixing layout width for %s\n", element.id))

	-- Only apply width fix here
	fixPercentStyle(element.style, "width")

	-- Also apply spacing fix at this level
	fixLayoutSpacingOnly(element, opts)
end

--- Applies layout fixes to children of main_background only
--- @param main_bg Element The element Rocket gives to initialize(); usually main_background
--- @param opts? table Optional parameters: { maxPercent, minPercent, scale }
--- @return nil
function ScpuiSystem:applyWideLayoutFix(main_bg, opts)
	if not main_bg or not main_bg.child_nodes then return end

	-- Step 1: Fix layout widths of all direct children
	for _, child in pairs(main_bg.child_nodes) do
		fixLayoutWidth(child, opts)

		-- Step 2: Recursively walk each child's descendants to fix spacing
		local function walkSpacing(el)
			fixLayoutSpacingOnly(el, opts)
			if el.child_nodes then
				for _, grandchild in pairs(el.child_nodes) do
					walkSpacing(grandchild)
				end
			end
		end

		walkSpacing(child)
	end
end

--- Triple-monitor layout patch: moves all children of main_background into a centered wrapper
--- @param document Document
--- @return nil
function ScpuiSystem:applyTripleMonitorLayoutFix(document)
	local screen_width = gr.getScreenWidth()
	local screen_height = gr.getScreenHeight()
	local center_width = gr.getCenterWidth()
	local center_height = gr.getCenterHeight()

	if center_width >= screen_width then return end

	local main = document:GetElementById("main_background")
	if not main then return end
	if main:GetElementById("center_wrapper") then return end

	local offset_x = math.floor((screen_width - center_width) / 2)
	local offset_y = math.floor((screen_height - center_height) / 2)

	-- Create wrapper
	local wrapper = document:CreateElement("div")
	wrapper.id = "center_wrapper"
	wrapper.style.width = string.format("%dpx", center_width)
	wrapper.style.height = string.format("%dpx", center_height)
	wrapper.style.position = "absolute"
	wrapper.style.left = string.format("%dpx", offset_x)
	wrapper.style.top = string.format("%dpx", offset_y)

	-- Move all children into wrapper
	local children = {}
	local child = main.first_child
	while child do
		table.insert(children, child)
		child = child.next_sibling
	end

	for _, el in ipairs(children) do
		main:RemoveChild(el)
		wrapper:AppendChild(el)
	end

	main:AppendChild(wrapper)

	ba.print(string.format("[SCPUI] Centered layout applied: root UI width = %d, screen = %d\n", center_width, screen_width))
end

--- Returns the appropriate root parent for downstream manipulation
--- @param document Document
--- @return Element
function ScpuiSystem:getRootParent(document)
	local main = document:GetElementById("main_background")
	if not main then return document end

	local center = main:GetElementById("center_wrapper")
	return center or main
end

--------------------------------------------------------------------------------
-- Monkey-patch Class() to wrap controller initialize() if loaded from ctrlr_*.lua
--------------------------------------------------------------------------------

if not ScpuiSystem._layoutPatchApplied then
	ScpuiSystem._layoutPatchApplied = true

	local originalRequire = require
	local originalClass = originalRequire("lib_class")

	-- Patch only lib_class when required from ctrlr_*.lua
	function require(path)
		if path == "lib_class" then
			local caller = debug.getinfo(2, "S").source or ""
			if caller:match("ctrlr_.*%.lua$") then

				return function(...)
                    local klass = originalClass(...)

                    local mt = getmetatable(klass) or {}
                    local raw_newindex = mt.__newindex

                    mt.__newindex = function(tbl, key, value)
                        if key == "initialize" and type(value) == "function" then
                            ba.print("SCPUI is patching the layout framework builder into the initialize method for " .. caller .. "...\n")

                            local origInit = value
                            local patchedInit = function(self, document)
								local result = origInit(self, document)

								if document then
									local screen_width = gr.getScreenWidth()
									local center_width = gr.getCenterWidth()
									local screen_ratio = gr.getScreenWidth() / gr.getScreenHeight()

									if center_width < screen_width and ScpuiSystem.applyTripleMonitorLayoutFix then
										ScpuiSystem:applyTripleMonitorLayoutFix(document)
									elseif screen_ratio >= aspect_threshold and ScpuiSystem.applyWideLayoutFix then
										ScpuiSystem:applyWideLayoutFix(document)
									end
								end

								return result
							end

                            if raw_newindex then
                                raw_newindex(tbl, key, patchedInit)
                            else
                                rawset(tbl, key, patchedInit)
                            end
                        else
                            if raw_newindex then
                                raw_newindex(tbl, key, value)
                            else
                                rawset(tbl, key, value)
                            end
                        end
                    end

                    setmetatable(klass, mt)
                    return klass
                end
			end
		end

		-- Fall through to original require
		return originalRequire(path)
	end
end
