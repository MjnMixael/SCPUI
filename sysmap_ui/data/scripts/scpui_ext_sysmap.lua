---@class sysmap_entry
---@field Name string The system name and its localization ID.
---@field Background string The background resource ID for the system map.
---@field Description string # The system description and its localization ID.
---@field Elements sysmap_element[] # A table of named elements within the system (e.g., planets, stations, nodes).
---@field ZoomOutTo string|nil The target for zooming out from this system (optional).
---@field Key string|nil The key for the system map entry (optional).
---@field Width number|nil The width of the system map (optional).
---@field Height number|nil The height of the system map (optional).

---@class sysmap_element
---@field ObjectName string The display name of the element (e.g., planet or station name).
---@field Orbits? string The name of the object this element orbits (e.g., the star or planet name).
---@field Orbit sysmap_orbit Orbit details such as angle, distance, and color.
---@field ParentOrbit sysmap_orbit|nil Optional orbit details for the parent object.
---@field Offset sysmap_offset|nil Optional offset for positioning elements in the map.
---@field IconOverride string|nil Optional icon resource override for the element.
---@field ModelOrientation number[]|nil Orientation of the model in 3D space ([pitch, yaw, roll]). Nil unless rendering
---@field RotationSpeed number|nil Rotation speed of the element (optional). Nil unless rendering
---@field ZoomLevel? number (Optional) The zoom level for the object. Nil unless rendering
---@field Selectable boolean Whether the element is selectable in the UI.
---@field ShowNew boolean Whether to display the "new" indicator for the element.
---@field ShowNewPersist boolean Whether to persist the "new" indicator for the element.
---@field ShowOrbit boolean|nil Whether to display the orbit path (optional).
---@field Visible boolean Whether the element is visible in the UI.
---@field ZoomTo string|nil The target for zooming in on this element (optional).
---@field Seen boolean|nil Whether the element has been seen by the player (optional).
---@field Name? string The name of the entry as a string. Added from the object reference during rendering.
---@field Bitmap? string The filename of the bitmap representing the object on the system map. Added from the object reference during rendering.
---@field ShipClass? string The class or type of ship/station/object associated with the entry. Added from the object reference during rendering.
---@field PropClass? string The class or type of prop associated with the entry. Added from the object reference during rendering.
---@field Description? string A table containing the description text of the entry as a string and its XSTR ID as a number. Added from the object reference during rendering.
---@field LargeBitmap? string The filename of a larger bitmap for the entry (e.g., for detailed views). Added from the object reference during rendering.
---@field UseTechDescription? boolean Whether to use the tech description for the entry. Added from the object reference during rendering.
---@field NameOverride? string A table containing the name override of the entry as a string and its XSTR ID as a number. Added from the object reference during rendering.
---@field BitmapX? number The X-coordinate of the bitmap on the system map. Added from the object reference during rendering.
---@field BitmapY? number The Y-coordinate of the bitmap on the system map. Added from the object reference during rendering.
---@field SeenElement? Element The element reference for the seen status. Added from the object reference during rendering.
---@field Text? string The text to display for the element. Added from the object reference during rendering.

---@class sysmap_orbit
---@field Angle? number The angle of the orbit in degrees.
---@field Distance? number The distance from the center of the system.
---@field Color number[]|nil Optional RGBA color values for the orbit ([R, G, B, A]).
---@field Width number|nil Optional orbit width for rendering.

---@class sysmap_offset
---@field X number X-offset for positioning the element.
---@field Y number Y-offset for positioning the element.

---@class sysmap_save_data
---@field Visbility table<string, boolean> Visibility data for icons.
---@field Maps table<string, table<string, boolean>> Map data for icons.
---@field Persistent table<string, boolean> Persistent data for icons.

---@class sysmap_object
---@field Name string A table containing the name of the entry as a string and its XSTR ID as a number.
---@field DisplayName string The display name of the object.
---@field Bitmap string The filename of the bitmap representing the object on the system map.
---@field ShipClass? string (Optional) The class or type of ship/station/object associated with the entry.
---@field PropClass? string (Optional) The class or type of prop associated with the entry.
---@field Description? string (Optional) A table containing the description text of the entry as a string and its XSTR ID as a number.
---@field LargeBitmap? string (Optional) The filename of a larger bitmap for the entry (e.g., for detailed views).
---@field UseTechDescription? boolean (Optional) Whether to use the tech description for the entry.

---@class sysmap_campaign_config
---@field Default string The default system key.
---@field Missions table<string, string> Mapping of mission filenames to system names.

