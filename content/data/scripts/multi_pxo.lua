local rocket_utils = require("rocket_util")
local topics = require("ui_topics")
local class = require("class")
local async_util = require("async_util")
local utils = require("utils")
local dialogs = require("dialogs")

local PXOController = class(AbstractBriefingController)

function PXOController:init()
	self.players = {} -- actual player entry
	self.playersList = {} -- list of player names only
	self.channels = {} -- actual channel entry
	self.channelsList = {} -- list of channel names only
	
	self.submittedValue = "" -- the player's text input
end

function PXOController:initialize(document)
	
	self.document = document
	
	---Load background choice
	self.document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)
	
	---Load the desired font size from the save file
	self.document:GetElementById("main_background"):SetClass(("p1-" .. ScpuiSystem:getFontSize()), true)
	
	self.players_el = self.document:GetElementById("players_list_ul")
	self.channels_el = self.document:GetElementById("channels_list_ul")
	self.chat_el = self.document:GetElementById("chat_window")
	self.banner_el = self.document:GetElementById("banner_div")
	
	self.input_id = self.document:GetElementById("chat_input")
	self.motd = ""
	
	if not ScpuiSystem.MultiReady then
		ui.MultiPXO.initPXO()
	end
	
	ScpuiSystem.MultiReady = true
	
	self:updateLists()
	
	--topics.multipxo.initialize:send(self)

end

function PXOController:SelectChannel(channel)
	if self.selectedChannel ~= nil then
		self.document:GetElementById(self.selectedChannel.key):SetPseudoClass("checked", false)
	end
	self.selectedChannel = channel
	self.document:GetElementById(channel.key):SetPseudoClass("checked", true)
end

function PXOController:joinChannel(entry)
	for i = 1, #ui.MultiPXO.Channels do
		if ui.MultiPXO.Channels[i].Name == entry.Name then
			if not ui.MultiPXO.Channels[i]:isCurrent() then
				ui.MultiPXO.Channels[i]:joinChannel()
			end
			return
		end
	end
end

function PXOController:joinPublicPressed()
	if self.selectedChannel then
		self:joinChannel(self.selectedChannel)
	end
end

function PXOController:joinPrivatePressed()
	self.promptControl = 2

	local text = "Enter the name of the private channel to join"
	local title = "Join Private Channel"
	local buttons = {}
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Okay", -1),
		b_value = "",
		b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
	}
	
	self:Show(text, title, true, buttons)
end

function PXOController:CreateChannelEntry(entry)
	
	local li_el = self.document:CreateElement("li")

	local name_el = self.document:CreateElement("div")
	name_el:SetClass("channel_name", true)
	name_el.inner_rml = entry.Name
	
	local players_el = self.document:CreateElement("div")
	players_el:SetClass("channel_players", true)
	players_el.inner_rml = entry.NumPlayers
	
	local games_el = self.document:CreateElement("div")
	games_el:SetClass("channel_games", true)
	games_el.inner_rml = entry.NumGames
	
	li_el:AppendChild(name_el)
	li_el:AppendChild(players_el)
	li_el:AppendChild(games_el)
	
	li_el.id = entry.Name
	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:SelectChannel(entry)
	end)
	li_el:AddEventListener("dblclick", function(_, _, _)
		self:joinChannel(entry)
	end)
	
	if entry.isCurrent == true then
		li_el:SetPseudoClass("active", true)
		self.currentChannel = entry
	end
	entry.key = li_el.id
	
	table.insert(self.channels, entry)

	return li_el
end

function PXOController:addChannel(channel)
	self.channels_el:AppendChild(self:CreateChannelEntry(channel))
	table.insert(self.channelsList, channel.Name)
end

function PXOController:removeChannel(idx)
	local chnl_idx = self:getChannelIndexByName(self.channelsList[idx])
	if chnl_idx > 0 then
		local el = self.document:GetElementById(self.channels[chnl_idx].key)
		self.channels_el:RemoveChild(el)
		table.remove(self.channels, chnl_idx)
	end
	table.remove(self.channelsList, idx)
end

