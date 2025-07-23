-----------------------------------
--This file contains functions and methods for handling the achievements system
-----------------------------------

local Utils = require("lib_utils")

--Create the achievements table
ScpuiSystem.data.Achievements = {
    Current_Achievements = {},
    Completed_Achievements = {},
    ModId = "",
    Types = {
        CUSTOM = -1,
        NUMBER_OF_KILLS = 0,
        WEAPONS_FIRED = 1
    },
}

--LuaSexp to set an achievement value
mn.LuaSEXPs['set-achievement-value'].Action = function(name, value)
    local id = ScpuiSystem:createAchievementId(name)
	ScpuiSystem:setAchievementValue(id, value, true)
end

--LuaSexp to get an achievement value
mn.LuaSEXPs['get-achievement-value'].Action = function(name, value)
    local id = ScpuiSystem:createAchievementId(name)
	return ScpuiSystem.data.Achievements.Completed_Achievements[id] or 0
end

--- Initialize the achievements system and begin parsing
--- @return nil
function ScpuiSystem:initAchievements()

    ScpuiSystem.data.Achievements.ModId = ScpuiSystem:getModId()

	ScpuiSystem:parseAchievementsTable("achievements.tbl")

    if #ScpuiSystem.data.Achievements.Current_Achievements > 0 then
        mn.LuaEnums["SCPUI_Achievements"]:removeEnumItem("<none>")
    end

end

--- Display an achievement message to the player
--- @param id string The ID of the achievement
--- @return nil
function ScpuiSystem:displayAchievementMessage(id)
    local achievement = nil
    for _, v in ipairs(ScpuiSystem.data.Achievements.Current_Achievements) do
        if v.Id == id then
            achievement = v
            break
        end
    end

    if achievement then
        local message = "Achievement Unlocked: " .. achievement.Name

        -- Get screen dimensions
        local screen_width = gr.getScreenWidth()
        local screen_height = gr.getScreenHeight()

        -- Get string dimensions
        local stringWidth, stringHeight = gr.getStringSize(message)

        -- Calculate X and Y for centered horizontal and 20% vertical
        local x = (screen_width - stringWidth) / 2
        local y = screen_height * 0.2

        -- Ensure the duration defaults to 10 seconds if not provided
        local duration = 10

        local start_time = ba.getSecondsOverall()

        async.run(function()
            while true do
                -- Get the current time
                local current_time = ba.getSecondsOverall()

                -- Check if the duration has elapsed
                if current_time - start_time >= duration then
                    break
                end

                -- Use the OnFrameExecutor to draw the string at the end of the frame
                async.awaitRunOnFrame(function()
                    local old_color = gr.getColor(true)
                    gr.setColor(255, 255, 255, 255)
                    gr.drawString(message, x, y)
                    gr.setColor(old_color)
                end)

                -- Wait for the next frame
                async.await(async.yield())
            end
        end, async.OnFrameExecutor)
    end
end

--- Sets an achievement to a value for the current player
--- @param id string The ID of the achievement
--- @param value number The value to set the achievement to
--- @param display boolean? True to display a message to the player, false otherwise
--- @param save boolean? True to save the achievement to the save file immediately, false otherwise
--- @return nil
function ScpuiSystem:setAchievementValue(id, value, display, save)
    local old_value = ScpuiSystem.data.Achievements.Completed_Achievements[id] or 0
    local achievement
    for _, v in ipairs(ScpuiSystem.data.Achievements.Current_Achievements) do
        if v.Id == id then
            achievement = v
            break
        end
    end

    local threshold = achievement.Criteria.Threshold
    value = Utils.clamp(value, 0, threshold)

    if value == old_value then return end

    ScpuiSystem.data.Achievements.Completed_Achievements[id] = value

    if save then
        ScpuiSystem:saveAchievementsToFile()
    end

    local show = false
    if value >= threshold and old_value < threshold then
        show = true
    end

    if display and show then
        ScpuiSystem:displayAchievementMessage(id)
    end
end

