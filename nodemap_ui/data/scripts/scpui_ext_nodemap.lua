--- Represents a single node in the system map.
--- @class node_map_node
--- @field Name string The name of the connected node.
--- @field Angle? number The angle (in degrees) of the node relative to the parent system.
--- @field Color? table<number, number> The RGB color of the node, represented as a table of three integers (red, green, blue).
--- @field EnforceColor? boolean Whether to enforce the node's color.
--- @field NoLine? boolean Whether to hide the line connecting this node to its parent system.

--- Represents a progression stage for a system.
--- @class node_map_progression
--- @field Key number The game progress key associated with this progression stage.
--- @field Description? string (Optional) The description of the system at this progression stage.
--- @field Append? string (Optional) Additional description text to append.
--- @field Faction? string (Optional) The faction controlling the system at this progression stage.
--- @field Color? string (Optional) The color name associated with the progression stage.
--- @field Bitmap? string (Optional) The bitmap file associated with the system at this stage.
--- @field Nodes node_map_node[] A list of nodes connected to this system at this progression stage.

--- Represents a single entry in the node map.
--- @class node_map_entry
--- @field Name string The unique name of the system.
--- @field DisplayName? string The display name of the system (defaults to `Name` if not specified).
--- @field HideLabel? boolean Whether the system's label should be hidden on the map.
--- @field Description? string A description of the system (defaults to an empty string if not specified).
--- @field Faction? string The faction controlling the system (defaults to an empty string if not specified).
--- @field SysType? string The type of system (defaults to an empty string if not specified).
--- @field X number The x-coordinate of the system on the map.
--- @field Y number The y-coordinate of the system on the map.
--- @field Color string The color name associated with the system.
--- @field Bitmap? string The filename of the bitmap representing the system on the map.
--- @field Visible? boolean Whether the system is visible on the map (defaults to `true` if not specified).
--- @field Selectable? boolean Whether the system is selectable on the map (defaults to `true` if not specified).
--- @field Nodes? node_map_node[] A list of nodes connected to this system.
--- @field Progression? node_map_progression[] A list of progression stages for the system.
--- @field ButtonElement? Element The button element associated with the system on the map.
--- @field ImageElement? Element The image element associated with the system on the map.
--- @field BitmapX? number The x-coordinate of the bitmap on the map.
--- @field BitmapY? number The y-coordinate of the bitmap on the map.
--- @field ConvertedX? number The converted x-coordinate of the system on the map.
--- @field ConvertedY? number The converted y-coordinate of the system on the map.

--- Represents the node map as a whole.
--- @class node_map
--- @field entries node_map_entry[] A list of systems in the node map.
--- @field icons table<string, string> A mapping of system names to their associated icon file base names.
--- @field colorValues table<string, table<number, number>> A mapping of color names to RGB values.

--- Represents a node on a node line
--- @class node_map_point
--- @field [1] number The x-coordinate of the node
--- @field [2] number The y-coordinate of the node
--- @field [3] color The color of the node
--- @field [4] boolean Whether the node color is enforced

--- Represents the node lines on the node map.
--- @class node_map_line
--- @field Points table<string, string> The names of two systems that should be connected
--- @field First node_map_point The first node on the line
--- @field Second? node_map_point The second node on the line

--- Scpui Nodemap Extension
--- @class NodemapUi
--- @field parseSystems fun(data: string): nil Parses the systems from the nodemap.tbl file.
--- @field clampColorValue fun(val: number): number Clamps a color value to the range 0-255.
--- @field verifyIcon fun(icon: string): boolean Verifies that the icon exists in the icons table.
--- @field getBitmap fun(name: string): string Gets the bitmap for the given system.
--- @field getRGB fun(color: string): table<number, number, number> Gets the RGB values for the given color.
--- @field limitCoords fun(val: number): number Limits the given value to the range 0-1.
--- @field parseTables fun(): nil Parses the tables for the node map.
--- @field icons table<string, string> The icons for the systems
--- @field colorValues table<string, table<number, number, number>> The color values for the systems
--- @field entries node_map_entry[] The entries for the systems

--- Create the local NodemapUi object
local NodemapUi = {
	Name = "Node Map",
	Version = "1.1.0",
	Submodule = "ndmp",
	Key = "NodemapUi"
}

NodemapUi.icons = {} --- @type table<string, string> The icons for the systems
NodemapUi.colorValues = {} --- @type table<string, table<number, number, number>> The color values for the systems
NodemapUi.entries = {} --- @type node_map_entry[] The entries for the systems

--- initialize the NodemapUi object. Called afer the nodemap extension is registered with SCPUI
--- @return nil
function NodemapUi:init()
    -- Register nodemap-specific topics
    ScpuiSystem:registerExtensionTopics("nodemap", {
        preload = function() return nil end,
        initialize = function() return nil end,
		postMapBuild = function() return nil end,
        progressionFunction = function()
            -- Default to returning a dummy function
            return function(_) return 1 end
        end,
        progress = function() return 99999 end,
        renderBackground = function() return true end,
        exit = function() return true end,
        selectEntry = function() return nil end,
        keydown = function() return false end,
        unload = function() return nil end
    })
