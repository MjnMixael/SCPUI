-----------------------------------
--Controller for the Multi Join Game UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local AbstractMultiController = require("ctrlr_multi_common")

--- This multi controller is merged with the Multi Common Controller
local JoinGameController = Class(AbstractMultiController)

JoinGameController.NETWORK_TYPE_PXO = 1
JoinGameController.NETWORK_TYPE_LOCAL = 2

--- Called by the class constructor
--- @return nil
function JoinGameController:init()
	self.GamesListEl = nil --- @type Element the games list element
	self.CommonTextEl = nil --- @type Element the common text element
	self.StatusTextEl = nil --- @type Element the status text element
	self.Network = self.NETWORK_TYPE_PXO --- @type number the network type
	self.Document = nil --- @type Document the RML document

	self.Subclass = AbstractMultiController.CTRL_JOIN_GAME
end

--- Called by the RML document
--- @param document Document
function JoinGameController:initialize(document)
	AbstractMultiController.initialize(self, document)
	ScpuiSystem.data.memory.multiplayer_general.Context = self

	self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

	self.GamesListEl = self.Document:GetElementById("games_list_ul")
	self.CommonTextEl = self.Document:GetElementById("common_text")
	self.StatusTextEl = self.Document:GetElementById("status_text")

	ScpuiSystem:clearEntries(self.GamesListEl)

	if not ScpuiSystem.data.memory.MultiJoinReady then
		ui.MultiJoinGame.initMultiJoin()
	end

	ScpuiSystem.data.memory.MultiJoinReady = true

	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = true
	ui.MultiGeneral.setPlayerState()

	--If we're in local only mode
	local options = opt.Options
	for _, v in ipairs(options) do
		if v.Key == "Multi.TogglePXO" then
			if v.Value.Display == "Off" then
				self.Network = self.NETWORK_TYPE_LOCAL
			end
			break
		end
	end


	Topics.multijoingame.initialize:send(self)

end

--- Exit the join game ui
--- @return nil
function JoinGameController:exit()
	ui.MultiJoinGame.closeMultiJoin()
	ScpuiSystem.data.memory.MultiJoinReady = false

	--Go back to mainhall if not in pxo!
	if self.Network == self.NETWORK_TYPE_LOCAL then
		ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
	else
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PXO"])
	end
end

--- Called by the RML to join a game
--- @return nil
function JoinGameController:join_pressed()
	ui.MultiJoinGame.sendJoinRequest()
end

--- Called by the RML to show help boxes
--- @return nil
function JoinGameController:help_pressed()
	--show help overlay
end

--- Called by the RML to create a game
--- @return nil
function JoinGameController:create_pressed()
	ui.MultiJoinGame:createGame()
end

--- Called by the RML to join a game as observer
--- @return nil
function JoinGameController:observer_pressed()
	ui.MultiJoinGame.sendJoinRequest(true)
end

--- Called by the RML to cancel the join game ui. Will exit the game state
--- @return nil
function JoinGameController:cancel_pressed()
	self:exit()
end

--- Called by the RML to refresh the game list
--- @return nil
function JoinGameController:refresh_pressed()
	ui.MultiJoinGame:refresh()
end

--- Called by the RML to show the options menu
--- @return nil
function JoinGameController:options_pressed()
	ba.postGameEvent(ba.GameEvents["GS_EVENT_OPTIONS_MENU"])
end

--- Called by the RML to exit the join game ui
--- @return nil
function JoinGameController:exit_pressed()
	self:exit()
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function JoinGameController:global_keydown(element, event)
	local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
       self:exit()
	end
end

--- Called when the screen is being unloaded
--- @return nil
function JoinGameController:unload()
	ScpuiSystem.data.memory.multiplayer_general.RunNetwork = false
	Topics.multijoingame.unload:send(self)
end

return JoinGameController
