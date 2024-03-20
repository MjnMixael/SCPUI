local utils = require("utils")
local topics = require("ui_topics")

-----------------------------------
--This is the core SCPUI file. It handles state management and
--all necessary preloading of content. Disabling this, disables
--everything. Modify with care.
-----------------------------------

local updateCategory = engine.createTracingCategory("UpdateRocket", false)
local renderCategory = engine.createTracingCategory("RenderRocket", true)

ScpuiSystem = {
	active = true,
	numFontSizes = 20,
    replacements = {},
	backgrounds = {},
	briefBackgrounds = {},
	preloadCoroutines = {},
	medalInfo = {},
	substate = "none",
	cutscene = "none",
	disableInMulti = true,
	hideMulti = false,
	debriefInit = false,
	selectInit = false,
	shipSelectInit = false,
	music_handle = nil,
	current_played = nil,
	initIcons = nil,
	logSection = 1,
	render = true,
	dialog = nil,
	dataSaverMulti = 1,
	missionLoaded = false
}

ScpuiOptionValues = {}

--RUN AWAY IT'S FRED!
if ba.inMissionEditor() then
	ScpuiSystem.active = nil
	return
end

--setting this to true will completely disable SCPUI
if false then
	ScpuiSystem.active = nil
	return
end

ScpuiSystem.context = rocket:CreateContext("menuui", Vector2i.new(gr.getCenterWidth(), gr.getCenterHeight()));

function ScpuiSystem:init()
	if cf.fileExists("scpui.tbl", "", true) then
        self:parseTable("scpui.tbl")
    end
    for _, v in ipairs(cf.listFiles("data/tables", "*-ui.tbm")) do
        self:parseTable(v)
    end
end

function ScpuiSystem:parseTable(data)
	parse.readFileText(data, "data/tables")
	
	if parse.optionalString("#Settings") then
		
		if parse.optionalString("$Hide Multiplayer:") then
			ScpuiSystem.hideMulti = parse.getBoolean()
		end
		
		if parse.optionalString("$Disable during Multiplayer:") then
			ScpuiSystem.disableInMulti = parse.getBoolean()
		end
		
		if parse.optionalString("$Data Saver Multiplier:") then
			ScpuiSystem.dataSaverMulti = parse.getInt()
		end
		
	end

	parse.requiredString("#State Replacement")

	while parse.optionalString("$State:") do
		local state = parse.getString()

		if state == "GS_STATE_SCRIPTING" then
			parse.requiredString("+Substate:")
			local state = parse.getString()
			parse.requiredString("+Markup:")
			local markup = parse.getString()
			ba.print("SCPUI found definition for script substate " .. state .. " : " .. markup .. "\n")
			self.replacements[state] = {
				markup = markup
			}
		else
			parse.requiredString("+Markup:")
			local markup = parse.getString()
			ba.print("SCPUI found definition for game state " .. state .. " : " .. markup .. "\n")
			self.replacements[state] = {
				markup = markup
			}
		end
	end
	
	if parse.optionalString("#Background Replacement") then
	
		while parse.optionalString("$Campaign Background:") do
			parse.requiredString("+Campaign Filename:")
			local campaign = utils.strip_extension(parse.getString())
			
			parse.requiredString("+RCSS Class Name:")
			local classname = parse.getString()
			
			self.backgrounds[campaign] = classname
		end
	
	end
	
	if parse.optionalString("#Briefing Stage Background Replacement") then
	
		while parse.optionalString("$Briefing Grid Background:") do
		
			parse.requiredString("+Mission Filename:")
			local mission = utils.strip_extension(parse.getString())
			
			parse.requiredString("+Default Background Filename:")
			local default_file = parse.getString()
			
			if not utils.hasExtension(default_file) then
				ba.warning("SCPUI parsed background file, " .. default_file .. ", that does not include an extension!")
			end
			
			self.briefBackgrounds[mission] = {}
			
			self.briefBackgrounds[mission]["default"] = default_file
			
			while parse.optionalString("+Stage Override:") do
				local stage = tostring(parse.getInt())
				
				parse.requiredString("+Background Filename:")
				local file = parse.getString()
				
				if not utils.hasExtension(file) then
					ba.warning("SCPUI parsed background file, " .. default_file .. ", that does not include an extension!")
				end
				
				self.briefBackgrounds[mission][stage] = file
			end
			
		end
	
	end
	
	if parse.optionalString("#Medal Placements") then
	
		while parse.optionalString("$Medal Bitmap:") do
		
			local id = parse.getString()
			
			self.medalInfo[id] = {}
			
			parse.requiredString("+Position X:")
			self.medalInfo[id].x = parse.getFloat()
			
			parse.requiredString("+Position Y:")
			self.medalInfo[id].y = parse.getFloat()
			
			parse.requiredString("+Width:")
			self.medalInfo[id].w = parse.getFloat()
		
		end
	
	end
		

	parse.requiredString("#End")

	parse.stop()
end

