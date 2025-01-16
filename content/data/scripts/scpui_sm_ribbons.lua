-----------------------------------
--This file contains functions and methods for handling the ribbons rewards system
-----------------------------------

--Create the ribbons table
ScpuiSystem.data.Player_Ribbons = {}

--LuaSexp to grant a ribbon permanently to the player
mn.LuaSEXPs['grant-scpui-ribbon'].Action = function(title, desc_name, border_r, border_g, border_b, ...)
	local desc = "From " .. ScpuiSystem:getModTitle()
	if mn.hasCustomStrings() then
		for _, v in ipairs(mn.CustomStrings) do
			if v.Name == desc_name.Name then
				desc = v.String
			end
		end
	end

	---@type scpui_color
	local border_color = {
		R = border_r,
		G = border_g,
		B = border_b
	}

	---@type scpui_ribbon_stripe[]
	local stripe_colors = {}
	for _, v in ipairs(arg) do

		---@type scpui_ribbon_stripe
		local stripe = {
			P = v[1],
			R = v[2],
			G = v[3],
			B = v[4]
		}

		table.insert(stripe_colors, stripe)
	end

	ScpuiSystem:grantRibbon(title, desc, border_color, stripe_colors)
end

--- Grants a ribbon. This is a permanent reward that will be displayed on the player's Ribbons UI across all mods
--- @param title string The title of the ribbon
--- @param description string The description of the ribbon
--- @param border_color scpui_color The color of the border
--- @param stripe_colors scpui_ribbon_stripe[] The colors of the stripes
function ScpuiSystem:grantRibbon(title, description, border_color, stripe_colors)
	local ribbon = {}

	ribbon.name = title
	ribbon.description = description
	ribbon.source = ScpuiSystem:getModTitle()
	ribbon.border = border_color
	ribbon.colors = stripe_colors

	ScpuiSystem:loadRibbonsFromFile()

	local ignore_ribbon = false
	local count = 0
	for _, v in ipairs(ScpuiSystem.data.Player_Ribbons) do
		if v.Name == ribbon.name then
			ignore_ribbon = true
			ba.print("SCPUI: Ribbon '" .. title .. "' already exists!\n")
			break
		end

		-- Limit mods to 5 ribbons. It's semi arbitrary, but let's prevent mods from going nuts with these
		if v.Source == ribbon.source then
			count = count + 1
		end

		if count > 5 then
			ignore_ribbon = true
			ba.print("SCPUI: Current mod already has 5 ribbons. Ribbon '" .. title .. "' will not be added!\n")
		end

	end

	if not ignore_ribbon then
		ba.print("SCPUI: Granted ribbon '" .. title .. "' to player!\n")
		table.insert(ScpuiSystem.data.Player_Ribbons, ribbon)
	end

	ScpuiSystem:saveRibbonsToFile()
end

--- Load the current ribbons save file
--- @return nil
function ScpuiSystem:loadRibbonsFromFile()

	---@type json
	local Json = require('dkjson')

	local location = 'data/players'

	local file = nil
	local config = {}

	if cf.fileExists('scpui_ribbons.cfg') then
		file = cf.openFile('scpui_ribbons.cfg', 'r', location)
		config = Json.decode(file:read('*a'))
		file:close()
		if not config then
			config = {}
		end
	end

	--- Mapping of old keys to new keys
	local keyMapping = {
		name = "Name",
		description = "Description",
		source = "Source",
		border = "Border",
		colors = "Stripes_List",
		r = "R",
		g = "G",
		b = "B",
		p = "P"
	}

	--- Function to convert keys using the key mapping
	local function convertKeysUsingMapping(data)
		if type(data) ~= "table" then
			return data
		end

		local newTable = {}
		for key, value in pairs(data) do
			-- Use mapped key if it exists, otherwise keep the original key
			local newKey = keyMapping[key] or key
			newTable[newKey] = convertKeysUsingMapping(value)
		end
		return newTable
	end

	-- Convert keys using the mapping table
    config = convertKeysUsingMapping(config)

	--Currently not doing this per-player on purpose.. but we could!
	--[[if not config[ba.getCurrentPlayer():getName()] then
		config[ba.getCurrentPlayer():getName()] = {}
	end]]--

	ScpuiSystem.data.Player_Ribbons = config
end

--- Save the current ribbons to the save file
--- @return nil
function ScpuiSystem:saveRibbonsToFile()

	---@type json
	local Json = require('dkjson')

	local location = 'data/players'

	local file = nil
	local config = {}

	if cf.fileExists('scpui_ribbons.cfg') then
		file = cf.openFile('scpui_ribbons.cfg', 'r', location)
		config = Json.decode(file:read('*a'))
		file:close()
		if not config then
			config = {}
		end
	end

	--Currently not doing this per-player on purpose.. but we could!
	--[[if not config[ba.getCurrentPlayer():getName()] then
		config[ba.getCurrentPlayer():getName()] = {}
	end]]--

	config = ScpuiSystem.data.Player_Ribbons

	--local Utils = require("lib_utils")
	--config = Utils.cleanPilotsFromSaveData(config)

	file = cf.openFile('scpui_ribbons.cfg', 'w', location)
	file:write(Json.encode(config))
	file:close()
end

--- Create a ribbon image from a ribbon object and return the image blob
--- @param ribbon ribbon_info The ribbon object
--- @return string blob The image blob
function ScpuiSystem:createRibbonImage(ribbon)
	local Utils = require("lib_utils")

	local saved_color = gr.getColor(true)
	local tex_h = gr.createTexture(200, 50)
	gr.setTarget(tex_h)

	local img = nil
	local border = gr.createColor(200, 200, 200, 255)

	if ribbon.Border then
		local r = Utils.clamp(ribbon.Border.R, 0, 255)
		local g = Utils.clamp(ribbon.Border.G, 0, 255)
		local b = Utils.clamp(ribbon.Border.B, 0, 255)
		border = gr.createColor(r, g, b, 255)
	end

	gr.setColor(border)
	gr.drawRectangle(0, 0, 200, 50)

	for i = 1, #ribbon.Stripes_List do
		local pos = ribbon.Stripes_List[i].P
		if i == 1 or pos < 3 then
			pos = 3
		end
		if pos >= 100 then
			pos = 99
		end

		local r = Utils.clamp(ribbon.Stripes_List[i].R, 0, 255)
		local g = Utils.clamp(ribbon.Stripes_List[i].G, 0, 255)
		local b = Utils.clamp(ribbon.Stripes_List[i].B, 0, 255)

		local this_color = gr.createColor(r, g, b, 255)

		gr.setColor(this_color)

		gr.drawRectangle(pos, 2, (200 - pos), 48)
	end

	local black = gr.createColor(0, 0, 0, 50)
	for i = 3, 48, 2 do
		gr.setColor(black)
		gr.drawRectangle(3, i, 197, i+1)
	end

	img = gr.screenToBlob()

	--clean up
	gr.setTarget()
	tex_h:destroyRenderTarget()
	tex_h:unload()
	gr.setColor(saved_color)

	return img
end