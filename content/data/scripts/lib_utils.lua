-----------------------------------
--This file contains many miscellaneous utility functions that can be used in any script
-----------------------------------

local utils = {}

utils.table = {}


--- Round a number to a specified number of decimal places
--- @param num number The number to round
--- @param decimal_places? number The number of decimal places to round to
--- @return number The rounded number
function utils.round(num, decimal_places)
    local places = decimal_places or 0
    local multiplier = 10^places
    return math.floor(num * multiplier + 0.5) / multiplier
end

--- Check if a value is even
--- @param number number The number to check
--- @return boolean result Whether the number is even
function utils.isEven(number)
    return number % 2 == 0
end

--- Check if a value is odd
--- @param number number The number to check
--- @return boolean result Whether the number is odd
function utils.isOdd(number)
    return number % 2 ~= 0
end

--- Parses an XSTR from Custom data if it's formatted like so:
---  +Val: NAME "string", #
--- and returns the string and id in a table That can be sent to ba.XSTR()
--- @param text string The XSTR to parse
--- @return table<string, number> The parsed XSTR
function utils.parseCustomXSTR(text)

	local input_string = text
	local result = {}

	-- Remove the leading and trailing parentheses
	text = string.gsub(text, "^%(", "")
	text = string.gsub(text, "%)$", "")

	-- Extract the values inside quotation marks
	local quoated_value = string.match(input_string, '"([^"]+)"')

	-- Extract the number after the comma
	local number_value = tonumber(string.match(input_string, ',%s*(-?%d+)'))

	if not quoated_value then
		ba.warning("Could not find the string in the xstr '" .. input_string .. "'. Expected it to be contained within quotation marks.")
		quoated_value = ""
	end

	if not number_value then
		ba.warning("Could not find the number in the xstr '" .. input_string .. "'. Expected it to be a valid number after a comma.")
		number_value = -1
	end

	table.insert(result, quoated_value)
	table.insert(result, number_value)

	return result

end

--Translates an XSTR from Custom data if it's formatted like so:
-- +Val: NAME "string", #
--and returns translated string. Similar to parseCustomXSTR, but returns the translated string directly by calling ba.XSTR() internally
---@param text string The XSTR to parse
---@return string text The translated XSTR
function utils.translateCustomXSTR(text)
	local result = utils.parseCustomXSTR(text)
	return ba.XSTR(result[1], result[2])
end

--- Parses a comma separated list into a table of values
--- @param input_string string The comma separated list to parse
--- @return table<string> The parsed list of values
function utils.parseCommaSeparatedList(input_string)
    local result = {}
    -- Split the string by comma
    for value in input_string:gmatch("[^,]+") do
        -- Trim leading and trailing whitespace from each value
        local trimmed_value = value:match("^%s*(.-)%s*$")
        table.insert(result, trimmed_value)
    end

    return result
end

--- A wrapper for mn.runSEXP that is not fucking stupid. Will take the arguments and construct the mn.runSEXP() call for you.
--- @param sexp string The SEXP to run
--- @param ... any The arguments to pass to the SEXP
--- @return boolean Whether the SEXP was run successfully
function utils.runSEXP(sexp, ...)

	local sexp_string = sexp
	local warned = false

	for _, data in ipairs(arg) do

		if data ~= nil and data ~= "" then
            ---@type any
			local param = ""

			if type(data) == "boolean" then
				param = "( " .. tostring(data) .. " )"
			elseif type(data) == "number" then
				param = math.floor(data)
			elseif type(data) == "string" then
                param = "!" .. data:gsub("!", "!!") .. "!"
            end

			if param ~= "" then
				sexp_string = sexp_string .. " " .. param
			else
				ba.warning("Util runSEXP() got parameter '" .. tostring(data) .. "' which is not a valid data type! Must be boolean, number, or string.")
				warned = true
			end

		end

	end

	if not warned then
		return mn.runSEXP("( " .. sexp_string .. " )")
	end

	return false

end

