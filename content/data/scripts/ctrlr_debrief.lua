-----------------------------------
--Controller for the Debrief UI
-----------------------------------

local AsyncUtil = require("lib_async")
local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local DebriefingController = Class()

DebriefingController.STATE_NONE = 0 --- @type number Enumeration for medals, options, or other non-debrief states
DebriefingController.STATE_DEBRIEF = 1 --- @type number Enumeration for the debriefing state
DebriefingController.STATE_STATS = 2 --- @type number Enumeration for the stats state

DebriefingController.PAGE_COMMAND_FIRST = 1 --- @type number Enumeration for the first page command
DebriefingController.PAGE_COMMAND_PREV = 2 --- @type number Enumeration for the previous page command
DebriefingController.PAGE_COMMAND_NEXT = 3 --- @type number Enumeration for the next page command
DebriefingController.PAGE_COMMAND_LAST = 4 --- @type number Enumeration for the last page command

--- Called by the class constructor
--- @return nil
function DebriefingController:init()
    --Check if we need to play the pre-debrief cutscene
	if not ScpuiSystem.data.state_init_status.Debrief then
		ScpuiSystem:maybePlayCutscene(MOVIE_PRE_DEBRIEF)
	end

    --Now initialize all our variables
    self.Stages = {} --- @type debriefing_stage[] The stages of the debriefing
    self.RecommendVisible = false --- @type boolean Whether the recommendation text is currently shown
    self.Player = nil --- @type player The current player, used for getting stats and medals
    self.Page = 1 --- @type number The current page of the stats screen
    self.HelpShown = false --- @type boolean Whether the help text is currently shown
    self.SelectedSection = DebriefingController.STATE_DEBRIEF --- @type number The currently selected section of the debriefing screen
    self.CurrentAudioStage = 0 --- @type number The current audio stage being played
    self.AudioFinished = false --- @type boolean Whether the audio has finished playing
    self.CurrentVoiceHandle = nil --- @type audio_stream The current audio stream handle
    self.RecommendationElements = {} --- @type Element[] The recommendation elements
    self.NumStages = 0 --- @type number The number of stages in the debriefing
    self.ChatEl = nil --- @type Element The chat window element
    self.ChatInputEl = nil --- @type Element The chat input element
    self.Document = nil --- @type Document The RML document
end

