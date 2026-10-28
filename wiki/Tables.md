This page lists every table [SCPUI](Home) reads, in alphabetical order. These are SCPUI's own tables, read by its Lua scripts; the engine's tables are documented on the [FreeSpace Wiki](https://wiki.hard-light.net/index.php/Tables).

## Contents

1. [Version badges](#version-badges)
2. [Tables](#tables)

---

## Version badges

Table pages mark when a field or behavior was added with a version badge. Fields without a badge are from SCPUI 0.5.0 or earlier.

![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg) ![SCPUI 0.9.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.9.0.svg) ![SCPUI 0.10.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.10.0.svg) ![SCPUI 0.12.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.12.0.svg) ![SCPUI 0.13.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.13.0.svg) ![SCPUI 1.0.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.0.0.svg) ![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) ![SCPUI 1.1.1](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.1.svg) ![Development](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-development.svg)

![Development](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-development.svg) marks a field or behavior that is on SCPUI's `development` branch but not in a release yet. It gets the version number of the release it ships in.

---

## Tables

| Table | Modular extension | Code | Purpose |
|---|---|---|---|
| [achievements.tbl](achievements.tbl) | (not modular) | [/content/data/scripts/scpui_sm_achievements.lua](https://github.com/MjnMixael/SCPUI/blob/development/content/data/scripts/scpui_sm_achievements.lua) | Achievements, their unlock criteria and how they are shown |
| [journal.tbl](journal.tbl) | (not modular; one `CAMPAIGN_FILE_NAME-journal.tbl` per campaign) | [/journal_ui/data/scripts/scpui_ext_journal.lua](https://github.com/MjnMixael/SCPUI/blob/development/journal_ui/data/scripts/scpui_ext_journal.lua) | Journal extension: title, sections and entries for a campaign |
| [keywords.tbl](keywords.tbl) | `xxx-kwrd.tbm` | [/content/data/scripts/scpui_sm_colors.lua](https://github.com/MjnMixael/SCPUI/blob/development/content/data/scripts/scpui_sm_colors.lua) | Keywords styled automatically in briefing text, with optional tooltips |
| [nodemap.tbl](nodemap.tbl) | `xxx-nmap.tbm` | [/nodemap_ui/data/scripts/scpui_ext_nodemap.lua](https://github.com/MjnMixael/SCPUI/blob/development/nodemap_ui/data/scripts/scpui_ext_nodemap.lua) | Node Map extension: icons, colors, systems, nodes and progression |
| [options.tbl](options.tbl) | `xxx-optn.tbm` | [/content/data/scripts/scpui_sm_options.lua](https://github.com/MjnMixael/SCPUI/blob/development/content/data/scripts/scpui_sm_options.lua) | Custom mod options shown in the Options screen |
| [scpui.tbl](scpui.tbl) | `xxx-ui.tbm` | [/content/data/scripts/scpui_sm_parser.lua](https://github.com/MjnMixael/SCPUI/blob/development/content/data/scripts/scpui_sm_parser.lua) | Global settings, game state replacement, backgrounds, loading screens and medal placements |
| [system_map.tbl](system_map.tbl) | `xxx-smap.tbm` | [/sysmap_ui/data/scripts/scpui_ext_sysmap.lua](https://github.com/MjnMixael/SCPUI/blob/development/sysmap_ui/data/scripts/scpui_ext_sysmap.lua) | Local System Map extension: objects, campaign configs and systems |