function PXOController:updateChannel(channel)
	local idx = self:getChannelIndexByName(channel.Name)
	if idx > 0 then
		local el = self.document:GetElementById(self.channels[idx].key)
		local players_el = el.first_child.next_sibling
		local games_el = el.first_child.next_sibling.next_sibling
		
		if channel:isCurrent() == true then
			if self.currentChannel ~= nil then
				self.document:GetElementById(self.currentChannel.key):SetPseudoClass("active", false)
			end
			el:SetPseudoClass("active", true)
			self.currentChannel = self.channels[idx]
		else
			el:SetPseudoClass("active", false)
		end
		
		if players_el.inner_rml ~= channel.NumPlayers then
			players_el.inner_rml = channel.NumPlayers
		end
		
		if games_el.inner_rml ~= channel.NumGames then
			games_el.inner_rml = channel.NumGames
		end
	end
end

function PXOController:getChannelIndexByName(name)
	for i = 1, #self.channels do
		if self.channels[i].Name == name then
			return i
		end
	end
	return -1
end

function PXOController:WebRankPressed()
	ba.warning("Need to setup getting the PXO urls from FSO through the API! Tell Mjn!")
end

function PXOController:PilotInfoPressed()
	if self.selectedPlayer then
		self:GetPlayerStats(self.selectedPlayer.Name)
	end
end

function PXOController:FindPilotPressed()
	self.promptControl = 4

	local text = "Enter the name of the player to search for."
	local title = "Search for player"
	local buttons = {}
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Okay", -1),
		b_value = "",
		b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
	}
	
	self:Show(text, title, true, buttons)
end

function PXOController:SelectPlayer(player)
	if self.selectedPlayer ~= nil then
		self.document:GetElementById(self.selectedPlayer.key):SetPseudoClass("checked", false)
	end
	self.selectedPlayer = player
	self.document:GetElementById(player.key):SetPseudoClass("checked", true)
end

function PXOController:GetPlayerChannel(player_name)
	local response, channel = ui.MultiPXO.getPlayerChannel(player_name)
	
	self.promptControl = 5

	local text = response
	local title = "Search for player"
	local buttons = {}
	
	--If we have a channel then offer the option to join
	if channel ~= "" then
		self.foundChannel = channel
		text = text .. "<br></br>Join channel?"
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_POSITIVE,
			b_text = ba.XSTR("Yes", -1),
			b_value = true,
			b_keypress = string.sub(ba.XSTR("Yes", -1), 1, 1)
		}
		buttons[2] = {
			b_type = dialogs.BUTTON_TYPE_NEGATIVE,
			b_text = ba.XSTR("No", -1),
			b_value = false,
			b_keypress = string.sub(ba.XSTR("No", -1), 1, 1)
		}
	else
		buttons[1] = {
			b_type = dialogs.BUTTON_TYPE_POSITIVE,
			b_text = ba.XSTR("Okay", -1),
			b_value = false,
			b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
		}
	end
	
	self:Show(text, title, false, buttons)
end

function PXOController:GetPlayerStats(player_name)
	local stats = ui.MultiPXO.getPlayerStats(player_name)
	
	self.promptControl = 3

	local text = self:initialize_stats_text(stats)
	local title = player_name .. "'s stats"
	local buttons = {}
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Okay", -1),
		b_value = "",
		b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
	}
	
	self:Show(text, title, false, buttons)
end

function PXOController:CreatePlayerEntry(entry)
	
	local li_el = self.document:CreateElement("li")

	li_el.inner_rml = "<span>" .. entry.Name .. "</span>"
	li_el.id = entry.Name
	li_el:SetClass("list_element", true)
	li_el:SetClass("button_1", true)
	li_el:AddEventListener("click", function(_, _, _)
		self:SelectPlayer(entry)
	end)
	li_el:AddEventListener("dblclick", function(_, _, _)
		self:GetPlayerStats(entry.Name)
	end)
	entry.key = li_el.id
	
	table.insert(self.players, entry)

	return li_el
end

function PXOController:addPlayer(player)
	self.players_el:AppendChild(self:CreatePlayerEntry(player))
	table.insert(self.playersList, player.Name)
end

function PXOController:removePlayer(idx)
	local plr_idx = self:getPlayerIndexByName(self.playersList[idx])
	if plr_idx > 0 then
		local el = self.document:GetElementById(self.players[plr_idx].key)
		self.players_el:RemoveChild(el)
		table.remove(self.players, plr_idx)
	end
	table.remove(self.playersList, idx)
end

function PXOController:getPlayerIndexByName(name)
	for i = 1, #self.players do
		if self.players[i].Name == name then
			return i
		end
	end
	return -1
end

function PXOController:sendChat()
	if string.len(self.submittedValue) > 0 then
		ui.MultiPXO.sendChat(self.submittedValue)
		self.input_id:SetAttribute("value", "")
		self.submittedValue = ""
	end
