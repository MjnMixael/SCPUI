local rocket_utils = require("rocket_util")
local topics = require("ui_topics")
local class = require("class")
local async_util = require("async_util")
local utils = require("utils")

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
	
	ui.MultiPXO.initPXO()
	
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

function PXOController:SelectPlayer(player)
	if self.selectedPlayer ~= nil then
		self.document:GetElementById(self.selectedPlayer.key):SetPseudoClass("checked", false)
	end
	self.selectedPlayer = player
	self.document:GetElementById(player.key):SetPseudoClass("checked", true)
end

function PXOController:GetPlayerChannel(player_name)
	local response, channel = ui.MultiPXO.getPlayerChannel(player_name)
	--ba.warning(channel)
end

function PXOController:GetPlayerStats(player_name)
	local stats = ui.MultiPXO.getPlayerStats(player_name)
	ba.warning(stats.Score)
end

function PXOController:ShowPlayerStats(player)
	self:SelectPlayer(player)
	
	self:GetPlayerChannel(player.Name)
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
		self:ShowPlayerStats(entry)
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
	ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

function PXOController:accept_pressed()
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
	motd = motd:gsub("\n","<br></br>")
	self.document:GetElementById("motd_text").inner_rml = motd
	
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
