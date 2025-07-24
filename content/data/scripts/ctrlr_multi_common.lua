-----------------------------------
--Shared Controller for all Multi Controllers
-----------------------------------

local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

local Class = require("lib_class")

local AbstractMultiController = Class()

--- Enumerations for the current subclass attached
AbstractMultiController.CTRL_CLIENT_SETUP = 1 --- @type number The client setup enumeration
AbstractMultiController.CTRL_HOST_OPTIONS = 2 --- @type number The host options enumeration
AbstractMultiController.CTRL_HOST_SETUP = 3 --- @type number The host setup enumeration
AbstractMultiController.CTRL_JOIN_GAME = 4 --- @type number The join game enumeration
AbstractMultiController.CTRL_PAUSED = 5 --- @type number The paused enumeration
AbstractMultiController.CTRL_PXO_HELP = 6 --- @type number The PXO help enumeration
AbstractMultiController.CTRL_PXO = 7 --- @type number The PXO enumeration
AbstractMultiController.CTRL_START_GAME = 8 --- @type number The start game enumeration
AbstractMultiController.CTRL_SYNC = 9 --- @type number The sync enumeration
AbstractMultiController.CTRL_BRIEFING = 10 --- @type number The briefing enumeration
AbstractMultiController.CTRL_SHIP_SELECT = 11 --- @type number The ship select enumeration
AbstractMultiController.CTRL_WEAPON_SELECT = 12 --- @type number The weapon select enumeration

--- Enumerations for handling dialog responses
AbstractMultiController.DIALOG_MOTD = 1 --- @type number The message of the day enumeration
AbstractMultiController.DIALOG_JOIN_PRIVATE = 2 --- @type number The join private channel enumeration
AbstractMultiController.DIALOG_PLAYER_STATS = 3 --- @type number The player stats enumeration
AbstractMultiController.DIALOG_FIND_PLAYER = 4 --- @type number The find player enumeration
AbstractMultiController.DIALOG_FIND_PLAYER_RESPONSE = 5 --- @type number The find player response enumeration

--- Game States to Hook into
AbstractMultiController.GAME_STATE_HOOKS = {
	"GS_STATE_MULTI_CLIENT_SETUP",
	"GS_STATE_MULTI_HOST_OPTIONS",
	"GS_STATE_MULTI_HOST_SETUP",
	"GS_STATE_MULTI_JOIN_GAME",
	"GS_STATE_MULTI_PAUSED",
	"GS_STATE_PXO_HELP",
	"GS_STATE_PXO",
	"GS_STATE_START_GAME",
	"GS_STATE_MULTI_MISSION_SYNC",
	"GS_STATE_BRIEFING",
	"GS_STATE_SHIP_SELECT",
	"GS_STATE_WEAPON_SELECT"
}

--- Called by the class constructor
--- @return nil
function AbstractMultiController:init()
    self.Document = nil --- @type Document the RML document
    self.Subclass = nil --- @type number The current subclass attached. One of the CTRL_ enumerations
    self.ChatEl = nil --- @type Element the chat window element
    self.ChatInputEl = nil --- @type Element the chat input element
	self.SubmittedChatValue = "" --- @type string the submitted value from the chat input
    self.PlayersListEl = nil --- @type Element the players list element
    self.Player_Ids = {} --- @type string[] the list of player ids
    self.Player_List = {} --- @type scpui_multi_setup_player[] the list of players
    self.PlayerListCleared = nil --- @type boolean whether the player list has been cleared
    self.SelectedPlayerEl = nil --- @type Element the selected player element
    self.Team_Elements = {} --- @type Element[] list of team elements
    self.MissionsListEl = nil --- @type Element the missions list element
    self.MissionListCleared = nil --- @type boolean whether the mission list has been cleared
    self.Mission_Files = {} --- @type string[] list of mission files
	self.Missions_List = {} --- @type scpui_multi_setup_mission[] list of actual missions
    self.SelectedMissionEl = nil --- @type Element the selected mission element
    self.Games_Elements = {} --- @type string[] list of games element ids
	self.Games_List = {} --- @type scpui_multi_active_game[] list of games
	self.GamesListEl = nil --- @type Element the games list element
    self.Pxo_Players = {} --- @type  scpui_pxo_chat_player[] actual player entry
    self.SelectedPxoPlayer = nil --- @type scpui_pxo_chat_player the currently selected player
    self.PlayersEl = nil --- @type Element the players list element
	self.ChannelsEl = nil --- @type Element the channels list element
    self.Channels_List = {} --- @type scpui_pxo_channel[] actual channel entry
	self.Channel_Names = {} --- @type string[] list of channel names only
    self.SelectedPxoChannel = nil --- @type scpui_pxo_channel the currently selected channel
    self.CurrentChannel = nil --- @type scpui_pxo_channel the currently active channel
    self.CommonTextEl = nil --- @type Element the common text element
    self.StatusTextEl = nil --- @type Element the status text element
    self.Netgame = nil --- @type netgame the current netgame
    self.BannerFilename = "" --- @type string the current banner filename
	self.BannerWebUrl = "" --- @type string the current banner URL
	self.BannerImgBlob = "" --- @type string the current banner image blob
	self.BannerWidth = 0 --- @type number the current banner width
	self.BannerHeight = 0 --- @type number the current banner height
    self.BannerEl = nil --- @type Element the banner element
    self.SelfIsHost = nil --- @type boolean true if we are the host
    self.Countdown = nil --- @type number countdown time in seconds or -1 if countdown hasn't started
	self.CountdownStarted = nil --- @type boolean true if countdown has started
end

--- Called by the RML document
--- @param document Document
function AbstractMultiController:initialize(document)
    self.Document = document
end

--- Send the current input chat string to the server
--- @return nil
function AbstractMultiController:sendChat()
	if string.len(self.SubmittedChatValue) > 0 then
		if self.Subclass == self.CTRL_PXO then
			ui.MultiPXO.sendChat(self.SubmittedChatValue)
		else
			ui.MultiGeneral.sendChat(self.SubmittedChatValue)
		end
		self.ChatInputEl:SetAttribute("value", "")
		self.SubmittedChatValue = ""
	end