--- Called by the RML document
--- @param document Document
function DebriefingController:initialize(document)
    self.Document = document

    if not ScpuiSystem.data.state_init_status.Debrief then
        ui.Debriefing.initDebriefing()
        if not mn.hasDebriefing() then
			Topics.debrief.skip:send()
            self:close()
            ui.Debriefing.acceptMission()
			ScpuiSystem:maybePlayCutscene(MOVIE_POST_DEBRIEF)
            return
        end
        self:startMusic()
        ScpuiSystem.data.state_init_status.Debrief = true
    end

    self.Player = ba.getCurrentPlayer()

    if self.Player.ShowSkipPopup and ui.Debriefing.canSkip() and ui.Debriefing.mustReplay() then
        self:offerSkipDialog()
    end

    ---Load background choice
    self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	self.ChatEl = self.Document:GetElementById("chat_window")
	self.ChatInputEl = self.Document:GetElementById("chat_input")

    ---Load the desired font size from the save file
    self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    self.Document:GetElementById("mission_name").inner_rml = mn.getMissionTitle()
    self.Document:GetElementById("awards_wrapper"):SetClass("hidden", true)

    local li_el = self.Document:CreateElement("li")

    local promo_stage, promo_name, promo_file = ui.Debriefing.getEarnedPromotion()
    local badge_stage, badge_name, badge_file = ui.Debriefing.getEarnedBadge()
    local medal_name, medal_file = ui.Debriefing.getEarnedMedal()
    local traitor_stage = ui.Debriefing.getTraitor()

    if not traitor_stage then
        if promo_name then
            self.NumStages = self.NumStages + 1
            self.Stages[self.NumStages] = promo_stage
            self.Document:GetElementById("awards_wrapper"):SetClass("hidden", false)
            local awards_el = self.Document:GetElementById("medal_image_wrapper")
            local imgEl = self.Document:CreateElement("img")
            imgEl:SetAttribute("src", promo_file)
            imgEl:SetClass("medal_img", true)
            awards_el:AppendChild(imgEl)
            self.Document:GetElementById("promotion_text").inner_rml = promo_name
        end

        if badge_name then
            self.NumStages = self.NumStages + 1
            self.Stages[self.NumStages] = badge_stage
            self.Document:GetElementById("awards_wrapper"):SetClass("hidden", false)
            local awards_el = self.Document:GetElementById("medal_image_wrapper")
            local imgEl = self.Document:CreateElement("img")
            imgEl:SetAttribute("src", badge_file)
            imgEl:SetClass("medal_img", true)
            awards_el:AppendChild(imgEl)
            self.Document:GetElementById("badge_text").inner_rml = badge_name
        end

        if medal_name then
			--Check for an alt debrief bitmap
			if ScpuiSystem.data.Medal_Info[medal_name] then
				if ScpuiSystem.data.Medal_Info[medal_name].AltDebriefBitmap then
					medal_file = ScpuiSystem.data.Medal_Info[medal_name].AltDebriefBitmap
				end
			end
            self.Document:GetElementById("awards_wrapper"):SetClass("hidden", false)
            local awards_el = self.Document:GetElementById("medal_image_wrapper")
            local imgEl = self.Document:CreateElement("img")
            imgEl:SetAttribute("src", medal_file)
            imgEl:SetClass("medal_img", true)
            awards_el:AppendChild(imgEl)
            self.Document:GetElementById("medal_text").inner_rml = medal_name
        end

        local debriefing = ui.Debriefing.getDebriefing()

        for i = 1, #debriefing do
            --- @type debriefing_stage
            local stage = debriefing[i]
            if stage:checkVisible() then
                self.NumStages = self.NumStages + 1
                self.Stages[self.NumStages] = stage
                --This is where we should replace variables and containers probably!
            end
        end
    else
        self.NumStages = 1
        self.Stages[1] = traitor_stage
    end

	self.Document:GetElementById("stage_select"):SetClass("hidden", true)
	self.Document:GetElementById("play_cont"):SetClass("hidden", true)
	self.Document:GetElementById("stop_cont"):SetClass("hidden", true)

    self:buildText()

    self:startAudio()

    self.Document:GetElementById("debrief_btn"):SetPseudoClass("checked", true)

	Topics.debrief.initialize:send(self)

    -- We initialize in a state so send that out, too
    Topics.debrief.stateChanged:send(self)

end

--- Start playing the debriefing audio at stage 0
--- @return nil
function DebriefingController:startAudio()
	self.CurrentAudioStage = 0
	self.AudioFinished = false
	self:playVoice()
	self.Document:GetElementById("play_cont"):SetClass("hidden", true)
	self.Document:GetElementById("stop_cont"):SetClass("hidden", false)
end

--- Wrapper to start voice playback when the play button is pressed
--- @return nil
function DebriefingController:start_audio()
    self:startAudio()
end

--- Stop playing the debriefing audio and set the current audio stage to the last stage when the button is pressed
--- @return nil
function DebriefingController:stop_audio()
	self.CurrentAudioStage = self.NumStages
	self:stopVoice()
	self.Document:GetElementById("play_cont"):SetClass("hidden", false)
	self.Document:GetElementById("stop_cont"):SetClass("hidden", true)
end

--- Play all the audio sections using an async check to automatically move to the next stage as long as stop is not pressed
--- @return nil
function DebriefingController:playVoice()
    -- Only play the voice if we are on the debriefing screen and not stats
	if self.SelectedSection ~= DebriefingController.STATE_DEBRIEF then
		return
	end
	-- If we've played all the audio then don't play any more!
	if self.CurrentAudioStage == self.NumStages then
		self.AudioFinished = true
		self.Document:GetElementById("play_cont"):SetClass("hidden", false)
		self.Document:GetElementById("stop_cont"):SetClass("hidden", true)
		return
	end
    async.run(function()
        -- First, wait until the text has been shown fully
        async.await(AsyncUtil.wait_for(1.0))

        -- Just in case the player has left the debriefing screen really fast
        if self.SelectedSection == DebriefingController.STATE_NONE then
            return
        end

        -- And now we can start playing the voice file
        if self.Stages[self.CurrentAudioStage + 1] then
            if self.Stages[self.CurrentAudioStage + 1].AudioFilename then
                self.CurrentAudioStage = self.CurrentAudioStage + 1
                local file = self.Stages[self.CurrentAudioStage].AudioFilename
                if #file > 0 and string.lower(file) ~= "none" then
					--If a voice is already playing then close it and start a new one
					self:stopVoice()
                    self.CurrentVoiceHandle = ad.openAudioStream(file, AUDIOSTREAM_VOICE)
                    self.CurrentVoiceHandle:play(ad.MasterVoiceVolume)
                end
            end
        end

        self:waitForStageFinishAsync()

        if self.SelectedSection == DebriefingController.STATE_DEBRIEF then
            self:playVoice()
        end
    end, async.OnFrameExecutor)
