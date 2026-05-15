# SCPUI — Project Notes for Claude

## UI library

SCPUI uses **librocket** (Lloyd Weehuizen's original Rocket library), **not RmlUi**.
RmlUi is a more modern fork, but it requires Lua 5.2; FSO is hard-capped to Lua
5.1 for the foreseeable future, so the SCP team has decided RmlUi is not
compatible with FSO.

When citing documentation or reasoning about RCSS / RML APIs, look at existing
SCPUI code as the source of truth (e.g. `content/data/scripts/ctrlr_*.lua`,
`content/data/interface/css/*.rcss`) rather than RmlUi docs. The element/style
APIs are mostly compatible, but RCSS extensions and newer properties added by
RmlUi may not be available.

## Type metadata

Anytime new state is added to the `ScpuiSystem` global table (a new field on
`ScpuiSystem.data`, a new sub-table on it, etc.), document it in the meta
file at `.vscode/meta/scpui.lua`. Add a `--- @class` block for any new
structured shape, then a `--- @field` line on the relevant container class
(usually `scpui_data`). This keeps the Lua Language Server happy and gives
modders IntelliSense on the global. Same applies when extending
`ScpuiSystem.extensions.*` or `ScpuiSystem.data.memory.*`.
