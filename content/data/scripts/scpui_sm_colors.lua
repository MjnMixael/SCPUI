-----------------------------------
--This file contains the necessary methods to colorize text based on keywords
--It also contains the necessary methods to add tooltips to text
-----------------------------------

--- Parse the affixes section of the keywords table
--- @param source scpui_keywords
--- @return scpui_keywords
local function parseKeywordAffixes(source)
    local prefixes = {}
    local suffixes = {}
    for _, prefix in ipairs(source.Prefixes) do
        table.insert(prefixes, prefix)
    end
    for _, suffix in ipairs(source.Suffixes) do
        table.insert(suffixes, suffix)
    end
    while true do
        if parse.optionalString("+Prefix:") then
            table.insert(prefixes, parse.getString() .. ' ')
        elseif parse.optionalString("+Immediate Prefix:") then
            table.insert(prefixes, parse.getString())
        elseif parse.optionalString("+Suffix:") then
            table.insert(suffixes, ' ' .. parse.getString())
        elseif parse.optionalString("+Immediate Suffix:") then
            table.insert(suffixes, parse.getString())
        else
            return { Prefixes = prefixes, Suffixes = suffixes }
        end
    end
end

--- Parse the keywords table
--- @param data string The file to parse
--- @param inherited_affixes scpui_keywords
--- @return scpui_keywords
local function parseKeywords(data, inherited_affixes)
    local KeywordAlgorithm = require("lib_keyword_algorithm")
    parse.readFileText(data, "data/tables")
    local lang = "#" .. ba.getCurrentLanguage()

    --If we can't find the language section then reset the parse and skip to Default
    if not parse.skipToString(lang) then
        parse.stop()
        parse.readFileText(data, "data/tables")
        if not parse.skipToString("#Default") then
            parse.stop()
            ba.print(data .. " is missing a valid language section!")
            -- Just return the inherited affixes
            return inherited_affixes
        end
    end

    ---@type scpui_keywords
    local global_affixes = parseKeywordAffixes(inherited_affixes)
    while parse.optionalString("$Style:") do
        local any = false
        local style = parse.getString()
        local affixes = parseKeywordAffixes(global_affixes)
        while parse.optionalString("+Text:") do
            any = true
            local text = parse.getString()
            local tooltip = nil
            if parse.optionalString("++Tooltip:") then
                tooltip = parse.getString()
            end
            for _, prefix in ipairs(affixes.Prefixes) do
                for _, suffix in ipairs(affixes.Suffixes) do
                    local t = prefix .. text .. suffix
                    if not KeywordAlgorithm.registerKeyword(t, style, tooltip) then
                        parse.displayMessage("SCPUI Keyword '" .. t .. "' already exists. Skipping!")
                    end
                end
            end
        end
        if not any then
            parse.displayMessage("Found '$Style: " .. style .. "' with no +Text: entries!")
        end
    end

    parse.requiredString("#End")
    parse.stop()
    return global_affixes
end

--- Initialize the keywords system and send the files to the keywords parser
--- This function is called when the SCPUI system is initialized
--- @return nil
local function initKeywords()
    ---@type scpui_keywords
    local affixes = {Prefixes = {''}, Suffixes = {''}}
    if cf.fileExists('keywords.tbl') then
        affixes = parseKeywords('keywords.tbl', affixes)
    end

    for _, v in ipairs(cf.listFiles("data/tables", "*-kwrd.tbm")) do
        parseKeywords(v, affixes)
    end
end

--- Check the global timers table and show the tooltip if the timer is greater than 3
--- @param tool_el Element The tooltip element
--- @param id string The id of the tooltip
--- @return nil
function ScpuiSystem:maybeShowTooltip(tool_el, id)
    local AsyncUtil = require("lib_async")
    if ScpuiSystem.data.Tooltip_Timers[id] == nil then
        return
    end

    if ScpuiSystem.data.Tooltip_Timers[id] >= 3 then
        tool_el:SetPseudoClass("shown", true)
    else
        async.run(function()
            async.await(AsyncUtil.wait_for(1.0))
            if ScpuiSystem.data.Tooltip_Timers[id] ~= nil then
                ScpuiSystem.data.Tooltip_Timers[id] = ScpuiSystem.data.Tooltip_Timers[id] + 1
                ScpuiSystem:maybeShowTooltip(tool_el, id)
            end
        end, async.OnFrameExecutor)
    end
end

--- Add a tooltip to a document
--- @param document Document The document to add the tooltip to
--- @param id string The id to give the tooltip
--- @param tooltip string The tooltip to add
function ScpuiSystem:addTooltip(document, id, tooltip)
    if tooltip == nil or id == nil then
        return
    end

    local parent = document:GetElementById(id)

    if not parent then
        ba.print('Could not find tooltip parent!\n')
        return
    end

    local tool_el = document:CreateElement("div")
    tool_el.id = id .. "_tooltip"
    tool_el:SetClass("tooltip", true)
    tool_el.style.position = "fixed"

    -- Set the width of the tooltip
    -- Calculate the width of the tooltip element
    local max_characters = 25 -- Maximum characters before wrapping
    local font_pixel_size = ScpuiSystem:getFontPixelSize()
    local actual_characters = math.min(max_characters, #tooltip)
    local element_width = font_pixel_size * actual_characters

    tool_el.style.width = element_width .. "px"

    -- Calculate the number of characters that fit in one line
    local characters_per_line = math.floor(element_width / font_pixel_size)

    -- Calculate the number of lines required
    local number_of_lines = math.ceil(#tooltip / characters_per_line)

    local total_width = element_width + 10 -- Tooltip class has a padding of 5
    local total_height = ((number_of_lines * font_pixel_size) + 10)

    -- Now append!
    tool_el.inner_rml = "<span class=\"tooltiptext\">" .. tooltip .. "</span>"
    local root = document:GetElementById('main_background')
    root:AppendChild(tool_el)

    parent:AddEventListener("mouseover", function(event, _, _)
        local x = event.parameters.mouse_x - total_width
        local y = event.parameters.mouse_y - total_height
        tool_el.style.left = math.max(3, x) .. "px"
        tool_el.style.top = math.max(3, y) .. "px"
        if ScpuiSystem.data.Tooltip_Timers[id] == nil then
            ScpuiSystem.data.Tooltip_Timers[id] = 0
            ScpuiSystem:maybeShowTooltip(tool_el, id)
        end
    end)

    parent:AddEventListener("mouseout", function()
        ScpuiSystem.data.Tooltip_Timers[id] = nil
        tool_el:SetPseudoClass("shown", false)
    end)
end

--- Apply keyword classes to the input text which is then colorized
--- @param input_text string The text to colorize
--- @return string, table register The colorized text and a table of tooltips
function ScpuiSystem:applyKeywordClasses(input_text)
    local KeywordAlgorithm = require("lib_keyword_algorithm")
    return KeywordAlgorithm.colorize(input_text)
end

initKeywords()