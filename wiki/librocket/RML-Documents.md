# RML Documents

RML documents have this basic structure.

## `<rml>`

All libRocket documents begin with the `<rml>` element. The element should contain two children, `<head>` and `<body>`.

```html
<rml>
	<head>
		<title>Options</title>
		<link type="text/rcss" href="default.rcss"/>
		<link type="text/rcss" href="options.rcss"/>
		<script>
			controller = require("ctrlr_options")()
		</script>
	</head>
	<body id="main_background" onload="controller:initialize(document)" onunload="controller:unload(); controller = nil">
	...
	</body>
</rml>
```

### `<head>`

The `<head>` element contains information about the current document, such as its title, the style sheets and templates it references, and its scripts. Nothing in the header is rendered.

### `<title>`

The `<title>` element contains the title of the document. It is passed through FSO's localization, so `XSTR("…", id)` works here, and it can be read or changed from Lua as `document.title`.

### `<link>`

The `<link>` element is used to specify additional resources the document requires.

#### Attributes

##### type

- Type of link, which should be one of:
- `text/rcss` (or `text/css`) - libRocket Style Sheet, see [Style Sheets](RML-StyleSheets)
- `text/template` - libRocket Template, see [Templates](RML-Templates)

Any other type is an error. Scripts are not linked; use `<script>` instead.

##### href

- The file to load. See [File paths](#file-paths) below.

### `<script>`

The `<script>` element holds Lua code for the document. It can contain the code directly, or load a file with the `src` attribute:

```html
<head>
	<script src="my_screen.lua"></script>
	<script>
		controller = require("ctrlr_options")()
	</script>
</head>
```

Scripts run when the parser reaches the end of `<head>`, before the body has been read, so they can't find the document's elements yet. Do that work in the body's `onload` handler instead. All external (`src`) scripts run first, in order, and then all inline scripts, in order, regardless of how they are mixed in the header. `<script>` only works inside `<head>`.

Each document has its own Lua environment. Globals set by its scripts (such as `controller` above) belong to that document only, and its inline event handlers see them. Anything not found there is looked up in the normal global table, so `ba`, `ui`, `rocket` and your own globals still work. SCPUI's usual pattern is a one-line inline script that creates the screen's controller with `require`, plus `onload`/`onunload` on the `<body>`. See [Per-document environment](Librocket#per-document-environment).

### `<body>`

The body of a document contains the document's content. All elements within the `<body>` tag are laid out and rendered by libRocket based on the active style sheets.

The attributes on `<body>` belong to the document itself. An `id` or `class` set here is the document's, and event attributes such as `onload`, `onunload`, `onshow` and `onkeydown` are attached to the document. See [Events](RML-Events).

The `template` attribute wraps the body in a template; see [Templates](RML-Templates).

## Text and localization

Text anywhere in the document is passed through FSO's localization, so `XSTR("Text", id)` is replaced with the translated string for the current language:

```html
<p>XSTR("Basic", 888153)</p>
```

## File paths

Paths in `href` and `src` are **not** relative to the document. FSO looks up a bare file name like `options.rcss` or `ops-panel-large-l.png` in all of its data paths (the mod's `data/interface/markup`, `data/interface/css`, `data/interface` and so on, plus VPs), the same way the rest of FSO finds files. Use bare file names; the folder a file is in doesn't matter as long as it's somewhere FSO looks.

## Requirements

SCPUI needs FSO's Unicode text mode. If the mod doesn't enable it, libRocket isn't started and no RML documents are loaded.