end

--- Stop the current voice playback
--- @return nil
function DebriefingController:stopVoice()
	if self.CurrentVoiceHandle ~= nil and self.CurrentVoiceHandle:isValid() then
		self.CurrentVoiceHandle:close(false)
	end
end

--- Wait for the current voice handle to finish playing + 0.5 seconds
--- @return nil
function DebriefingController:waitForStageFinishAsync()
    if self.CurrentVoiceHandle ~= nil and self.CurrentVoiceHandle:isValid() then
        while self.CurrentVoiceHandle:isPlaying() do
            async.await(async.yield())
        end
    else
        --Do nothing
    end

    -- Voice part is done so wait for a bit before saying we are actually finished
    async.await(AsyncUtil.wait_for(0.5))
end

--- Build all the text for the debrief state including inserting recommendations
--- @return nil
function DebriefingController:buildText()

    local text_el = self.Document:GetElementById("debrief_text")

    self.RecommendationElements = {}

    for i = 1, #self.Stages do
        local paragraph = self.Document:CreateElement("p")
        text_el:AppendChild(paragraph)
        paragraph:SetClass("debrief_text_actual", true)
        local color_text = ScpuiSystem:setBriefingText(paragraph, self.Stages[i].Text)
        if self.Stages[i].Recommendation ~= "" then
            local recommendation = self.Document:CreateElement("p")
            self.RecommendationElements[i] = recommendation
            text_el:AppendChild(recommendation)
            recommendation.inner_rml = self.Stages[i].Recommendation
            recommendation:SetClass("hidden", true)
            recommendation:SetClass("red", true)
            recommendation:SetClass("recommendation", true)
        end
    end

    if #self.RecommendationElements == 0 then
        local paragraph = self.Document:CreateElement("p")
        text_el:AppendChild(paragraph)
        local recommendation = self.Document:CreateElement("p")
        self.RecommendationElements[1] = recommendation
        text_el:AppendChild(recommendation)
        recommendation.inner_rml = ba.XSTR("We have no recommendations for you.", 888314)
        recommendation:SetClass("hidden", true)
        recommendation:SetClass("red", true)
        recommendation:SetClass("recommendation", true)
    end

end