---@class sysmap_data
---@field Objects sysmap_object[] A table of system map objects, indexed by their names.
---@field Configs? table<string, any> A table containing configuration data for the system map.
---@field Systems sysmap_entry[] A table of system map entries, indexed by their names.

--- Scpui System Map Extension
--- @class SysmapUi
--- @field loadSysMapTables fun(self: SysmapUi, objectsOnly: boolean?, noCache: boolean?): sysmap_data Parses a system map table from the specified file.
--- @field CachedData sysmap_data Cached data for the system map.

local SysmapUi = {
    Name = "System Map",
    Version = "1.0.0",
    Submodule = "sysm",
    Key = "SysmapUi"
}

--- Initialize the SysmapUi object. Called after the sysmap extension is registered with SCPUI
--- @return nil
function SysmapUi:init()
    -- Register nodemap-specific topics
    ScpuiSystem:registerExtensionTopics("systemmap", {
        initialize = function() return nil end,
        keydown = function() return false end,
        unload = function() return nil end
    })

    self.CachedData = self:loadSysMapTables(true)

    self:postProcessData()

    if ba.inMissionEditor() then
        local action_list = mn.LuaEnums["SysMapObjects"]

        -- Add each object name to FRED in alphabetical order
        local fred_list = {}
        for name in pairs(self.CachedData.Objects or {}) do
            table.insert(fred_list, name)
        end
        table.sort(fred_list)
        for _, name in ipairs(fred_list) do
            action_list:addEnumItem(name)
        end
    else
        mn.LuaSEXPs['set-sysmap-visibility'].Action = function(icon, visibility)
            local SysMapUtils = require('lib_sysmap_utils')
            SysMapUtils:setIconVisibility(icon, visibility)
        end

        ScpuiSystem:addHook("On Campaign Begin", function()
            local SysMapUtils = require('lib_sysmap_utils')
            SysMapUtils:resetData()
        end)
    end
end

--- Post-processes the loaded system map data to warn for invalid data
--- @return nil
function SysmapUi:postProcessData()
    for _, system in pairs(self.CachedData.Systems) do
        if system.ZoomOutTo and not self.CachedData.Systems[system.ZoomOutTo] then
            ba.error("SystemMap system '" .. system.Key .. "' has ZoomOutTo set to '" .. system.ZoomOutTo .. "' but that system does not exist!")
        end
        for _, element in pairs(system.Elements) do
            if element.ObjectName and not self.CachedData.Objects[element.ObjectName] then
                ba.error("SystemMap element '" .. element.ObjectName .. "' in system '" .. system.Key .. "' does not exist!")
            end
            if element.ZoomTo and not self.CachedData.Systems[element.ZoomTo] then
                ba.error("SystemMap element '" .. element.ObjectName .. "' in system '" .. system.Key .. "' has ZoomTo set to '" .. element.ZoomTo .. "' but that system does not exist!")
            end
            if element.Orbits and not system.Elements[element.Orbits] then
                ba.error("SystemMap element '" .. element.ObjectName .. "' in system '" .. system.Key .. "' has Orbits set to '" .. element.Orbits .. "' but that element does not exist!")
            end
        end
    end
end

--- Parses the system map tbl and tbm files
--- @param noCache boolean If true, load from disk, otherwise load from cache. Defaults to false.
--- @return sysmap_data result The parsed components (objects, config, systems)
function SysmapUi:loadSysMapTables(noCache)

    if not noCache and self.CachedData then
        return self.CachedData
    end

    ---@type sysmap_data
    local merged = {
        Objects = {},
        Configs = {},
        Systems = {}
    }

    --- Merge the results of all system map tables
    --- @param partial sysmap_data The parsed data from a single table
    --- @return nil
    local function mergeResults(partial)
        -- Merge objects (simple key-to-entry)
        for k, v in pairs(partial.Objects or {}) do
            merged.Objects[k] = v
        end

        -- Merge config (simple key-to-entry)
        for k, v in pairs(partial.Configs or {}) do
            merged.Configs[k] = v
        end

        -- Merge systems (simple key-to-entry)
        for k, v in pairs(partial.Systems or {}) do
            merged.Systems[k] = v
        end
    end

    if cf.fileExists("system_map.tbl", "", true) then
        mergeResults(self:parseTable("system_map.tbl"))
    end
    for _, v in ipairs(cf.listFiles("data/tables", "*-smap.tbm")) do
        mergeResults(self:parseTable(v))
    end

    return merged
end


