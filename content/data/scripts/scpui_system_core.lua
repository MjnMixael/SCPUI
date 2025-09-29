-- Version of SCPUI System
local version = "1.1.0-RC17"

local Utils = require("lib_utils")
local Topics = require("lib_ui_topics")

-----------------------------------
--This is the core SCPUI file. It handles state management and
--all necessary preloading of content. Disabling this, disables
--everything. Modify with care.
-----------------------------------

local UpdateCategory = engine.createTracingCategory("UpdateRocket", false)
local RenderCategory = engine.createTracingCategory("RenderRocket", true)

ScpuiSystem = {}

--- @type scpui_constants
ScpuiSystem.constants = {
	VERSION = version,
	NUM_FONT_SIZES = 40,
	INITIALIZED = false,
	Dialog_Constants = {
		BUTTON_TYPE_POSITIVE = 1,
		BUTTON_TYPE_NEGATIVE = 2,
		BUTTON_TYPE_NEUTRAL = 3,
		DIALOG_STYLE_REGULAR = 1,
		DIALOG_STYLE_DEATH = 2,
	}
}

---@type scpui_data
ScpuiSystem.data = {
	Active = true,
	DefaultFsoFont = gr.Fonts[1],
	Replacements_List = {},
	Backgrounds_List_Campaign = {},
	Backgrounds_List_Mainhall = {},
	Brief_Backgrounds_List = {},
	Preload_Coroutines = {},
	Medal_Info = {},
	Substate = "none",
	OldSubstate = "none",
	table_flags = {
		DisableInMulti = false,
		HideMulti = false,
		DataSaverMultiplier = 1,
		DatabaseUnreadShowString = true,
		DatabaseUnreadStringText = ba.XSTR("NEW!", 888549),
		DatabaseUnreadShowIcon = false,
		DatabaseUnreadBadgePosition = "left",
		IconDimensions = {
			ship = {
				Width = 128,
				Height = 112,
			},
			weapon = {
				Width = 112,
				Height = 48,
			}
		},
		MinSplashTime = 2,
		FadeSplashImages = true,
		DrawSplashImages = true,
		DrawSplashText = true,
	},
	state_init_status = {
		Debrief = false,
		Select = false,
		LoadScreen = false,
		PreLoad = false,
	},
	memory = {
		Cutscene = "none",
		LogSection = 1,
		MissionLoaded = false,
		MultiJoinReady = false,
		MultiReady = false,
		WarningCountShown = false,
		loading_bar = {},
		multiplayer_host = {},
		control_config = {},
		multiplayer_general = {},
		tech_cutscene = {},
	},
	Render = true,
	Tooltip_Timers = {},
	ScpuiOptionValues = {}
}

--- Initialize the table for SCPUI extensions
ScpuiSystem.extensions = {}

--keep multiplayer standalone servers lean
if ba.getCurrentMPStatus() == "MULTIPLAYER_STANDALONE" then
	ScpuiSystem.data.Active = nil
	return
end

--setting this to true will completely disable SCPUI
if false then
	ScpuiSystem.data.Active = nil
	return
end

if not ba.inMissionEditor() then
	ScpuiSystem.data.Context = rocket:CreateContext("menuui", Vector2i.new(gr.getScreenWidth(), gr.getScreenHeight()));
end

--- Initialize ScpuiSystem and send relevant scpui.tbl files to the parser
--- @return nil
function ScpuiSystem:init()
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	ba.print("SCPUI Core (v" .. ScpuiSystem.constants.VERSION .. ") is initializing. Standby...\n")

	if (ba.isEngineVersionAtLeast(25, 0, 0) and not opt.isInGameOptionsEnabled()) then
		ba.error("SCPUI requires in-game options to be enabled! Please enable them in your game settings table.\n")
	end

	self:loadSubmodules()

	self:loadScpuiTables()

	self:loadExtensions()

	self:loadPlugins()

	-- Check that the default font scales correctly
	if ba.isEngineVersionAtLeast(25, 0, 0) and ScpuiSystem.data.DefaultFsoFont then
		if not ScpuiSystem.data.DefaultFsoFont:hasAutoSize() then
			ba.error("Default font for SCPUI needs to have auto-sizing enabled! (+Auto Size: true)\n")
		end

		if not ScpuiSystem.data.DefaultFsoFont:hasCanScale() then
			ba.error("Default font for SCPUI needs to have scaling enabled! (+Can Scale: true)\n")
		end
	end

	-- Set up the in-game font multiplier option if it exists
	if ba.isEngineVersionAtLeast(24, 3, 0) then
		---@return option | nil
		local function getFontOption()
			local options = opt.Options
			for _, v in ipairs(options) do
				if v.Key == "Game.FontScaleFactor" then
					return v
				end
			end
		end

        -- Get the range of the font multiplier
        local option = getFontOption()
		if option then
			ScpuiSystem.data.FontValue = tonumber(option.Value.Serialized)
		end
	end

	ScpuiSystem.data.CurrentBaseFontClass = "base_font" .. self:getFontPixelSize()