--- Build all the stats text elements
--- @return nil
function DebriefingController:buildStats()

    local stats = self.Player.Stats
    local name = self.Player:getName()

    ---@type number | string
    local difficulty = ba.getGameDifficulty()

    ---@type number | string
    local mission_time = mn.getMissionTime() + mn.MissionHUDTimerPadding

    --Convert mission time to minutes + seconds
    mission_time = (math.floor(mission_time/60)) .. ":" .. (math.floor(mission_time % 60))

    if difficulty == 1 then difficulty = ba.XSTR("Very Easy", 469, false) end
    if difficulty == 2 then difficulty = ba.XSTR("Easy", 470, false) end
    if difficulty == 3 then difficulty = ba.XSTR("Medium", 471, false) end
    if difficulty == 4 then difficulty = ba.XSTR("Hard", 472, false) end
    if difficulty == 5 then difficulty = ba.XSTR("Very Hard", 473, false) end

    local text_el = self.Document:GetElementById("debrief_text")

    local titles = ""
    local numbers = ""

    --Build stats header
    local header = self.Document:CreateElement("div")
    text_el:AppendChild(header)
    header:SetClass("blue", true)
    header:SetClass("stats_header", true)
    local name_el = self.Document:CreateElement("p")
    local page_el = self.Document:CreateElement("p")
    header:AppendChild(name_el)
    name_el:SetClass("stats_header_left", true)
    header:AppendChild(page_el)
    page_el:SetClass("stats_header_right", true)
    name_el.inner_rml = name
    page_el.inner_rml = self.Page .. " of 4"

    --Build stats sub header
    local subheader = self.Document:CreateElement("div")
    text_el:AppendChild(subheader)
    subheader:SetClass("stats_subheader", true)
    local name_el = self.Document:CreateElement("p")
    local page_el = self.Document:CreateElement("p")
    subheader:AppendChild(name_el)
    name_el:SetClass("stats_left", true)
    subheader:AppendChild(page_el)
    page_el:SetClass("stats_right", true)
    name_el.inner_rml = ba.XSTR("Skill Level", 1509, false)
    page_el.inner_rml = tostring(difficulty)

    --Build stats page 1
    if self.Page == 1 then
        local titles_table = {
            ba.XSTR("Mission Time", 446, false), "<br></br><br></br>",
            ba.XSTR("Mission Stats", 114, false), "<br></br><br></br>",
            ba.XSTR("Total Kills", 115, false), "<br></br><br></br>",
            ba.XSTR("Primary Weapon Shots", 116, false), "<br></br>",
            ba.XSTR("Primary Weapon Hits", 117, false), "<br></br>",
            ba.XSTR("Primary Friendly Hits", 118, false), "<br></br>",
            ba.XSTR("Primary Hit %", 119, false), "<br></br>",
            ba.XSTR("Primary Friendly Hit %", 120, false), "<br></br><br></br>",
            ba.XSTR("Secondary Weapon Shots", 121, false), "<br></br>",
            ba.XSTR("Secondary Weapon Hits", 122, false), "<br></br>",
            ba.XSTR("Secondary Friendly Hits", 123, false), "<br></br>",
            ba.XSTR("Secondary Hit %", 124, false), "<br></br>",
            ba.XSTR("Secondary Friendly Hit %", 125, false), "<br></br><br></br>",
            ba.XSTR("Assists", 126, false)
        }

        titles = table.concat(titles_table)

        local primary_hit_percent = math.floor((stats.MissionPrimaryShotsHit / stats.MissionPrimaryShotsFired) * 100) .. "%"
        local primary_fr_hit_percent = math.floor((stats.MissionPrimaryFriendlyHit / stats.MissionPrimaryShotsFired) * 100) .. "%"
        local secondary_hit_percent = math.floor((stats.MissionSecondaryShotsHit / stats.MissionSecondaryShotsFired) * 100) .. "%"
        local secondary_fr_hit_percent = math.floor((stats.MissionSecondaryFriendlyHit / stats.MissionSecondaryShotsFired) * 100) .. "%"

        --Zero out percentages if appropriate
        if stats.MissionPrimaryShotsHit == 0 then
            primary_hit_percent = 0 .. "%"
            primary_fr_hit_percent = 0 .. "%"
        end
        if stats.MissionSecondaryShotsHit == 0 then
            secondary_hit_percent = 0 .. "%"
            secondary_fr_hit_percent = 0 .. "%"
        end

        local numbers_table = {
            mission_time, "<br></br><br></br><br></br><br></br>",
            stats.MissionTotalKills, "<br></br><br></br>",
            stats.MissionPrimaryShotsFired, "<br></br>",
            stats.MissionPrimaryShotsHit, "<br></br>",
            stats.MissionPrimaryFriendlyHit, "<br></br>",
            primary_hit_percent, "<br></br>",
            primary_fr_hit_percent, "<br></br><br></br>",
            stats.MissionSecondaryShotsFired, "<br></br>",
            stats.MissionSecondaryShotsHit, "<br></br>",
            stats.MissionSecondaryFriendlyHit, "<br></br>",
            secondary_hit_percent, "<br></br>",
            secondary_fr_hit_percent, "<br></br><br></br>",
            stats.MissionAssists
        }

        numbers = table.concat(numbers_table)
    end

    if self.Page == 2 then
        local mission_kills_s = ba.XSTR("Mission Kills by Ship Type", 888562)
        titles = mission_kills_s .. "<br></br><br></br>"
        numbers = "<br></br><br></br>"

        for i = 1, #tb.ShipClasses do
            local kills = stats:getMissionShipclassKills(tb.ShipClasses[i])
            if kills > 0 then
                local name = Topics.ships.name:send(tb.ShipClasses[i])
                titles = titles .. name .. "<br></br><br></br>"
                numbers = numbers .. kills .. "<br></br><br></br>"
            end
        end
    end

    if self.Page == 3 then
        local titles_table = {
            ba.XSTR("All Time Stats", 128, false), "<br></br><br></br>",
            ba.XSTR("Total Kills", 115, false), "<br></br><br></br>",
            ba.XSTR("Primary Weapon Shots", 116, false), "<br></br>",
            ba.XSTR("Primary Weapon Hits", 117, false), "<br></br>",
            ba.XSTR("Primary Friendly Hits", 118, false), "<br></br>",
            ba.XSTR("Primary Hit %", 119, false), "<br></br>",
            ba.XSTR("Primary Friendly Hit %", 120, false), "<br></br><br></br>",
            ba.XSTR("Secondary Weapon Shots", 121, false), "<br></br>",
            ba.XSTR("Secondary Weapon Hits", 122, false), "<br></br>",
            ba.XSTR("Secondary Friendly Hits", 123, false), "<br></br>",
            ba.XSTR("Secondary Hit %", 124, false), "<br></br>",
            ba.XSTR("Secondary Friendly Hit %", 125, false), "<br></br><br></br>",
            ba.XSTR("Assists", 126, false)
        }

        titles = table.concat(titles_table)

        local primary_hit_percent = math.floor((stats.PrimaryShotsHit / stats.PrimaryShotsFired) * 100) .. "%"
        local primary_fr_hit_percent = math.floor((stats.PrimaryFriendlyHit / stats.PrimaryShotsFired) * 100) .. "%"
        local secondary_hit_percent = math.floor((stats.SecondaryShotsHit / stats.SecondaryShotsFired) * 100) .. "%"
        local secondary_fr_hit_percent = math.floor((stats.SecondaryFriendlyHit / stats.SecondaryShotsFired) * 100) .. "%"

        --Zero out percentages if appropriate
        if stats.MissionPrimaryShotsHit == 0 then
            primary_hit_percent = 0 .. "%"
            primary_fr_hit_percent = 0 .. "%"
        end
        if stats.MissionSecondaryShotsHit == 0 then
            secondary_hit_percent = 0 .. "%"
            secondary_fr_hit_percent = 0 .. "%"
        end

        local numbers_table = {
            "<br></br><br></br>",
            stats.TotalKills, "<br></br><br></br>",
            stats.PrimaryShotsFired, "<br></br>",
            stats.PrimaryShotsHit, "<br></br>",
            stats.PrimaryFriendlyHit, "<br></br>",
            primary_hit_percent, "<br></br>",
            primary_fr_hit_percent, "<br></br><br></br>",
            stats.SecondaryShotsFired, "<br></br>",
            stats.SecondaryShotsHit, "<br></br>",
            stats.SecondaryFriendlyHit, "<br></br>",
            secondary_hit_percent, "<br></br>",
            secondary_fr_hit_percent, "<br></br><br></br>",
            stats.Assists
        }

        numbers = table.concat(numbers_table)
    end

    if self.Page == 4 then
        titles = ba.XSTR( "All-time Kills by Ship Type", 448, false) .. "<br></br><br></br>"
        numbers = "<br></br><br></br>"

        for i = 1, #tb.ShipClasses do
            local kills = stats:getShipclassKills(tb.ShipClasses[i])
            if kills > 0 then
                local name = Topics.ships.name:send(tb.ShipClasses[i])
                titles = titles .. name .. "<br></br><br></br>"
                numbers = numbers .. kills .. "<br></br><br></br>"
            end
        end
    end

    --Actually write the stats data here
    local stats = self.Document:CreateElement("div")
    text_el:AppendChild(stats)
    local titles_el = self.Document:CreateElement("p")
    local numbers_el = self.Document:CreateElement("p")
    stats:AppendChild(titles_el)
    titles_el:SetClass("stats_left", true)
    stats:AppendChild(numbers_el)
    numbers_el:SetClass("stats_right", true)
    titles_el.inner_rml = titles
    numbers_el.inner_rml = numbers

