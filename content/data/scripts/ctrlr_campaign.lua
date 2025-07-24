-----------------------------------
--Controller for the Campaign Select UI
-----------------------------------

local Topics = require("lib_ui_topics")

local Class = require("lib_class")

local CampaignController = Class()

--- Called by the class constructor
--- @return nil
function CampaignController:init()
    self.Document = nil --- @type Document The RML document
    self.Selection = nil --- @type string | nil The selected campaign
    self.Campaigns_List = {} --- @type scpui_campaign[] The list of available campaigns
end

--- Called by the RML document
--- @param document Document
function CampaignController:initialize(document)
    self.Document = document

	---Load background choice
	self.Document:GetElementById("main_background"):SetClass(ScpuiSystem:getBackgroundClass(), true)

	---Load the desired font size from the save file
	self.Document:GetElementById("main_background"):SetClass(("base_font" .. ScpuiSystem:getFontPixelSize()), true)

    ui.CampaignMenu.loadCampaignList();

    local names, fileNames, descriptions = ui.CampaignMenu.getCampaignList()

    local currentCampaignFile = ba.getCurrentPlayer():getCampaignFilename()
    local selectedCampaign = nil

    for i, v in ipairs(names) do
        --- @type scpui_campaign
        local campaign = {
            Name = v,
            Description = descriptions[i],
            Filename = fileNames[i]
        }

        self.Campaigns_List[i] = campaign

        if campaign.Filename == currentCampaignFile then
            selectedCampaign = self.Campaigns_List[i]
        end
    end

    self:initCampaignList()

    Topics.campaign.initialize:send(self)

    -- Initialize selection
    self:selectCampaign(selectedCampaign)
end

--- Global keydown function handles all keypresses
--- @param element Element The main document element
--- @param event Event The event that was triggered
--- @return nil
function CampaignController:global_keydown(element, event)
    local keys = ScpuiSystem:getKeyInfo(event)
    if keys.ESCAPE then
        event:StopPropagation()

        ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
    end
end

--- Select a campaign by name
--- @param campaign scpui_campaign | nil The campaign name
--- @return nil
function CampaignController:selectCampaign(campaign)
    if campaign ~= nil and self.Selection == campaign.Name then
        -- No changes
        return
    end

    --- Uncheck the previous campaign
    if self.Selection ~= nil then
        local element = self:getCampaignByName(self.Selection).Element
        if element ~= nil then
            element:SetPseudoClass("checked", false)
        end
    end

    local description = ""

    if campaign == nil then
        self.Selection = nil
    else
        self.Selection = campaign.Name
        description = campaign.Description
    end

    self.Document:GetElementById("desc_text").inner_rml = description

    --- Check the new campaign and bring it into view
    if self.Selection ~= nil then
        local element = self:getCampaignByName(self.Selection).Element
        if element ~= nil then
            element:SetPseudoClass("checked", true)
            element:ScrollIntoView()
        end
    end
end

--- Create a list item for a campaign
--- @param campaign scpui_campaign The campaign name
--- @return Element The list item element
function CampaignController:createCampaignListItem(campaign)
    local li_el = self.Document:CreateElement("li")

	local display = Topics.campaign.listCampaign:send({campaign.Name, campaign.Filename})

    li_el.inner_rml = display
    li_el:SetClass("campaignlist_element", true)
    li_el:AddEventListener("click", function(_, _, _)
        self:selectCampaign(campaign)
    end)

    campaign.Element = li_el

    return li_el
end

--- Initialize the campaign list
--- @return nil
function CampaignController:initCampaignList()
    local campaign_list_el = self.Document:GetElementById("campaignlist_ul")
    for _, v in ipairs(self.Campaigns_List) do
        -- Add all the elements
        campaign_list_el:AppendChild(self:createCampaignListItem(v))
    end
end

--- Get a campaign by name
--- @param name string The campaign name
--- @return scpui_campaign | nil The campaign
function CampaignController:getCampaignByName(name)
    for _, v in ipairs(self.Campaigns_List) do
        if v.Name == name then
            return v
        end
    end

    return nil
end

--- The commit button was clicked, so load the selected campaign
--- @param element Element The element that was clicked
--- @return nil
function CampaignController:commit_pressed(element)
    if self.Selection == nil then
        ui.playElementSound(element, "click", "error")
        return
    end

    local campaign = self:getCampaignByName(self.Selection)
    assert(campaign ~= nil)

    ui.CampaignMenu.selectCampaign(campaign.Filename)

    ui.playElementSound(element, "click", "success")
    ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])
end

--- The restart button was clicked, so reset the campaign
--- @param element Element The element that was clicked
--- @return nil
function CampaignController:restart_pressed(element)
    if self.Selection == nil then
        ui.playElementSound(element, "click", "error")
        return
    end

    local campaign = self:getCampaignByName(self.Selection)
    assert(campaign ~= nil)

    local title = ba.XSTR("Warning", 888284)
    local text = ba.XSTR("This will cause all progress in your\nCurrent campaign to be lost", 888285)
    ---@type dialog_button[]
    local buttons = {}
    buttons[1] = {
        Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_POSITIVE,
        Text = ba.XSTR("Ok", 888286),
        Value = true,
        Keypress = string.sub(ba.XSTR("Ok", 888286), 1, 1)
    }
    buttons[2] = {
        Type = ScpuiSystem.constants.Dialog_Constants.BUTTON_TYPE_NEGATIVE,
        Text = ba.XSTR("Cancel", 888091),
        Value = false,
        Keypress = string.sub(ba.XSTR("Cancel", 888091), 1, 1)
    }

    ---@type dialog_setup
    local params = {
        Buttons_List = buttons,
        Title = title,
        Text = text,
    }

    ScpuiSystem:showDialog(self, params, function(response)
        if not response then
            ui.playElementSound(element, "click", "error")
            return
        end

        ui.CampaignMenu.resetCampaign(campaign.Filename)

        ba.savePlayer(ba.getCurrentPlayer())
        ui.playElementSound(element, "click", "success")
    end)
end

--- Called when the screen is being unloaded
--- @return nil
function CampaignController:unload()
	Topics.campaign.unload:send(self)
end

return CampaignController
