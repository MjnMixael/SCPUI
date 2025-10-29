-----------------------------------
--This contains the keyword algorithm for colorizing text in the game based on the keywords.tbl
-----------------------------------

--[[
A "term" is either a non-empty sequence characters such that each character the
sequence is a word character or ' character, or no character in the sequence is
any of those. For example, "the Intrepid's battlegroup" contains the terms
"the", " ", "Intrepid's", " ", and "battlegroup".

Keywords are broken up into terms and arranged in a tree structure. Each node
in the tree can have a color, but doesn't need to. For example, suppose
"Admiral Po" is defined as blue, "Admiral Glaive" is defined as red, and
"Admiral" is defined as white for some reason. We'd get the following tree:

  keywords['Admiral']                (white)
  keywords['Admiral'][' ']           (no color)
  keywords['Admiral'][' ']['Po']     (blue)
  keywords['Admiral'][' ']['Glaive'] (red)

When it comes time to apply colorization, we start with a term and see if it
is a key into the keywords table. If it is, we repeatedly check the next
term and descend further into the tree. Once we find a term that isn't a
match, we stop and check if our match has a color. If not, we backtrack
until we find one that is.

For example, given the input 'Admiral Po', we'd see that 'Admiral' is a
valid key, ' ' is a valid sub-key, and 'Po' is a valid sub-sub-key, and
color it blue. Given 'Admiral Poopypants', we'd see that 'Admiral' is a
valid key and ' ' is a valid sub-key, but since 'Poopypants' isn't a valid
sub-sub-key, we stop there. However, keywords['Admiral'][' '] has no color,
so we backtrack to keywords['Admiral'], which does, and ultimately settle
on white.

There is one more caveat, which is that we only want to process keywords
which are not inside a valid HTML tag. This is supported further below.
]]

-- Some arbitrary key which is not a legal term
local COLOR = '<{@[ COLOR ]@}>'
local TOOLTIP = '<{@[ TOOLTIP ]@}>'

--- Get all the terms in a string.
--- @param s string
--- @return table
local function getTerms(s)
  -- Lua patterns don't support alternation, so we need to get creative.
  -- First, we'll find pairs of sequences such that the first sequence contains
  -- only word and ' characters, and the second contains only other characters,
  -- allowing empty sequences...
  local matches = s:gmatch("([%w'À-ÖØ-öø-ÿ]*)([^%w'À-ÖØ-öø-ÿ]*)")
  -- ...then, we flatten the result, removing empty sequences.
  local terms = {}
  for word, rest in matches do
    if word ~= '' then table.insert(terms, word) end
    if rest ~= '' then table.insert(terms, rest) end
  end
  return terms
end

-- The tree of keywords described at the top of this file.
local keywords = {}

--- Register a keyword with a color.
--- @param keyword string The keyword to register
--- @param color string The rcss color class to apply to the keyword
--- @param tooltip? string The tooltip to display when hovering over the keyword
--- @return boolean Whether the keyword was successfully registered
local function registerKeyword(keyword, color, tooltip)
  local node = keywords
  for _, term in ipairs(getTerms(keyword)) do
    local next_node = node[term]
    if not next_node then
      next_node = {}
      node[term] = next_node
    end
    node = next_node
  end
  if tooltip then
    node[TOOLTIP] = tooltip
  end
  if node[COLOR] then
    -- Unless we're registering the same color twice, this is a conflict.
    return node[COLOR] == color
  else
    node[COLOR] = color
    return true
  end
end

--- Get the color of a sequence of terms.
--- @param terms table The terms to colorize
--- @param index number The index of the first term to colorize
--- @param node table The node in the keyword tree to start from
--- @return number?, string?, string?
local function getColor(terms, index, node)
  -- This would probably perform better as an iterative function.
  -- Refactor if the recursion proves to be a performance issue.
  local term = terms[index]
  local next_node = node[term]
  if next_node then
    local next_index, next_color, next_tooltip = getColor(terms, index + 1, next_node)
    if next_color then
     return next_index, next_color, next_tooltip
    else
     return index, next_node[COLOR], next_node[TOOLTIP]
    end
  else
    return nil, nil, nil
  end
end

local tooltipRegister = {}

--- Colorize a fragment of text.
--- @param s string The fragment to colorize
--- @return string fragment The colorized fragment with html span tags added.
local function colorizeFragment(s)
  -- Take a fragment of literal text (i.e. text without any HTML tags in it),
  -- break it up into terms, and scan for keywords within those terms using the
  -- algorithm described at the top of this file.
  local i = 1
  local result = ''
  local terms = getTerms(s)
  local count = #terms
  while i <= count do
    local j, color, tooltip = getColor(terms, i, keywords)
    if j and color then
      -- We found a keyword! Color it and skip ahead if it spans multiple terms.

	  -- If we have a tooltip then add a unique id and register both
	  local id = ''
	  if tooltip then
		-- This uuid implementation is only has resolution up to 1 second so we supply a unique string instead
	    local uuid = require("lib_uuid")
		-- But that string can only be hex characters so let's jump through some hoops
		local function randomHexChar()
          local hex_chars = "0123456789abcdef"
		  return hex_chars:sub(math.random(1, #hex_chars), math.random(1, #hex_chars))
		end
		local function replaceNonHexWithRandomHex(input_string)
          return input_string:gsub("[^0-9a-fA-F]", function()
            return randomHexChar()
          end)
        end
		local key = uuid(j .. replaceNonHexWithRandomHex(tooltip) .. #tooltipRegister)

		-- Now register the tooltip with the uuid and set the id string
	    tooltipRegister[key] = tooltip
		id = "id='" .. key .. "'"
	  end
      result = result .. "<span " .. id .. " class='" .. color .. "' style='position: relative;'>"
      for x = i, j do
        result = result .. terms[x]
      end
      result = result .. '</span>'
      i = j + 1
    else
      -- We couldn't find any keywords, so return this term literally.
      result = result .. terms[i]
      i = i + 1
    end
  end
  return result
end

--- Colorize a string of text.
--- @param s string The text to colorize
--- @return string, table register The colorized text and a table of tooltips
local function colorize(s)
  -- Clear the tooltip register for this run
  tooltipRegister = {}
  -- This depth variable keeps track of whether we're nested inside a tag.
  local depth = 0
  -- A "fragment" is an HTML start tag (e.g. <span>), end tag (e.g. </span>),
  -- or self-closing tag (e.g. <br/>), or text that contains no tags. This
  -- pattern matches fragments, assuming that we're given valid HTML; it will
  -- technically behave incorrectly on invalid HTML, but libRocket won't handle
  -- that anyway, so whatever.
  return s:gsub('[<]?[^<>]*[>]?', function(x)
    if x:sub(1, 1) == '<' then
      if (x:sub(2, 2) == '/') then
        -- This is a start tag (e.g. <span>). Increase the nesting depth.
        depth = depth + 1
        return x
      elseif x:find('/>$') then
        -- This is a self-closing tag (e.g. <br/>). It has no effect on the
        -- nesting depth, but doesn't make sense to colorize.
        return x
      else
        -- This is a end tag (e.g. </span>). Decrease the nesting depth.
        depth = depth - 1
        return x
      end
    elseif depth == 0 then
      -- A depth of 0 means this fragment isn't nested. Colorize away!
      return colorizeFragment(x)
    else
      -- This fragment is nested, so don't colorize it.
      return x
    end
  end):gsub('> <', '>&nbsp;<'), tooltipRegister
end

return { colorize = colorize, registerKeyword = registerKeyword }