end

--- Clears the current text in the debriefing window
--- @return nil
function DebriefingController:clearDebriefText()
    self.Document:GetElementById("debrief_text").inner_rml = ""
end

--- Start the the debriefing music after a 2.5 second wait
--- @return nil
function DebriefingController:startMusic()
    local filename = ui.Debriefing.getDebriefingMusicName()

    ScpuiSystem.data.memory.MusicHandle = ad.openAudioStream(filename, AUDIOSTREAM_MENUMUSIC)
    async.run(function()
        async.await(AsyncUtil.wait_for(2.5))
        ScpuiSystem.data.memory.MusicHandle:play(ad.MasterEventMusicVolume, true)
    end, async.OnFrameExecutor)
end

--- Handle the dialog response
--- @param response string The response from the dialog box
--- @return nil
function DebriefingController:dialogReponse(response)
    local switch = {
        accept = function()

            Topics.debrief.accept:send()

            self:close()
            ui.Debriefing.acceptMission()
			ScpuiSystem:maybePlayCutscene(MOVIE_POST_DEBRIEF)
        end,
        acceptquit = function()

            Topics.debrief.accept:send()

            self:close()
            ui.Debriefing.acceptMission(false)
			ScpuiSystem:maybePlayCutscene(MOVIE_POST_DEBRIEF)
            mn.unloadMission(true)
            ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
        end,
        replay = function()

            Topics.debrief.reject:send()

            self:close()
            ui.Debriefing.clearMissionStats()
            ui.Debriefing.replayMission()
        end,
        quit = function()

            Topics.debrief.reject:send()

            self:close()
            ui.Debriefing.clearMissionStats()
            ui.Debriefing.replayMission(false)
            mn.unloadMission(true)
            ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
        end,
        skip = function()

            Topics.debrief.accept:send()

            self:close()
            ui.Debriefing.acceptMission(false)
			ScpuiSystem:maybePlayCutscene(MOVIE_POST_DEBRIEF)
            ui.Briefing.skipMission()
        end,
        optout = function()
            self.Player.ShowSkipPopup = false
        end,
        cancel = function()
            --Do Nothing
        end,
    }

    if switch[response] then
        switch[response]()
    else
        switch["cancel"]()
    end