end

--- Load submodules for SCPUI core or an extension
--- @param prefix string|nil The unique identifier for the extension (e.g., "jrnl" for the Journal extension), or nil for the core system
--- @return nil
function ScpuiSystem:loadSubmodules(prefix)
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	if not prefix then
		ba.print("SCPUI is loading core submodules...\n")
	else
		ba.print("SCPUI is loading " .. prefix .. " submodules...\n")
	end

    local files = cf.listFiles("data/scripts", "*.lua")
    local submodules_prefix = prefix and ("scpui_" .. prefix .. "_sm_") or "scpui_sm_"
	local debug = "submodule: "
	if prefix then
		debug = prefix .. " submodule: "
	end

    if not files then
        return
    end

    for _, filename in ipairs(files) do
        if string.find(filename, submodules_prefix) then
            local module_name = filename:match(submodules_prefix .. "(.-)%.lua")
            if module_name then
                local module_path = string.format("%s%s", submodules_prefix, module_name)
                local ok, module = pcall(require, module_path)
                if ok then
                    ba.print("SCPUI loaded " .. debug .. module_name .. " (" .. module_path .. ")\n")
                else
                    ba.warning("SCPUI Error loading " .. debug .. module_path .. ": " .. tostring(module) .. "\n")
                end
            end
        end
    end
end

--- Load ScpuiSystem extensions (script files starting with `scpui_ext_`) that add new UIs or features
--- @return nil
function ScpuiSystem:loadExtensions()
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	ba.print("SCPUI is loading extensions...\n")

    local files = cf.listFiles("data/scripts", "*.lua")
	local extension_prefix = "scpui_ext_"

    if not files then
        return
    end

	local function makeExtensionReadOnly(ext)
		local locked_keys = {
			Name = true,
			Version = true,
			Key = true,
			Submodule = true,
			init = true,
			postInit = true,
		}

		return setmetatable({}, {
			__index = ext,
			__newindex = function(_, k, v)
				if locked_keys[k] then
					ba.warning("Attempt to modify read-only SCPUI extension field '" .. k .. "', new value will be ignored.")
				else
					ext[k] = v -- allow dynamic fields to be added
				end
			end,
			__pairs = function()
				return pairs(ext)
			end
		})
	end

	local function disabledInit()
		ba.warning("Cannot initialize an extension that has already been initialized!")
	end

    for _, filename in ipairs(files) do
        if string.find(filename, extension_prefix) then
            local module_name = filename:match(extension_prefix .. "(.-).lua")

            if module_name then
                local module_path = string.format("%s%s", extension_prefix, module_name)

                -- Attempt to load the extension
                local ok, extension = pcall(require, module_path)
                if ok and extension then
                    -- Validate required metadata
                    if not extension.Name or not extension.Version or not extension.Key then
                        ba.error("SCPUI Error: Extension " .. module_path .. " missing Name, Version, or Key. Extension not loaded!\n")
					elseif not extension.init then
                        ba.error("SCPUI Error: Extension " .. module_path .. " is missing the required init() function\n")
                    else
                        -- Add to extensions table
                        ScpuiSystem.extensions[extension.Key] = extension
						ba.print("SCPUI loaded extension: " .. extension.Name .. " (v" .. extension.Version .. ")\n")

						-- Initialize the extension
						ScpuiSystem.extensions[extension.Key]:init()

						-- Load the extension's submodules
						if ScpuiSystem.extensions[extension.Key].Submodule then
							ScpuiSystem:loadSubmodules(ScpuiSystem.extensions[extension.Key].Submodule)
						end

						-- If the extension defines a postInit function, call it now
						if ScpuiSystem.extensions[extension.Key].postInit then
							ScpuiSystem.extensions[extension.Key]:postInit()
						end

						-- Prevent double initializing
						ScpuiSystem.extensions[extension.Key].init = disabledInit
						ScpuiSystem.extensions[extension.Key].postInit = disabledInit

						-- Lock the extension to prevent further modifications to protected fields
						ScpuiSystem.extensions[extension.Key] = makeExtensionReadOnly(ScpuiSystem.extensions[extension.Key])
                    end
                else
                    ba.warning("SCPUI Error loading extension " .. module_path .. ": " .. tostring(extension) .. "\n")
                end
            end
        end
    end