--- A wrapper for mn.evaluateSEXP that is not fucking stupid. Will take the arguments and construct the mn.evaluateSEXP() call for you.
--- @param sexp string The SEXP to run
--- @param ... any The arguments to pass to the SEXP
--- @return boolean Whether the SEXP was run successfully
function utils.evaluateSEXP(sexp, ...)

	local sexp_string = sexp
	local warned = false

	for _, data in ipairs(arg) do

		if data ~= nil and data ~= "" then
            ---@type any
			local param = ""

			if type(data) == "boolean" then
				param = "( " .. tostring(data) .. " )"
			elseif type(data) == "number" then
				param = math.floor(data)
			elseif type(data) == "string" then
                param = "!" .. data:gsub("!", "!!") .. "!"
            end

			if param ~= "" then
				sexp_string = sexp_string .. " " .. param
			else
				ba.warning("Util evaluateSEXP() got parameter '" .. tostring(data) .. "' which is not a valid data type! Must be boolean, number, or string.")
				warned = true
			end

		end

	end

	if not warned then
		return mn.evaluateSEXP("( " .. sexp_string .. " )")
	end

	return false

end

--- Removes data in a save table that is tied to pilots that can no longer be found
--- @param data table The save data to clean
--- @return table data The cleaned save data
function utils.cleanPilotsFromSaveData(data)

	--get the pilots list
	local pilots = ui.PilotSelect.enumeratePilots()

	local clean_data = {}

	-- for each existing pilot, keep the data
	for _, v in ipairs(pilots) do
		if data[v] ~= nil then
			clean_data[v] = data[v]
		end
    end

	return clean_data
end

--- Check if an animation file exists. Checks all valid extensions
--- @param name string The name of the animation file to check
--- @return boolean exists Whether the animation file exists
function utils.animExists(name)
	--remove extension if it's included
	local file = name:match("(.+)%..+")

	if file == nil then
		file = name
	end

	--now see if it exists
	local anim_exts = {".png", ".ani", ".eff"}
	for i = 1, #anim_exts do
		local this_file = file .. anim_exts[i]
		if cf.fileExists(this_file, "", true) then
			return true
		end
	end
	return false
end

--- Gets the index of a value in a table
--- @param tab table The table to search
--- @param val any The value to search for
--- @return number index The index of the value in the table, -1 if not found
function utils.getTableIndex(tab, val)

	for i, v in ipairs(tab) do
		if v.name == val then
			return i
		end
	end

	return -1

end

--- Remove an extension from a filename
--- @param name string The filename to remove the extension from
--- @return string name The filename without the extension
function utils.strip_extension(name)
    local text, count = string.gsub(name, "%..+$", "")
    return text
end

--- Check if a file has an extension of any kind
--- @param filename string The filename to check
--- @return boolean value Whether the file has an extension
function utils.hasExtension(filename)
    local last_dot_index = filename:find("%.[^%.]*$")
    return last_dot_index ~= nil
end

--- Check if a value is one of multiple values
--- @param val any The value to check
--- @param ... any The values to check against
--- @return boolean result Whether the value is one of the specified values
function utils.isOneOf(val, ...)
    for _,k in ipairs({...}) do
        if val == k then
            return true
        end
    end
    return false
end

--- Extract part of a string up to a specified character
--- @param inputstr string The string to extract from
--- @param stop string The character to stop at
--- @return string text The extracted string
function utils.extractString(inputstr, stop)
	local start_index, end_index = string.find(inputstr, stop)

    -- Check if an underscore was found
    if start_index then
        -- Extract the substring from the start to the first underscore
        return string.sub(inputstr, 1, start_index - 1)
    else
		return inputstr
	end
end

--- Convert rgba color values to a hex color code
--- @param r number The red value
--- @param g number The green value
--- @param b number The blue value
--- @param a number The alpha value
--- @return string hex The hex color code
function utils.rgbaToHex(r, g, b, a)
    -- Ensure all values are within the 0-255 range
    r = math.max(0, math.min(255, r))
    g = math.max(0, math.min(255, g))
    b = math.max(0, math.min(255, b))
    a = math.max(0, math.min(255, a))

    -- Format the values as a hexadecimal color code
    return string.format("#%02X%02X%02X%02X", r, g, b, a)
end