end

--- Return the character at a specific word index in a string
--- @param text string The text to search
--- @param index number The index of the word to search
--- @return string The character at the start of the word
function DebriefingController:getCharacterAtWord(text, index)

    local words = {}
    for word in text:gmatch("%S+") do table.insert(words, word) end

    if index > #words then index = #words end
    if index < 1 then index = 1 end

    return string.sub(words[index], 1, 1)

end

--- Creates the skip mission dialog box
--- @return nil
function DebriefingController:offerSkipDialog()
    local text = ba.XSTR("You have failed this mission five times.  If you like, you may advance to the next mission.", 888315)
    local title = ""
    --- @type dialog_button[]
    local buttons = {}



    buttons[1] = {
        Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
        Text = ba.XSTR("Do Not Skip This Mission", 888316),
        Value = "cancel",
        Keypress = self:getCharacterAtWord(ba.XSTR("Do Not Skip This Mission", 888316), 2)
    }
    buttons[2] = {
        Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
        Text = ba.XSTR("Advance To The Next Mission", 888318),
        Value = "skip",
        Keypress = self:getCharacterAtWord(ba.XSTR("Advance To The Next Mission", 888318), 1)
    }
    buttons[3] = {
        Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEUTRAL,
        Text = ba.XSTR("Don't Show Me This Again", 888320),
        Value = "optout",
        Keypress = self:getCharacterAtWord(ba.XSTR("Don't Show Me This Again", 888320), 1)
    }

    ---@type dialog_setup
    local params = {
        Title = title,
        Text = text,
        Buttons_List = buttons,
    }

    ScpuiSystem:showDialog(self, params, function(response)
        self:dialogReponse(response)
    end)
end

--- A paging button was pressed, so set the appropriate page
--- @param element Element The element that was pressed
--- @param command number The command that was pressed. Should be one of the PAGE_COMMAND enumerations
--- @return nil
function DebriefingController:page_pressed(element, command)
    if self.SelectedSection == DebriefingController.STATE_DEBRIEF then
        ui.playElementSound(element, "click", "failure")
        --FIXMEEEE
    else
        if command == self.PAGE_COMMAND_FIRST then
            self.Page = 1
        end
        if command == self.PAGE_COMMAND_LAST then
            self.Page = 4
        end
        if command == self.PAGE_COMMAND_PREV then
            self.Page = self.Page - 1
            if self.Page <= 0 then
                self.Page = 1
            end
        end
        if command == self.PAGE_COMMAND_NEXT then
            self.Page = self.Page + 1
            if self.Page >= 5 then
                self.Page = 4
            end
        end

        ui.playElementSound(element, "click", "success")
        self:clearDebriefText()
        self:buildStats()
    end
end

