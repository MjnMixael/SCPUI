--- This file is named as a table as a lua file which ensures that SCPUI's core modules are loaded before
--- any other script files or -sct.tbm files. That in turn nearly guarantees that SCPUI is ready and available
--- for all other scripts to use.

require('scpui_system_core')