end

--- Get the player stats and display them in a dialog box
--- @param name string The name of player to get the stats for
--- @return nil
function AbstractMultiController:getPlayerStats(name)

	local stats = nil

	if self.Subclass == self.CTRL_PXO then
		stats = ui.MultiPXO.getPlayerStats(name)
	else
		stats = self:getPlayerByName(name).Entry:getStats()
	end

	ScpuiSystem.data.memory.multiplayer_general.DialogType = AbstractMultiController.DIALOG_PLAYER_STATS

	local text = self:initializeStatsText(stats)
	local title = name .. "'s stats"
	---@type dialog_button[]
	local buttons = {}
	buttons[1] = {
		Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
		Text = ba.XSTR("Okay", 888290),
		Value = "",
		Keypress = string.sub(ba.XSTR("Okay", 888290), 1, 1)
	}

	ScpuiSystem:showDialog(self, title, text, buttons, nil, nil, nil, nil, nil, function(response)
		ScpuiSystem.data.memory.multiplayer_general.DialogResponse = response
	end)
end

--- Add a heading to the player stats
--- @param text string The text to add as a heading
--- @return string text the stylized string
function AbstractMultiController:addHeadingElement(text)
	return "<span style=\"width: 49%; float: left; text-align: right;\">" .. text .. "</span><br></br>"
end

--- Add a value to the player stats
--- @param text string The name of the value
--- @param value string The value to add
--- @return string text the stylized string
function AbstractMultiController:addValueElement(text, value)
	local final = "<br></br><span style=\"width: 50%; float: left; text-align: right;\">" .. text .. "</span>"
	return final .. "<br></br><span style=\"width: 49%; float: right; padding-left: 1%;\">" .. value .. "</span>"
end

--- Add an empty line to the player stats
--- @return string text the stylized string
function AbstractMultiController:addEmptyLine()
    return "<br></br>"
end

--- Initialize the player stats text for display
--- @param stats scoring_stats The stats to display
--- @return string The formatted player stats string
function AbstractMultiController:initializeStatsText(stats)
    local stats_string = ""

    stats_string = stats_string .. self:addHeadingElement(ba.XSTR("All Time Stats", 128, false))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Primary Weapon Shots", 116, false), tostring(stats.PrimaryShotsFired))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Primary Weapon Hits", 117, false), tostring(stats.PrimaryShotsHit))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Primary Friendly Hits", 118, false), tostring(stats.PrimaryFriendlyHit))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Primary Hit %", 119, false), Utils.compute_percentage(stats.PrimaryShotsHit, stats.PrimaryShotsFired))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Primary Friendly Hit %", 120, false), Utils.compute_percentage(stats.PrimaryFriendlyHit, stats.PrimaryShotsFired))
    stats_string = stats_string .. self:addEmptyLine()

    stats_string = stats_string .. self:addValueElement(ba.XSTR("Secondary Weapon Shots", 121, false), tostring(stats.SecondaryShotsFired))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Secondary Weapon Hits", 122, false), tostring(stats.SecondaryShotsHit))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Secondary Friendly Hits", 123, false), tostring(stats.SecondaryFriendlyHit))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Secondary Hit %", 124, false), Utils.compute_percentage(stats.SecondaryShotsHit, stats.SecondaryShotsFired))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Secondary Friendly Hit %", 125, false), Utils.compute_percentage(stats.SecondaryFriendlyHit, stats.SecondaryShotsFired))
    stats_string = stats_string .. self:addEmptyLine()

    stats_string = stats_string .. self:addValueElement(ba.XSTR("Total Kills", 115, false), tostring(stats.TotalKills))
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Assists", 126, false), tostring(stats.Assists))
    stats_string = stats_string .. self:addEmptyLine()

    stats_string = stats_string .. self:addValueElement(ba.XSTR("Current Score:", 1583, false), tostring(stats.Score))
    stats_string = stats_string .. self:addEmptyLine()
    stats_string = stats_string .. self:addEmptyLine()

    stats_string = stats_string .. self:addHeadingElement(ba.XSTR("Kills by Ship Type", 64, false))
    local score_from_kills = 0
    for i = 1, #tb.ShipClasses do
        local ship_cls = tb.ShipClasses[i]
        local kills    = stats:getShipclassKills(ship_cls)

        if kills > 0 then
            local name = Topics.ships.name:send(ship_cls)
            score_from_kills = score_from_kills + kills * ship_cls.Score
            stats_string = stats_string .. self:addValueElement(name .. ":", tostring(kills))
        end
    end
    stats_string = stats_string .. self:addValueElement(ba.XSTR("Score from kills only:", 1636, false), tostring(score_from_kills))

	return stats_string
end

function AbstractMultiController:updateChat()
    local chat
    if self.Subclass == self.CTRL_PXO then
        chat = ui.MultiPXO.getChat()
    else
        chat = ui.MultiGeneral.getChat()
    end

	local txt = ""
	for i = 1, #chat do
		local line = ""
		if chat[i].Callsign ~= "" then
			line = chat[i].Callsign .. ": " .. chat[i].Message
		else
			line = chat[i].Message
		end
		txt = txt .. ScpuiSystem:replaceAngleBrackets(line) .. "<br></br>"
	end
	self.ChatEl.inner_rml = txt
	self.ChatEl.scroll_top = self.ChatEl.scroll_height
end