--- The debrief button was pressed so switch to the debrief text and restart the audio if it hasn't finished
--- @param element Element The element that was pressed
--- @return nil
function DebriefingController:debrief_pressed(element)
    if self.SelectedSection ~= DebriefingController.STATE_DEBRIEF then
        ui.playElementSound(element, "click", "success")
        self.Document:GetElementById("debrief_btn"):SetPseudoClass("checked", true)
        self.Document:GetElementById("stats_btn"):SetPseudoClass("checked", false)
        self.SelectedSection = DebriefingController.STATE_DEBRIEF

        self.Document:GetElementById("stage_select"):SetClass("hidden", true)
		self.Document:GetElementById("play_controls"):SetClass("hidden", false)

        self:clearDebriefText()
        self:buildText()

		if not self.AudioFinished then
			self:startAudio()
		end

        self.RecommendVisible = false
    end

    Topics.debrief.stateChanged:send(self)
end

--- The stats button was pressed so switch to the stats text
--- @param element Element The element that was pressed
--- @return nil
function DebriefingController:stats_pressed(element)
    if self.SelectedSection ~= DebriefingController.STATE_STATS then
        ui.playElementSound(element, "click", "success")
        self.Document:GetElementById("debrief_btn"):SetPseudoClass("checked", false)
        self.Document:GetElementById("stats_btn"):SetPseudoClass("checked", true)
        self.SelectedSection = DebriefingController.STATE_STATS

        self.Document:GetElementById("stage_select"):SetClass("hidden", false)
		self.Document:GetElementById("play_controls"):SetClass("hidden", true)

        self:clearDebriefText()
        self:stopVoice()
        self:buildStats()

        self.RecommendVisible = false
    end

    Topics.debrief.stateChanged:send(self)
end

--- The recommend button was pressed so toggle the recommendations on or off
--- @param element Element The element that was pressed
--- @return nil
function DebriefingController:recommend_pressed(element)
    ui.playElementSound(element, "click", "success")

    for i = 1, #self.RecommendationElements do
        self.RecommendationElements[i]:SetClass("hidden", self.RecommendVisible)
    end

    self.RecommendVisible = not self.RecommendVisible
end

--- The replay button was pressed so show a dialog box to confirm the replay of the mission
--- @param element Element The element that was pressed
--- @return nil
function DebriefingController:replay_pressed(element)
    ui.playElementSound(element, "click", "success")
    if ui.Debriefing:mustReplay() then
        ui.Debriefing.clearMissionStats()

        Topics.debrief.reject:send()

        self:close()
        ui.Debriefing.replayMission()
    else
        local text = ba.XSTR("If you choose to replay this mission, you will be required to complete it again before proceeding to future missions.\n\nIn addition, any statistics gathered during this mission will be discarded if you choose to replay.", 888322)
        text = string.gsub(text,"\n","<br></br>")
        local title = ""
        ---@type dialog_button[]
        local buttons = {}
        buttons[1] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
            Text = ba.XSTR("Cancel", 888091),
            Value = "cancel",
            Keypress = self:getCharacterAtWord(ba.XSTR("Cancel", 888091), 1)
        }
        buttons[2] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
            Text = ba.XSTR("Replay", 888325),
            Value = "replay",
            Keypress = self:getCharacterAtWord(ba.XSTR("Replay", 888325), 1)
        }

        ---@type dialog_setup
        local params = {
            Title = title,
            Text = text,
            Buttons_List = buttons,
        }

        ScpuiSystem:showDialog(self, params, function(response)
            self:dialogReponse(response)
        end)
    end
end

--- The accept mission button was pressed so accept the mission or show a dialog box if necessary instead
--- @param element Element The element that was pressed
--- @return nil
function DebriefingController:accept_pressed(element)
    if ui.Debriefing:mustReplay() then
        local text
        if ui.Debriefing.getTraitor() then
            text = ba.XSTR("Your career is over, Traitor!  You can't accept new missions!", 888327)
        else
            text = ba.XSTR("You have failed this mission and cannot accept.  What do you you wish to do instead?", 888328)
        end
        local title = ""
        ---@type dialog_button[]
        local buttons = {}
        buttons[1] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEUTRAL,
            Text = ba.XSTR("Return to Debriefing", 888329),
            Value = "cancel",
            Keypress = self:getCharacterAtWord(ba.XSTR("Return to Debriefing", 888329), 3)
        }
        buttons[2] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEUTRAL,
            Text = ba.XSTR("Go to Flight Deck", 888331),
            Value = "quit",
            Keypress = self:getCharacterAtWord(ba.XSTR("Go to Flight Deck", 888331), 1)
        }
        buttons[3] = {
            Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEUTRAL,
            Text = ba.XSTR("Replay Mission", 888058),
            Value = "replay",
            Keypress = self:getCharacterAtWord(ba.XSTR("Replay Mission", 888058), 1)
        }

        ---@type dialog_setup
        local params = {
            Title = title,
            Text = text,
            Buttons_List = buttons,
        }

        ScpuiSystem:showDialog(self, params, function(response)
            self:dialogReponse(response)
        end)
    else

        Topics.debrief.accept:send()

        self:close()
        ui.Debriefing.acceptMission()
		ScpuiSystem:maybePlayCutscene(MOVIE_POST_DEBRIEF)
    end
