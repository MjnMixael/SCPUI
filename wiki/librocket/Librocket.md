# Librocket

Librocket is the UI library that [SCPUI](Home) uses to layout, draw, and implement the upgraded ui system within FreeSpace Open. It uses the open standards XHTML1.0 and CSS2.0 (while borrowing features from HTML5 and CSS3), and extends them with features suited towards real-time applications.

FSO's version of the library is a bugfixed fork of the original. [The source code is available here.](https://github.com/scp-fs2open/libRocket)

## Basics

The basic implementation of a librocket UI within FSO contains three files: RML (the markup), RCSS (the style sheet), and Lua (the script that drives it).

Librocket only runs when FSO is in Unicode text mode. If the mod does not enable Unicode text mode, librocket is disabled entirely and no SCPUI screens will appear.

## Development and Debugging

There are a few main things to know when working with the librocket library within FSO.

1. You can view the librocket debugger by pressing ***ctrl-shift-d***
2. You can live-reload RML and RCSS files by pressing ***ctrl-shift-r***
   - Both shortcuts fire when the key is released, and only work while a context has input enabled (see `ui.enableInput` below). The debugger attaches to that context.
   - Reloading only affects documents that were loaded from a file. It clears the cached style sheets and templates, unloads each document and loads it again, so `onunload` and `onload` run again.
   - Reloading does **not** reload Lua modules that were loaded with `require`, because Lua caches them. Changes to a controller script need a restart. Any document or element handles your Lua code kept from before the reload point at the old, unloaded document.
3. Librocket errors and warnings are forwarded to FSO. Librocket errors show up as FSO warnings (in release builds too), librocket warnings show up as debug-build warnings, and everything else goes to the log. Errors in your Lua code are reported as normal FSO Lua errors.
   - The Lua API does not check the types of the values you pass it. Passing the wrong kind of object to a method (for example a context where an element is expected), or casting an element to the wrong type with `Element.As`, can crash FSO instead of producing an error.
   - Methods must be called with `:` (`element:Focus()`, not `element.Focus()`). A call with `.` silently does nothing and returns nil. Writing to a read-only or misspelled property is also silently ignored.

## RML

RML is based loosely around XHTML 1.0 and HTML 4.01, however element names are (mostly) open-ended in RML and can be used in any way that is logical for your application. All documents follow strict XML1.0 specification and where possible all libRocket elements follow their HTML equivalent.

RML maintains the core components of HTML4, including CSS and scripting. It provides a number of basic elements including input fields, radio buttons and check boxes as well as more complex enhancements such as templates and datagrids.

- [Elements](RML-Elements) - The basic RML element.
- [Documents](RML-Documents) - The HEAD and BODY of a document.
- [Images](RML-Images) - Referencing images.
- [Style Sheets](RML-StyleSheets) - Adding style to RML documents.
- [Forms](RML-Forms) - User-input forms.
- [Controls](RML-Controls) - Tabsets and window handles.
- [Data Display](RML-DataDisplay) - Data grids and data selects.
- [Templates](RML-Templates) - Making all your windows look consistent.
- [Events](RML-Events) - Mouse clicks, movement, key presses, text entry.

## RCSS

RCSS is based on the CSS2 specification, with certain elements removed or altered to suit the needs of libRocket. In some cases, elements have been taken from the CSS3 working draft. This document provides an overview of RCSS and the differences between RCSS and CSS, and should be read in conjunction with the CSS2 specification.

RCSS interacts with RML in an identical fashion to CSS and HTML. Style properties declared in a RCSS are attached selectively to elements defined in RML to affect layout, positioning and other style attributes (such as font, color, text decoration, etc).

If you are familiar with CSS, a good place to start is the [property index](RCSS-Properties), which outlines the properties and values supported in RCSS and the new functionality included. Next, read up on decorators, the new, flexible way to skin elements.

If you are not, read through this documentation while consulting the CSS2 specification for detailed examples and technical details, or skip all this for now and play around with the samples!

- [Syntax and basic data types](RCSS-Syntax)
- [Selectors](RCSS-Selectors)
- [Box model](RCSS-BoxModel)
- [Visual formatting model](RCSS-VisualModel)
- [Visual effects](RCSS-VisualEffects)
- [Colors and backgrounds](RCSS-ColorsBackgrounds)
- [Fonts](RCSS-Fonts)
- [Text](RCSS-Text)
- [Cursors, Dragging and Tabbing](RCSS-CursorsDragTab)
- [Decorators](RCSS-Decorators)
- [Font effects](RCSS-FontEffects)
- [Scrollbars and Sliders](RCSS-Scrollbars)
- [Property Index](RCSS-Properties)

## LUA API

The Lua interface to libRocket has been designed to resemble Javascript as closely as possible. It is how the librocket UI will actually interact with the Freespace Open engine. Below is a list of property and API references.