--- Enable or disable the team buttons based on the player's team
--- @param player scpui_multi_setup_player
--- @return nil
function AbstractMultiController:activateTeamButtons(player)
	self.Document:GetElementById("team_1_btn"):SetPseudoClass("checked", false)
	self.Document:GetElementById("team_2_btn"):SetPseudoClass("checked", false)
	if player.Team == 0 then
		self.Document:GetElementById("team_1_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("team_2_btn"):SetPseudoClass("checked", true)
	end

    if self.Subclass == self.CTRL_CLIENT_SETUP then
        if player.Entry:isSelf() then
            self.Document:GetElementById("player_team_lock"):SetClass("hidden", true)
        else
            self.Document:GetElementById("player_team_lock"):SetClass("hidden", false)
        end
    end
end

--- Remove a team element from the Team_Elements list
--- @param id string The id of the element to remove
--- @return nil
function AbstractMultiController:removeTeamElement(id)
	for i = 1, #self.Team_Elements do
		if self.Team_Elements[i].id == id then
			table.remove(self.Team_Elements, i)
			return
		end
	end
end

--- Remove a state element from the list
--- @param id string the id of the state element
--- @return nil
function AbstractMultiController:removeStateElement(id)
	for i = 1, #self.State_Elements do
		if self.State_Elements[i].id == id then
			table.remove(self.State_Elements, i)
			return
		end
	end
end

--- Update the player team
--- @param player scpui_multi_setup_player
--- @return nil
function AbstractMultiController:updateTeam(player)
	player.Team = player.Entry.Team
	self.Document:GetElementById(player.InternalId .. "_team").inner_rml = "Team" .. player.Team + 1
	self:activateTeamButtons(player)
end

--- Updates a player's state in the UI
--- @param player scpui_multi_setup_player the player to update
--- @return nil
function AbstractMultiController:updateState(player)
	player.State = player.Entry.State
	self.Document:GetElementById(player.InternalId .. "_state").inner_rml = player.State
end

--- Hide or show the team buttons
--- @param toggle boolean Whether to hide or show the team buttons
--- @return nil
function AbstractMultiController:hideTeamButtons(toggle)
	self.Document:GetElementById("team_1_cont"):SetClass("hidden", toggle)
	self.Document:GetElementById("team_2_cont"):SetClass("hidden", toggle)

	for i = 1, #self.Team_Elements do
		self.Team_Elements[i]:SetClass("hidden", toggle)
	end
end

--- Select a player from the player list and update the UI
--- @param player scpui_multi_setup_player
--- @return nil
function AbstractMultiController:selectPlayer(player)
	if self.SelectedPlayerEl then
		self.SelectedPlayerEl:SetPseudoClass("checked", false)
	end
	self.SelectedPlayerEl = self.Document:GetElementById(player.Key)
	self.SelectedPlayerEl:SetPseudoClass("checked", true)

    if self.Subclass ~= self.CTRL_SYNC then
	    self:activateTeamButtons(player)
    end
end

--- Create a player entry element and insert the entry into the Player_List table
--- @param entry scpui_multi_setup_player
--- @return Element li_el The created element
function AbstractMultiController:createPlayerEntry(entry)

	local li_el = self.Document:CreateElement("li")

	local name_el = self.Document:CreateElement("div")
	name_el:SetClass("player_name", true)
	name_el:SetClass("player_item", true)
	name_el.inner_rml = entry.Name
	li_el:AppendChild(name_el)

	local team_el = self.Document:CreateElement("div")
	team_el.id = entry.InternalId .. "_team"
	team_el:SetClass("player_team", true)
	team_el:SetClass("player_item", true)
	team_el.inner_rml = "Team" .. entry.Team + 1
	li_el:AppendChild(team_el)

	--These will eventually just change color or something I dunno
	local host = entry.Host
	local observer = entry.Observer
	local captain = entry.Captain

	li_el.id = entry.InternalId
	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:selectPlayer(entry)
	end)
	li_el:AddEventListener("dblclick", function(_, _, _)
		self:selectPlayer(entry)
	end)
	entry.Key = li_el.id

	table.insert(self.Player_List, entry)
	table.insert(self.Team_Elements, team_el)

	return li_el
end

--- Add a player to the Player_Ids list and the PlayersListEl
--- @param player scpui_multi_setup_player
--- @return nil
function AbstractMultiController:addPlayer(player)
	self.PlayersListEl:AppendChild(self:createPlayerEntry(player))
	table.insert(self.Player_Ids, player.InternalId)
end

--- Remove a player from the Player_Ids list and the PlayersListEl
--- @param idx number The index of the player to remove
--- @return nil
function AbstractMultiController:removePlayer(idx)
	local player_idx = self:getPlayerIndexByID(self.Player_Ids[idx])
	if player_idx > 0 then
		local el = self.Document:GetElementById(self.Player_List[player_idx].Key)
		--Also remove the team element to prevent an error later
		self:removeTeamElement(self.Player_Ids[idx] .. "_team")
		self.PlayersListEl:RemoveChild(el)
		table.remove(self.Player_List, player_idx)
	end
	table.remove(self.Player_Ids, idx)
end

--- Get the player index by ID
--- @param id string The ID to search for
--- @return number The index of the player
function AbstractMultiController:getPlayerIndexByID(id)
	for i = 1, #self.Player_List do
		if self.Player_List[i].InternalId == id then
			return i
		end
	end
	return -1
end

--- Check if the netgame type is squadwar and set the button accordingly
function AbstractMultiController:checkSquadwar()
	--Not actually sure what this button is for!
	if self.Netgame.Type == MULTI_TYPE_SQUADWAR then
		self.Document:GetElementById("squadwar_btn"):SetPseudoClass("checked", true)
	else
		self.Document:GetElementById("squadwar_btn"):SetPseudoClass("checked", false)
	end
end