--- Parse the criteria of a specific achievement
--- @return scpui_achievement_criteria criteria The criteria of the achievement
function ScpuiSystem:parseCriteria()
    local criteria = {}

    -- Type is mandatory and must be valid
    parse.requiredString("+Type:")
    local type_value = parse.getString()

    local types_map = {
        ["Custom"] = ScpuiSystem.data.Achievements.Types.CUSTOM,
        ["Number of Kills"] = ScpuiSystem.data.Achievements.Types.NUMBER_OF_KILLS,
        ["Weapons Fired"] = ScpuiSystem.data.Achievements.Types.WEAPONS_FIRED
    }

    -- Map human-readable type to its numeric value
    local numeric_type = types_map[type_value]
    if numeric_type == nil then
        parse.displayMessage("Invalid Criteria Type: " .. type_value, true)
    end

    criteria.Type = numeric_type

    -- Target is optional
    if parse.optionalString("+Target:") then
        criteria.Target = parse.getString()

        if numeric_type == ScpuiSystem.data.Achievements.Types.NUMBER_OF_KILLS then
            if not tb.ShipClasses[criteria.Target] then
                parse.displayMessage("Invalid Ship Class: " .. criteria.Target, true)
            end
        end

        if numeric_type == ScpuiSystem.data.Achievements.Types.WEAPONS_FIRED then
            if not tb.WeaponClasses[criteria.Target] then
                parse.displayMessage("Invalid Weapon Class: " .. criteria.Target, true)
            end
        end
    end

    -- Threshold is mandatory
    criteria.Threshold = 1
    if parse.optionalString("+Threshold:") then
        criteria.Threshold = parse.getFloat()

        if criteria.Threshold <= 0 then
            parse.displayMessage("Threshold must be greater than or equal to 0", true)
        end
    end

    return criteria
end

--- Create an achievement id
--- @param name string The name of the achievement
--- @return string id The id of the achievement
function ScpuiSystem:createAchievementId(name)
    return name:gsub("%s", "_") .. "_" .. ScpuiSystem.data.Achievements.ModId
end

--- Parse the achievements table
--- @param file string The filename of the achievements table
--- @return nil
function ScpuiSystem:parseAchievementsTable(file)

    if not parse.readFileText(file, "data/tables") then
		return
	end

    parse.requiredString("#ACHIEVEMENTS")

    while parse.optionalString("$Name:") do

        local name = parse.getString()

        -- Check if the name exceeds the character limit
        if #name > 32 then
            parse.displayMessage("Error: Achievement Name exceeds 32 characters: " .. name, true)
        end

        for _, v in ipairs(ScpuiSystem.data.Achievements.Current_Achievements) do
            if v.Name == name then
                parse.displayMessage("Achievement '" .. name .. "' already exists!", true)
            end
        end

        parse.requiredString("+Description:")
        local description = parse.getString()

        -- Check if the name exceeds the character limit
        if #description > 50 then
            parse.displayMessage("Error: Achievement Description exceeds 50 characters: " .. description, true)
        end

        parse.requiredString("+Criteria:")
        local criteria = ScpuiSystem:parseCriteria()

        local hidden = false
        if parse.optionalString("+Hidden:") then
            hidden = parse.getBoolean()
        end

        local text_color = nil
        if parse.optionalString("+Color:") then
            local colorString = parse.getString()

            -- Extract RGBA values from the string
            local r, g, b, a = colorString:match("^(%d+),%s*(%d+),%s*(%d+),?%s*(%d*)$")

            if not r or not g or not b then
                parse.displayMessage("Invalid color format: " .. colorString, true)
                return
            end

            -- Convert extracted values to numbers and ensure they are within range
            r = math.max(0, math.min(255, tonumber(r)))
            g = math.max(0, math.min(255, tonumber(g)))
            b = math.max(0, math.min(255, tonumber(b)))
            a = tonumber(a)
            a = (a and math.max(0, math.min(255, a))) or 255 -- Default alpha to 255 if not provided


            text_color = Utils.rgbaToHex(r, g, b, a)
        end

        local bar_color = "#4CAF50"
        if parse.optionalString("+Bar Color:") then
            local colorString = parse.getString()

            -- Extract RGBA values from the string
            local r, g, b, a = colorString:match("^(%d+),%s*(%d+),%s*(%d+),?%s*(%d*)$")

            if not r or not g or not b then
                parse.displayMessage("Invalid color format: " .. colorString, true)
                return
            end

            -- Convert extracted values to numbers and ensure they are within range
            r = math.max(0, math.min(255, tonumber(r)))
            g = math.max(0, math.min(255, tonumber(g)))
            b = math.max(0, math.min(255, tonumber(b)))
            a = tonumber(a)
            a = (a and math.max(0, math.min(255, a))) or 255 -- Default alpha to 255 if not provided


            bar_color = Utils.rgbaToHex(r, g, b, a)
        end

        --- @type scpui_current_achievement
        local achievement = {
            Name = name,
            Id = self:createAchievementId(name),
            Description = description,
            Criteria = criteria,
            Hidden = hidden,
            BarColor = bar_color,
            TextColor = text_color
        }

        table.insert(ScpuiSystem.data.Achievements.Current_Achievements, achievement)
        --- @type LuaEnum
        local enum =mn.LuaEnums["SCPUI_Achievements"]
        enum:addEnumItem(name)
    end

    parse.requiredString("#END")

    parse.stop()