end

--- The medals button was clicked so switch to the medals game state
--- @param element Element The element that was pressed
--- @return nil
function DebriefingController:medals_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    self.SelectedSection = DebriefingController.STATE_NONE
    ba.postGameEvent(ba.GameEvents["GS_EVENT_VIEW_MEDALS"])
end

--- The options button was clicked so switch to the options game state
--- @param element Element The element that was pressed
--- @return nil
function DebriefingController:options_button_clicked(element)
    ui.playElementSound(element, "click", "success")
    self.SelectedSection = DebriefingController.STATE_NONE
    ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- The help button was clicked so toggle showing the help text
--- @param element Element The element that was pressed
--- @return nil
function DebriefingController:help_clicked(element)
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
function DebriefingController:global_keydown(element, event)
    local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()
        if ui.Debriefing:mustReplay() then
            local text = ba.XSTR("Because this mission was a failure, you must replay this mission when you continue your campaign.\n\nReturn to the Flight Deck?", 888335)
            text = string.gsub(text,"\n","<br></br>")
            local title = ""
            ---@type dialog_button[]
            local buttons = {}
            buttons[1] = {
                Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
                Text = ba.XSTR("No", 888298),
                Value = "cancel",
                Keypress = self:getCharacterAtWord(ba.XSTR("No", 888298), 1)
            }
            buttons[2] = {
                Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
                Text = ba.XSTR("Yes", 888296),
                Value = "quit",
                Keypress = self:getCharacterAtWord(ba.XSTR("Yes", 888296), 1)
            }

            --- @type dialog_setup
            local params = {
                Title = title,
                Text = text,
                Buttons_List = buttons,
            }

            ScpuiSystem:showDialog(self, params, function(response)
                self:dialogReponse(response)
            end)
        else
            local text = ba.XSTR("Accept this mission outcome?", 888340)
            local title = ""
            ---@type dialog_button[]
            local buttons = {}
            buttons[1] = {
                Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
                Text = ba.XSTR("Cancel", 888091),
                Value = "cancel",
                Keypress = self:getCharacterAtWord(ba.XSTR("Cancel", 888091), 1)
            }
            buttons[2] = {
                Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
                Text = ba.XSTR("Yes", 888296),
                Value = "acceptquit",
                Keypress = self:getCharacterAtWord(ba.XSTR("Yes", 888296), 1)
            }
            buttons[3] = {
                Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEUTRAL,
                Text = ba.XSTR("No, retry later", 888345),
                Value = "quit",
                Keypress = self:getCharacterAtWord(ba.XSTR("No, retry later", 888345), 1)
            }

            --- @type dialog_setup
            local params = {
                Title = title,
                Text = text,
                Buttons_List = buttons,
            }

            ScpuiSystem:showDialog(self, params, function(response)
                self:dialogReponse(response)
            end)
        end
    end
end

--- Close the debriefing controller, stop the audio, and unload the debriefing state
--- @return nil
function DebriefingController:close()
    if ScpuiSystem.data.memory.MusicHandle ~= nil and ScpuiSystem.data.memory.MusicHandle:isValid() then
        ScpuiSystem.data.memory.MusicHandle:close(false)
        ScpuiSystem.data.memory.MusicHandle = nil
    end
	self:unload()
    ScpuiSystem.data.state_init_status.Debrief = false
end

--- Called when the screen is being unloaded
--- @return nil
function DebriefingController:unload()
	self.SelectedSection = DebriefingController.STATE_NONE
    self:stopVoice()

	Topics.debrief.unload:send(self)
end

--Prevent the debriefing UI from being drawn if we're just going
--to skip it in a frame or two
ScpuiSystem:addHook("On Frame", function()
    if not mn.hasDebriefing() and not ui.isCutscenePlaying() then
        gr.clearScreen()
    end
end, {State="GS_STATE_DEBRIEF"}, function()
    return false
end)

return DebriefingController