--- Update the players list
--- @return nil
function AbstractMultiController:updatePlayersList()
    if #ui.MultiGeneral.NetPlayers == 0 then
		ScpuiSystem:clearEntries(self.PlayersListEl)
		self.PlayersListEl.inner_rml = "Loading Players..."
		self.PlayerListCleared = true
	else
		if self.PlayerListCleared then
			ScpuiSystem:clearEntries(self.PlayersListEl)
			self.PlayerListCleared = nil
		end
		-- check for new players
		for i = 1, #ui.MultiGeneral.NetPlayers do
			if ui.MultiGeneral.NetPlayers[i]:isValid() then

                -- Special path for the Multi Sync UI checking if we're the host
                if self.Subclass == self.CTRL_SYNC then
                    --if self.host is nil, then we need to check if we're the host
                    if self.SelfIsHost == nil then
                        if ui.MultiGeneral.NetPlayers[i]:isSelf() and ui.MultiGeneral.NetPlayers[i].Host then
                            self.SelfIsHost = true
                            self.Document:GetElementById("bottom_panel_a"):SetClass("hidden", false)
                            self.Document:GetElementById("bottom_panel_c"):SetClass("hidden", false)
                        end
                    end
                end

                -- Regular player updates
				local int_id = ui.MultiGeneral.NetPlayers[i].Name .. "_" .. i
				if not Utils.table.contains(self.Player_Ids, int_id) then
					---@type scpui_multi_setup_player
					local entry = {
						Name = ui.MultiGeneral.NetPlayers[i].Name,
						Team = ui.MultiGeneral.NetPlayers[i].Team,
						Host = ui.MultiGeneral.NetPlayers[i].Host,
						Observer = ui.MultiGeneral.NetPlayers[i].Observer,
						Captain = ui.MultiGeneral.NetPlayers[i].Captain,
						InternalId = int_id,
						Index = i,
						Entry = ui.MultiGeneral.NetPlayers[i]
					}
					self:addPlayer(entry)
				end
			end
		end

        if self.Subclass == self.CTRL_SYNC then
            -- if self.host is still nil then we are not the host
            if self.SelfIsHost == nil then
                self.SelfIsHost = false
            end
        end

		-- now check for players that expired
        --- @type string[]
		local players = {}

		-- create a simple table to use for comparing
		for i = 1, #ui.MultiGeneral.NetPlayers do
			table.insert(players, ui.MultiGeneral.NetPlayers[i].Name .. "_" .. i)
		end

		for i = 1, #self.Player_Ids do
			--remove it if it no longer exists on the server
			if not Utils.table.contains(players, self.Player_Ids[i]) then
				self:removePlayer(i)
			end
		end
	end
end

--- Get a player from the Player_List by key
--- @param key string The key to search for
--- @return scpui_multi_setup_player? player The player object
function AbstractMultiController:getPlayerByKey(key)
	for i = 1, #self.Player_List do
		if self.Player_List[i].Key == key then
			return self.Player_List[i]
		end
	end
end

--- Get a player from the Player_List by name
--- @param name string The name to search for
--- @return scpui_multi_setup_player? player The player object
function AbstractMultiController:getPlayerByName(name)
	for i = 1, #self.Player_List do
		if self.Player_List[i].Name == name then
			return self.Player_List[i]
		end
	end
end

--- Update the teams data for players and the UI
--- @return nil
function AbstractMultiController:updateTeams()
    if self.Subclass ~= self.CTRL_SYNC then
        if self.Netgame and self.Netgame.Type == MULTI_TYPE_TEAM then
            self:hideTeamButtons(false)
        else
            self:hideTeamButtons(true)
        end
    end

	--Update the player teams
	for i = 1, #self.Player_List do
		if self.Player_List[i].Team ~= self.Player_List[i].Entry.Team then
			self:updateTeam(self.Player_List[i])
		end
	end
end

--- Update the states data for players and the UI
--- @return nil
function AbstractMultiController:updateStates()
    --Update the player states
	for i = 1, #self.Players_List do
		if self.Players_List[i].State ~= self.Players_List[i].Entry.State then
			self:updateState(self.Players_List[i])
		end
	end
end

--- Creates a mission entry element
--- @param entry scpui_multi_setup_mission The mission to create an element for
--- @return Element mission The created element
function AbstractMultiController:createMissionEntry(entry)

	local li_el = self.Document:CreateElement("li")

	local type_el = self.Document:CreateElement("div")
	type_el:SetClass("type", true)
	type_el:SetClass("mission_item", true)
	if entry.Type == MULTI_TYPE_COOP then
		type_el.inner_rml = "co-op"
	elseif entry.Type == MULTI_TYPE_TEAM then
		type_el.inner_rml = "team"
	elseif entry.Type == MULTI_TYPE_DOGFIGHT then
		type_el.inner_rml = "dogfight"
	end
	li_el:AppendChild(type_el)

	local builtin_el = self.Document:CreateElement("div")
	builtin_el:SetClass("mission_builtin", true)
	builtin_el:SetClass("mission_item", true)
	if entry.Builtin then
		builtin_el.inner_rml = "*"
	else
		builtin_el.inner_rml = ""
	end
	li_el:AppendChild(builtin_el)

	local validity_el = self.Document:CreateElement("div")
	validity_el:SetClass("mission_validity", true)
	validity_el:SetClass("mission_item", true)
	if entry.Builtin then
		validity_el.inner_rml = "X"
	else
		validity_el.inner_rml = ""
	end
	li_el:AppendChild(validity_el)

	local name_el = self.Document:CreateElement("div")
	name_el:SetClass("mission_name", true)
	name_el:SetClass("mission_item", true)
	name_el.inner_rml = entry.Name
	li_el:AppendChild(name_el)

	local players_el = self.Document:CreateElement("div")
	players_el:SetClass("mission_players", true)
	players_el:SetClass("mission_item", true)
	players_el.inner_rml = tostring(entry.Players)
	li_el:AppendChild(players_el)

	local filename_el = self.Document:CreateElement("div")
	filename_el:SetClass("mission_filename", true)
	filename_el:SetClass("mission_item", true)
	filename_el.inner_rml = entry.Filename
	li_el:AppendChild(filename_el)

	li_el.id = entry.InternalId
	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:selectMission(entry)
	end)
	li_el:AddEventListener("dblclick", function(_, _, _)
		self:selectMission(entry)
	end)
	entry.Key = li_el.id

	table.insert(self.Missions_List, entry)

	return li_el
end

--- Select a mission element
--- @param mission scpui_multi_setup_mission The mission to select
--- @return nil
function AbstractMultiController:selectMission(mission)
	if self.SelectedMissionEl then
		self.SelectedMissionEl:SetPseudoClass("checked", false)
	end
	self.SelectedMissionEl = self.Document:GetElementById(mission.Key)
	self.SelectedMissionEl:SetPseudoClass("checked", true)
	self.Netgame:setMission(mission.Entry)
end

--- Get the index of a mission by its ID
--- @param id string The ID of the mission
--- @return number index The index of the mission
function AbstractMultiController:getMissionIndexByID(id)
	for i = 1, #self.Missions_List do
		if self.Missions_List[i].InternalId == id then
			return i
		end
	end
	return -1
