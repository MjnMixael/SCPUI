# RML Templates

There are two different things called templates in SCPUI: libRocket's own `<template>` element, which wraps a document's content in a shared layout when the document loads, and SCPUI's Lua template pattern, which clones hidden RML at runtime to build repeated UI elements. They are unrelated.

## libRocket templates

A libRocket template is a separate file holding a layout, such as a window frame, that several documents can share. Each document that uses it puts its own content inside the template's content element.

SCPUI's own screens don't use libRocket templates, so they are less tested in FSO than the rest of this documentation.

### The template file

A template file uses `<template>` in place of `<rml>`, and must contain both a `<head>` and a `<body>`:

```html
<template name="window" content="content">
	<head>
		<link type="text/rcss" href="window.rcss"/>
	</head>
	<body>
		<div id="window_frame">
			<div id="title_bar">...</div>
			<div id="content">
			</div>
		</div>
	</body>
</template>
```

The template's `<head>` is merged into every document that links the template, so style sheets it links are loaded for those documents too. The document's own header is applied last and wins.

#### Attributes

##### name

The name of the template. Must be unique. Is used by other RML documents to reference the template.

##### content

The id of the element that the content will be put into. When the template is used, the document's content is placed inside this element. If it isn't found, the content is added after the template's body.

### Loading a template

A document must load the template file in its `<head>` before it can use it:

```html
<link type="text/template" href="window.rml"/>
```

The `href` is the file name; uses refer to the template by its `name`, not its file name.

### `<body template>`

The `<body>` element has a template attribute that is a shorthand for injecting a template around the body tag.

#### template

The name of the template to use. All child elements under the `<body>` element will be loaded into the template.

```html
<rml>
	<head>
		<link type="text/template" href="window.rml"/>
	</head>
	<body template="window">
		<p>This text ends up inside #content.</p>
	</body>
</rml>
```

### `<template>` inside a document

`<template>` can also be used inside a document's body to inject a template at that point. Everything inside the `<template>` tag is placed inside the template's content element.

#### src

The name of the template to inject.

```html
<template src="window">
	<p>Window contents</p>
</template>
```

## SCPUI's Lua templates

SCPUI builds repeated UI elements (such as each option control on the options screen) by cloning hidden RML from Lua. This uses ordinary elements, not `<template>`:

1. The RML for each piece is written once, in a hidden container. The options screen keeps them in a separate file brought in with `<include>`:

   ```html
   <div class="hidden">
   	<include src="options_templates.rml"/>
   </div>
   ```

2. Each piece has an `id` to find it by, and classes on the sub-elements Lua needs to fill in:

   ```html
   <div id="dropdown_template" class="btn_panel_horz">
   	<if condition="not no_title">
   		<div class="ops_left_header">
   			<span class="dropdown_text_el"></span>
   		</div>
   	</if>
   	<dataselect class="dropdown_dataselect_el" fields="display" valuefield="serialized"></dataselect>
   </div>
   ```

3. Lua clones the template with `lib_templates`, gets the sub-elements by class, and adds the clone to the page:

   ```lua
   local Templates = require("lib_templates")

   local actual_el, text_el, dataselect_el = Templates.instantiate_template(
   	document, "dropdown_template", "graphics_detail", { "dropdown_text_el", "dropdown_dataselect_el" }, { no_title = false })

   text_el.inner_rml = "Detail"
   document:GetElementById("graphics_column"):AppendChild(actual_el)
   ```

`instantiate_template(document, template_id, element_id, classes, parameters)` clones the element with id `template_id`, gives the clone the id `element_id`, and returns the clone followed by the first element found for each class in `classes`. Inputs among them are already cast with `Element.As.ElementFormControlInput`.

`<if condition="…">` is SCPUI's, not libRocket's: it only means something to `instantiate_template`. The condition is a Lua expression evaluated with the `parameters` table as its only variables. If it is true the `<if>` is replaced by its children; if false, it is removed with its children. In a document that isn't processed this way, `<if>` is just an ordinary element.

See [Elements](RML-Elements#include) for `<include>`.
