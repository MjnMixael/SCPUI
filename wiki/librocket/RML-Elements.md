# RML Elements

When parsing a tag libRocket will look up custom elements associated with the tag name and fall back to a generic element. Very few custom elements are required as most of the power in libRocket comes from styling elements with RCSS to produce the desired layout.

Any tag libRocket doesn't know becomes a generic element, so you can use HTML names like `<div>`, `<span>`, `<p>` or `<button>`, or invent your own. A generic element has no built-in behaviour or look; it is whatever your RCSS makes it.

The user is encouraged to follow standard HTML guidelines where possible to improve readability across the community.

### No default style sheet

libRocket has no built-in style sheet. Every element, including `<div>` and `<p>`, is `display: inline` until a style sheet says otherwise. SCPUI's `default.rcss` supplies the basic defaults (`div` and `p` as blocks, `em` italic, `strong` bold, and so on), so link it first in every document:

```html
<link type="text/rcss" href="default.rcss"/>
```

### Tag and attribute names

Tag and attribute names are converted to lower case when a document is parsed. `<scrollingText>` becomes `scrollingtext`, so RCSS selectors and Lua comparisons such as `element.tag_name` must use the lower-case name.

## Global Attributes

Elements have a base set of attributes that are common to across all types, which are:

### id

The unique identifier for the element in this document.

### class

Assigns a class name or set of class names to an element. Any number of elements may be assigned the same class name or names. Multiple class names must be separated by white space characters. See [RCSS](Librocket#rcss).

### style

Specifies inline style information for the element. See [RCSS](Librocket#rcss).

### on* events

Any attribute whose name starts with `on` becomes a Lua event listener for the event named by the rest of the attribute name: `onclick` listens for `click`, `ondragdrop` for `dragdrop`. The value is Lua code. These are bound only when the element is created, so adding an `on*` attribute later from Lua does nothing; use `AddEventListener` instead. See [Events](RML-Events).

## List

The following is a list of elements with special meaning in RML inside FSO.

### Document structure

- `<rml>`, `<head>`, `<body>` - see [Documents](RML-Documents)
- `<title>` - see [Documents](RML-Documents)
- `<link>` - see [Documents](RML-Documents)
- `<script>` - Lua code, `<head>` only; see [Documents](RML-Documents)
- `<style>` - inline RCSS, `<head>` only; see [Style Sheets](RML-StyleSheets)
- `<template>` - see [Templates](RML-Templates)
- `<include>` - FSO; see below

### Content

- `<img>` - see [Images](RML-Images)
- `<ani>` - FSO; animated images, see [Images](RML-Images)
- `<scrollingText>` - FSO; see below
- `<br>` - line break

### Forms

See [Forms](RML-Forms).

- `<form>`
- `<input>`
- `<textarea>`
- `<select>`
- `<option>`
- `<dataselect>`

### Controls

See [Controls](RML-Controls).

- `<handle>`
- `<tabset>`
- `<tab>`, `<tabs>`
- `<panel>`, `<panels>`

### Data display

See [Data Display](RML-DataDisplay).

- `<datagrid>`
- `<col>`
- `<datagridexpand>`

`<style>` and `<script>` only work inside `<head>`. In the body they are treated as ordinary elements, so their contents show up as text.

## `<include>`

FSO's `<include>` element inserts the contents of another RML file at that point, as if they had been written there. SCPUI uses it to split large screens into several files:

```html
<tabset id="ops_tabs_cont">
	<tab id="basic_btn" class="button_1 tab">XSTR("Basic", 888153)</tab>
	<panel class="options_panel">
		<include src="options_basic_tab.rml"/>
	</panel>
</tabset>
```

### Attributes

#### src

The file to include. As with other paths, use a bare file name; see [Documents](RML-Documents#file-paths).

### The included file

The included file wraps its content in a `<body>` tag and has no `<rml>` or `<head>`:

```html
<body>
<div class="options_column_40">
	<p>XSTR("Volume", 888162)</p>
	...
</div>
</body>
```

The content is parsed into the element that contains the `<include>`. Style sheets and scripts belong in the main document's `<head>`.

Keep the included file's `<body>` tag bare. Any attributes on it (an `id`, `class` or `onload`, for example) are applied to the *including* document and replace the document's own.

## `<scrollingText>`

FSO's `<scrollingText>` element reveals its content with a left-to-right wipe, like retail's briefing text. SCPUI uses it for briefing and command briefing text:

```html
<div id="brief_text">
	<scrollingText id="brief_text_el">
	</scrollingText>
</div>
```

The wipe restarts whenever a child is added or removed, so setting new text from Lua replays it:

```lua
local text_el = document:GetElementById("brief_text_el")
text_el.inner_rml = stage.Text
```

The wipe moves across the parent element's width in steps of 15 pixels.

### Attributes

#### duration

How long the wipe takes, in seconds. The default is 1.5.

> **Known issue:** a `duration` set in RML, or set on its own from Lua, is ignored; the element keeps using 1.5 seconds. It only reads `duration` when some *other* attribute changes. To apply it, set `duration` and then change any other attribute:
>
> ```lua
> text_el:SetAttribute("duration", "3")
> text_el:SetAttribute("data-refresh", "1")
> ```