--- Parses the system map table
--- @param data string the name of the file to parse
--- @return sysmap_data result The parsed components (objects, config, systems)
function SysmapUi:parseTable(data)
    ba.print("SCPUI is parsing " .. data .. "\n")

    ---@type sysmap_data
    local result = {
        Objects = {},
        Configs = {},
        Systems = {}
    }

    if not parse.readFileText(data, "data/tables") then
        return result
    end

    if parse.optionalString("#Objects") then
        while parse.optionalString("$Name:") do
            local object = self:parseSystemMapObject()
            if object.Name then
                if result.Objects[object.Name] then
                    ba.warning("Duplicate SystemMap object '" .. object.Name .. "' found in " .. data .. ". Data will be overwritten!")
                end
                ba.print("SCPUI found SystemMap object '" .. object.Name .. "' in " .. data .. "\n")
                result.Objects[object.Name] = object
            end
        end
    end

    if parse.optionalString("#Config") then
        result.Configs = self:parseConfigSection()
    end

    if parse.optionalString("#Systems") then
        while parse.optionalString("$Name:") do
            local system = self:parseSystemMapSystem()
            if system.Key then
                if result.Systems[system.Key] then
                    ba.warning("Duplicate SystemMap system '" .. system.Key .. "' found in " .. data .. ". Data will be overwritten!")
                end
                result.Systems[system.Key] = system
            end
        end
    end

    parse.stop()
    return result
end

--- Parses a single object entry in the #Objects section
--- @return sysmap_object object The parsed object definition
function SysmapUi:parseSystemMapObject()

	---@type sysmap_object
    local obj = {
		Name = "",
        DisplayName = "",
		Bitmap = "",
	}

    -- Required: Name
    obj.Name = parse.getString()

    if parse.optionalString("$Display Name:") then
        obj.DisplayName = parse.getString()
    else
        obj.DisplayName = obj.Name
    end

    -- Optional: Bitmap
    if parse.optionalString("$Bitmap:") then
        obj.Bitmap = parse.getString()
    end

    if not obj.Bitmap or obj.Bitmap == "" then
        ba.warning("SystemMap object '" .. obj.Name .. "' has no bitmap defined!")
    end

    -- Optional: LargeBitmap
    if parse.optionalString("$Large Bitmap:") then
        obj.LargeBitmap = parse.getString()
    end

    if obj.LargeBitmap == "" then
        ba.warning("SystemMap object '" .. obj.Name .. "' has invalid large bitmap defined!")
    end

    -- Optional: ShipClass
    if parse.optionalString("$Ship Class:") then
        obj.ShipClass = parse.getString()
    end

    if obj.ShipClass and tb.ShipClasses[obj.ShipClass] == nil then
        ba.warning("SystemMap object '" .. obj.Name .. "' has invalid ship class defined!")
    end

    -- Optional: PropClass
    if parse.optionalString("$Prop Class:") then
        obj.PropClass = parse.getString()
    end

    if obj.PropClass and tb.PropClasses[obj.PropClass] == nil then
        ba.warning("SystemMap object '" .. obj.Name .. "' has invalid prop class defined!")
    end

    -- Required: Description (as xstr pair)
    if parse.optionalString("$Description:") then
        obj.Description = parse.getString()
    end

    -- Optional: UseTechDescription
    if parse.optionalString("$Use Tech Description:") then
        obj.UseTechDescription = parse.getBoolean()

        if obj.ShipClass == nil and obj.UseTechDescription then
            ba.warning("SystemMap object '" .. obj.Name .. "' has UseTechDescription set to true but no ShipClass defined!")
            obj.UseTechDescription = false
        end
    else
        obj.UseTechDescription = false
    end

    return obj
end

--- Parses the #Config section and returns a Configs table
--- @return sysmap_campaign_config[] Configs
function SysmapUi:parseConfigSection()
    ---@type sysmap_campaign_config[]
    local configs = {}

    while parse.optionalString("$Campaign:") do
        local campaign = parse.getString()
        local cfg = {
            Missions = {}
        }

        if parse.requiredString("+Default System:") then
            cfg.Default = parse.getString()
        end

        while parse.optionalString("$Mission Map:") do
            parse.requiredString("+Mission:")
            local mission = parse.getString()

            parse.requiredString("+System:")
            local system = parse.getString()

            cfg.Missions[mission] = system
        end

        if configs[campaign] then
            ba.warning("Duplicate #Config for campaign '" .. campaign .. "'. Overwriting previous entry.")
        end

        configs[campaign] = cfg
    end

    return configs
end