function ScpuiSystem:getDef(state)
	if self.render == false then
		return nil
	end
    return self.replacements[state]
end

function ScpuiSystem:cleanSelf()
	ba.print("SCPUI is closing document " .. ScpuiSystem.currentDoc.markup .. "\n")
	while ScpuiSystem.currentDoc.document:HasChildNodes() do
		ScpuiSystem.currentDoc.document:RemoveChild(ScpuiSystem.currentDoc.document.first_child)
		ba.print("SCPUI HAS KILLED A CHILD! But that's allowed in America.\n")
	end

    ScpuiSystem.currentDoc.document:Close()
    ScpuiSystem.currentDoc.document = nil
	ScpuiSystem.currentDoc = nil
end

function ScpuiSystem:stateStart()

	if ba.MultiplayerMode then
		self.render = not ScpuiSystem.disableInMulti
	else
		self.render = true
	end

	--This allows for states to correctly return to the previous state even if has no rocket ui defined
	ScpuiSystem.currentState = ba.getCurrentGameState()
	
	--If hv.NewState is nil then use the Current Game State; This allows for Script UIs to jump from substate to substate
	local state = hv.NewState or ba.getCurrentGameState()
	
    if not self:hasOverrideForState(getRocketUiHandle(state)) then
        return
    end
	
	--Make sure we're all cleaned up
	if ScpuiSystem.currentDoc then
		self:cleanSelf()
	end
	
    ScpuiSystem.currentDoc = self:getDef(getRocketUiHandle(state).Name)
    ba.print("SCPUI is loading document " .. ScpuiSystem.currentDoc.markup .. "\n")
    ScpuiSystem.currentDoc.document = self.context:LoadDocument(ScpuiSystem.currentDoc.markup)
    ScpuiSystem.currentDoc.document:Show()

    ui.enableInput(self.context)
end

function ScpuiSystem:stateFrame()
    if not self:hasOverrideForCurrentState() then
        return
    end

    -- Add some tracing scopes here to see how long this stuff takes
    updateCategory:trace(function()
        self.context:Update()
    end)
    renderCategory:trace(function()
        self.context:Render()
    end)
end

function ScpuiSystem:stateEnd(substate)

	--This allows for states to correctly return to the previous state even if has no rocket ui defined
	ScpuiSystem.lastState = ScpuiSystem.currentState

	if not substate then
		if not self:hasOverrideForState(getRocketUiHandle(hv.OldState)) then
			return
		end
	end

    self:cleanSelf()

    ui.disableInput()
	
	if not substate and hv.OldState.Name == "GS_STATE_SCRIPTING" then
		ScpuiSystem.substate = "none"
	end
	
	if ba.MultiplayerMode then
		self.render = ScpuiSystem.disableInMulti
	end
end

function getRocketUiHandle(state)
    if state.Name == "GS_STATE_SCRIPTING" then
        return {Name = ScpuiSystem.substate}
    else
        return state
    end
end

function ScpuiSystem:beginSubstate(state) 
	ScpuiSystem.oldSubstate = ScpuiSystem.substate
	ScpuiSystem.substate = state
	--If we're already in GS_STATE_SCRIPTING then force loading the new scpui define
	if ba.getCurrentGameState().Name == "GS_STATE_SCRIPTING" then
		ba.print("Got event SCPUI SCRIPTING SUBSTATE " .. ScpuiSystem.substate .. " in SCPUI SCRIPTING SUBSTATE " .. ScpuiSystem.oldSubstate .. "\n")
		--We don't actually change game states so we need to manually clean up
		ScpuiSystem:stateEnd(true)
		--Now we can start the new state
		ScpuiSystem:stateStart()
	else
		ba.print("Got event SCPUI SCRIPTING SUBSTATE " .. ScpuiSystem.substate .. "\n")
		ba.postGameEvent(ba.GameEvents["GS_EVENT_SCRIPTING"])
	end
end

--This allows for states to correctly return to the previous state even if has no rocket ui defined
function ScpuiSystem:ReturnToState(state)

	local event

	if state.Name == "GS_STATE_BRIEFING" then
		event = "GS_EVENT_START_BRIEFING"
	elseif state.Name == "GS_STATE_VIEW_CUTSCENES" then
		event = "GS_EVENT_GOTO_VIEW_CUTSCENES_SCREEN"
	elseif state.Name == "GS_STATE_SCRIPTING" then
		ScpuiSystem:beginSubstate(ScpuiSystem.oldSubstate)
		return
	else
		event = string.gsub(state.Name, "STATE", "EVENT")
	end

	ba.postGameEvent(ba.GameEvents[event])

end

function ScpuiSystem:hasOverrideForState(state)
    return self:getDef(state.Name) ~= nil
end

function ScpuiSystem:hasOverrideForCurrentState()
    return self:hasOverrideForState(getRocketUiHandle(ba.getCurrentGameState()))
end

