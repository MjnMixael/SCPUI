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