end

--- Add a mission entry to the list and the UI
--- @param mission scpui_multi_setup_mission The mission to add
--- @return nil
function AbstractMultiController:addMission(mission)
	self.MissionsListEl:AppendChild(self:createMissionEntry(mission))
	table.insert(self.Mission_Files, mission.InternalId)

	if mission.Filename == self.Netgame.MissionFilename then
		self:selectMission(mission)
	end
end

--- Remove a mission entry from the list and the UI
--- @param idx number The index of the mission to remove
--- @return nil
function AbstractMultiController:removeMission(idx)
	local mission_idx = self:getMissionIndexByID(self.Mission_Files[idx])
	if mission_idx > 0 then
		if self.SelectedMissionEl and self.SelectedMissionEl.id == self.Missions_List[mission_idx].Key then
			self.SelectedMissionEl = nil
		end
		local el = self.Document:GetElementById(self.Missions_List[mission_idx].Key)
		self.MissionsListEl:RemoveChild(el)
		table.remove(self.Missions_List, mission_idx)
	end
	table.remove(self.Mission_Files, idx)
end

--- Update the missions list for the UI
--- @return nil
function AbstractMultiController:updateMissions()
    local list = ui.MultiHostSetup.NetMissions

	if ScpuiSystem.data.memory.multiplayer_host.HostList ~= "missions" then
		list = ui.MultiHostSetup.NetCampaigns
	end

	if #list == 0 then
		ScpuiSystem:clearEntries(self.MissionsListEl)
		self.MissionsListEl.inner_rml = "Loading Mission List..."
		self.MissionListCleared = true
	else
		if self.MissionListCleared then
			ScpuiSystem:clearEntries(self.MissionsListEl)
			self.MissionsListEl.inner_rml = ""
			self.MissionListCleared = nil
		end
		-- check for new missions
		for i = 1, #list do
			local int_id = list[i].Filename .. "_" .. i
			local add_entry = true
			if ScpuiSystem.data.memory.multiplayer_host.HostFilter then
				if list[i].Type == ScpuiSystem.data.memory.multiplayer_host.HostFilter then
					add_entry = true
				else
					add_entry = false
				end
			end
			if add_entry and not Utils.table.contains(self.Mission_Files, int_id) then
				---@type scpui_multi_setup_mission
				local entry = {
					Filename = list[i].Filename,
					Name = list[i].Name,
					Players = list[i].Players,
					Respawn = list[i].Respawn,
					Tracker = list[i].Tracker,
					Type = list[i].Type,
					Builtin = list[i].Builtin,
					InternalId = int_id,
					Index = i,
					Entry = list[i]
				}
				self:addMission(entry)
			end
		end

		-- now check for missions that expired
		local missions = {}

		-- create a simple table to use for comparing
		for i = 1, #list do
			table.insert(missions, list[i].Filename .. "_" .. i)
		end

		for i = 1, #self.Mission_Files do
			--remove it if it no longer exists on the server
			if not Utils.table.contains(missions, self.Mission_Files[i]) then
				self:removeMission(i)
			end
		end
	end
end

--- Create a game entry element
--- @param entry scpui_multi_active_game
--- @return Element el the created element
function AbstractMultiController:createGameEntry(entry)

	local li_el = self.Document:CreateElement("li")

	local status_el = self.Document:CreateElement("div")
	status_el:SetClass("game_status", true)
	status_el:SetClass("game_item", true)
	status_el.inner_rml = entry.Status
	li_el:AppendChild(status_el)

	local type_el = self.Document:CreateElement("div")
	type_el:SetClass("game_type", true)
	type_el:SetClass("game_item", true)
	type_el.inner_rml = entry.Type
	li_el:AppendChild(type_el)

	local server_el = self.Document:CreateElement("div")
	server_el:SetClass("game_server", true)
	server_el:SetClass("game_item", true)
	server_el.inner_rml = entry.Server
	li_el:AppendChild(server_el)

	local players_el = self.Document:CreateElement("div")
	players_el:SetClass("game_players", true)
	players_el:SetClass("game_item", true)
	players_el.inner_rml = tostring(entry.Players)
	li_el:AppendChild(players_el)

	local ping_el = self.Document:CreateElement("div")
	ping_el:SetClass("game_ping", true)
	ping_el:SetClass("game_item", true)
	ping_el.inner_rml = entry.Ping .. "ms"
	li_el:AppendChild(ping_el)

	li_el.id = entry.Server .. entry.InternalId
	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:selectGame(entry)
	end)
	li_el:AddEventListener("dblclick", function(_, _, _)
		self:selectGame(entry)
		ui.MultiJoinGame.sendJoinRequest()
	end)
	entry.Key = li_el.id

	table.insert(self.Games_List, entry)

	return li_el
end

--- Select a game element
--- @param game scpui_multi_active_game
--- @return nil
function AbstractMultiController:selectGame(game)
	if self.selected_game then
		self.selected_game:SetPseudoClass("checked", false)
	end
	self.selected_game = self.Document:GetElementById(game.Key)
	self.selected_game:SetPseudoClass("checked", true)
	ui.MultiJoinGame.ActiveGames[game.Index]:setSelected()
end

--- Add a game to the list and UI
--- @param game scpui_multi_active_game
--- @return nil
function AbstractMultiController:addGame(game)
	self.GamesListEl:AppendChild(self:createGameEntry(game))
	table.insert(self.Games_Elements, game.InternalId)
end

--- Remove a game from the list and UI
--- @param idx number the index of the game to remove
--- @return nil
function AbstractMultiController:removeGame(idx)
	local game_idx = self:getGameIndexByID(self.Games_Elements[idx])
	if game_idx > 0 then
		local el = self.Document:GetElementById(self.Games_List[game_idx].Key)
		self.GamesListEl:RemoveChild(el)
		table.remove(self.Games_List, game_idx)
	end
	table.remove(self.Games_Elements, idx)
end