end

--- Load plugins for SCPUI which are downstream scripts that should be loaded last
--- @return nil
function ScpuiSystem:loadPlugins()
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	ba.print("SCPUI is loading user plugins...\n")

    local files = cf.listFiles("data/scripts", "*.lua")
    local plugins_prefix = "scpui_plg_"

    if not files then
        return
    end

    for _, filename in ipairs(files) do
        if string.find(filename, plugins_prefix) then
            local module_name = filename:match(plugins_prefix .. "(.-)%.lua")
            if module_name then
                local module_path = string.format("%s%s", plugins_prefix, module_name)
                local ok, module = pcall(require, module_path)
                if ok then
                    ba.print("SCPUI loaded plugin " .. module_name .. " (" .. module_path .. ")\n")
                else
                    ba.warning("SCPUI Error loading plugin " .. module_path .. ": " .. tostring(module) .. "\n")
                end
            end
        end
    end
end

--- Makes all loaded methods in ScpuiSystem read-only
--- @return nil
function ScpuiSystem:finalizeMethods()
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	local locked = {}
	local rawSystem = ScpuiSystem

	for k, v in pairs(rawSystem) do
		if type(v) == "function" then
			locked[k] = true
		end
	end

	local proxy = {}
	local mt = {
		__index = rawSystem,
		__newindex = function(_, k, v)
			if locked[k] then
				ba.warning("Attempt to overwrite locked SCPUI method: " .. tostring(k) .. ". New value will be ignored.")
			else
				rawSystem[k] = v
			end
		end,
		__pairs = function()
			return pairs(rawSystem)
		end
	}

	setmetatable(proxy, mt)
	ScpuiSystem = proxy
end

--- Get the current SCPUI document definition
--- @param state string The current state key
--- @return ui_replacement? The current SCPUI document definition
function ScpuiSystem:getDef(state)
	if self.data.Render == false then
		return nil
	end
	return self.data.Replacements_List[state]
end

--- When a document is closed this function tries to make sure everything is properly cleaned up
--- @return nil
function ScpuiSystem:cleanSelf()
	ba.print("SCPUI is closing document " .. ScpuiSystem.data.CurrentDoc.Markup .. "\n")
	while ScpuiSystem.data.CurrentDoc.Document:HasChildNodes() do
		ScpuiSystem.data.CurrentDoc.Document:RemoveChild(ScpuiSystem.data.CurrentDoc.Document.first_child)
		ba.print("SCPUI HAS KILLED A CHILD! But that's allowed in America.\n")
	end

	ScpuiSystem.data.CurrentDoc.Document:Close()
	ScpuiSystem.data.CurrentDoc.Document = nil
	ScpuiSystem.data.CurrentDoc = nil
	ScpuiSystem.data.Tooltip_Timers = {}
end

--- Gets the name of a game state or substate in a table with indexed key 'Name'
--- The primary purpose of this function is to handle the special case of SCPUI SCRIPTING SUBSTATE
--- @param state gamestate The game state or substate
--- @return gamestate state The game state or substate table
function ScpuiSystem:getRocketUiHandle(state)
	if state.Name == "GS_STATE_SCRIPTING" or state.Name == "GS_STATE_SCRIPTING_MISSION" then
		return {Name = ScpuiSystem.data.Substate}
	else
		return state
	end
end

