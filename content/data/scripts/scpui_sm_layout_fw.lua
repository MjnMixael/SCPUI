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

	local value = styleTable[key]
	if not value then return end

	local pct = tonumber(value:match("^(%d+%.?%d*)%s*%%"))
	if not pct then return end

    -- Skip 100% values – these are often full-width containers
	if pct >= 100 then return end

	local scale = getResponsiveScale(gr.getScreenWidth() / gr.getScreenHeight())
    local new_pct = pct * scale

    ba.print(string.format("Resizing %s: %.2f%% → %.2f%%", key, pct, new_pct))
    styleTable[key] = string.format("%.2f%%", new_pct)
end

--- Fixes the width of an element if the screen is wider than an allowed threshold
--- @param element Element The UI element to adjust
--- @param opts? table Optional parameters: { maxPercent, minPercent, scale }
local function fixLayoutWidth(element, opts)
	if not element or not element.style then return end

	local screen_ratio = gr.getScreenWidth() / gr.getScreenHeight()
	if screen_ratio < aspect_threshold then return end

	-- Resize width if in percent
	fixPercentStyle(element.style, "width")

	-- Resize margin and padding fields if in percent
	for _, key in ipairs({
		"margin_top", "margin_bottom", "margin_left", "margin_right",
		"padding_top", "padding_bottom", "padding_left", "padding_right"
	}) do
		fixPercentStyle(element.style, key)
	end
end

--- Recursively applies layout fixes to all elements in the document
--- @param document Document The Rocket screen or document context
--- @param opts? table Optional parameters passed to each fix
function ScpuiSystem:applyWideLayoutFix(document, opts)
	if not document then return end

	local function walk(element)
		fixLayoutWidth(element, opts)

		local child = element.first_child
		while child do
			walk(child)
			child = child.next_sibling
		end
	end

	walk(document)
end

--------------------------------------------------------------------------------
-- 🔧 Monkey-patch Class() to wrap controller initialize() if loaded from ctrlr_*.lua
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

                                if document and ScpuiSystem.applyWideLayoutFix then
                                    ScpuiSystem:applyWideLayoutFix(document)
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
