-----------------------------------
--This file contains all available UI Topics that can be interacted with throughou the UI.
-----------------------------------

local Topic = require("lib_topic")
local Utils = require("lib_utils") --to allow use of utils.round()

--- Returns the AltName if it exists, otherwise returns the Name.
--- @param x shipclass | weaponclass the ship or weapon class to check
--- @return string name the alt name or name
local function altNameOrName(x)
	local alt_name = x.AltName
	if alt_name and alt_name ~= '' then
		return alt_name
	else
		return x.Name
	end
end

--- Returns the index of the other tab in the simulator.
--- @param x number
--- @return number
local function simulatorTab(x)
	if x == 2 then
		return 1
	else
		return 2
	end
end

--- Updates weapon stats based on most of its properties.
--- @param weapon_class weaponclass
--- @return table values the weapon stats
local function weaponStats(weapon_class)
	local base_damage = weapon_class.Damage
	if weapon_class.OuterRadius > 0 then
		-- This weapon has a shockwave, which gives it additional damage on a direct hit.
		-- Added formula to calculate shockwave damage -- WW
		local bonus_damage
		if weapon_class.ShockwaveDamage and weapon_class.ShockwaveDamage > 0 then
			bonus_damage = weapon_class.ShockwaveDamage
		else
			ba.print("Shockwave damage returned zero. Assuming equal to base damage.\n")
			bonus_damage = base_damage
		end
		base_damage = base_damage + bonus_damage
	end

	local velocity = weapon_class.Speed
	local rof = Utils.round(1 / weapon_class.FireWait, 2)
	local range = math.min(weapon_class.Range, (velocity * weapon_class.LifeMax))

	-- new code to calculate volley size -- WW
	local is_swarmer, swarm_count = weapon_class:getSwarmInfo()
	local is_corkscrew, corkscrew_count = weapon_class:getCorkscrewInfo()

	if not is_swarmer then
		swarm_count = 1
	end

	if not is_corkscrew then
		corkscrew_count = 1
	end

	local burst = math.max(weapon_class.BurstShots, 1)
	local volley = Utils.round(swarm_count * corkscrew_count * burst)
	-- end volley code

	return {
		HullDamage = base_damage * weapon_class.ArmorFactor,
		ShieldDamage = base_damage * weapon_class.ShieldFactor,
		SubsystemDamage = base_damage * weapon_class.SubsystemFactor,
		Velocity = velocity,
		Range = range,
		RoF = rof,
		CargoSize = Utils.round(weapon_class.CargoSize, 2),
		Power = Utils.round(weapon_class.EnergyConsumed / weapon_class.FireWait, 2),
		VolleySize = volley
	}
end