--- This function is used to begin a new scripting substate in the GS_STATE_SCRIPTING or GS_STATE_SCRIPTING_MISSION game states
--- @param state string The substate to begin
--- @param mission_state boolean? True to use GS_STATE_SCRIPTING_MISSION instead of GS_STATE_SCRIPTING
--- @return nil
function ScpuiSystem:beginSubstate(state, mission_state)
	if not self:hasOverrideForState({Name = state}) then
		ba.warning("No SCPUI document defined for " .. state .. " in scpui.tbl!\n")
		return
	end

	ScpuiSystem.data.OldSubstate = ScpuiSystem.data.Substate
	ScpuiSystem.data.Substate = state

	local script_state = "GS_STATE_SCRIPTING"
	if mission_state then
		script_state = "GS_STATE_SCRIPTING_MISSION"
	end
	--If we're already in the scripting state then force loading the new scpui define
	if ba.getCurrentGameState().Name == script_state then
		ba.print("Got event SCPUI SCRIPTING SUBSTATE " .. ScpuiSystem.data.Substate .. " in SCPUI SCRIPTING SUBSTATE " .. ScpuiSystem.data.OldSubstate .. "\n")
		--We don't actually change game states so we need to manually clean up
		ScpuiSystem:stateEnd(true)
		--Now we can start the new state
		ScpuiSystem:stateStart()
	else
		ba.print("Got event SCPUI SCRIPTING SUBSTATE " .. ScpuiSystem.data.Substate .. "\n")
		ba.postGameEvent(ba.GameEvents[script_state:gsub("STATE", "EVENT")])
	end
end

--- Returns to a previous game state checking if we should return to a substate as well
--- This allows for states to correctly return to the previous state even if has no rocket ui defined
--- @param state gamestate The game state or substate
--- @return nil
function ScpuiSystem:returnToState(state)

	local event

	if state.Name == "GS_STATE_BRIEFING" then
		event = "GS_EVENT_START_BRIEFING"
	elseif state.Name == "GS_STATE_VIEW_CUTSCENES" then
		event = "GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"
	elseif state.Name == "GS_STATE_GAME_PLAY" then
		event = "GS_EVENT_ENTER_GAME"
	elseif state.Name == "GS_STATE_SCRIPTING" or state.Name == "GS_STATE_SCRIPTING_MISSION" then
		ScpuiSystem:beginSubstate(ScpuiSystem.data.OldSubstate)
		return
	else
		event = string.gsub(state.Name, "STATE", "EVENT")
	end

	ba.postGameEvent(ba.GameEvents[event])

end

--- Checks if a gamestate has an SCPUI document defined
--- @param state gamestate The game state or substate
--- @return boolean result If the game state or substate has an SCPUI document defined
function ScpuiSystem:hasOverrideForState(state)
	return self:getDef(state.Name) ~= nil
end

--- Checks if the current gamestate has an SCPUI document defined
--- @return boolean result If the current game state or substate has an SCPUI document defined
function ScpuiSystem:hasOverrideForCurrentState()
	return self:hasOverrideForState(ScpuiSystem:getRocketUiHandle(ba.getCurrentGameState()))
end

--- On start of a new game state this function will try to load the related SCPUI document, if any exists for the state
--- @return nil
function ScpuiSystem:stateStart()

	if ba.MultiplayerMode then
		self.data.Render = not ScpuiSystem.data.table_flags.DisableInMulti
	else
		self.data.Render = true
	end

	--This allows for states to correctly return to the previous state even if has no rocket ui defined
	ScpuiSystem.data.CurrentState = ba.getCurrentGameState()

	--If hv.NewState is nil then use the Current Game State; This allows for Script UIs to jump from substate to substate
	local state = hv.NewState or ba.getCurrentGameState()

	if not self:hasOverrideForState(ScpuiSystem:getRocketUiHandle(state)) then
		ba.print("No SCPUI document defined for " .. ScpuiSystem:getRocketUiHandle(state).Name .. " in scpui.tbl!\n")
		return
	end

	--Make sure we're all cleaned up
	if ScpuiSystem.data.CurrentDoc then
		self:cleanSelf()
	end

	ScpuiSystem.data.CurrentDoc = self:getDef(ScpuiSystem:getRocketUiHandle(state).Name)
	ba.print("SCPUI is loading document " .. ScpuiSystem.data.CurrentDoc.Markup .. "\n")
	ScpuiSystem.data.CurrentDoc.Document = self.data.Context:LoadDocument(ScpuiSystem.data.CurrentDoc.Markup)
	ScpuiSystem.data.CurrentDoc.Document:Show()

	ui.enableInput(self.data.Context)
end

