# SCPUI

<p align="center"><img src="https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/SCPUI.png" alt="SCPUI" width="500"></p>

SCPUI is a term that refers to both the LUA Script implementation and the user interface LUA API in the FreespaceOpen engine available from versions 23.2 onwards. It is intended to be used with the [librocket libraries](Librocket) to replace the base Freespace Open interface in an easily customizable way through LUA scripts.

Badges show the SCPUI version a field or feature was added in. Unbadged items date from SCPUI 0.5.0 or earlier.

The original implementation of SCPUI was started by m!m and finished by MjnMixael. This specific implementation attempts to replicate the original Freespace UI experience while offering enhancements such as in-game options not normally available.

[For documentation on the Librocket API, go here.](Librocket)

The GitHub source files for SCPUI are available [here.](https://github.com/MjnMixael/SCPUI) However, it is highly recommended that you have your game or mod rely on the core SCPUI mod on Knossos.NET [here.](https://fsnebula.org/mod/SCPUI)

## Overview
SCPUI works by completely overriding a given game state's internal code. Everything that interface should be expected to do must be handled in the Lua scripts. Methods to get and set appropriate game data are supplied by FSO's UI API. The core file that handles this is `scpui_system_core.lua`. This file is SCPUI's state management controller. If it detects a valid SCPUI interface for a given game state, it will load a librocket file and begin execution of the appropriate scripts.

An SCPUI game state definition has three main files; RML, RCSS, and LUA. More information is available on those specific pages, but for now it's enough to know that RML is a kind of base HTML, RCSS is a base CSS, and LUA is an FSO compatible LUA file.

The lua file for that state will be run until an FSO game state change is detected. When that happens, `scpui_system_core.lua` will clean up the librocket elements and then check if a new set of SCPUI files should be loaded.

The FSO Engine's Lua API provides a library of methods for interfacing with UI code. Please consult the [scripting.html](https://wiki.hard-light.net/index.php/Command-Line_Reference#-output_scripting) file and the ***UserInterface (ui)*** library for details.

## Scpui.tbl
SCPUI's global settings can be modified with scpui.tbl or xxx-ui.tbm files.
[Documentation on scpui.tbl is available here.](scpui.tbl)

## Visual Customization
Unlike FSO's built-in User Interface, SCPUI liberally re-uses visual assets wherever possible. Because of this, there are only about 225 image files compared to retail's thousands. This makes changing the look and feel of the UI incredibly easy even for those who are not interested in modifying the underlying Lua code.

### Custom.RCSS
![SCPUI 0.12.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.12.0.svg)

Every UI screen loads `custom.rcss` as its primary style sheet in addition to the rest of the style sheets for that UI screen. The idea here is that you can list all of your custom styles in that file stored in your own mod's game data. The file should be `data/interface/css/custom.rcss` and you can start by copying the file directly out of SCPUI's base install. This is also where you'll set your mod's primary font file.

### Fonts
Fonts are defined in SCPUI using an `.rcss` style sheet. In the base install of SCPUI, the primary font is defined in `custom.rcss` like this

```css
body
{
	font-family: BankGothic Md BT;
	font-weight: normal;
	font-style: normal;
}
```

Note that the font-family is the font's name as defined in the font metadata and not the filename. In some fonts that may strictly be the font family name only, but not always. For example, `Noto Sans Medium` actually needs to be listed as `Noto Sans`.

You will want to put all family variant font files (for example: BankGothic.ttf, BankGothic-bold.ttf, BankGotic-italic.ttf) in the `data/fonts` directory.

![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) SCPUI will try to match its default font size to FSO's internal font size, which by default is the first font in fonts.tbl. You can customize this setting in [scpui.tbl.](scpui.tbl). You will also want to enable `+Auto Size` and `+Can Scale` on your default FSO font in [fonts.tbl](https://wiki.hard-light.net/index.php/Fonts.tbl) so that SCPUI's font and FSO's font can scale together as players will expect.

### Background
You can change the main background image for all SCPUI screens by simply replacing `bg.png`. Other background features are covered in the [scpui.tbl documentation.](scpui.tbl)

### Logo
There are several UI screens that use a logo image. It comes in three main variants...

- Standard
  - Replace `logo.png` to replace the standard logo throughout all of SCPUI.
- Wide
  - For FS2, this logo is the version with the "wings". Replace `logo-wide.png` to change this one.
- ![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg) Loop
  - In FS2 this is the [SOC](https://wiki.hard-light.net/index.php/Special_Operations_Command) logo used in the Loop Brief UI. For this one replace `loop-logo.png`

### Loading Screen Backgrounds
![SCPUI 0.13.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.13.0.svg)

Loading screen backgrounds are handled a little differently than in base FreespaceOpen. You must create or modify the `load_screen_bgs.rcss` file to add the custom backgrounds you wish to use. In that file create a css class with the mission filename that is to have a custom screen and then define the file like the example below.

```css
.bta1_m1_01 {
	background-decorator: image;
	background-image: 3_Load_1M1_01.png;
}
```

Mission `bta1_m1_01.fs2` will now have the image `3_Load_1M1_01.png` used as its background. Every loading screen also gets the `loadscreen_default` class, which is the background used when no mission class matches.

![Development](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-development.svg) Backgrounds can also be assigned through [scpui.tbl](scpui.tbl#loading-screens) instead of naming classes after missions. A `#Loading Screens` profile lists one or more `+Background Class:` entries (one is picked at random each load), an optional `$Loading Bar Image:`, and optional `$Tip:` references to `#Loading Text` entries; `#Mission Screens` then maps mission filenames to profiles. The background classes themselves are still defined in `load_screen_bgs.rcss`, and tips are styled with the `#loadscreen_tip` selector.

To modify the loading bar, background class, or tip text from a script see [UI Topics.](#ui-topics)

### Keywords
![SCPUI 0.13.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.13.0.svg)

SCPUI has a built in feature to allow coloring keywords automatically for UI the various briefing screens. It can also, optionally, add tooltips to these keywords. This feature works in Briefing, Command Briefing, Debriefing, Fiction Viewer, Loop Briefing, and Red Alert, and only on text that is in [HTML mode](#briefing-color-tags). Definitions for keywords are tabled in a special table. See [keywords.tbl documentation](keywords.tbl) for more information.

### Elements
The main UI elements (window boxes, button panels, etc) are all re-used liberally throughout SCPUI. At the time of writing this article, there are 53 of these files in total. You can modify them however you like.

- It is highly recommended you do not change the aspect ratio of these images if you do not want to have to modify RML and RCSS files.

### Buttons
There are a number of button styles that SCPUI uses to match FS2's retail UI. Each button has at least three images: Main, Hover, and On. Generally they are designated like the following example:

```text
arrow-up.png ;;Main
arrow-up-h.png ;;Hover
arrow-up-o.png ;;On
```

In some cases there are Positive and Negative versions. These are named like the following example:

```text
select.png ;;Main
select-pos-h.png ;;Positive Hover
select-pos-o.png ;;Positive On
select-neg-h.png ;;Negative Hover
select-neg-o.png ;;Negative On
```

### Custom Data
![SCPUI 0.10.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.10.0.svg)

SCPUI often uses special [Custom Data](https://wiki.hard-light.net/index.php/Ships.tbl#$Custom_data:) for various special cases. This provides a way to set values per-object without needing additional tables. All keys are optional.

| Key | Value Type | Supported Tables | Description |
|---|---|---|---|
| `HideInTechRoom` | Boolean (default: false) | ships.tbl, weapons.tbl | If `true` (must be written exactly that way), the object is always hidden from the tech room database, including when using Ctrl+Shift+S to show all entries. |
| ![Development](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-development.svg) `LoadoutListPriority` | Integer (default: -1) | ships.tbl, weapons.tbl | Controls sorting in ship and weapon loadout UIs. Lower numbers are listed first; a negative or non-numeric value means no priority, and those entries are listed after all prioritized entries in table order. |

## Briefing Color Tags
![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg)

SCPUI supports two methods for coloring text in briefings. It supports the retail style [color tag](https://wiki.hard-light.net/index.php/Briefing_Text) system out of the box. However, SCPUI also has its own HTML-based approach to styling text. It works everywhere that classic color tags do - briefings (including command, loop, and red alert briefings), debriefings, and the fiction viewer - but also the tech room, campaign descriptions, and nearly everywhere that long-form text is supported. For it to work in briefings, the text must be put in "HTML mode" by putting `!html` at the start, followed by a space. Everywhere else will work without that tag.

Text in HTML mode may contain HTML markup. Text may be styled using `<span>` tags with appropriate classes drawn from common.rcss; inline styles are also supported. FSO and HTML both make use of double quotes and slashes; to minimize conflicts, using single quotes and writing slashes as `$slash` is recommended. A complete example might look something like this: `!html <span class='white'>Pilot attend!<$slashspan> Today, we'll be escorting the <span class='green italic'>GTC Examplar<$slashspan> as she raids <span class='red'>Shivan<$slashspan> positions throughout <span class='yellow'>Gamma Draconis<$slashspan>.` The list of color classes available by default is at the bottom of `common.rcss`. You can add more to `custom.rcss` if needed.

It is, however, rarely necessary to perform simple styling like this manually: SCPUI's [Keywords.tbl](keywords.tbl) may be used to automate common styling rules.

## Loadout Select Icons
![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg)

SCPUI supports both 2D pre-drawn icons as well as generated 3D icons. However, they are handled a little differently than inside base FSO. SCPUI pre-generates icon images on game start and displays those in place of the actual icons. Icons are generated during SCPUI's splash screens and cached to the appdata directory to speed up load times on subsequent gameplay instances.

To use 3D icons generated from ship models you must have 3D icons enabled in your [game_settings.tbl](https://wiki.hard-light.net/index.php/Game_settings.tbl#.24Use_3d_ship_select:) and for weapons you must have a [Tech Model defined](https://wiki.hard-light.net/index.php/Weapons.tbl#.24Tech_Model:).

To use 2D icons you must have a Select Icon defined for the [ship](https://wiki.hard-light.net/index.php/Ships.tbl#.24Ship_Icon:) or [weapon](https://wiki.hard-light.net/index.php/Weapons.tbl#.24Icon:).

You can set the icon dimensions in [scpui.tbl](scpui.tbl).

## Ribbons
![SCPUI 0.13.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.13.0.svg)

SCPUI comes with a brand new award system called Ribbons. This is meant as a way for players to show off how many FreespaceOpen Engine games they have completed. Ribbons are granted via the `grant-scpui-ribbon` sexp and once granted cannot be modified. Ribbons are saved to global data that spans all Freespace campaigns, mods, and other games. An example of what ribbons look like is below.

<p align="center"><img src="https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/Scpui_ribbons.jpg" alt="SCPUI ribbons"></p>

## Achievements
![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg)

SCPUI comes with a full achievements system. Achievements can be automatically granted in some cases or granted by sexp in others. Achievements must be defined in the new [achievements.tbl](achievements.tbl). Achievement progress is stored automatically on a per-player and per-mod basis. When an achievement is unlocked, a notification is automatically shown to the player.

## Loadout Handling
![SCPUI 0.10.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.10.0.svg)

SCPUI includes an entirely custom loadout handler that bypasses some of FSO's built-in methods. The biggest change is that each loadout is saved to a json file in the player's appdata directory as `scpui_loadouts.cfg`. Note this is saved in the mod's appdata `data/config` directory and not the `data/players` directory, so loadouts are not carried across mod versions.

The past loadout will be reloaded across game instances and much more reliably across gameplay entirely. Loadout saves differentiate between missions played in Campaign and missions played via Simulator room. All saved campaign loadouts are cleared when a campaign is started or restarted.

## Optional Extensions
![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg)

SCPUI comes with several optional extension UIs that can be used for specific tasks that the base FreespaceOpen interface is not equipped for. These packages ship as optional packages of the SCPUI mod (`journal_ui`, `nodemap_ui`, and `sysmap_ui`) and must be enabled in your SCPUI configuration with buttons for access added where desired. Each one adds a [Scripting Substate](scpui.tbl#substate) that can be opened with `ScpuiSystem:beginSubstate()`, and has its own set of UI Topics, table parsers, SEXPs, or other features.

### Journal
![SCPUI 0.12.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.12.0.svg)

The Journal extension was based heavily of Axem's original Lua-only version. SCPUI's iteration is not backwards compatible with it but comes with several enhancements for easier translation and management.

The Journal is configured on a per-campaign basis where each campaign loads from a table matching the format `CAMPAIGN_FILE_NAME-journal.tbl`. [Documentation is available here.](journal.tbl)

![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) Open it with `ScpuiSystem:beginSubstate("Journal")`.

### Node Map
The Node Map extension was originally created for [Between the Ashes](https://wiki.hard-light.net/index.php/Bta) and was intended to be used in the tech room. Some configuration with UI Topics may be necessary to modify its appearance to work in other contexts.

The Node Map features a robust progression system so the map can optionally update as the campaign progresses. All configuration is done with the [nodemap.tbl](nodemap.tbl). The progression system must be defined by the mod's own Lua scripts through the use of UI Topics.

Open it with `ScpuiSystem:beginSubstate("NodeMap")`.

### Local System Map
The Local System Map extension was originally by Axem as a Lua only interface. This version was rebuilt from the ground up for [Between the Ashes](https://wiki.hard-light.net/index.php/Bta) and, notably, cannot be used in-mission like Axem's original version.

The Local System Map configuration is done with the [system_map.tbl](system_map.tbl). Open it with `ScpuiSystem:beginSubstate("SystemMap")`.

## Advanced Customization
**The following sections assume a working knowledge of Lua and are intended for users who wish to extend SCPUI in more advanced ways.**

SCPUI is a highly flexible system that allows for extensive customization through Lua scripting. To fully take advantage of these features, you will need to understand Lua and be comfortable writing, debugging, and integrating Lua scripts within the FreespaceOpen Engine environment.

This section introduces the types of scripts used in SCPUI and how they fit into the overall architecture.

### Script Architecture
![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg)

SCPUI organizes its scripts into distinct categories to improve modularity, maintainability, and extensibility. Each type of script serves a specific purpose:

- **Submodules**: Submodules are core components of SCPUI or one of its extensions, designed to handle specific tasks or functionality. They are automatically loaded during initialization. Submodules help organize code into manageable files that work together to deliver SCPUI's core features.
  - Naming convention: `scpui_sm_*.lua`
  - Naming convention for extensions: `scpui_SUBMODULE_sm_*.lua`, where `SUBMODULE` is the extension's `Submodule` value
  - Loading: Core submodules are loaded during SCPUI's core initialization, with `scpui_sm_parser.lua` always loaded first. Submodules for extensions are loaded after that extension has been initialized.
  - Examples: A submodule to manage table parsing or handle preload operations.

- **Extensions**: Extensions are optional add-ons that provide entirely new functionality or custom UI elements for SCPUI. They can include their own submodules, controllers, and other assets. Extensions are ideal for games that require unique user interfaces as part of the SCPUI system.
  - Naming convention: `scpui_ext_*.lua`
  - Variables: Each extension must include the following variables:
    - Name: The user-facing name of the extension.
    - Version: The current version of the extension.
    - Key: The key that will be used to access the Extension within the `ScpuiSystem.extensions` table.
  - Optional variables:
    - Submodule: The text used to find the extension's submodules. If omitted, no submodules are loaded for the extension.
  - Initialization: Each extension must include an init function. SCPUI will call this function as soon as the extension is loaded.
  - Post Initialization: Each extension may optionally include a postInit function. SCPUI will call this function after init and all submodules are loaded.
  - Once loaded, `Name`, `Version`, `Key`, `Submodule`, `init`, and `postInit` are read-only, and `init` and `postInit` cannot be called again.
  - Topics: Extensions can add their own [UI Topics](#ui-topics) category with `ScpuiSystem:registerExtensionTopics(category, topics_table)`, which must be called during initialization.
  - Structure: Extensions must return themselves as a table when called.
  - Loading: Extensions are loaded after SCPUI's core submodules during SCPUI's initialization.
  - Examples: A custom campaign journal interface or a map UI.

- **Plugins**: Plugins are lightweight, optional scripts that are loaded after SCPUI has initialized. They allow downstream mods or users to add custom behavior or extend functionality without modifying SCPUI's core files. Plugins are intended for advanced users who want to integrate new features or adjust existing ones.
  - Naming convention: `scpui_plg_*.lua`
  - Loading: Plugins are loaded last during SCPUI's initialization after everything else is ready.
  - Examples: A plugin to log custom analytics data or define [UI Topics](#ui-topics) binds.

- **Controllers**: Controllers are Lua scripts associated with a specific UI. They manage the logic, data handling, and interactions for that UI state.
  - Naming convention: `ctrlr_*.lua`
  - Loading: Controllers are loaded by a markup (RML) file; defined in the header section of that file.
  - Examples: A controller for the pilot select screen, mission briefing screen, or in-game options screen.

- **Libraries**: Libraries are reusable utility scripts that provide specific functionality without being tied to a particular UI state or task. They are designed to be called from other scripts as needed.
  - Naming convention: `lib_*.lua`
  - Structure: Libraries should return themselves as a table when called.
  - Loading: Libraries are loaded when needed by using a `require()` method call.
  - Examples: A library for data saving/loading, dialog pop-ups, or utility methods.

### Librocket
[Librocket](Librocket) is a pseudo html/css rendering library included with FSO. It is designed as a complete solution for any project's interface needs.SCPUI uses this library to create and manage each UI context.

LibRocket uses the time-tested open standards XHTML1.0 and CSS2.0 (while borrowing features from HTML5 and CSS3), and extends them with features suited towards real-time applications.

Documentation on how to interface with the librocket API can be found [here](Librocket).

### Game State Management
SCPUI's game state management is handled by the [scpui.tbl](scpui.tbl) file that simply lists the game state from [FSO's game states](https://wiki.hard-light.net/index.php/List_of_Game_States) and matches it with an RML file that will be associated. One notable exception is GS_STATE_SCRIPTING\*\* which allows for substates. This feature means that you can effectively create an unlimited amount of custom UIs that all exist within GS_STATE_SCRIPTING\*\*.

- To call a built-in game state, post its game event, e.g. `ba.postGameEvent(ba.GameEvents["GS_EVENT_MAIN_MENU"])`.
- ![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg) To call a scripting substate use `ScpuiSystem:beginSubstate("substate")`
- ![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) To call a substate in GS_STATE_SCRIPTING_MISSION use `ScpuiSystem:beginSubstate("substate", true)`, or the `scpui-show-menu` SEXP from within a mission.

![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) \*\*GS_STATE_SCRIPTING_MISSION can be used for custom UIs that should not end the mission when loaded.

### UI Topics
![SCPUI 0.12.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.12.0.svg)

SCPUI implements a way to essentially do modular scripting which allows downstream games to modify how SCPUI works without having to carry a complete copy of SCPUI itself. This system is called UI Topics. These work very similar to FSO engine hooks. There are listeners throughout the SCPUI script base that can be attached to in order to modify behavior of various screens, buttons, or other elements. Every screen contains an initialize topic which is the last code run when a game state is started and a screen is created. As a basic example, [Between the Ashes](https://wiki.hard-light.net/index.php/Bta) uses this to modify the background image that is used throughout. Here is the Topic code that is used to change the Fiction Viewer background.

```lua
local Topics = require('lib_ui_topics')
local Utils = require ('lib_utils')

Topics.fictionviewer.initialize:bind(1, function(message, context)
  local campaignfilename = ba.getCurrentPlayer():getCampaignFilename()
  local main = message.Document:GetElementById("main_background")
  if Utils.isOneOf(campaignfilename, "bta1_m", "bta2_m", "bta-tem_m") then
    main:SetClass("fiction_viewer_bg", true)
  end
end)
```

Topics sometimes include relevant data in the parameters called `message` and can change specific values by settings `context.value`. The initialize topics, like the example above, always send the screen's controller, whose `Document` field is the entire UI document reference. There are others, like the loading screen loading bar that sends the loading bar filename only and expects a filename return. Here is an example that changes the default loading bar image to something else.

```lua
Topics.loadscreen.load_bar:bind(9999, function(message, context)
  context.value = "fancyloadingbar"
end)
```

Topics are run based on the priority value, the argument in the bind() method, in order from lowest number to highest. You can prevent higher priority topics from being run at all by setting `context.done = true` inside a Topic. Whatever `context.value` holds after the last Topic has run is returned to the screen that sent it.

A full list of available topics can be found in SCPUI's `lib_ui_topics.lua` file.

![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) Optional extensions register their own categories at startup (`journal`, `nodemap`, and `systemmap`); see each extension's `scpui_ext_*.lua` file.

### Data Saver
![SCPUI 0.12.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.12.0.svg)

SCPUI comes with a set of Lua functions to handle saving and loading custom data quickly and easily for any kind of custom data you need. The data is saved to a json file using a hashed version of the mod's [mod title](https://wiki.hard-light.net/index.php/Game_settings.tbl#.24Mod_title:) and the hash can be further randomized by setting a custom seed in [scpui.tbl](scpui.tbl#data-saver-multiplier).

Data can be saved as 'persistent' or 'not persistent'. Persistent data is saved to `data/players` as `HASH_save_data.cfg`, meaning it will be available to your mod even across mod versions. Non persistent data is saved to `data/config` as `HASH_save_data_local.cfg` instead. The first time data is loaded in a session, both files are backed up to `data/config` as `HASH_save_backup_N.cfg` and `HASH_save_backup_local_N.cfg`, keeping up to 10 backups before the oldest is overwritten.

All data is saved on a per-pilot basis, so a pilot must be selected before data can be saved or loaded.

#### Saving Arbitrary Data
Make sure the data you intend to save can be converted to JSON. Basically don't send any userdata. Access datasaver by calling `local DataSaver = require("lib_data_saver")`. You can then save arbitrary data with a call like this `DataSaver:saveDataToFile("data title", saveData, true)`.

Saving data takes three arguments. First is the name of the data. It should be a string. Second is the data to save. The last argument defines if the data is saved as 'persistent' (true) or 'not persistent' (false or omitted) which defines where the data is saved to.

#### Loading Arbitrary Data
Loading arbitrary data is just as easy. Set up datasaver with a call like this `local DataSaver = require("lib_data_saver")`. Then simply ask for the data you want to load like this `local saveData = DataSaver:loadDataFromFile("data title", true) or {}`.

Loading data takes two arguments. First is the name of the data and should match the name you used to save with. It should be a string. The second argument defines if the data is loaded as 'persistent' (true) or 'not persistent' (false or omitted) which defines where the data is loaded from. It returns `nil` if no data has been saved under that name for the current pilot.

### Custom Mod Options
![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg)

SCPUI comes with a built-in feature to allow for custom in-game options specific to a particular mod. These options are defined by [options.tbl](options.tbl) and saved to the player folder as `scpui_options.cfg`. Scripts can take advantage of this feature to allow players to customize how scripts run, or if they even run at all.

For example, you could take the [HUD Icons script](https://github.com/FSO-Scripters/fso-scripts/tree/master/radaricon) and create a global toggle. This allows players to turn HUD Icons on or off entirely. Furthermore you could allow customizing the max opacity of the icons, the distance at which the icons become fully transparent, and the distance at which the icons become fully opaque. These options will all appear within the in-game Options UI.

- **Note that [$Mod_title:](https://wiki.hard-light.net/index.php/Game_settings.tbl#$Mod_title:) in [game_settings.tbl](https://wiki.hard-light.net/index.php/Game_settings.tbl) should be set for this feature!** Options are saved under the mod title; without one, SCPUI falls back to the mod's folder name (up to the first `-`) and shows a warning.
- It's a good idea to make sure your mod title is unique to avoid mod options collisions.

#### Options.tbl
![SCPUI 0.9.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.9.0.svg)

This table file is used to define the Options buttons within the Options UI.
- It can be extended with xxx-optn.tbm
- [Documentation on the options.tbl is available here.](options.tbl)

#### Save Structure
The player's options are saved to `scpui_options.cfg` in data/players. This makes the options available across mod versions. The save structure within the file follows a player->mod->option hierarchy. (See example below.) This allows for each player to have their own preferences for each mod they play without interfering with other players' preferences.

```text
"John": {
	"Between The Ashes": {
		"Alarm_Voice": "Vasudan",
		"Verbose_Debugging": "Off",
		"Font_Multiplier": 2,
		"Icon_Far": 2,
		"Icon_Near": 5,
		"Brief_Render_Option": "Texture",
		"Icon_Opacity": "1",
		"Cockpit_Alarms": "On",
		"HUD_Icons": "Off",
		"Cockpit_Rendering": "Off",
		"Easter_Eggs": "On"
	}
},
"Mike": {
	"Between The Ashes": {
		"Cockpit_Rendering": "Off",
		"Easter_Eggs": "On",
		"Font_Multiplier": 5,
		"Icon_Far": 2,
		"Icon_Near": 5,
		"Brief_Render_Option": "Texture",
		"Icon_Opacity": "1",
		"Cockpit_Alarms": "On",
		"HUD_Icons": "Off",
		"Verbose_Debugging": "On",
		"Alarm_Voice": "Female"
	}
}
```

#### Accessing Save Data
Modifying Options within the in-game UI and saving those values to a file is just a start. In order for these options to do anything, you'll need to hook them into your scripts. After the Pilot Select screen and a player is chosen, the current Options are available in the table `ScpuiSystem.data.ScpuiOptionValues` with direct access to a specific option by specifying the [option key](options.tbl#key).

![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) In order to apply these options create a UI Topic connected to `options.apply` and run the appropriate code there. SCPUI sends `options.apply` whenever the player leaves the Pilot Select, Barracks, or Options screens.

```text
#Conditional Hooks
$Application: FS2_Open
$On Game Init:
[
(function()
	
	local topics = require('lib_ui_topics')
	
	--Apply user settings to relevant script data
	topics.options.apply:bind(9999, function(message, context)
		
		--Handle HUD Icon Option
		if ScpuiSystem.data.ScpuiOptionValues.HUD_Icons == "On" then
			ba.print("MOD OPTION: Player enabled HUD Icons\n")
			RadarIcon.PlayerEnabled = true
		else
			ba.print("MOD OPTION: Player disabled HUD Icons\n")
			RadarIcon.PlayerEnabled = false
		end

	end)

end)()
]
#End
```

#### Pilot Select
The pilot select UI has special handling of custom mod options because player preferences cannot be loaded until a player is selected. For this specific use case, SCPUI creates a `scpui_options_global.cfg` whenever user preferences are saved. This file contains no mod or player specific information in the save structure. It is just a list of key/value pairs for the most recently used pilot.
- This setup can be used to perform script actions before a player is selected if necessary.
- In this case, options are still available as ***ScpuiSystem.data.ScpuiOptionValues*** and accessed the same way, but there is no guarantee that the option will exist depending on the last mod the player played.

### Dialog Popups
![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg) Freespace Open has a number of built-in dialog popups throughout the user interface. SCPUI automatically intercepts those popups and displays them as a librocket styled popup window.

You can create your own custom dialog popups within the UI scripts. To do this you must include `local Dialogs = require("lib_dialogs")` within the scope of your script and create a new dialog with `local dialog = Dialogs.new()`. The dialog has several parameters for you to define. Each method returns the dialog itself, so calls can be chained.

#### Title
- Used to define the title of the dialog window.
- `dialog:title("yourtitle")`

#### Text
- Used to define the text or description your popup will contain.
- `dialog:text("yourtext")`

#### Input
![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg)

- Defines if the user can type a string as input
- Useful for allowing the user to name pilots, saves, etc
- When input is enabled, the typed string is returned instead of the button's value, whether the user presses ENTER or clicks a button
- The input is limited to 32 characters
- True to allow input, false to disallow. Defaults to false if this parameter is not provided.
  - `dialog:input(boolean)`

#### Buttons
- Defines the user-clickable buttons that will be included in the dialog. It has the following parameters
- Type can be one of the following:
  - Dialogs.BUTTON_TYPE_POSITIVE
  - Dialogs.BUTTON_TYPE_NEGATIVE
  - ![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg) Dialogs.BUTTON_TYPE_NEUTRAL
- Text is the text for the button, such as "Okay".
- Value is the data that will be returned when the button is clicked. If nil, the button's position in the list (1, 2, 3...) is returned instead.
- ![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg) Keypress is the keyboard shortcut for this button. If the key's letter appears in the button text, it is underlined.
- `dialog:button(type, text, value, keypress)`

#### Escape
![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg)

- Used to define if the user should be able to cancel the dialog popup with the ESC key.
- A non nil value enables ESC and will be the return value if ESC is pressed
- `dialog:escape(value)`

#### Click Escape
![SCPUI 0.13.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.13.0.svg)

- Used to define if the user should be able to cancel the dialog popup by clicking outside of it.
- Only works if an Escape value is also set; that value is returned when the user clicks outside the dialog.
- Never allowed for death style dialogs.
- `dialog:clickescape(boolean)`

#### Style
- Used to define which dialog layout to use. Defaults to the regular style.
- ![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) Style can be one of the following:
  - Dialogs.STYLE_REGULAR
  - Dialogs.STYLE_DEATH (the layout used for FSO's death popup)
- `dialog:style(style)`

#### Background
![SCPUI 0.13.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.13.0.svg)

- Used to set the background color behind the dialog window, as any RCSS color value such as `"#00000080"`.
- `dialog:background(color)`

#### Show
![SCPUI 0.6.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.6.0.svg)

- This is the final step that displays the popup and defines how to handle the return values
- It takes the librocket context to display the dialog in and returns a promise
- return values come back as the parameter *response*
- ![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) An optional second argument is a table; SCPUI will store an `Abort` function in it that closes the dialog and rejects the promise.
- The ui.enableInput() here specifically enables input on the dialog popup context. The dialog will automatically return input to the SCPUI context when it's closed.

```lua
dialog:show(self.Document.context)
   :continueWith(function(response)
      -- Execute code here
   end)
ui.enableInput(self.Document.context)
```

#### Dialog Helpers
![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg)

SCPUI also provides two shortcuts that build and show a dialog in one call. Both take either the current UI controller (any table with a `Document` field) or a librocket context as the first argument, and call `ui.enableInput()` for you.

- `ScpuiSystem:showDialog(context_or_caller, params, callback)`
  - `params` is a table with the keys `Title` and `Text` (both required), and optionally `Input`, `EscapeValue`, `ClickEscape`, `Style`, `BackgroundColor` (defaults to clear), and `Buttons_List`, a list of tables with the keys `Type`, `Text`, `Value`, and `Keypress`.
  - `callback` is an optional function that receives the response.
- `ScpuiSystem:showSimpleDialog(context_or_caller, title, text)`
  - Shows a dialog with a single "Ok" button and no callback.

### Preload Coroutines
![SCPUI 0.12.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.12.0.svg)

SCPUI has a preload system that is used to generate the loadout icon cache. However, it is possible to add any number of arbitrary preload coroutines. To add a preload, call `ScpuiSystem:addPreload()` before SCPUI finishes initializing (for example from a submodule, extension, or plugin) with the following arguments:
- Debug Message
  - The message to print to the log when this preload coroutine is run.
- Debug String
  - The text string to draw to the screen when this preload coroutine is run and FSO is run in debug mode.
- ![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) Function
  - The actual function to call. Will be called with pcall and errors with the call will halt game execution.
- ![SCPUI 1.1.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-1.1.0.svg) Args
  - Any arguments you want to pass to your function in a table.
- Priority
  - This should be a 1 or 2 and determines if this coroutine runs during the first splash image or the second. This allows having coroutines build upon each other if necessary.

An example of an icon coroutine call.

```lua
ScpuiSystem:addPreload(
    "Generating icon for " .. v.Name,
    "Generating " .. v.Name .. " icon",
    ScpuiSystem.setIconFrames,
    {ScpuiSystem, v.Name, true},
    2
)
```

### Individual UIs
All game stages are now supported with the following exceptions:

- Main Hall
  - The main hall (GS_STATE_MAIN_MENU) always uses FSO's built-in mainhall.
- Cutscenes
  - Because of FSO/Librocket limitations, viewing a cutscene from the tech room actually sets SCPUI to the `Cutscene` [Scripting Substate](scpui.tbl#substate) for the duration of the cutscene itself. Cutscenes that play during a campaign are played by FSO while SCPUI pauses its own rendering.
- F3 Lab is not supported as an SCPUI style UI. It will use the Base FSO UI
- F3 In-game options is not supported as an SCPUI style UI.
  - This is because SCPUI integrates in-game options directly into the main options UI.
- Multi UIs have not been thoroughly tested and may be buggy

### Development and Debugging
There are five main things to know when developing and debugging SCPUI.

1. You can view the librocket debugger by pressing ***ctrl-shift-d***
2. You can live-reload RML and RCSS files by pressing ***ctrl-shift-r***
   - It's worth noting that Librocket will drop the existing elements and lose them in memory. This will cause a warning on game-exit.
3. Librocket errors are forwarded to FSO as warnings that appear in all builds, while Librocket warnings only appear in debug builds. Other Librocket messages are written to the log. Lua errors raised from inside a Librocket document, such as in an event handler, are reported through FSO's normal Lua error popup.
4. ![SCPUI 0.10.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.10.0.svg) You can force regenerating all loadout icons by pressing F12 during FSO's splash screen.
5. ![SCPUI 0.10.0](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-0.10.0.svg) You can force deleting the current mission's loadout by pressing F12 during mission loading.

### Tips
- In general, the ui system will handle passing control back and forth between the SCPUI context and FSO. In rare cases you may need to handle this manually. The FSO API methods ui.enableInput() and ui.disableInput() are provided to handle this case.

- For 3D weapon selection, SCPUI can only use [Tech models](https://wiki.hard-light.net/index.php/Weapons.tbl#.24Tech_Model:) and you need to make sure you have [Closeup_Pos](https://wiki.hard-light.net/index.php/Weapons.tbl#.2BCloseup_Pos:) and [Closeup_Zoom](https://wiki.hard-light.net/index.php/Weapons.tbl#.2BCloseup_Zoom:) set. If you don't have a tech model, just set the regular model file as the tech model in your table.

### Tutorials
- TODO