function ScpuiSystem:dialogStart()
    ui.enableInput(self.context)
    
    local dialogs = require('dialogs')
	if hv.IsDeathPopup then
		self.DeathDialog = { Abort = {}, Submit = nil }
	else
		self.Dialog = { Abort = {}, Submit = nil }
	end
    local dialog = dialogs.new()
        dialog:title(hv.Title)
        dialog:text(hv.Text)
		dialog:input(hv.IsInputPopup)

		if hv.IsDeathPopup then
			dialog:style(2)
			dialog:text(topics.deathpopup.setText:send(self))
		else
			dialog:escape(-1) --Assuming that all non-death built-in popups can be cancelled safely with a negative response!
		end
    
    for i, button in ipairs(hv.Choices) do
        local positivity = nil
        if button.Positivity == 0 then
            positivity = dialogs.BUTTON_TYPE_NEUTRAL
        elseif button.Positivity == 1 then
            positivity = dialogs.BUTTON_TYPE_POSITIVE
        elseif button.Positivity == -1 then
            positivity = dialogs.BUTTON_TYPE_NEGATIVE
        end
        dialog:button(positivity, button.Text, i - 1, button.Shortcut)
    end
	
	if hv.IsDeathPopup then
		dialog:show(self.context, self.DialogAbort)
			:continueWith(function(response)
				self.DeathDialog.Submit = response
			end)
	else
		dialog:show(self.context, self.DialogAbort)
			:continueWith(function(response)
				self.Dialog.Submit = response
			end)
	end
end

function ScpuiSystem:dialogFrame()
    -- Add some tracing scopes here to see how long this stuff takes
    updateCategory:trace(function()
		if hv.Freeze ~= nil and hv.Freeze ~= true then
			self.context:Update()
		end
    end)
    renderCategory:trace(function()
        self.context:Render()
    end)
	
	--So that the skip mission popup can re-enable the death popup on dialog end
	if self.Reenable ~= nil and self.Reenable == true then
		ui.enableInput(self.context)
		self.Reenable = nil
	end
		
    
	if hv.IsDeathPopup then
		if self.DeathDialog.Submit ~= nil then
			local submit = self.DeathDialog.Submit
			self.DeathDialog = nil
			hv.Submit(submit)
		end
	else
		if self.Dialog.Submit ~= nil then
			local submit = self.Dialog.Submit
			self.Dialog = nil
			hv.Submit(submit)
		end
	end
end

function ScpuiSystem:dialogEnd()
    ui.disableInput(self.context)
	
	if not hv.IsDeathPopup then
		self.Reenable = true
	end

	if hv.IsDeathPopup then
		if self.DeathDialog and self.DeathDialog.Abort then
			if self.DeathDialog.Abort.Abort then
				self.DeathDialog.Abort.Abort()
			end
		end
	else
		if self.Dialog and self.Dialog.Abort then
			if self.Dialog.Abort.Abort then
				self.Dialog.Abort.Abort()
			end
		end
	end
	
	self:CloseDialog()
end

function ScpuiSystem:addPreload(message, text, run, val)
	if self.preloadCoroutines == nil then
		self.preloadCoroutines = {}
	end
	
	local num = #self.preloadCoroutines + 1
	
	if val > 1 then
		val = 2
	else
		val = 1
	end
	
	self.preloadCoroutines[num] = {
		debugMessage = message,
		debugString = text,
		func = run,
		priority = val
	}
end	

function ScpuiSystem:CloseDialog()
	if ScpuiSystem.dialog ~= nil then
		ba.print("SCPUI is closing dialog `" .. ScpuiSystem.dialog.title .. "`\n")
		ScpuiSystem.dialog:Close()
		ScpuiSystem.dialog = nil
	end
end

ScpuiSystem:init()

engine.addHook("On State Start", function()
	ScpuiSystem:stateStart()
end, {}, function()
    return ScpuiSystem:hasOverrideForState(getRocketUiHandle(hv.NewState))
end)

engine.addHook("On Frame", function()
	ScpuiSystem:stateFrame()
end, {}, function()
    return ScpuiSystem:hasOverrideForCurrentState()
end)

engine.addHook("On State End", function()
	ScpuiSystem:stateEnd()
end, {}, function()
    return ScpuiSystem:hasOverrideForState(getRocketUiHandle(hv.OldState))
end)

engine.addHook("On Dialog Init", function()
	if ScpuiSystem.render == true then
		ScpuiSystem:dialogStart()
	end
end, {}, function()
    return ScpuiSystem.render
end)

engine.addHook("On Dialog Frame", function()
	if ScpuiSystem.render == true then
		ScpuiSystem:dialogFrame()
	end
end, {}, function()
    return ScpuiSystem.render
end)

engine.addHook("On Dialog Close", function()
	if ScpuiSystem.render == true then
		ScpuiSystem:dialogEnd()
	end
end, {}, function()
    return ScpuiSystem.render
end)

engine.addHook("On Load Screen", function()
	ScpuiSystem.missionLoaded = true
end, {}, function()
	return false
end)

engine.addHook("On Mission End", function()
	ScpuiSystem.missionLoaded = false
end, {}, function()
	return false
end)