--- On each frame of a game state this function will update and render the related SCPUI document, if any exists for the state
--- @return nil
function ScpuiSystem:stateFrame()
	if not self:hasOverrideForCurrentState() then
		return
	end

	-- Add some tracing scopes here to see how long this stuff takes
	UpdateCategory:trace(function()
		self.data.Context:Update()
	end)
	RenderCategory:trace(function()
		self.data.Context:Render()
	end)
end

--- On end of a game state this function will try to clean up the related SCPUI document, if any exists for the state
--- It will also return control back to the FSO UI
--- @param substate? boolean If the state to end is a substate
--- @return nil
function ScpuiSystem:stateEnd(substate)

	--This allows for states to correctly return to the previous state even if has no rocket ui defined
	ScpuiSystem.data.LastState = ScpuiSystem.data.CurrentState

	--Provide a UI topic for custom mod options to apply user selections
	local valid_states = {"GS_STATE_INITIAL_PLAYER_SELECT", "GS_STATE_BARRACKS_MENU", "GS_STATE_OPTIONS_MENU"}

	if not substate and (Utils.table.contains(valid_states, hv.OldState.Name)) then
		Topics.options.apply:send(nil)
	end

	if not substate then
		if not self:hasOverrideForState(ScpuiSystem:getRocketUiHandle(hv.OldState)) then
			return
		end
	end

	self:cleanSelf()

	ui.disableInput()

	if not substate and (hv.OldState.Name == "GS_STATE_SCRIPTING" or hv.OldState.Name == "GS_STATE_SCRIPTING_MISSION") then
		ScpuiSystem.data.Substate = "none"
	end
end

--- SCPUI's override for the FSO dialog system
--- If a dialog is to be shown, SCPUI will capture the relevant data and
--- show it using SCPUI's own dialog system
--- @return nil
function ScpuiSystem:dialogStart()
	local Dialogs = require("lib_dialogs")
	if hv.IsDeathPopup then
		self.data.DeathDialog = { Abort = {}, Submit = nil }
	else
		self.data.Dialog = { Abort = {}, Submit = nil }
	end
	local dialog = Dialogs.new()
		dialog:title(hv.Title)
		dialog:text(hv.Text)
		dialog:input(hv.IsInputPopup)

		if hv.IsDeathPopup then
			dialog:style(Dialogs.STYLE_DEATH)
			dialog:text(Topics.deathpopup.setText:send(self))
		else
			dialog:escape(-1) --Assuming that all non-death built-in popups can be cancelled safely with a negative response!
		end

	local hv_choices = hv.Choices
	local num_choices = #hv_choices
	if num_choices > 0 then
		--put in reverse order so it matches retail UI
		for i=num_choices,1, -1 do
			local button = hv_choices[i]
			local positivity = Dialogs.BUTTON_TYPE_NEUTRAL
			if button.Positivity == 1 then
				positivity = Dialogs.BUTTON_TYPE_POSITIVE
			elseif button.Positivity == -1 then
				positivity = Dialogs.BUTTON_TYPE_NEGATIVE
			end
			dialog:button(positivity, button.Text, i - 1, button.Shortcut)
		end
	end

	if hv.IsDeathPopup then
		dialog:show(self.data.Context, self.data.DeathDialog.Abort)
			:continueWith(function(response)
				self.data.DeathDialog.Submit = response
			end)
	else
		dialog:show(self.data.Context, self.data.Dialog.Abort)
			:continueWith(function(response)
				self.data.Dialog.Submit = response
			end)
	end
	ui.enableInput(self.data.Context)
end

--- For a dialog frame, check for any user input and handle it while also
--- updating and rendering the dialog itself
--- @return nil
function ScpuiSystem:dialogFrame()
	-- Add some tracing scopes here to see how long this stuff takes
	UpdateCategory:trace(function()
		if hv.Freeze ~= nil and hv.Freeze ~= true then
			self.data.Context:Update()
		end
	end)
	RenderCategory:trace(function()
		self.data.Context:Render()
	end)

	if ba.isEngineVersionAtLeast(25, 0, 0) and ScpuiSystem.data.DialogDoc then
		local text_el = ScpuiSystem.data.DialogDoc:GetElementById("text_container").first_child
		if text_el then
			text_el.inner_rml = hv.Text
		end
	end
	if hv.IsDeathPopup then
		local submit = self.data.DeathDialog.Submit
		-- This really shouldn't happen, but just in case
		if submit == nil and not ScpuiSystem.data.DialogDoc then
			ba.warning("SCPUI Error: Death popup was not submitted and no dialog document is open!\n")
			-- We aren't showing a death popup when we should be, which is a soft lock;
			-- default to 0 (Quickstart Mission) to get to a state we can proceed from
			submit = 0
		end
		if submit ~= nil then
			self.data.DeathDialog = nil
			hv.Submit(submit)
		end
	else
		if self.data.Dialog.Submit ~= nil then
			local submit = self.data.Dialog.Submit
			self.data.Dialog = nil
			hv.Submit(submit)
		end
	end
