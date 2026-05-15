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

- `#Loading Text` — named tip strings.
- `#Loading Screens` — load-screen profiles: which CSS background classes to
  pick from (random selection if more than one), which loading bar to use,
  tip style, title style, and which tip(s) to draw.
- `#Mission Screens` — mission filename → profile mapping.

Backgrounds remain CSS-class-only. You declare each background image once as
a CSS class in `data/interface/css/load_screen_bgs.rcss`, then reference the
class name(s) from a profile.

## Old script section → SCPUI equivalent

| Old section / field | SCPUI equivalent |
| --- | --- |
| `#General Settings $Scale Zoom: true` | No-op; CSS scales backgrounds automatically. |
| `#Loading Bars $Name: ... $File: bar.ani` | `$Loading Bar Image: bar.ani` inside a `#Loading Screens` profile. |
| `#Loading Bars $Origin: / $Offset:` | Override `div#loadingbar` positioning in your mod's RCSS (see below). |
| `#Loading Text $Name: / $Text: / $Font:` | `#Loading Text $Name: / $Text: / +Font Class:`. The value of `+Font Class:` is an RCSS class name (e.g. `p6`), not an FSO font index. |
| `#Loading Screens $Loading Image: random` + `+Image:` list | Multiple `+Background Class:` entries in the profile. One is picked at random per load. |
| `#Loading Screens $Loading Image: <fixed>` | A single `+Background Class:` entry. |
| `#Loading Screens +Scaling: true` | No-op; CSS handles scaling. |
| `#Loading Screens $Text Color: r,g,b,a` | `+Color: r, g, b, a` inside the profile's `$Tip Style:` block. |
| `#Loading Screens $Text Origin: x, y` | `+Origin: x, y` inside `$Tip Style:`. (Screen-fractional, like the old script.) |
| `#Loading Screens +Width: N` | `+Width: N` inside `$Tip Style:`. (Pixels.) |
| `#Loading Screens $Draw Mission Name: true / +Font: / +Origin: / +Offset: / +Justify:` | `$Title Style:` block with `+Font Class:`, `+Origin:`, `+Offset:`, `+Justify:`. |
| `#Loading Screens $Loading Text: <name>` | `$Tip: <name>` (one or more; one is picked at random). |
| `#Mission Screens $Filename: / $Loading Screen:` | Same field names, same shape. `.fs2` extensions are stripped on parse. |

## Walkthrough — translating `RoR-01`

Original Axem entry (excerpt):

```
$Name:          Proverbs-1
$Text:          XSTR("...''Ribos is all broken promises buried under miles of military supply chains.''...", -1)
$Font:          6

$Name:          RoR-01
$Loading Bar:   MoGW-pale_blue
$Loading Image: random
    +Scaling:   true
    +Image:     nLS-RoR-01a
    +Image:     nLS-RoR-01b
    +Image:     nLS-RoR-01c
    +Image:     nLS-RoR-01d
$Text Color:    192, 192, 255, 255
$Text Origin:   0.03, 0.75
    +Width:     800
$Draw Mission Name: true
    +Font:      5
    +Origin:    0.65, 0
    +Offset:    0, 20
    +Justify:   left
$Loading Text:  Proverbs-1

$Filename:      RoR_01.fs2
$Loading Screen: RoR-01
```

### Step 1 — author the background CSS classes