end

--- after everything is loaded, parse the table
--- @return nil
function NodemapUi:postInit()
    self:parseTables()
end

--- Parses the systems from the nodemap.tbl file.
--- @param data string the file to parse
--- @return nil
function NodemapUi:parseSystems(data)

    parse.readFileText(data, "data/tables")

        if parse.optionalString("#Node Map Icons") then

        while parse.optionalString("$Name:") do
            local name = string.lower(parse.getString())

            parse.requiredString("+File Base:")
            local file = parse.getString()

            file = string.gsub(file, "%..+$", "")

            NodemapUi.icons[name] = file
        end
    end

    if parse.optionalString("#Node Map Colors") then

        while parse.optionalString("$Name:") do
            local name = string.lower(parse.getString())

            parse.requiredString("+Red:")
            local red = self:clampColorValue(parse.getInt())

            parse.requiredString("+Green:")
            local green = self:clampColorValue(parse.getInt())

            parse.requiredString("+Blue:")
            local blue = self:clampColorValue(parse.getInt())

            NodemapUi.colorValues[name] = {red, green, blue}
        end
    end

    if parse.optionalString("#Node Map Systems") then

        while parse.optionalString("$Name:") do
            ---@type node_map_entry
            local entry = {
                Name = "",
                X = 0,
                Y = 0,
                Color = "",
            }

            entry.Name = parse.getString()

            for _, v in ipairs(NodemapUi.entries) do
                if v.Name == entry.Name then
                    ba.error("System '" .. entry.Name .. "' in nodemap.tbl is a duplicate system! All systems must have unique names!")
                end
            end

            if parse.optionalString("$Display Name:") then
                entry.DisplayName = parse.getString()
            else
                entry.DisplayName = entry.Name
            end

            entry.HideLabel = parse.optionalString("$Hide Label:") and parse.getBoolean()

            if parse.optionalString("$Description:") then
                entry.Description = parse.getString()
            else
                entry.Description = ""
            end

            if parse.optionalString("$Controlling Faction:") then
                entry.Faction = parse.getString()
            else
                entry.Faction = ""
            end

            if parse.optionalString("$Type Of System:") then
                entry.SysType = parse.getString()
            else
                entry.SysType = ""
            end

            parse.requiredString("$X Coordinate:")
            entry.X = NodemapUi:limitCoords(parse.getFloat())

            parse.requiredString("$Y Coordinate:")
            entry.Y = NodemapUi:limitCoords(parse.getFloat())

            parse.requiredString("$Color:")
            entry.Color = string.lower(parse.getString())

            --Verify we have a valid color
            if not NodemapUi:verifyIcon(entry.Color) then
                ba.warning("System '" .. entry.Name .. "' has invalid color '" .. entry.Color .. "' in nodemap.tbl. Setting to green!")
                entry.Color = "green"
            end

            if parse.optionalString("$Visible:") then
                entry.Visible = parse.getBoolean()
            else
                entry.Visible = true
            end

            if parse.optionalString("$Selectable:") then
                entry.Selectable = parse.getBoolean()
            else
                entry.Selectable = true
            end

            entry.Bitmap = NodemapUi:getBitmap(entry.Color)

            entry.Nodes = {}

            while parse.optionalString("$Node:") do

                ---@type node_map_node
                local node = {
                    Name = "",
                }

                node.Name = parse.getString()

                for _, v in ipairs(entry.Nodes) do
                    if v.Name == node.Name then
                    ba.error("System '" .. entry.Name .. "' in nodemap.tbl has duplicate node '" .. node.Name .. "'. All nodes must have unique names with a single system!")
                    end
                end

                parse.requiredString("+Angle:")
                node.Angle = parse.getInt() - 90

                parse.requiredString("+Color:")
                node.Color = NodemapUi:getRGB(string.lower(parse.getString()))

                if node.Color == nil then
                    ba.warning("Could not find color for node '" .. node.Name .. "'. Setting to blue!")
                    node.Color = NodemapUi:getRGB("blue")
                end

                if parse.optionalString("+Enforce Line Color:") then
                    node.EnforceColor = parse.getBoolean()
                else
                    node.EnforceColor = false
                end

                if parse.optionalString("+Do Not Connect:") then
                    node.NoLine = parse.getBoolean()
                else
                    node.NoLine = false
                end

                table.insert(entry.Nodes, node)
            end

            entry.Progression = {}
            while parse.optionalString("$Progression:") do

                ---@type node_map_progression
                local e = {
                    Key = 0,
                    Nodes = {},
                }

                local Topics = require("lib_ui_topics")
                local getProgress = Topics.nodemap.progressionFunction:send()
                e.Key = getProgress and getProgress(parse.getString()) or 1

                if parse.optionalString("+Description:") then
                    e.Description = parse.getString()
                end

                if parse.optionalString("+Append Description:") then
                    e.Append = parse.getString()
                end

                if parse.optionalString("+Controlling Faction:") then
                    e.Faction = parse.getString()
                end

                if parse.optionalString("+Color:") then
                    e.Color = string.lower(parse.getString())

                    --Verify we have a valid color
                    if not NodemapUi:verifyIcon(e.Color) then
                    ba.warning("System '" .. entry.Name .. "' has invalid color '" .. e.Color .. "' in nodemap.tbl. Setting to green!")
                    e.Color = "green"
                    end

                    e.Bitmap = NodemapUi:getBitmap(e.Color)
                end

                while parse.optionalString("+Node:") do

                    ---@type node_map_node
                    local n = {
                        Name = "",
                    }
                    n.Name = parse.getString()

                    if parse.optionalString("+Color:") then
                    n.Color = NodemapUi:getRGB(string.lower(parse.getString()))

                    if n.Color == nil then
                        ba.warning("Could not find color for node '" .. n.Name .. "'. Setting to blue!")
                        n.Color = NodemapUi:getRGB("blue")
                    end
                    end

                    if parse.optionalString("+Enforce Line Color:") then
                    n.EnforceColor = parse.getBoolean()
                    end

                    if parse.optionalString("+Do Not Connect:") then
                    n.NoLine = parse.getBoolean()
                    end

                    table.insert(e.Nodes, n)
                end

                table.insert(entry.Progression, e)
            end

            local function sortByKey(a, b)
                return a.Key > b.Key
            end

            -- Make sure the progressions are sorted by key value
            table.sort(entry.Progression, sortByKey)

            -- Make sure old data falls forward into new data progressively
            local f_bitmap = entry.Bitmap
            local f_faction = entry.Faction
            local f_description = entry.Description
            local f_nodes = entry.Nodes

            for i = #entry.Progression, 1, -1 do
                if entry.Progression[i].Bitmap == nil then
                    entry.Progression[i].Bitmap = f_bitmap
                else
                    f_bitmap = entry.Progression[i].Bitmap
                end
                if entry.Progression[i].Faction == nil then
                    entry.Progression[i].Faction = f_faction
                else
                    f_faction = entry.Progression[i].Faction
                end
                if entry.Progression[i].Description == nil then
                    entry.Progression[i].Description = f_description
                else
                    f_description = entry.Progression[i].Description
                end
                if entry.Progression[i].Append ~= nil then
                    f_description = entry.Progression[i].Description .. entry.Progression[i].Append
                    entry.Progression[i].Description = f_description
                end

                if entry.Progression[1].Nodes ~= nil then
                    for _, v in ipairs(entry.Progression[1].Nodes) do
                        if f_nodes then
                            for _, n in ipairs(f_nodes) do
                                if v.Name == n.Name then
                                    if v.Color == nil then
                                        v.Color = n.Color
                                    else
                                        n.Color = v.Color
                                    end
                                    if v.NoLine == nil then
                                        v.NoLine = n.NoLine
                                    else
                                        n.NoLine = v.NoLine
                                    end
                                    if v.EnforceColor == nil then
                                        v.EnforceColor = n.EnforceColor
                                    else
                                        n.EnforceColor = v.EnforceColor
                                    end
                                end
                            end
                        end
                    end
                end
            end

            table.insert(NodemapUi.entries, entry)
        end
    end

    parse.requiredString("#End")

    parse.stop()