end

--- On dialog end, SCPUI will close the dialog and return control back to the FSO UI
--- Also handle any abort callbacks
--- @return nil
function ScpuiSystem:dialogEnd()
	ui.disableInput()

	if hv.IsDeathPopup then
		if self.data.DeathDialog and self.data.DeathDialog.Abort then
			if self.data.DeathDialog.Abort.Abort then
				self.data.DeathDialog.Abort.Abort()
			end
		end
	else
		if self.data.Dialog and self.data.Dialog.Abort then
			if self.data.Dialog.Abort.Abort then
				self.data.Dialog.Abort.Abort()
			end
		end
	end

	self:closeDialog()
end

--- Closes the current dialog and returns control to the state that called it
--- @return nil
function ScpuiSystem:closeDialog()
	if ScpuiSystem.data.DialogDoc ~= nil then
		ba.print("SCPUI is closing dialog `" .. ScpuiSystem.data.DialogDoc.title .. "`\n")
		ScpuiSystem.data.DialogDoc:Close()
		ScpuiSystem.data.DialogDoc = nil
	end

	local state = hv.NewState or ba.getCurrentGameState()

	--If we're going back to an SCPUI state, then give it control
	--Otherwise cede control back to FSO
	if self:hasOverrideForState(ScpuiSystem:getRocketUiHandle(state)) then
		ui.enableInput(self.data.Context)
	else
		ui.disableInput()
	end
end

--- During the loading screen, SCPUI will show a custom loading screen if defined
--- @return nil
function ScpuiSystem:loadStart()

	if ScpuiSystem.data.state_init_status.LoadScreen then
		return
	end

	if ba.MultiplayerMode then
		ScpuiSystem.data.Render = not ScpuiSystem.data.table_flags.DisableInMulti
	else
		ScpuiSystem.data.Render = true
	end

	if not self:hasOverrideForState({Name = "LOAD_SCREEN"}) then
		return
	end

	ScpuiSystem.data.LoadDoc = self:getDef("LOAD_SCREEN")
	ba.print("SCPUI is loading document " .. ScpuiSystem.data.LoadDoc.Markup .. "\n")
	ScpuiSystem.data.LoadDoc.Document = self.data.Context:LoadDocument(ScpuiSystem.data.LoadDoc.Markup)
	ScpuiSystem.data.LoadDoc.Document:Show(DocumentFocus.FOCUS)

	--ui.enableInput(self.data.context)

	ScpuiSystem.data.memory.loading_bar.LoadProgress = 0
	ScpuiSystem.data.state_init_status.LoadScreen = true
end

--- During the loading screen, SCPUI will update and render the custom loading screen if defined
--- The LoadProgress variable is updated to show the progress of the loading bar
--- @return nil
function ScpuiSystem:loadFrame()
	if ScpuiSystem.data.state_init_status.LoadScreen == nil then
		return
	end

	ScpuiSystem.data.memory.loading_bar.LoadProgress = hv.Progress

	-- Add some tracing scopes here to see how long this stuff takes
	UpdateCategory:trace(function()
		self.data.Context:Update()
	end)
	RenderCategory:trace(function()
		self.data.Context:Render()
	end)
end

--- When a loading screen ends, clean up the relevant data
--- @return nil
function ScpuiSystem:loadEnd()

	if ScpuiSystem.data.state_init_status.LoadScreen == nil then
		return
	end

	self:closeLoadScreen()

	--ui.disableInput()
	ScpuiSystem.data.memory.loading_bar.LoadProgress = nil
	ScpuiSystem.data.state_init_status.LoadScreen = nil
end