- [Elements](Librocket-API-Element)
- [Documents](Librocket-API-Document)
- [Contexts](Librocket-API-Context)
- [Events](Librocket-API-Event)
- [API Reference](Librocket-API-Reference)

### Embedding Script

Lua code can be embedded into RML files. Inline responses to events are executed as Lua code. Functions, structures and variables can be declared or included with the `<script>` tag, then referenced from the inline code.

Similarly to Javascript, the Lua can be included from a separate file with the src attribute, or otherwise declared inline as loose content within the `<script>` tag. Any code embedded in this manner will be compiled with the document and will be available to inline event handlers in the RML.

SCPUI keeps the logic for each screen in a controller module under `data/scripts`, and the document's `<script>` only creates the controller. The inline handlers then call methods on it:

```html
<rml>
	<head>
		<script>
			controller = require("ctrlr_pilot_select")()
		</script>
	</head>
	<body onload="controller:initialize(document)" onunload="controller:unload(); controller = nil">
		<button id="playercommit_btn" onclick="controller:commit_pressed()">Continue</button>
	</body>
</rml>
```

A small screen can also define its functions directly in the `<script>` tag, or load them from a file:

```html
<rml>
	<head>
		<script>
			function Test()
				ba.print("Hello world!\n")
			end
		</script>
	</head>
	<body>
		<button onclick="Test()">Continue</button>
	</body>
</rml>
```

```html
<rml>
	<head>
		<script src="test.lua"></script>
	</head>
	<body>
		<button onclick="Test()">Continue</button>
	</body>
</rml>
```

#### Per-document environment

Each document gets its own Lua environment. Its `<script>` code, its inline event handlers and the event listeners attached to it all run in that environment. A global you set there (like `controller` above) belongs to that document only, so two documents can each have their own `controller` without overwriting each other. Anything not found in the document's environment is looked up in the normal global table, so `ba`, `ui`, `rocket` and your own true globals are still available.

When you pass a Lua function to `AddEventListener`, that function is switched to the document's environment the first time the event fires. Globals the function reads still resolve normally, but globals it *writes* go into the document's environment rather than the global table.

### Attaching To Events

You can attach to user interface events statically in the RML or dynamically in the lua scripts.

- A list of events available to attach to is in the [RML Events](RML-Events) documentation.

#### Statically

With this method you write your code directly into the RML files, using the on* attributes. The code becomes the body of a function that receives three parameters, `event`, `element` and `document`:

- [event](Librocket-API-Event) - The event that's currently being processed
- [element](Librocket-API-Element) - The element that carries the on* attribute. This is not necessarily the element the event happened on; use `event.target_element` for that.
- [document](Librocket-API-Document) - The document the element belongs to

There is no `self` variable.

Using the on* attributes you write your code inline

- Example: `<button onclick="ba.print('Clicked!\n')"/>`

LibRocket allows multiple lines of code to be put on one line, separated by a semicolon.

- Example: `<button onclick="ba.print('Line 1\n');ba.print('Line 2\n')"/>`

#### Dynamically

The `AddEventListener()` method allows you to bind any Lua function to an event. The function receives the same three parameters as an inline handler: `(event, element, document)`. You can also pass a string of code instead of a function; it is treated exactly like an inline on* attribute.

```lua
function createListener(document)
   local element = document:GetElementById("button")
   element:AddEventListener("click", function(event, element, document)
      ba.print("clicked!\n")
   end)
end
```

Listeners added from Lua cannot be removed again. They are removed only when the element is destroyed.

## FSO's `ui` library

FSO's `ui` scripting library has a few functions that work directly with librocket objects:

| Function | Description |
|---|---|
| `ui.enableInput(context)` | Sends mouse and keyboard input to the given context. Only one context receives input at a time; enabling a new one disables the previous one. Returns true on success. A context that has not been enabled does not react to the mouse or keyboard at all. |
| `ui.disableInput()` | Stops sending input to librocket and gives it back to FSO. |
| `ui.setOffset(x, y)` | Sets the offset from the top left corner of the screen at which all contexts are rendered. Returns true on success. |
| `ui.playElementSound(element, event, state = "")` | Plays the sound set by the element's `<event>-sound` RCSS property (for example `click-sound`). If `state` is given, the sound for that state is played instead, as in `click-sound: (error)10,(success)18;`. Returns true if a sound was played. |
| `ui.linkTexture(texture)` | Makes an FSO texture available to librocket and returns a URL for it, or an empty string if the texture is invalid. Use the URL as an image source, for example `el:SetAttribute("src", ui.linkTexture(tex))`. |

```lua
-- SCPUI's basic setup: one context for the whole screen, with input routed to it
local context = rocket:CreateContext("menuui", Vector2i.new(gr.getScreenWidth(), gr.getScreenHeight()))
local document = context:LoadDocument("data/interface/markup/dialog.rml")
document:Show()
ui.enableInput(context)

-- ...and every frame
context:Update()
context:Render()
```