--- Converts a hexadecimal color string to RGBA values
--- @param hex string The hexadecimal color string (e.g., "#RRGGBB" or "#RRGGBBAA")
--- @return number, number, number, number values The RGBA values (0-255)
function utils.hexToRgba(hex)
    -- Ensure the hex starts with '#' and is the correct length
    if not hex or not hex:match("^#%x%x%x%x%x%x") then
        return 255, 255, 255, 255 -- Default to white with full opacity
    end

    -- Remove the '#' prefix
    hex = hex:sub(2)

    -- Extract RGBA values
    local r, g, b, a
    if #hex == 6 then
        -- Hex format is RRGGBB
        r, g, b = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
        a = 255 -- Default alpha
    elseif #hex == 8 then
        -- Hex format is RRGGBBAA
        r, g, b, a = tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16), tonumber(hex:sub(7, 8), 16)
    else
        return 255, 255, 255, 255 -- Default to white with full opacity
    end

    return r, g, b, a
end


--- Split a string using a separator or space if separator is not provided
--- @param inputstr string The string to split
--- @param sep? string The separator to split by
--- @return table<string> strings The split strings
function utils.split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, utils.trim(str))
    end
    return t
end

--- Load a config file as json and return the data in a table
--- @param filename string The name of the config file to load
--- @return table data The loaded config data
function utils.loadConfig(filename)
  ---@type json
  local Json = require('dkjson')
  local file = cf.openFile(filename, 'r', 'data/config')
  local config = Json.decode(file:read('*a'))
  file:close()
  if not config then
    ba.error('Please ensure that ' .. filename .. ' exists in data/config and is valid JSON.')
  end
  return config
end

--- A wrapper for ba.XSTR that can take a string or a table with a string and an id and return the translated string
--- @param message string|table<string, number> The message to translate
--- @param id? number The id of the message to translate
--- @return string text The translated string
function utils.xstr(message, id)
  if id then
    return ba.XSTR(tostring(message), id)
  elseif type(message) == 'string' then
    ba.print('Utils.lua: Got string with missing XSTR index: ' .. message .. "\n")
    return message
  else
    return ba.XSTR(message[1], message[2])
  end
end

--- Clamp a value between a minimum and maximum
--- @param value number The value to clamp
--- @param minimum number The minimum value
--- @param maximum number The maximum value
--- @return number clamped The clamped value
function utils.clamp(value, minimum, maximum)
  if value < minimum then
    return minimum
  elseif value > maximum then
    return maximum
  else
    return value
  end
end

--- Call this as copy(someData) and ignore the seen parameter. It's used internally.
--- @param obj any The data to copy
--- @param seen? table Ignored value, do not use
--- @return any copy The copied data
function utils.copy(obj, seen)
  if type(obj) ~= 'table' then return obj end
  if seen and seen[obj] then return seen[obj] end
  local s = seen or {}
  local res = setmetatable({}, getmetatable(obj))
  s[obj] = res
  for k, v in pairs(obj) do res[utils.copy(k, s)] = utils.copy(v, s) end
  return res
end

--- Get a percentage as a string based on a fraction and a total
--- @param fract number The fraction to calculate the percentage of
--- @param total number The total to calculate the percentage of
--- @return string percentage The percentage as a string
function utils.compute_percentage(fract, total)
    if total <= 0 then
        return "0%"
    end

    return string.format("%.2f%%", (fract / total) * 100)
end

--- Get a random number between two values, but safely
--- @param min number The minimum value
--- @param max number The maximum value
--- @param exact? boolean if true return an integer, else return a float
--- @return number rand The random number
function utils.safeRand(min, max, exact)
    if (min == nil and max ~= nil) then
        return max
    elseif (max == nil and min ~= nil) then
        return min
    elseif (min == nil and max == nil) then
        return 0
    end

    if (min == max) then
        return min
    end

    if (exact) then
        if (min > max) then
            return math.random(max, min)
        else
            return math.random(min, max)
        end
    else
        if (min > max) then
            return max + (min - max) * math.random()
        else
            return min + (max - min) * math.random()
        end
    end
end

--- Get the length of a table
--- @param T table The table to get the length of
--- @return number count The length of the table
function utils.tableLength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
end