end

function PXOController:convertBanner()
	local imag_h = gr.loadTexture(self.banner)
	self.bannerWidth = imag_h:getWidth()
	self.bannerHeight = imag_h:getHeight()
	local tex_h = gr.createTexture(self.bannerWidth, self.bannerHeight)
	gr.setTarget(tex_h)
	gr.clearScreen(0,0,0,0)
	gr.drawImage(imag_h, 0, 0, self.bannerWidth, self.bannerHeight, 0, 1, 1, 0, 1)
	self.bannerImg = gr.screenToBlob()
	
	--clean up
	gr.setTarget()
	tex_h:destroyRenderTarget()
	imag_h:unload()
	tex_h:unload()
end

function PXOController:bannerClicked()
	ui.launchURL(self.bannerURL)
end

function PXOController:exit()
	ui.MultiPXO.closePXO()
	ScpuiSystem.MultiReady = false
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

function PXOController:dialog_response(response)
	local path = self.promptControl
	self.promptControl = nil
	if path == 1 then --MOTD
		--Do nothing!
	elseif path == 2 then --Join Private Channel
		if response and response ~= "" then
			ui.MultiPXO.joinPrivateChannel(response)
		end
	elseif path == 3 then --Show Player Stats
		--Do nothing!
	elseif path == 4 then --Find player
		if response and response ~= "" then
			self:GetPlayerChannel(response)
		end
	elseif path == 5 then --Find player response
		if response == true then
			self:joinChannel(self.foundChannel)
		end
		self.foundChannel = nil
	end
end

function PXOController:Show(text, title, input, buttons)
	--Create a simple dialog box with the text and title

	currentDialog = true
	
	local dialog = dialogs.new()
		dialog:title(title)
		dialog:text(text)
		dialog:input(input)
		for i = 1, #buttons do
			dialog:button(buttons[i].b_type, buttons[i].b_text, buttons[i].b_value, buttons[i].b_keypress)
		end
		dialog:escape("")
		dialog:show(self.document.context)
		:continueWith(function(response)
			self:dialog_response(response)
    end)
	-- Route input to our context until the user dismisses the dialog box.
	ui.enableInput(self.document.context)
end

function PXOController:motd_pressed()

	self.promptControl = 1

	local text = self.motd
	local title = "Message of the Day"
	local buttons = {}
	buttons[1] = {
		b_type = dialogs.BUTTON_TYPE_POSITIVE,
		b_text = ba.XSTR("Okay", -1),
		b_value = "",
		b_keypress = string.sub(ba.XSTR("Okay", -1), 1, 1)
	}
	
	self:Show(text, title, false, buttons)

end

function PXOController:add_heading_element(text)
	self.playerStats = self.playerStats .. "<span style=\"width: 49%; float: left; text-align: right;\">" .. text .. "</span><br></br>"
end

function PXOController:add_value_element(text, value)
	self.playerStats = self.playerStats .. "<br></br><span style=\"width: 50%; float: left; text-align: right;\">" .. text .. "</span>"
	self.playerStats = self.playerStats .. "<br></br><span style=\"width: 49%; float: right; padding-left: 1%;\">" .. value .. "</span>"
end

function PXOController:add_empty_line()
    self.playerStats = self.playerStats .. "<br></br>"
end

function PXOController:initialize_stats_text(stats)
    self.playerStats  = ""

    self:add_heading_element("All Time Stats")
    self:add_value_element("Primary weapon shots:", stats.PrimaryShotsFired)
    self:add_value_element("Primary weapon hits:", stats.PrimaryShotsHit)
    self:add_value_element("Primary friendly hits:", stats.PrimaryFriendlyHit)
    self:add_value_element("Primary hit %:",
                           utils.compute_percentage(stats.PrimaryShotsHit, stats.PrimaryShotsFired))
    self:add_value_element("Primary friendly hit %:",
                           utils.compute_percentage(stats.PrimaryFriendlyHit, stats.PrimaryShotsFired))
    self:add_empty_line()

    self:add_value_element("Secondary weapon shots:", stats.SecondaryShotsFired)
    self:add_value_element("Secondary weapon hits:", stats.SecondaryShotsHit)
    self:add_value_element("Secondary friendly hits:", stats.SecondaryFriendlyHit)
    self:add_value_element("Secondary hit %:",
                           utils.compute_percentage(stats.SecondaryShotsHit, stats.SecondaryShotsFired))
    self:add_value_element("Secondary friendly hit %:",
                           utils.compute_percentage(stats.SecondaryFriendlyHit, stats.SecondaryShotsFired))
    self:add_empty_line()

    self:add_value_element("Total kills:", stats.TotalKills)
    self:add_value_element("Assists:", stats.Assists)
    self:add_empty_line()

    self:add_value_element("Current Score:", stats.Score)
    self:add_empty_line()
    self:add_empty_line()

    self:add_heading_element("Kills by Ship Type")
    local score_from_kills = 0
    for i = 1, #tb.ShipClasses do
        local ship_cls = tb.ShipClasses[i]
        local kills    = stats:getShipclassKills(ship_cls)

        if kills > 0 then
            local name = topics.ships.name:send(ship_cls)
            score_from_kills = score_from_kills + kills * ship_cls.Score
            self:add_value_element(name .. ":", kills)
        end
    end
    self:add_value_element("Score from kills only:", score_from_kills)
	
	return self.playerStats
