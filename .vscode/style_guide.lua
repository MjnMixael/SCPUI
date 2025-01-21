--- @diagnostic disable: action-after-return

-----------------------------------
--SCPUI's Lua Style Guide
-----------------------------------

--- SCPUI follows the FreespaceOpen API's style for members and methods. It's somewhat non-standard to lua but
--- matching that style will make it easier to read and understand the codebase because SCPUI code and FSO API
--- code is often intermingled.
---
--- SCPUI is designed to use the Lua Language Server extension for Visual Studio Code for type-checking and intellisense.

ScpuiSystemGlobal = {} -- Represents the ScpuiSystem global table that must contain all members and methods. No other globals should exist.

local FirstLibrary = require("lib_first_library") -- Represents a library that is required by the ScpuiSystem global. Libraries included at the top of the file should use PascalCase
local SecondLibrary = require("lib_second_library") -- Multiple libriaries should be listed in alphabetical order

local Class = require("lib_class") -- Class is a special library that merges class-like tables together. It should always be listed separately from other libraries

local AbstractBriefingController = require("ctrlr_your_ui_controller") -- If a controller extends another controller, the parent controller should be required at the top of the file after the libraries are listed

--- The Ui Controller class should be created at the top of the file after all required libraries and parent controllers are listed
local MergedUiController = Class(AbstractBriefingController)



-----------------------------------
--- Members
-----------------------------------

ScpuiSystemGlobal.data = { -- Represents the data table that must contain all data-related members and methods. Each member must be documented in .vscode/scpui.lua
    MemberVariable = false, -- Represents a member variable. Variables use PascalCase
    CONSTANT = 0, -- Represents a constant. Constants use ALL_CAPS
    Iterable_List = {"item1", "item2", "item3"}, -- Represents an iterable list. Lists and tables use Pascal_Snake_Case
    sub_table = { -- Represents a sub-table. Sub-tables use snake_case and group related data logically to reduce namespace clutter
        SubTableMember = "value" -- Represents a member of a sub-table and follows the above styles
    }
}

ScpuiSystemGlobal.extensions = {} -- Represents the extensions table that must contain all extension-related members and methods. Each member must be documented in .vscode/scpui.lua

--- Downstream mods may store data directly in the global table like `ScpuiSystem.SomeDataValue = 0`. Data stored outside the ScpuiSystem.data or ScpuiSystem.extensions table does not need to be documented and is not type-checked



-----------------------------------
--- Methods
-----------------------------------

--- ScpuiSystemGlobal Methods
function ScpuiSystemGlobal:exampleFunction(value, value_one) -- Functions within the ScpuiSystem Global should be camelCase and must use Method Call syntax (:) as opposed to Function Call so that 'self' is always available
    if (value == value_one) then -- Arguments of functions should use snake_case
        return true
    end

    local value_two = value -- Local variables should use snake_case
end

--- UI Controllers
local Class = require("lib_class") -- Always use the class library for UI controllers
local ScpuiSystemUiController = Class() -- UI Controllers use PascalCase and must be a class and end with `Controller`

function ScpuiSystemUiController:init() -- All UI Controllers must have an init method
    self.Variable = nil -- Initialize all ui variables in the init method using PascalCase. For different types of variables, refer to the global member documentation above.
end

function ScpuiSystemUiController:initialize(document) -- All UI Controllers must have an initialize method. This should be called by the body on load and send the document
    self.Document = document -- Initialize the document here to the class instance variable

    --- Perform any other necessary initialization
end

function ScpuiSystemUiController:processData() -- UI Controller methods must use camelCase for internal methods
end

function ScpuiSystemUiController:on_button_click() -- UI Controller methods must use snake_case for methods called by libRocket RML files
end



-----------------------------------
--- Whitespace
-----------------------------------
local function myFunction()
    local myVariable = 0 -- Use 4 spaces for each indentation
    if (myVariable == 0) then
        return true
    end
end



-----------------------------------
--- File Structure & Naming
-----------------------------------
--- All files should be named in snake_case and should be placed in the appropriate directory
--- --- content/data/scripts/ -- For lua files
--- --- content/data/interface/markup/ -- For RML files
--- --- content/data/interface/css/ -- For RCSS files
---
--- Lua files should be named as follows:
--- --- ctrlr_*.lua -- For UI Controllers called by RML documents
--- --- lib_*.lua -- For libraries
--- --- scpui_sm_*.lua -- ScpuiSystem submodules that extend the ScpuiSystem global
---
--- Modular UI Controllers should have their own folder in the root directory and contain a similar structure to the above
--- Using Journal UI as an example
--- --- journal_ui/ -- Folder for the Journal UI
--- --- journal_ui/scripts/ -- Folder for the Journal UI's lua files
--- --- journal_ui/interface/markup/ -- Folder for the Journal UI's RML files
--- --- journal_ui/interface/css/ -- Folder for the Journal UI's RCSS files
--- ---
--- --- Naming Lua files in UI extensions should follow similar rules to the core SCPUI files
--- --- --- journal_ui/scripts/ctrlr_journal.lua -- For the Journal UI's main controller
--- --- --- journal_ui/scripts/lib_jrnl_*.lua -- For the Journal UI's libraries
--- --- --- journal_ui/scripts/scpui_ext_journal.lua -- For the Journal UI's core code extension file
--- --- --- journal_ui/scripts/scpui_jrnl_sm_*.lua -- For the Journal UI's submodules



-----------------------------------
--- Documentation
-----------------------------------

local example_variable = false --- @type boolean The type of the variable is listed on the same line with a brief description

--- This is the description of the exampleFunction
--- @param value string This is the description of the value parameter
--- @param value_one string This is the description of the value_one parameter
--- @return boolean var This is the description of the return value
local function exampleFunction(value, value_one)
    if (value == value_one) then
        return true
    else
        return false
    end
end

--- Controller classes should not be documented with @class because their members methods are automatically inferred
local ScpuiSystemNewController = Class()

--- Controllers and libraries must return themselves at the end of the file
return ScpuiSystemNewController



-----------------------------------
--- Extensions
-----------------------------------

--- Extensions are a way to add new functionality to the ScpuiSystem global table and are automatically stored in the ScpuiSystem.extensions table
--- Extensions should be in their own subfolder in the root directory and should follow the structure as seen in the File Structure & Naming section

--- The top of the extension file should include any class documentation. See the Journal UI Extension for an example

--- Extensions create themselves as a table starting with the Name, Version, and Key members
local ExtensionUi = {
	Name = "Extension", -- Human readable name of the extension
	Version = "1.0.0", -- Version of the extension
	Key = "ExtensionUi" -- Key used to access the extension in the ScpuiSystem.extensions table
}

--- All extensions must have an init method. This method is called when the extension is loaded
--- @return nil
function ExtensionUi:init()
    -- Your initialization code can go here

    -- Load any submodules for the extension
    ScpuiSystem:loadSubmodules("ext")

    -- Register extension-specific topics
    ScpuiSystem:registerExtensionTopics("extension", {
        initialize = function() return nil end,
        unload = function() return nil end
    })

    --- Add any additional FSO hooks needed
    ScpuiSystem:addHook("On Campaign Begin", function()
        self:clearAll()
    end)
end

--- Return the extension at the end of the file
return ExtensionUi