end

--- Clamps a color value to the range 0-255.
--- @param val number The value to clamp
--- @return number result The clamped value
function NodemapUi:clampColorValue(val)
    if val < 0 then
        return 0
    elseif val > 255 then
        return 255
    else
        return math.floor(val)
    end
end

--- Verifies that the icon exists in the icons table.
--- @param icon string The icon to verify
--- @return boolean result Whether the icon exists
function NodemapUi:verifyIcon(icon)
    for k, v in pairs(NodemapUi.icons) do
        if icon == k then
            return true
        end
    end

    return false
end

--- Gets the bitmap for the given system.
--- @param name string The name of the system
--- @return string result The bitmap for the system
function NodemapUi:getBitmap(name)
    return NodemapUi.icons[name]
end

--- Gets the RGB values for the given color.
--- @param color string The color to get the RGB values for
--- @return table<number, number, number> result The RGB values for the color
function NodemapUi:getRGB(color)
    return NodemapUi.colorValues[color]
end

--- Limits the given value to the range 0-1.
--- @param val number The value to limit
--- @return number result The limited value
function NodemapUi:limitCoords(val)
    if val < 0 then
        return 0
    elseif val > 1 then
        return 1
    end

    return val
end

--- Parses the tables for the node map.
--- @return nil
function NodemapUi:parseTables()
    self.entries = {}
    self.icons = {}
    self.colorValues = {}

    ScpuiSystem:parseTable(NodemapUi, NodemapUi.parseSystems, "nodemap", "nmap")
end

return NodemapUi