--- Closes the loading screen and returns control back to the state that called it, if any
--- @return nil
function ScpuiSystem:closeLoadScreen()
	if ScpuiSystem.data.LoadDoc ~= nil then
		ba.print("SCPUI is closing loading screen\n")
		ScpuiSystem.data.LoadDoc.Document:Close()
		ScpuiSystem.data.LoadDoc = nil
	end

	local state = hv.NewState or ba.getCurrentGameState()

	--If we're going back to an SCPUI state, then give it control
	--Otherwise cede control back to FSO
	if self:hasOverrideForState(ScpuiSystem:getRocketUiHandle(state)) then
		ui.enableInput(self.data.Context)
	else
		ui.disableInput()
	end
end

--- These methods must be available for submodules which are loaded after scpui_system_core

--- Gets the current mod title from FSO. If not defined then set it to 'SCPUI Development Mod'
--- If the mod root name is not 'SCPUI' then warn that a mod title is required
--- @return string title The current mod title
function ScpuiSystem:getModTitle()
    local title = ba.getModTitle()

    if title == "" then
        title = ba.getModRootName()

        -- Extract title up to the first "-"
        local extracted_title = title:match("^(.-)%s*%-")
        if extracted_title then
            title = extracted_title
        end

        if title ~= "SCPUI" then
            ba.warning("It is highly recommended that you set a Mod Title in your game settings.tbl!")
        else
            title = "SCPUI Development Mod"
        end
    end

    return title
end

--- Extracts the base mod ID from the mod root
--- @return string The sanitized mod ID without versioning
function ScpuiSystem:getModId()

	if ScpuiSystem.data.table_flags.ModId then
		return ScpuiSystem.data.table_flags.ModId
	end

    local modRoot = ba.getModRootName()

	-- Fallback if empty string is returned
    if not modRoot or modRoot == "" then
        ba.warning("getModRootName() returned an empty string; using fallback mod ID.")
        modRoot = "unknown_mod"
    end

    -- Remove trailing semantic version if present (e.g., "-2.1.1")
	local baseID = modRoot:match("^(.-)-?%d*%.?%d*%.?%d*$")

	-- If no version string is found, sanitize the modRoot
	if not baseID or baseID == "" then
		baseID = modRoot
	end

	-- Sanitize the baseID by removing invalid characters for JSON keys
	baseID = baseID:gsub("[^%w_]", "_")

	ScpuiSystem.data.table_flags.ModId = baseID

	return baseID
end

--- Adds a preload coroutine to the SCPUI system that will be run during the splash screens
--- @param message string The debug message to print
--- @param text string The debug string to display
--- @param func function The function to run
--- @param args table The arguments to pass to the function
--- @param val number The priority of the preload coroutine, should be 1 or 2
--- @return nil
function ScpuiSystem:addPreload(message, text, func, args, val)
    assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

    if self.data.Preload_Coroutines == nil then
        self.data.Preload_Coroutines = {}
    end

    table.insert(self.data.Preload_Coroutines, {
		DebugMessage = message,
		DebugString = text,
		Function = func,
		Args = args or {},
		Priority = Utils.clamp(val, 1, 2)
	})
end


--- Wrapper to create an engine hook that also will print to the log that the hook was created by SCPUI and for which lua script
--- @param hook_name string The name of the hook
--- @param hook_function function The function to run when the hook is triggered
--- @param condition? table The condition to check before running the hook
--- @param override_function? function The function to run to check if the hook should run as override
--- @return nil
function ScpuiSystem:addHook(hook_name, hook_function, condition, override_function)
    if condition == nil and override_function == nil then
        -- Call with only hook name and function
        engine.addHook(hook_name, hook_function)
    elseif override_function == nil then
        -- Call with hook name, function, and condition
        engine.addHook(hook_name, hook_function, condition)
    else
        -- Call with all parameters
        engine.addHook(hook_name, hook_function, condition, override_function)
    end

	local function get_caller_file()
		local info = debug.getinfo(3, "S") -- Level 3: The caller of the function that called addHook
		if info and info.source then
			return info.source
		end
		return "[unknown]"
	end

    ba.print("SCPUI registered hook '" .. hook_name .. "' for script document '" .. get_caller_file() .. "'\n")
end

--- Register extension topics to the topics system
--- @param category string The category of topics to register
--- @param topics_table table The table of topics to register
--- @return nil
function ScpuiSystem:registerExtensionTopics(category, topics_table)
	if not Topics.registerTopics then
		ba.error("SCPUI Error: Topics cannot be registered after initialization!\n")
	end

    -- Register the topics in the specified category
    Topics:registerTopics(category, topics_table)