--- Get a game index by its internal ID
--- @param id string the internal ID of the game
--- @return number the index of the game
function AbstractMultiController:getGameIndexByID(id)
	for i = 1, #self.Games_List do
		if self.Games_List[i].InternalId == id then
			return i
		end
	end
	return -1
end

--- Update the active games list for the UI
--- @return nil
function AbstractMultiController:updateActiveGames()
    if #ui.MultiJoinGame.ActiveGames == 0 then
		ScpuiSystem:clearEntries(self.GamesListEl)
		self.GamesListEl.inner_rml = "[No game servers found]"
		self.cleared = true
	else
		if self.cleared then
			ScpuiSystem:clearEntries(self.GamesListEl)
			self.cleared = nil
		end
		-- check for new games
		for i = 1, #ui.MultiJoinGame.ActiveGames do
			local int_id = ui.MultiJoinGame.ActiveGames[i].Server .. "_" .. i
			if not Utils.table.contains(self.Games_Elements, int_id) then
				--- @type scpui_multi_active_game
				local entry = {
					Status = ui.MultiJoinGame.ActiveGames[i].Status,
					Type = ui.MultiJoinGame.ActiveGames[i].Type,
					Speed = ui.MultiJoinGame.ActiveGames[i].Speed,
					Standalone = ui.MultiJoinGame.ActiveGames[i].Standalone,
					Campaign = ui.MultiJoinGame.ActiveGames[i].Campaign,
					Server = ui.MultiJoinGame.ActiveGames[i].Server,
					Mission = ui.MultiJoinGame.ActiveGames[i].Mission,
					Ping = ui.MultiJoinGame.ActiveGames[i].Ping,
					Players = ui.MultiJoinGame.ActiveGames[i].Players,
					InternalId = int_id,
					Index = i
				}
				self:addGame(entry)
			end
		end

		-- now check for games that expired
		local games = {}

		-- create a simple table to use for comparing
		for i = 1, #ui.MultiJoinGame.ActiveGames do
			table.insert(games, ui.MultiJoinGame.ActiveGames[i].Server .. "_" .. i)
		end

		for i = 1, #self.Games_Elements do
			if not Utils.table.contains(games, self.Games_Elements[i]) then
				self:removeGame(i)
			end
		end
	end
end

--- Selects a player in the UI list and unselects the previous one
--- @param player scpui_pxo_chat_player the player to select
--- @return nil
function AbstractMultiController:selectPxoPlayer(player)
	if self.SelectedPxoPlayer ~= nil then
		self.Document:GetElementById(self.SelectedPxoPlayer.Key):SetPseudoClass("checked", false)
	end
	self.SelectedPxoPlayer = player
	self.Document:GetElementById(player.Key):SetPseudoClass("checked", true)
end

--- Create a player entry in the UI list
--- @param entry scpui_pxo_chat_player the player to create an entry for
--- @return Element li_el the created element
function AbstractMultiController:createPxoPlayerEntry(entry)

	local li_el = self.Document:CreateElement("li")

	li_el.inner_rml = "<span>" .. entry.Name .. "</span>"
	li_el.id = entry.Name
	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:selectPxoPlayer(entry)
	end)
	li_el:AddEventListener("dblclick", function(_, _, _)
		self:getPlayerStats(entry.Name)
	end)
	entry.Key = li_el.id

	table.insert(self.Pxo_Players, entry)

	return li_el
end

--- Adds a player to the names table and the UI list
--- @param player scpui_pxo_chat_player the player to add
--- @return nil
function AbstractMultiController:addPxoPlayer(player)
	self.PlayersEl:AppendChild(self:createPxoPlayerEntry(player))
	table.insert(self.Player_Ids, player.Name)
end

--- Removes a player from the names table and the UI list by index
--- @param idx number the index of the player to remove
--- @return nil
function AbstractMultiController:removePxoPlayer(idx)
	local plr_idx = self:getPlayerIndexByName(self.Player_Ids[idx])
	if plr_idx > 0 then
		local el = self.Document:GetElementById(self.Pxo_Players[plr_idx].Key)
		self.PlayersEl:RemoveChild(el)
		table.remove(self.Pxo_Players, plr_idx)
	end
	table.remove(self.Player_Ids, idx)
end

--- Get the index of a player in the table by name
--- @param name string the name of the player to find
--- @return number index the index of the player in the table
function AbstractMultiController:getPlayerIndexByName(name)
	for i = 1, #self.Pxo_Players do
		if self.Pxo_Players[i].Name == name then
			return i
		end
	end
	return -1
end

--- Update the PXO Players list
--- @return nil
function AbstractMultiController:updatePxoPlayers()
    local players = ui.MultiPXO.getPlayers()

	-- check for new players
	for i = 1, #players do
		if not Utils.table.contains(self.Player_Ids, players[i]) then
			--- @type scpui_pxo_chat_player
			local entry = {
				Name = players[i]
			}
			self:addPxoPlayer(entry)
		end
	end

	-- now check for players that left
	for i = 1, #self.Player_Ids do
		if not Utils.table.contains(players, self.Player_Ids[i]) then
			self:removePxoPlayer(i)
		end
	end
end

--- Set the selected channel as checked on the UI and unselect the previous one
--- @param channel scpui_pxo_channel the channel to select
--- @return nil
function AbstractMultiController:selectChannel(channel)
	if self.SelectedPxoChannel ~= nil then
		self.Document:GetElementById(self.SelectedPxoChannel.Key):SetPseudoClass("checked", false)
	end
	self.SelectedPxoChannel = channel
	self.Document:GetElementById(channel.Key):SetPseudoClass("checked", true)
end

--- Join a chat channel
--- @param entry scpui_pxo_channel the channel to join
--- @return nil
function AbstractMultiController:joinChannel(entry)
	for i = 1, #ui.MultiPXO.Channels do
		if ui.MultiPXO.Channels[i].Name == entry.Name then
			if not ui.MultiPXO.Channels[i]:isCurrent() then
				ui.MultiPXO.Channels[i]:joinChannel()
			end
			return
		end
	end
end