end

-- Load the current achievements save file
--- @return nil
function ScpuiSystem:loadAchievementsFromFile()

    -- Ensure the player is valid
    if ba.getCurrentPlayer():getName() == "" then
        return
    end

    local Datasaver = require('lib_data_saver')

    local config = Datasaver:loadDataFromFile("scpui_achievements", true)

    if config then
        ScpuiSystem.data.Achievements.Completed_Achievements = config
        ba.print("SCPUI: Loaded achievements from save file!\n")
    end

end

--- Save the current achievements to the save file
--- @return nil
function ScpuiSystem:saveAchievementsToFile()

    -- Ensure the player is valid
    if ba.getCurrentPlayer():getName() == "" then
        return
    end

    local Datasaver = require('lib_data_saver')

    Datasaver:saveDataToFile("scpui_achievements", ScpuiSystem.data.Achievements.Completed_Achievements, true)

end

ScpuiSystem:initAchievements()

-- Do not create engine hooks in FRED
if ba.inMissionEditor() then
    return
end

if #ScpuiSystem.data.Achievements.Current_Achievements > 0 then
    ScpuiSystem:addHook("On Mission End", function()
        ScpuiSystem:saveAchievementsToFile()
    end)

    ScpuiSystem:addHook("On Player Loaded", function()
        ScpuiSystem:loadAchievementsFromFile()
    end)
end

for _, v in ipairs(ScpuiSystem.data.Achievements.Current_Achievements) do
    if v.Criteria.Type == ScpuiSystem.data.Achievements.Types.NUMBER_OF_KILLS then
        local condition = { State = "GS_STATE_GAME_PLAY" }
        if v.Criteria.Target then
            condition["Ship class"] = v.Criteria.Target
        end
        engine.addHook("On Ship Death", function()
            local object = hv.Killer
            while object and object:isValid() do
                if object:getBreedName():lower() == "ship" then
                    if object.Name == hv.Player.Name then
                        ScpuiSystem:setAchievementValue(v.Id, (ScpuiSystem.data.Achievements.Completed_Achievements[v.Id] or 0) + 1, true)
                        break
                    end
                end
                object = object.Parent
            end
        end, condition)
    elseif v.Criteria.Type == ScpuiSystem.data.Achievements.Types.WEAPONS_FIRED then
        local condition = { State = "GS_STATE_GAME_PLAY" }
        if v.Criteria.Target then
            condition["Weapon class"] = v.Criteria.Target
        end
        engine.addHook("On Weapon Fired", function()
            ScpuiSystem:setAchievementValue(v.Id, (ScpuiSystem.data.Achievements.Completed_Achievements[v.Id] or 0) + 1, true)
        end, condition)
    end
end