end

--- Mark the constants table as read-only by utilizing a proxy table and custom metatable
--- @return nil
function ScpuiSystem:finalizeConstants()
	assert(not ScpuiSystem.constants.INITIALIZED, "SCPUI has already been Initialized!")

	local function makeReadOnly(tbl)
		local proxy = {}
		local mt = {
			__index = tbl,
			__newindex = function(_, k, _)
				ba.warning("Attempt to modify read-only SCPUI field '" .. tostring(k) .. "', new value will be ignored.")
			end,
			__pairs = function()
				return pairs(tbl)
			end
		}

		for k, v in pairs(tbl) do
			if type(v) == "table" then
				tbl[k] = makeReadOnly(v) -- recurse into nested tables
			end
		end

		setmetatable(proxy, mt)
		return proxy
	end

	ScpuiSystem.constants.INITIALIZED = true -- set before lock

	local original_data = ScpuiSystem.constants
	ScpuiSystem.constants = makeReadOnly(original_data)
end

--- Completes the initialization of the SCPUI system. Runs after the preload methods are complete. (After the splash screens)
--- @return nil
function ScpuiSystem:completeInitialization()
	ScpuiSystem:finalizeMethods()
	ScpuiSystem:finalizeConstants()

	ba.print("SCPUI initialization complete!\n")
end

mn.LuaSEXPs["scpui-show-menu"].Action = function(state)
	ScpuiSystem:beginSubstate(state, true)
end

--RUN AWAY IT'S FRED!
if ba.inMissionEditor() then
	ScpuiSystem.data.Active = nil
	ScpuiSystem:init() -- Parse the tables and load the submodules for downstream extensions
	ScpuiSystem:completeInitialization() -- Finalize the constants table and mark the system as initialized
	return
end

ScpuiSystem:init()

--Core Ui Takeover

ScpuiSystem:addHook("On State Start", function()
	ScpuiSystem:stateStart()
end, {}, function()
	return ScpuiSystem:hasOverrideForState(ScpuiSystem:getRocketUiHandle(hv.NewState))
end)

ScpuiSystem:addHook("On Frame", function()
	ScpuiSystem:stateFrame()
end, {}, function()
	return ScpuiSystem:hasOverrideForCurrentState()
end)

ScpuiSystem:addHook("On State End", function()
	ScpuiSystem:stateEnd()
end, {}, function()
	return ScpuiSystem:hasOverrideForState(ScpuiSystem:getRocketUiHandle(hv.OldState))
end)

--Dialog Takeover

ScpuiSystem:addHook("On Dialog Init", function()
	if ScpuiSystem.data.Render == true then
		ScpuiSystem:dialogStart()
	end
end, {}, function()
	return ScpuiSystem.data.Render
end)

ScpuiSystem:addHook("On Dialog Frame", function()
	if ScpuiSystem.data.Render == true then
		ScpuiSystem:dialogFrame()
	end
end, {}, function()
	return ScpuiSystem.data.Render
end)

ScpuiSystem:addHook("On Dialog Close", function()
	if ScpuiSystem.data.Render == true then
		ScpuiSystem:dialogEnd()
	end
end, {}, function()
	return ScpuiSystem.data.Render
end)

--Load Screen Takeover

ScpuiSystem:addHook("On Load Screen", function()
	ScpuiSystem:loadStart()
end, {}, function()
	return ScpuiSystem:hasOverrideForState({Name = "LOAD_SCREEN"})
end)

ScpuiSystem:addHook("On Load Screen", function()
	ScpuiSystem:loadFrame()
end, {}, function()
	return ScpuiSystem:hasOverrideForState({Name = "LOAD_SCREEN"})
end)

ScpuiSystem:addHook("On Load Complete", function()
	ScpuiSystem:loadEnd()
end, {}, function()
	return ScpuiSystem:hasOverrideForState({Name = "LOAD_SCREEN"})
end)

--Helpers

ScpuiSystem:addHook("On Load Screen", function()
	ScpuiSystem.data.memory.MissionLoaded = true
end, {}, function()
	return false
end)

ScpuiSystem:addHook("On Mission End", function()
	ScpuiSystem.data.memory.MissionLoaded = false
end, {}, function()
	return false
end)

ba.print("------------------ SCPUI is ready to go! ------------------ \n")