In `data/interface/css/load_screen_bgs.rcss` (or your mod's override of it),
add one class per background image:

```rcss
.ror_01_bg1 { background-decorator: image; background-image: nLS-RoR-01a.png; }
.ror_01_bg2 { background-decorator: image; background-image: nLS-RoR-01b.png; }
.ror_01_bg3 { background-decorator: image; background-image: nLS-RoR-01c.png; }
.ror_01_bg4 { background-decorator: image; background-image: nLS-RoR-01d.png; }
```

### Step 2 — add the table entries

In `scpui.tbl` (or a `your_mod-ui.tbm` modular). The sections may appear in
any combination, but they must come after `#Briefing Stage Background Replacement`
and before `#Medal Placements` (when present), and the file still ends with a
single top-level `#End`:

```
#Loading Text

$Name: Proverbs-1
$Text: XSTR("...''Ribos is all broken promises buried under miles of military supply chains.''...", -1)
+Font Class: p6

#Loading Screens

$Name: RoR-01
$Loading Bar Image: LB-mogw-pb.ani
+Background Class: ror_01_bg1
+Background Class: ror_01_bg2
+Background Class: ror_01_bg3
+Background Class: ror_01_bg4
$Tip Style:
	+Font Class: p6
	+Color: 192, 192, 255, 255
	+Origin: 0.03, 0.75
	+Width: 800
$Title Style:
	+Font Class: p5
	+Origin: 0.65, 0
	+Offset: 0, 20
	+Justify: left
$Tip: Proverbs-1

#Mission Screens

$Filename: RoR_01.fs2
$Loading Screen: RoR-01

#End
```

### Step 3 (optional) — reposition the loading bar

The Axem entry's `MoGW-pale_blue` bar lived at screen-relative origin
`(1.0, 0.5)` with a pixel offset of `(-26, -210)`. SCPUI's default bar is
50% wide, centered at the bottom. To reproduce the old layout, add to your
mod's RCSS (e.g. an override of `load_screen.rcss` or a new linked file):

```rcss
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

## Three-step recipe for adding a new mission load screen

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

The new sections do not yet provide a 1:1 mapping for every field the Axem
script supported. The following are deliberately out of scope right now;
**if you need any of them, open an issue and they can be added**:

- `$Image:` under a `#Loading Text` entry (a graphic drawn alongside the tip).
- `$Variable:` under `#Loading Text` (text pulled from a SEXP variable at
  runtime).
- Text `+Center` and `+Offset:` modes other than what `$Tip Style:` exposes.
- `$Image Origin:` and its `+Offset:` (the tip-image positioning).
- `+Scaling:` on a `#Loading Bars` entry (the bar inheriting background scale).
- The Axem-style `default` mission entry. SCPUI's `.loadscreen_default` CSS
  class already covers fallback rendering when no profile matches.

## Topic API reference (for mods that want to override in Lua)

If you need behavior that the declarative table can't express, bind a
listener to one of the loadscreen Topics. Each Topic sends the mission
filename stem (no extension) as its message. Set `context.value` to your
override and `context.done = true` to skip the table-driven default at
priority 9999.

| Topic | Returns | Use case |
| --- | --- | --- |
| `Topics.loadscreen.load_bar` | image filename (string) | Per-mission loading bar override. |
| `Topics.loadscreen.bg_class` | CSS class name (string) | Replace the per-mission background class (e.g., pick based on game state). |
| `Topics.loadscreen.tip_text` | `{ Text, FontClass, Color, Origin, Offset, Width }` | Provide tip content + style from custom sources (e.g., a SEXP variable). |
| `Topics.loadscreen.title_style` | `{ FontClass, Origin, Offset, Justify }` | Override the mission title layout. |
| `Topics.loadscreen.initialize` | — | Side-effect hook fired after the load screen is fully wired up. |
| `Topics.loadscreen.unload` | — | Side-effect hook fired when the load screen is being torn down. |

Example — override the tip text using a SEXP variable:

```lua
local Topics = require("lib_ui_topics")

Topics.loadscreen.tip_text:bind(100, function(mission_stem, context)
	if mn.SEXPVariables["LoadScreenTip"]:isValid() then
		context.value = {
			Text = mn.SEXPVariables["LoadScreenTip"].Value,
			FontClass = "p6",
			Origin = { x = 0.03, y = 0.75 },
			Width = 800,
		}
		context.done = true
	end
end)
```