end

function PXOController:accept_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MULTI_JOIN_GAME"])
end

function PXOController:help_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_PXO_HELP"])
end

function PXOController:exit_pressed()
	self:exit()
end

function PXOController:global_keydown(_, event)
    if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
       self:exit()
    elseif event.parameters.key_identifier == rocket.key_identifier.S then --TESTING!
		if event.parameters.shift_key == 1 then
			ui.MultiPXO.joinPrivateChannel("test")
		end
	end
end

function PXOController:SubmitPressed()
	if self.submittedValue then
		self:sendChat()
	end
end

function PXOController:InputFocusLost()
	--do nothing
end

function PXOController:InputChange(event)

	if event.parameters.linebreak ~= 1 then
		local val = self.input_id:GetAttribute("value")
		self.submittedValue = val
	else
		submit_id = self.document:GetElementById("submit_btn")
		ui.playElementSound(submit_id, "click")
		self:sendChat()
	end

end

function PXOController:updateLists()
	ui.MultiPXO.runNetwork()
	local chat = ui.MultiPXO.getChat()
	
	local players = ui.MultiPXO.getPlayers()
	
	-- check for new players
	for i = 1, #players do
		if not utils.table.contains(self.playersList, players[i]) then
			local entry = {
				Name = players[i]
			}
			self:addPlayer(entry)
		end
	end
		
	-- now check for players that left
	for i = 1, #self.playersList do
		if not utils.table.contains(players, self.playersList[i]) then
			self:removePlayer(i)
		end
	end	
	
	-- check for new channels
	for i = 1, #ui.MultiPXO.Channels do
		if not utils.table.contains(self.channelsList, ui.MultiPXO.Channels[i].Name) then
			local entry = {
				Name = ui.MultiPXO.Channels[i].Name,
				NumPlayers = ui.MultiPXO.Channels[i].NumPlayers,
				NumGames = ui.MultiPXO.Channels[i].NumGames,
				isCurrent = ui.MultiPXO.Channels[i]:isCurrent()
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
	
	for i = 1, #self.channelsList do
		if not utils.table.contains(channels, self.channelsList[i]) then
			self:removeChannel(i)
		end
	end	
	
	local txt = ""
	for i = 1, #chat do
		local line = chat[i].Callsign .. ": " .. chat[i].Message
		txt = txt .. line .. "<br></br>"
	end
	self.chat_el.inner_rml = txt
	
	self.document:GetElementById("status_text").inner_rml = ui.MultiPXO.StatusText
	local motd = ui.MultiPXO.MotdText
	--Replace new lines with break tags
	self.motd = motd:gsub("\n","<br></br>")
	
	if self.banner ~= ui.MultiPXO.bannerFilename then
		self.banner = ui.MultiPXO.bannerFilename
		self.bannerURL = ui.MultiPXO.bannerURL
		
		if string.len(self.banner) > 0 then
			self:convertBanner()
			
			self.banner_el.style.width = self.bannerWidth .. "px"
			self.banner_el.style.height = self.bannerHeight .. "px"
			
			ScpuiSystem:ClearEntries(self.banner_el)
			
			local img_el = self.document:CreateElement("img")
			img_el:SetAttribute("src", self.bannerImg)
			img_el:AddEventListener("click", function(_, _, _)
				self:bannerClicked()
			end)
			self.banner_el:AppendChild(img_el)
		end
	end
	
	async.run(function()
        async.await(async_util.wait_for(0.01))
        self:updateLists()
    end, async.OnFrameExecutor)
	
end

return PXOController
