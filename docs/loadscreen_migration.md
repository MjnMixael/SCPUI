# Migrating from Axem's Extended Loading Screen Script to SCPUI

This guide explains how to translate a mod that uses Axem's parse-scripting
`.tbm` + `lua-loadscreen.tbl` system onto SCPUI's native loading-screen pipeline.

Most of the work is editing `scpui.tbl` (or a `*-ui.tbm` modular) and authoring
a CSS class per background image. No Lua is required.

## What SCPUI already provides

- Per-mission background via a CSS class applied by the load-screen controller.
- Background scaling (handled by RCSS, no setting needed — the old script's
  `$Scale Zoom: true` is the default behavior).
- An animated loading bar (`data/interface/loadscreen/LoadingBar.*`).
- Mission title rendering.
- A `.loadscreen_default` fallback class used when no per-mission class matches.

## What this migration adds

Three new sections in `scpui.tbl` (and any `*-ui.tbm` modulars) drive the
features the Axem script provided that SCPUI didn't have natively:

- `#Loading Text` - named tip strings.
- `#Loading Screens` - load-screen profiles: which CSS background classes to
  pick from (random selection if more than one), which loading bar to use,
  and which tip(s) to draw (random if multiple).
- `#Mission Screens` - mission filename → profile mapping.

The table carries **data only**. Visual styling (fonts, colors, screen
positions, widths, mission-title layout, loading-bar placement) lives in
RCSS. Author per-mod overrides in `data/interface/css/load_screen.rcss`
(or `custom.rcss`) and target the relevant selectors:
`div#main_background`, `div#title`, `div#loadscreen_tip`, `div#loadingbar`.

Backgrounds remain CSS-class-only. You declare each background image once as
a CSS class in `data/interface/css/load_screen_bgs.rcss`, then reference the
class name(s) from a profile.

## Old script section → SCPUI equivalent

| Old section / field | SCPUI equivalent |
| --- | --- |
| `#General Settings $Scale Zoom: true` | No-op; CSS scales backgrounds automatically. |
| `#Loading Bars $Name: ... $File: <bar>.ani` | `$Loading Bar Image: <bar>.ani` inside a `#Loading Screens` profile. |
| `#Loading Bars $Origin: / $Offset:` | RCSS rule on `div#loadingbar` in your mod's load-screen CSS. |
| `#Loading Text $Name: / $Text: / $Font:` | `#Loading Text $Name: / $Text:`. Font is set via RCSS on `div#loadscreen_tip` (or a class on it), not in the table. |
| `#Loading Screens $Loading Image: random` + `+Image:` list | Multiple `+Background Class:` entries in the profile. One is picked at random per load. |
| `#Loading Screens $Loading Image: <fixed>` | A single `+Background Class:` entry. |
| `#Loading Screens +Scaling: true` | No-op; CSS handles scaling. |
| `#Loading Screens $Text Color: r,g,b,a` | RCSS `color:` on `div#loadscreen_tip`. |
| `#Loading Screens $Text Origin: x, y` / `+Width: N` | RCSS `left: / top: / width:` on `div#loadscreen_tip`. |
| `#Loading Screens $Draw Mission Name: true / +Font: / +Origin: / +Offset: / +Justify:` | RCSS rule on `div#title` (font class, `left:`, `top:`, `margin:`, `text-align:`). |
| `#Loading Screens $Loading Text: <name>` | `$Tip: <name>` (one or more; one is picked at random). |
| `#Mission Screens $Filename: / $Loading Screen:` | Same field names, same shape. `.fs2` extensions are stripped on parse. |

## Walkthrough: translating a single screen

Suppose your mod has a mission `chapter1_mission01.fs2` that, under the old
script, picks a random background from four images, shows a loading bar in
the lower-right, draws a per-screen tip in pale blue at the lower-left, and
renders the mission title in the upper-right. The old entry looks like:

```
$Name:          tip_chapter1_01
$Text:          XSTR("...some lore text...", -1)
$Font:          6

$Name:          chapter1_01_screen
$Loading Bar:   my_loading_bar
$Loading Image: random
    +Scaling:   true
    +Image:     chapter1_01_bg_a
    +Image:     chapter1_01_bg_b
    +Image:     chapter1_01_bg_c
    +Image:     chapter1_01_bg_d
$Text Color:    192, 192, 255, 255
$Text Origin:   0.03, 0.75
    +Width:     800
$Draw Mission Name: true
    +Font:      5
    +Origin:    0.65, 0
    +Offset:    0, 20
    +Justify:   left
$Loading Text:  tip_chapter1_01

$Filename:      chapter1_mission01.fs2
$Loading Screen: chapter1_01_screen
```

### Step 1: author the background CSS classes

In `data/interface/css/load_screen_bgs.rcss` (or your mod's override of it),
add one class per background image:

```rcss
.chapter1_01_bg_a { background-decorator: image; background-image: chapter1_01_bg_a.png; }
.chapter1_01_bg_b { background-decorator: image; background-image: chapter1_01_bg_b.png; }
.chapter1_01_bg_c { background-decorator: image; background-image: chapter1_01_bg_c.png; }
.chapter1_01_bg_d { background-decorator: image; background-image: chapter1_01_bg_d.png; }
```

### Step 2: add the table entries

In `scpui.tbl` (or a `your_mod-ui.tbm` modular). The sections may appear in
any combination, but they must come after `#Briefing Stage Background Replacement`
and before `#Medal Placements` (when present), and the file still ends with a
single top-level `#End`:

```
#Loading Text

$Name: tip_chapter1_01
$Text: XSTR("...some lore text...", -1)

#Loading Screens

$Name: chapter1_01_screen
$Loading Bar Image: my_loading_bar.ani
+Background Class: chapter1_01_bg_a
+Background Class: chapter1_01_bg_b
+Background Class: chapter1_01_bg_c
+Background Class: chapter1_01_bg_d
$Tip: tip_chapter1_01

#Mission Screens

$Filename: chapter1_mission01.fs2
$Loading Screen: chapter1_01_screen

#End
```

### Step 3: style the tip, title, and loading bar in RCSS

All visual styling lives in your mod's load-screen CSS (add it to
`load_screen.rcss`, `custom.rcss`, or a new RCSS file you link from
`load_screen.rml`). The old entry's combined styling translates to:

