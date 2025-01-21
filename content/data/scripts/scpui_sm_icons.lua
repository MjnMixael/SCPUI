-----------------------------------
--This file contains all the methods used for SCPUI to generate weapon and ship select icons
-----------------------------------

ScpuiSystem.data.Generated_Icons = {}

--- Open the cache file and return the contents
--- @return table
function ScpuiSystem:openCache()

	---@type json
	local Json = require('dkjson')
	local location = 'data/config'
	local file = nil

	local mod_name = string.sub(ScpuiSystem:getModTitle(), 1, 20)

	if mod_name == "" then
		ba.print("SCPUI could not load the icon cache because no mod name was found!\n")
		return {}
	end

	local filename = "scpui_" .. mod_name:gsub(" ", "") .. ".cache"
	local cache
	if cf.fileExists(filename, location) then
		file = cf.openFile(filename, 'r', location)
		cache = Json.decode(file:read('*a'))
		file:close()
		if not cache then
			cache = {}
		end
	end

	return cache

end

--- Save the icon cache to disk
--- @param cache table
--- @return nil
function ScpuiSystem:saveCache(cache)

	local Json = require('dkjson')
	local location = 'data/config'

	local mod_name = string.sub(ScpuiSystem:getModTitle(), 1, 20)

	if mod_name == "" then
		ba.print("SCPUI could not get a valid mod name. Skipping icon caching!\n")
		return
	end

	local filename = "scpui_" .. mod_name:gsub(" ", "") .. ".cache"

	local file = cf.openFile(filename, 'w', location)
	file:write(Json.encode(cache))
	file:close()

end