local topics = {
	--Global
	Scpui = {
		pauseAudio = Topic(nil)
	},
	--Objects
	ships = {
		filter = Topic(function(x) return x.InTechDatabase end),
		name = Topic(altNameOrName),
		description = Topic(function(x) return x.TechDescription end)
	},
	weapons = {
		filter = Topic(function(x) return x.InTechDatabase end),
		name = Topic(altNameOrName),
		description = Topic(function(x) return x.TechDescription end),
		stats = Topic(weaponStats)
	},
	intel = {
		filter = Topic(function(x) return x.InTechDatabase end),
		name = Topic(function(x) return x.Name end),
		description = Topic(function(x) return x.Description end),
		type = Topic(function(x) return ba.XSTR('Other', 888553) end)
	},

	--Interfaces
	preload = {
		loadingTextCoords = Topic(function(x) return x end), --Runs arbitrary script and expects x and y returned in a table. Sends the x and y coordinates in a table
		debugTextCoords = Topic(function(x) return x end), --Runs arbitrary script and expects x and y returned in a table. Sends the x and y coordinates in a table
	},
	pilotselect = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context
		startsound = Topic(true), --Whether or not to start the default mainhall background sound. Sends the document context and expects boolean return
		escKeypress = Topic(true), --Whether or not to use the default action on ESC keydown. Sends the document context and expects boolean return
		upKeypress = Topic(true), --Whether or not to use the default action on UP keydown. Sends the document context and expects boolean return
		dwnKeypress = Topic(true), --Whether or not to use the default action on DOWN keydown. Sends the document context and expects boolean return
		retKeypress = Topic(true), --Whether or not to use the default action on RETURN keydown. Sends the document context and expects boolean return
		delKeypress = Topic(true), --Whether or not to use the default action on DELETE keydown. Sends the document context and expects boolean return
		globalKeypress = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context and the event
		commit = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	playcutscene = {
		start = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context
		finish = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	loadscreen = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		load_bar = Topic('LoadingBar'), --Expects an image file returned, replaces the loading screen bar. Should be an animation.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	briefcommon = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context
		stageChanged = Topic(nil) --Runs arbitrary script when the stage changes and expects no return value. Sends the document context and the stage index
	},
	fictionviewer = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		accept = Topic(true), --Whether or not to continue to with the Accept press. Sends the context and expects boolean return
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	cmdbriefing = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		stage = Topic(function(x) return x[1] end), --Sends the stage handle and the stage index in a table, expects the stage returned
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	briefing = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		brief_bg = Topic('brief-main-window.png'), --Expects an image file returned, replaces the briefing goals stage BG
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	redalert = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		commit = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	loopbrief = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	debrief = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context
		accept = Topic(nil), --Runs arbitrary script and expects no return value
		reject = Topic(nil), --Runs arbitrary script and expects no return value
		skip = Topic(nil), --Runs arbitrary script and expects no return value
		unload = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context
		stateChanged = Topic(nil) --Runs arbitrary script when the state changes between stats/dialog and expects no return value. Sends the document context
	},
	campaign = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context
		listCampaign = Topic(function(x) return x[1] end), --Sends the campaign name string and filename string and expects a string returned
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	barracks = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the document context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	loadouts = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value
		saveLoadout = Topic(nil), --Runs arbitrary script and expects no return value. Sends the save data to be saved
		loadLoadout = Topic(nil), --Runs arbitrary script and expects no return value. Sends the loaded save data
		rejectSavedLoadout = Topic(false), --Runs arbitrary script and expects a boolean return, true to abort applying saved loadout
		initPool = Topic(nil), --Runs arbitrary script and expects no return value. Sends the ship slot
		emptyShipSlot = Topic(nil), --Runs arbitrary script and expects no return value. Sends the ship slot
		fillShipSlot = Topic(nil), --Runs arbitrary script and expects no return value. Sends the ship slot
		emptyWeaponSlot = Topic(nil), --Runs arbitrary script and expects no return value. Sends the ship slot and the weapon bank
		fillWeaponSlot = Topic(true), -- Runs arbitrary script and expects a boolean return for if the weapon slot fill was successful. Sends the ship slot and the weapon bank
		returnShipSlot = Topic(nil), --Runs arbitrary script and expects no return value. Sends the ship slot
		initWeaponInfo = Topic(nil), --Runs arbitrary script and expects no return value. Sends the weapon data as a table
		initShipInfo = Topic(nil), --Runs arbitrary script and expects no return value. Sends the ship data as a table
		copyShipSlot = Topic(nil), --Runs arbitrary script and expects no return value. Sends the source ship slot and the target ship slot
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends a boolean whether or not the mission is being committed to or canceled
	},
	medals = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		setRankBitmap = Topic(function(x) return x[2] end), --Sends the medal name and bitmap suffix. Expects a new bitmap suffix returned
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	options = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		changeEffectsVol = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		changeVoiceVol = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		apply = Topic(nil), -- Runs arbitrary script and expects no return value. Sends nothing. Runs when custom mod options should be applied to controlling scripts
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	missionlog = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	controlconfig = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	hudconfig = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	hotkeyconfig = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	gamehelp = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	gamepaused = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the UI context.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	shipselect = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		poolentry = Topic(true), --Runs arbitrary script and expects a boolean return for whether or not the pool item can be made draggable. Sends the UI context, the pool element and the entry
		selectShip = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the selected ship.
		selectSlot = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the selected slot.
		entryInfo = Topic(nil), --Runs arbitrary script and expects no return value. Sends the ship entry and the stats UI element
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	weaponselect = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context.
		entryInfo = Topic(nil), --Runs arbitrary script and expects no return value. Sends the weapon entry and the stats UI element
		selectShip = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the selected ship.
		selectSlot = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the selected slot.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	techroom = { --All tech room UIs!
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		btn1Action = Topic(nil), --The code to run when tech room button 1 is clicked. When changing game states, lowest priority takes precedence. Set value to false to play error sound
		btn2Action = Topic(nil), --The code to run when tech room button 2 is clicked. When changing game states, lowest priority takes precedence. Set value to false to play error sound
		btn3Action = Topic(nil), --The code to run when tech room button 3 is clicked. When changing game states, lowest priority takes precedence. Set value to false to play error sound
		btn4Action = Topic(nil) --The code to run when tech room button 4 is clicked. When changing game states, lowest priority takes precedence. Set value to false to play error sound
	},
	techdatabase = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		beginDataLoad = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		initShipData = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the ship
		initWeaponData = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the weapon
		initIntelData = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the intel
		initSortFuncs = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		selectSection = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		selectEntry = Topic(nil), --Runs arbitrary script when an entry is selected. Sends the context
		sortItems = Topic(false), --Sends the context. Expects a boolean return for whether or not custom sort was sucessful
		sortCategories = Topic(false), --Sends the context. Expects a boolean return for whether or not custom sort was sucessful
		setSortCat = Topic(false), --Sends the context. Expects a boolean return for whether or not category was set
		uncheckSorts = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		createHeader = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		selectHeader = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	techcredits = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	simulator = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		listSingle = Topic(true), --Return true or false if the mission should be listed as a single mission. Sends the mission filename
		listCampaign = Topic(true), --Return true or false if the mission should be listed as a campaign mission. Sends the mission filename
		createitem = Topic(nil), --Runs arbitrary script and expects no return value. Sends the element being created
		newsection = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the section value
		sectionname = Topic(nil), --Runs arbitrary script and expects a string return for the mission list internal name. Sends the section index.
		allowall = Topic(true), --Return true or false for if ctrl-s should be allowed for the currently displayed section. Sends the context.
		tabkey = Topic(simulatorTab), --Sends the currently selected section index and expects a number return for the new index to select when TAB is pressed.
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	cutscenes = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		addParam = Topic(nil), --Can add a parameter to a cutscene list item. Sends the current list item and te current cutscene entry.
		hideMovie = Topic(false), --Return true or false if the cutscene should be globally hidden from the visible list. Sends the cutscene item.
		createList = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context and the current cutscene.
		selectScene = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	deathpopup = {
		setText = Topic('') --Runs arbitrary script and expects no return value. Sends the context and expects a string return
	},
	mission = { --All UIs where mission can be committed to!
		commit = Topic(true) --Whether or not to continue to with the Commit press. Sends the context and expects boolean return
	},

	--- Multiplayer UIs
	multisync = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	multistartgame = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	multipxo = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	multipxohelp = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	multipaused = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	multijoingame = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	multihostsetup = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	multihostoptions = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	},
	multiclientsetup = {
		initialize = Topic(nil), --Runs arbitrary script and expects no return value. Sends the context
		unload = Topic(nil) --Runs arbitrary script and expects no return value. Sends the document context
	}
}

--- Register a new topic
--- @param category string The category to add the topic to (e.g., "journal", "ships").
--- @param topic_name string The name of the topic (e.g., "initialize").
--- @param handler any The topic instance to register.
function topics:registerTopic(category, topic_name, handler)
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

    if not self[category] then
        self[category] = {}
    end

    if self[category][topic_name] then
        ba.error("SCPUI cannot override existing topic '" .. topic_name .. "' in category '" .. category .. "'")
    end

    self[category][topic_name] = Topic(handler)
    ba.print("SCPUI registered topic '" .. topic_name .. "' in category '" .. category .. "'\n")
end

--- Register multiple topics at once.
--- @param category string The category to add the topics to.
--- @param new_topics table A table of topic names and instances.
function topics:registerTopics(category, new_topics)
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

    for topic_name, handler in pairs(new_topics) do
        self:registerTopic(category, topic_name, handler)
    end
end

return topics