--- Parse a single system in the #Systems section
--- @return sysmap_entry system
function SysmapUi:parseSystemMapSystem()
    local key = parse.getString()

    ---@type sysmap_entry
    local system = {
        Key = key,
        Elements = {},
        Name = "",
        Background = "",
        Description = "",
    }

    parse.requiredString("$Display Name:")
    system.Name = parse.getString()

    parse.requiredString("$Background:")
    system.Background = parse.getString()

    if parse.optionalString("$Description:") then
        system.Description = parse.getString()
    end

    if parse.optionalString("$Zoom Out To:") then
        system.ZoomOutTo = parse.getString()
    end

    while parse.optionalString("$Element:") do
        local element = self:parseSystemMapElement()
        system.Elements[element.ObjectName] = element
    end

    return system
end

--- Parses a single $Element: entry within a system
--- @return sysmap_element element
function SysmapUi:parseSystemMapElement()
    local Utils = require('lib_utils')

    --- Trim leading and trailing junk from a string containing numbers
    --- @param str string The string to clean
    --- @return string str The cleaned string with leading and trailing junk removed
    local function cleanNumericList(str)
        -- Remove everything before the first digit or minus sign (but preserve it)
        str = str:match("[-%d].*")
        -- Remove everything after the last digit
        str = str and str:match(".*[%d]") or str
        return str or ""
    end

    ---@type sysmap_element
    local element = {
        ObjectName = "",
        Selectable = true,
        Visible = true,
        ShowOrbit = false,
        ShowNew = true,
        ShowNewPersist = true,
        Offset = {
            X = 0,
            Y = 0
        },
        Orbit = {
            Angle = 0,
            Distance = 0,
        },
        ModelOrientation = {0, 0, 0},
    }

    -- Required: ObjectName
    parse.requiredString("+Object:")
    element.ObjectName = parse.getString()

    -- Optional overrides
    if parse.optionalString("+Name Override:") then
        element.NameOverride = parse.getString()
    end
    if parse.optionalString("+Icon Override:") then
        element.IconOverride = parse.getString()
    end

    -- Optional booleans
    if parse.optionalString("+Selectable:") then
        element.Selectable = parse.getBoolean()
    end
    if parse.optionalString("+Visible:") then
        element.Visible = parse.getBoolean()
    end
    if parse.optionalString("+Show Orbit:") then
        element.ShowOrbit = parse.getBoolean()
    end
    if parse.optionalString("+Show New:") then
        element.ShowNew = parse.getBoolean()
    end
    if parse.optionalString("+Show New Persist:") then
        element.ShowNewPersist = parse.getBoolean()
    end

    -- Optional Navigation
    if parse.optionalString("+Zoom To:") then
        element.ZoomTo = parse.getString()
    end

    -- Optional model properties
    if parse.optionalString("+Model Rotation Speed:") then
        element.RotationSpeed = parse.getFloat()
    end
    if parse.optionalString("+Model Orientation:") then
        local float_list = parse.getString()
        if float_list then
            local float_table = Utils.parseCommaSeparatedList(cleanNumericList(float_list))
            element.ModelOrientation = {
                tonumber(float_table[1]) or 0,
                tonumber(float_table[2]) or 0,
                tonumber(float_table[3]) or 0,
            }
        end
    end

    -- Optional Offset
    if parse.optionalString("+Offset:") then
        local float_list = parse.getString()
        if float_list then
            local float_table = Utils.parseCommaSeparatedList(cleanNumericList(float_list))
            element.Offset.X = tonumber(float_table[1]) or 0
            element.Offset.Y = tonumber(float_table[2]) or 0
        end
    end

    -- Optional Orbit Properties
    if parse.optionalString("+Orbits:") then
        element.Orbits = parse.getString()
    end
    if parse.optionalString("+Orbit Angle:") then
        element.Orbit.Angle = parse.getFloat()
    end
    if parse.optionalString("+Orbit Distance:") then
        element.Orbit.Distance = parse.getFloat()
    end
    if parse.optionalString ("+Orbit Width:") then
        element.Orbit.Width = parse.getFloat()
    end
    if parse.optionalString("+Orbit Color:") then
        local float_list = parse.getString()
        if float_list then
            local float_table = Utils.parseCommaSeparatedList(cleanNumericList(float_list))
            element.Orbit.Color = {
                tonumber(float_table[1]) or 128,
                tonumber(float_table[2]) or 128,
                tonumber(float_table[3]) or 128,
                tonumber(float_table[4]) or 255
            }
        end
    end

    return element
end

return SysmapUi