--- Set the icon frames for a ship or weapon
--- @param item string The ship or weapon name
--- @param is_ship? boolean True if the item is a ship, false if it is a weapon
--- @return nil
function ScpuiSystem:setIconFrames(item, is_ship)

	--If the icon was preloaded, then skip!
	if ScpuiSystem.data.Generated_Icons[item] ~= nil then
		return
	end

	local ship_3d, ship_effect, ship_icon_3d = ui.ShipWepSelect.get3dShipChoices()
	local weapon_3d, weapon_effect, weapon_icon_3d = ui.ShipWepSelect.get3dWeaponChoices()

	local gen_3d = false

	if (ship_icon_3d and is_ship) or (weapon_icon_3d and not is_ship) then
		gen_3d = true
	end

	---@type loadout_icon
	local icon_details = {
		Width = 0,
		Height = 0,
		Icon = {}
	}

	local o_clr = gr.getColor(true)

	--Create a texture and then draw the image to it, save the output
	local function makeIconFromIconFile(filename)
		local imag_h = nil

		local valid_extensions = {".ani", ".eff", ".png"}

		--Iterate through the extensions and check if the file exists
		local exists = false
		for _, extension in ipairs(valid_extensions) do
			local full_filename = filename .. extension
			if cf.fileExists(full_filename, "", true) then
				exists = true
				break
			end
		end

		--Warn but continue because icon generation will create an empty frame for the icon.
		if not exists then
			ba.warning("Could not generate an icon from file " .. filename .. "! Check that the file exists...")
		end

		if is_ship == true then
			imag_h = gr.loadTexture(tb.ShipClasses[item].SelectIconFilename, true, true)
		else
			imag_h = gr.loadTexture(tb.WeaponClasses[item].SelectIconFilename, true, true)
		end

		local num_frames = 0

		--Invalid image files somehow don't fully error as a texture except when getting frames
		--So in that case we leave frames at 0 and the draw function will just create an empty
		--image for the icon frame. The log will show an error from the drawing function.
		if imag_h:isValid() then
			num_frames = imag_h:getFramesLeft()
		end

		local width = imag_h:getWidth()
		local height = imag_h:getHeight()
		local tex_h = gr.createTexture(width, height)
		gr.setTarget(tex_h)
		for j = 1, 6, 1 do
			gr.clearScreen(0,0,0,0)
			gr.drawImage(imag_h[math.min(j, num_frames)], 0, 0, width, height, 0, 1, 1, 0, 1)
			icon_details.Icon[j] = gr.screenToBlob()
		end
		icon_details.Width = width
		icon_details.Height = height

		--clean up
		gr.setTarget()
		tex_h:destroyRenderTarget()
		--imag_h:destroyRenderTarget() --Don't need to destroy this render target apparently
		imag_h:unload()
		tex_h:unload()
	end

	--Create a texture and then draw the model to it, save the output
	local function makeIconFromModel()
		local name = nil
		local icon = nil
		local model_h = nil
		local model_details = {
			width = nil,
			height = nil,
			heading = nil,
			pitch = nil,
			bank = nil,
			zoom = nil
		}

		if is_ship == true then
			name = tb.ShipClasses[item].Name
			icon = tb.ShipClasses[item].SelectIconFilename
			model_h = tb.ShipClasses[item]
			model_details.width = ScpuiSystem.data.table_flags.IconDimensions.ship.Width
			model_details.height = ScpuiSystem.data.table_flags.IconDimensions.ship.Height
			model_details.heading = 50
			model_details.pitch = 15
			model_details.bank = 50
			model_details.zoom = 1.1
		else
			name = tb.WeaponClasses[item].Name
			icon = tb.WeaponClasses[item].SelectIconFilename
			model_h = tb.WeaponClasses[item]
			model_details.width = ScpuiSystem.data.table_flags.IconDimensions.weapon.Width
			model_details.height = ScpuiSystem.data.table_flags.IconDimensions.weapon.Height
			model_details.heading = 75
			model_details.pitch = 0
			model_details.bank = 40
			model_details.zoom = 0.4
		end

		icon_details.Width = model_details.width
		icon_details.Height = model_details.height

		local tex_h = gr.createTexture(model_details.width, model_details.height)
		gr.setTarget(tex_h)
		gr.clearScreen(0,0,0,0)
		local result = model_h:renderTechModel(0, 0, model_details.width, model_details.height, model_details.heading, model_details.pitch, model_details.bank, model_details.zoom, false)
		if not result then
			--If we don't have an icon file then we're done!
			if not icon or #icon == 0 then
				ba.warning("An icon for " .. name .. " could not be created because it has neither a select icon or a tech model defined!")
			else
				--clean up this run
				gr.setTarget()
				gr.setColor(o_clr)
				tex_h:destroyRenderTarget()
				tex_h:unload()

				--now try a 2D icon
				makeIconFromIconFile(icon)
				return
			end
		end
		local blob = gr.screenToBlob()

		for j = 1, 5, 1 do -- 1 through 5 are the plain ship for now
			icon_details.Icon[j] = blob
		end

		local function colorize(color, loop, monochrome, index)
			gr.setTarget() --Have to clear the target between textures
			local tex_i = gr.createTexture(model_details.width, model_details.height)
			gr.setTarget(tex_i)
			gr.clearScreen(0,0,0,0)
			--Draw the normal version first to have a solid base.. this is pretty hacky, but what are ya gonna do about it?
			gr.drawImage(tex_h, 0, 0, model_details.width, model_details.height, 0, 0, 1, 1, 2, false)
			gr.setColor(color)
			for l = 1, loop do -- Now draw the monochrome on top 4 times to "colorize" the image
				gr.drawImage(tex_h, 0, 0, model_details.width, model_details.height, 0, 0, 1, 1, 2, monochrome)
			end
			icon_details.Icon[index] = gr.screenToBlob()
			tex_i:destroyRenderTarget()
			tex_i:unload()
		end

		colorize(gr.createColor(255, 255, 255, 0.2), 1, true, 2) --Full color mouseover
		colorize(gr.createColor(255, 255, 255, 0.5), 1, true, 3) --Full color highlighted
		colorize(gr.createColor(255, 165, 0), 4, true, 4) --Orange for items being dragged
		colorize(gr.createColor(128, 128, 128), 4, true, 5) --Grey for locked
		colorize(gr.createColor(225, 225, 225), 4, true, 6) --Grey highlighted

		--clean up
		gr.setTarget()
		gr.setColor(o_clr)
		tex_h:destroyRenderTarget()
		tex_h:unload()
	end

	--Icon from 3D model or from a file?
	if gen_3d then
		makeIconFromModel()
	else
		local icon = nil
		if is_ship == true then
			icon = tb.ShipClasses[item].SelectIconFilename
		else
			icon = tb.WeaponClasses[item].SelectIconFilename
		end

		--If we don't have a file then fallback to using the model
		if not icon or #icon == 0 then
			makeIconFromModel()
		else
			makeIconFromIconFile(icon)
		end
	end

	ScpuiSystem.data.Generated_Icons[item] = icon_details