--- Check if a string starts with a specified pattern
--- @param str string The string to check
--- @param pattern string The pattern to check for
--- @return boolean startsWith Whether the string starts with the pattern
function utils.stringStartsWith(str, pattern)
	return str:sub(1, #pattern) == pattern
end

--- Remove leading and trailing whitespace from a string
--- @param str string The string to trim
--- @return string trimmed The trimmed string
function utils.trim(str)
	return str:find'^%s*$' and '' or str:match'^%s*(.*%S)'
end

--- Find the first occurrence of any of the specified patterns in a string
---@param str string The string to search
---@param patterns string[] The patterns to search for
---@param start_idx number The index to start searching from
---@return ... The result of the search, if any
function utils.find_first_either(str, patterns, start_idx)
    local first_result = nil
    for i, v in ipairs(patterns) do
        local values = { str:find(v, start_idx) }

        if values[1] ~= nil then
            if first_result == nil then
                first_result = values
            elseif values[1] < first_result[1] then
                first_result = values
            end
        end
    end

    if first_result == nil then
        return nil
    else
        return unpack(first_result)
    end
end

--- Replace certain rml key characters with their direct HTML equivalents
--- Replaces < with &lt;, > with &gt;, & with &amp;, and " with &quot;
--- @param inputStr string The string to escape
--- @return string text The escaped string
function utils.rml_escape(inputStr)
    local escaped = inputStr:gsub('[<>&"]', function(char)
        if char == "<" then
            return "&lt;"
        end

        if char == ">" then
            return "&gt;"
        end

        if char == "&" then
            return "&amp;"
        end

        if char == "\"" then
            return "&quot;"
        end
    end)

    return escaped
end

--- Truncate a string at the first hash character
--- @param inputstr string The string to truncate
--- @return string truncated The truncated string
function utils.truncateAtHash(inputstr)
    local hash_position = inputstr:find("#") -- Find the position of the first #
    if hash_position then
        return inputstr:sub(1, hash_position - 1) -- Return the substring up to (but not including) the #
    else
        return inputstr -- If no # is found, return the original string
    end
end

--- Find a value in a table and return its index using ipairs
--- @param tbl table The table to search
--- @param val any The value to search for
--- @param compare? fun(a:any, b:any):boolean The comparison function to use
--- @return number index The index of the value in the table, -1 if not found
function utils.table.ifind(tbl, val, compare)
    for i, v in ipairs(tbl) do
        if compare ~= nil then
            if compare(v, val) then
                return i
            end
        else
            if v == val then
                return i
            end
        end
    end

    return -1
end

--- Find a value in a table and return its index using pairs
--- @param tbl table The table to search
--- @param val any The value to search for
--- @param compare? fun(a:any, b:any):boolean The comparison function to use
--- @return number | nil index The index of the value in the table, nil if not found
function utils.table.find(tbl, val, compare)
    for i, v in pairs(tbl) do
        if compare ~= nil then
            if compare(v, val) then
                return i
            end
        else
            if v == val then
                return i
            end
        end
    end

    return nil
end

function utils.table.contains(tbl, val, compare)
    return utils.table.find(tbl, val, compare) ~= nil
end

--- Remove an element from a table by value
--- @param tbl table The table to remove the value from
--- @param val any The value to remove
--- @param compare? fun(a:any, b:any):boolean The comparison function to use
--- @return number index The index of the removed value in the table
function utils.table.iremove_el(tbl, val, compare)
    local i = utils.table.ifind(tbl, val, compare)
    if i >= 1 then
        table.remove(tbl, i)
    end
    return i
end

--- Maps an input array using a function
--- @generic T
--- @generic V
--- @param tbl T[] The table to map
--- @param map_fun fun(el:T):V The function to map with
--- @return V[] The mapped table
function utils.table.map(tbl, map_fun)
    local out = {}
    for i, v in ipairs(tbl) do
        out[i] = map_fun(v)
    end
    return out
end

--- Reduces a list of values to a single value
--- @generic T
--- @generic V
--- @param tbl T[] The table to reduce
--- @param reduceFn fun(accumulator: V, el: T):V The function to reduce with
--- @param initial V Initial value to use
--- @return V The final value after all elements have been looked at
function utils.table.reduce(tbl, reduceFn, initial)
    local acc = initial
    for _, v in ipairs(tbl) do
        acc = reduceFn(acc, v)
    end
    return acc
end

--- Computes the sum of the specified table
--- @param tbl number[] The table to sum
--- @return number sum The sum of the table
function utils.table.sum(tbl)
    return utils.table.reduce(tbl, function(sum, el)
        return sum + el
    end, 0)
end

return utils