--- Create a channel entry in the UI list
--- @param entry scpui_pxo_channel the channel to create an entry for
--- @return Element li_el the created element
function AbstractMultiController:createChannelEntry(entry)

	local li_el = self.Document:CreateElement("li")

	local name_el = self.Document:CreateElement("div")
	name_el:SetClass("channel_name", true)
	name_el.inner_rml = entry.Name

	local players_el = self.Document:CreateElement("div")
	players_el:SetClass("channel_players", true)
	players_el.inner_rml = tostring(entry.NumPlayers)

	local games_el = self.Document:CreateElement("div")
	games_el:SetClass("channel_games", true)
	games_el.inner_rml = tostring(entry.NumGames)

	li_el:AppendChild(name_el)
	li_el:AppendChild(players_el)
	li_el:AppendChild(games_el)

	li_el.id = entry.Name
	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:selectChannel(entry)
	end)
	li_el:AddEventListener("dblclick", function(_, _, _)
		self:joinChannel(entry)
	end)

	if entry.IsCurrent == true then
		li_el:SetPseudoClass("active", true)
		self.CurrentChannel = entry
	end
	entry.Key = li_el.id

	table.insert(self.Channels_List, entry)

	return li_el
end

--- Adds a channel to the names table and the UI list
--- @param channel scpui_pxo_channel the channel to add
--- @return nil
function AbstractMultiController:addChannel(channel)
	self.ChannelsEl:AppendChild(self:createChannelEntry(channel))
	table.insert(self.Channel_Names, channel.Name)
end

--- Removes a channel from the names table and the UI list by index
--- @param idx number the index of the channel to remove
--- @return nil
function AbstractMultiController:removeChannel(idx)
	local chnl_idx = self:getChannelIndexByName(self.Channel_Names[idx])
	if chnl_idx > 0 then
		local el = self.Document:GetElementById(self.Channels_List[chnl_idx].Key)
		self.ChannelsEl:RemoveChild(el)
		table.remove(self.Channels_List, chnl_idx)
	end
	table.remove(self.Channel_Names, idx)
end

--- Updates a channel in the UI list with the latest data
--- @param channel pxo_channel the channel to update
--- @return nil
function AbstractMultiController:updateChannel(channel)
	local idx = self:getChannelIndexByName(channel.Name)
	if idx > 0 then
		local el = self.Document:GetElementById(self.Channels_List[idx].Key)
		local players_el = el.first_child.next_sibling
		local games_el = el.first_child.next_sibling.next_sibling

		if channel:isCurrent() == true then
			if self.CurrentChannel ~= nil then
				self.Document:GetElementById(self.CurrentChannel.Key):SetPseudoClass("active", false)
			end
			el:SetPseudoClass("active", true)
			self.CurrentChannel = self.Channels_List[idx]
		else
			el:SetPseudoClass("active", false)
		end

		if players_el.inner_rml ~= channel.NumPlayers then
			players_el.inner_rml = tostring(channel.NumPlayers)
		end

		if games_el.inner_rml ~= tostring(channel.NumGames) then
			games_el.inner_rml = tostring(channel.NumGames)
		end
	end
end

--- Get the index of a channel in the table by name
--- @param name string the name of the channel to find
--- @return number index the index of the channel in the table
function AbstractMultiController:getChannelIndexByName(name)
	for i = 1, #self.Channels_List do
		if self.Channels_List[i].Name == name then
			return i
		end
	end
	return -1
end

--- Update the PXO Channels list
--- @return nil
function AbstractMultiController:updatePxoChannels()
    -- check for new channels
	for i = 1, #ui.MultiPXO.Channels do
		if not Utils.table.contains(self.Channel_Names, ui.MultiPXO.Channels[i].Name) then
			--- @type scpui_pxo_channel
			local entry = {
				Name = ui.MultiPXO.Channels[i].Name,
				NumPlayers = ui.MultiPXO.Channels[i].NumPlayers,
				NumGames = ui.MultiPXO.Channels[i].NumGames,
				IsCurrent = ui.MultiPXO.Channels[i]:isCurrent()
			}
			self:addChannel(entry)
		else
			self:updateChannel(ui.MultiPXO.Channels[i])
		end
	end

	-- now check for channels that were removed
	local channels = {}

	-- create a simple table to use for comparing
	for i = 1, #ui.MultiPXO.Channels do
		table.insert(channels, ui.MultiPXO.Channels[i].Name)
	end

	for i = 1, #self.Channel_Names do
		if not Utils.table.contains(channels, self.Channel_Names[i]) then
			self:removeChannel(i)
		end
	end
end

--- Converts the banner image to a blob for display
function AbstractMultiController:convertBanner()
	local imag_h = gr.loadTexture(self.BannerFilename)
	self.BannerWidth = imag_h:getWidth()
	self.BannerHeight = imag_h:getHeight()
	local tex_h = gr.createTexture(self.BannerWidth, self.BannerHeight)
	gr.setTarget(tex_h)
	gr.clearScreen(0,0,0,0)
	gr.drawImage(imag_h, 0, 0, self.BannerWidth, self.BannerHeight, 0, 1, 1, 0, 1)
	self.BannerImgBlob = gr.screenToBlob()

	--clean up
	gr.setTarget()
	tex_h:destroyRenderTarget()
	imag_h:unload()
	tex_h:unload()
end

--- When the banner is clicked, open the URL in the player's browser
--- @return nil
function AbstractMultiController:bannerClicked()
	ui.launchURL(self.BannerWebUrl)
end

--- Update the PXO Banner and MOTD
--- @return nil
function AbstractMultiController:updatePxoBanner()
    if self.BannerFilename ~= ui.MultiPXO.bannerFilename then
		self.BannerFilename = ui.MultiPXO.bannerFilename
		self.BannerWebUrl = ui.MultiPXO.bannerURL

		if string.len(self.BannerFilename) > 0 then
			self:convertBanner()

			self.BannerEl.style.width = self.BannerWidth .. "px"
			self.BannerEl.style.height = self.BannerHeight .. "px"

			ScpuiSystem:clearEntries(self.BannerEl)

			local img_el = self.Document:CreateElement("img")
			img_el:SetAttribute("src", self.BannerImgBlob)
			img_el:AddEventListener("click", function(_, _, _)
				self:bannerClicked()
			end)
			self.BannerEl:AppendChild(img_el)
		end
	end