end

--- Starts the generation of icons by opening the cache or creating a new one
--- @return nil
function ScpuiSystem:beginIconGeneration()
	ScpuiSystem.data.Generated_Icons = ScpuiSystem:openCache()

	if ScpuiSystem.data.Generated_Icons == nil or ScpuiSystem.data.Reset == true then
		ba.print("SCPUI is resetting icon cache!\n")
		ScpuiSystem.data.Generated_Icons = {}
	end

	--prevent the keypress hook now
	ScpuiSystem.data.Reset = true
end

--- Finish the icon generation by saving the cache to disk and freeing all models
--- @return nil
function ScpuiSystem:finishIconGeneration()
	ScpuiSystem:saveCache(ScpuiSystem.data.Generated_Icons)

	ba.print("SCPUI successfully generated ship and weapon loadout icons!\n")

	gr.freeAllModels()
end

--- Generate the scpui preload calls that will create the icons during the splash screens
--- @return nil
function ScpuiSystem:genIcons()

	if not ScpuiSystem.data.Active then
		return
	end

	ScpuiSystem:addPreload(
		"SCPUI is starting generation of ship and weapon loadout icons!",
		"Initializing icon generation...",
		"ScpuiSystem:beginIconGeneration()",
		1
	)

	for i = 1, #tb.WeaponClasses do

		local v = tb.WeaponClasses[i]

		if v:isPlayerAllowed() then
			local safe_name = v.Name:gsub("'", "\\'")
			ScpuiSystem:addPreload(
				"Generating icon for " .. v.Name,
				"Generating " .. v.Name .. " icon",
				"ScpuiSystem:setIconFrames('" .. safe_name .. "', false)",
				1
			)
		end

	end

	for i = 1, #tb.ShipClasses do

		local v = tb.ShipClasses[i]

		if v:isPlayerAllowed() then
			local safe_name = v.Name:gsub("'", "\\'")
			ScpuiSystem:addPreload(
				"Generating icon for " .. v.Name,
				"Generating " .. v.Name .. " icon",
				"ScpuiSystem:setIconFrames('" .. safe_name .. "', true)",
				2
			)
		end

	end

	ScpuiSystem:addPreload(
		"Saving ship and weapon loadout icons!",
		"Finalizing icon generation...",
		"ScpuiSystem:finishIconGeneration()",
		2
	)

end

--- Do not create engine hookes if we're in FRED
if ba.inMissionEditor() then
	return
end

--- Forces the icon cache to be cleared and regenerated
--- @return nil
local function resetIconCache()
    if ScpuiSystem.data.Reset == nil then
		ScpuiSystem.data.Reset = true
		ba.print("SCPUI got manual command to reset the icon cache!\n")
	end
end

ScpuiSystem:addHook("On Key Pressed", function()
	resetIconCache()
end,
{KeyPress="F12"})

ScpuiSystem:genIcons()