```rcss
/* Tip text - was $Text Color / $Text Origin / +Width on the screen profile */
div#loadscreen_tip
{
	color: #C0C0FFFF;
	left: 3%;
	top: 75%;
	width: 800px;
	/* Pick a font via class or font-family. p6 is one of the SCPUI font classes. */
	font-family: ...;
	font-size: ...;
}

/* Mission title - was $Draw Mission Name + Font/Origin/Offset/Justify */
div#title
{
	left: 65%;
	top: 0;
	margin-top: 20px;
	width: auto;
	text-align: left;
	/* Override the default p2 class with whatever font you want for the title */
	font-family: ...;
	font-size: ...;
}

/* Loading bar - anchored to the right edge, vertically centered, then nudged */
div#loadingbar
{
	width: auto;
	left: auto;
	right: 0;
	top: 50%;
	margin: -210px -26px 0 0;
}
```

Note: the old script's pixel offsets assumed 1024×768. They will not be
pixel-identical at other aspect ratios. If you need an exact reproduction,
keep the bar at a fixed pixel size and use percentage-only positioning.

If you need styling that varies **per mission** (rather than uniformly
across the mod), bind `Topics.loadscreen.initialize` from your own script
and adjust `#loadscreen_tip` / `#title` styles on the document at that
point, see the Topic API reference below.

## Three-steps for adding a new mission load screen

1. Drop the background image files into the mod's `data/interface/` (or
   wherever you ship loading-screen assets) and author one CSS class per
   image in `data/interface/css/load_screen_bgs.rcss`.
2. Add an entry to `#Loading Screens` referencing the class name(s), and an
   entry to `#Mission Screens` mapping the mission filename to that profile.
   Add any tip strings to `#Loading Text` and reference them with `$Tip:`.
3. Launch FSO and start the mission. The mission filename (stem, no `.fs2`)
   resolves to a profile; one background class and one tip are picked at
   random per load.

## Unsupported features

Most of the old script's styling features (text `+Center`/`+Offset:`,
`$Text Color:`, `$Text Origin:`, `+Width:`, `$Draw Mission Name:` and its
sub-fields, `+Scaling:` on a loading bar) are not in the new table by
design. They're set in RCSS instead, which is more flexible.

The following old-script features do not yet have a built-in equivalent
in SCPUI; **if you need any of them, open an issue and they can be added**:

- `$Image:` under a `#Loading Text` entry (a graphic drawn alongside the tip).
- `$Variable:` under `#Loading Text` (text pulled from a SEXP variable at
  runtime). Note: this is easy to do today via `Topics.loadscreen.tip_text`
  (see the example below).
- The Axem-style `default` mission entry. SCPUI's `.loadscreen_default` CSS
  class already covers fallback rendering when no profile matches.

## Topic API reference (for mods that want to override in Lua)

If you need behavior that the declarative table can't express, bind a
listener to one of the loadscreen Topics. Each Topic sends the UI context
(the `LoadScreenController` instance) as its message. Pull the mission
filename from `mn.getMissionFilename()` inside the listener. Set
`context.value` to your override and `context.done = true` to skip the
table-driven default at priority 9999.

| Topic | Returns | Use case |
| --- | --- | --- |
| `Topics.loadscreen.load_bar` | image filename (string) | Per-mission loading bar override. |
| `Topics.loadscreen.bg_class` | CSS class name (string) | Replace the per-mission background class (e.g., pick based on game state). |
| `Topics.loadscreen.tip_text` | tip text (string) | Supply the tip text from a custom source (e.g., a SEXP variable). All styling stays in RCSS. |
| `Topics.loadscreen.initialize` | — | Side-effect hook fired after the load screen is fully wired up. Use this for per-mission DOM/style tweaks that RCSS alone can't express. |
| `Topics.loadscreen.unload` | — | Side-effect hook fired when the load screen is being torn down. |

Example: drive the tip from a SEXP variable:

```lua
local Topics = require("lib_ui_topics")

Topics.loadscreen.tip_text:bind(100, function(controller, context)
	if mn.SEXPVariables["LoadScreenTip"]:isValid() then
		context.value = mn.SEXPVariables["LoadScreenTip"].Value
		context.done = true
	end
end)
```

Example: apply a per-mission CSS class to `#loadscreen_tip` so the tip is
styled differently for one mission group:

```lua
local Topics = require("lib_ui_topics")
local Utils = require("lib_utils")

Topics.loadscreen.initialize:bind(100, function(controller, context)
	local mission = Utils.strip_extension(mn.getMissionFilename() or "")
	if mission:sub(1, 8) == "chapter1" then
		controller.Document:GetElementById("loadscreen_tip"):SetClass("chapter1_tip", true)
	end
end)
```