end

--- Called when the countdown begins and updates the UI
--- @return nil
function AbstractMultiController:countdownBegins()
	if self.CountdownStarted then
		return
	end

	local ani_el = self.Document:CreateElement("ani")
    ani_el:SetAttribute("src", "countdown.png")
	self.Document:GetElementById("countdown"):AppendChild(ani_el)
	ui.disableInput() --Probably need to still allow chat.. but :shrug:
	self.CountdownStarted = true
end

--- Update the countdown timer
--- @return nil
function AbstractMultiController:updateCountdown()
    --get the current countdown, if any
	self.Countdown = ui.MultiSync:getCountdownTime()

    if self.Countdown and self.Countdown > 0 then
		self:countdownBegins()
	end
end

--- Update the loadout locked button
--- @return nil
function AbstractMultiController:updateLoadoutLocked()
	local locked_el = self.Document:GetElementById("lock_btn")
	if not locked_el then
		return
	end
	if ui.MultiGeneral.getNetGame().Locked == true then
		locked_el:SetPseudoClass("checked", true)
	else
		locked_el:SetPseudoClass("checked", false)
	end
end

--- Update the loadouts from the server
--- @return nil
function AbstractMultiController:updateLoadouts()
	 assert(ScpuiSystem.data.memory.multiplayer_general.LoadoutContext, "Loadout context is nil")

	 ScpuiSystem.data.memory.multiplayer_general.LoadoutContext:update()
	 if self.Subclass == self.CTRL_SHIP_SELECT then
		ScpuiSystem.data.memory.multiplayer_general.Context:updateShipPool()
		ScpuiSystem.data.memory.multiplayer_general.Context:updateSlots()
	 elseif self.Subclass == self.CTRL_WEAPON_SELECT then
		ScpuiSystem.data.memory.multiplayer_general.Context:updateShipSlots()
		ScpuiSystem.data.memory.multiplayer_general.Context:updateUiElements()
	 end
end

AbstractMultiController.UpdateSwitch = function(self)
    return {
        [AbstractMultiController.CTRL_CLIENT_SETUP] = function()
            ui.MultiClientSetup.runNetwork()
            self:updateChat()
            self:updatePlayersList()
            self:updateTeams()
            self:checkSquadwar()
        end,
        [AbstractMultiController.CTRL_HOST_OPTIONS] = function()
            ui.MultiHostSetup.runNetwork()
            self:updateChat()
        end,
        [AbstractMultiController.CTRL_HOST_SETUP] = function()
            ui.MultiHostSetup.runNetwork()
            self:updateChat()
            self:updateMissions()
            self:updatePlayersList()
            self:updateTeams()
        end,
        [AbstractMultiController.CTRL_JOIN_GAME] = function()
            ui.MultiJoinGame.runNetwork()
            self:updateActiveGames()
        end,
        [AbstractMultiController.CTRL_PAUSED] = function()
            ui.MultiPauseScreen.runNetwork()
            self:updateChat()
        end,
        [AbstractMultiController.CTRL_PXO_HELP] = function()
            ui.MultiPXO.runNetwork()
        end,
        [AbstractMultiController.CTRL_PXO] = function()
            ui.MultiPXO.runNetwork()
            self:updateChat()
            self:updatePxoPlayers()
            self:updatePxoChannels()
            self:updatePxoBanner()

            local motd = ui.MultiPXO.MotdText
            -- Replace new lines with break tags
            self.Motd = motd:gsub("\n", "<br></br>")
        end,
        [AbstractMultiController.CTRL_START_GAME] = function()
            ui.MultiStartGame.runNetwork()
        end,
        [AbstractMultiController.CTRL_SYNC] = function()
            ui.MultiSync.runNetwork()
            self:updateChat()
            self:updatePlayersList()
            self:updateTeams()
        end,
		[AbstractMultiController.CTRL_BRIEFING] = function()
			self:updateChat()
			self:updateLoadoutLocked()
		end,
		[AbstractMultiController.CTRL_SHIP_SELECT] = function()
			self:updateChat()
			self:updateLoadoutLocked()
			self:updateLoadouts()
		end,
		[AbstractMultiController.CTRL_WEAPON_SELECT] = function()
			self:updateChat()
			self:updateLoadoutLocked()
			self:updateLoadouts()
		end,
    }
end

--- Runs the network commands to update all relevant UI elements.
--- Runs continuously every frame as long as the previous loop has finished.
--- @return nil
function AbstractMultiController:updateLists()
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = false
    local switch = AbstractMultiController.UpdateSwitch(self)
    if switch[self.Subclass] then
        switch[self.Subclass]()
    else
        error("Invalid subclass: " .. tostring(self.Subclass))
    end

	--Select the first player
	if self.SelectedPlayerEl == nil and #self.Player_List > 0 then
		self:selectPlayer(self.Player_List[1])
	end

    --Select the first mission
	if self.Netgame and self.SelectedMissionEl == nil and #self.Missions_List > 0 then
		self:selectMission(self.Missions_List[1])
	end

    --Update the common text string
    if self.CommonTextEl then
        self.CommonTextEl.inner_rml = string.gsub(ui.MultiGeneral.InfoText, "\n", "<br></br>")
    end

    if self.StatusTextEl then
        if self.Subclass == self.CTRL_PXO then
            self.StatusTextEl.inner_rml = ui.MultiPXO.StatusText
        else
            self.StatusTextEl.inner_rml = ui.MultiGeneral.StatusText
        end
    end

	--Check for dialog responses
	if ScpuiSystem.data.memory.multiplayer_general.DialogResponse then
		self:dialogResponse()
	end
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
end

--- During multiplayer run the network functions every frame
for _, v_statename in ipairs(AbstractMultiController.GAME_STATE_HOOKS) do
	ScpuiSystem:addHook("On Frame", function()
		if ScpuiSystem.data.memory.multiplayer_general.RunNetwork then
			ScpuiSystem.data.memory.multiplayer_general.Context:updateLists()
		end
	end, {State=v_statename}, function()
		return false
	end)
end

return AbstractMultiController