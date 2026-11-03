# Librocket API Context

A context is a separate UI space with its own documents, focus and mouse cursor. SCPUI creates a single context called `menuui` that covers the whole screen and loads every screen's document into it.

A context only receives mouse and keyboard input after it has been passed to FSO's `ui.enableInput(context)`, and only one context receives input at a time. `ui.disableInput()` hands input back to FSO. Your script must also call `Update()` and `Render()` on the context every frame. See [Librocket](Librocket) for the `ui` functions.

## Properties

| Lua property | Brief description | Equivalent functions |
|---|---|---|
| dimensions | Gets/sets the dimensions of the context, as a `Vector2i`. | GetDimensions(), SetDimensions() |
| documents | Retrieves a document within the interface. Read-only. | GetDocument(), GetNumDocuments() |
| focus_element | Retrieves the context’s focus element. Read-only. | GetFocusElement() |
| hover_element | Retrieves the element under the context’s cursor. Read-only. | GetHoverElement() |
| root_element | Retrieves the context’s root element. Read-only. | GetRootElement() |
| name | Retrieves the context’s name. Read-only. | GetName() |

To resize a context, assign a new `Vector2i` to `dimensions`:

```lua
context.dimensions = Vector2i.new(gr.getScreenWidth(), gr.getScreenHeight())
```

Don't change the fields of the returned vector (`context.dimensions.x = 1024`). That writes straight into the context's size without telling it, so the layout is not updated.

### Retrieving documents

The documents property on the context can be referenced in several ways. Documents are looked up by the `id` of their `<body>` element:

```lua
local document = context.documents["main_background"]
```

Or accessing documents as fields on the documents property itself:

```lua
local document = context.documents.main_background
```

Or by number. Numeric indices are **0-based**: the first document is `context.documents[0]`. An index that is out of range returns nil.

To loop over all documents, use `pairs` (which gives the document id and the document) or `ipairs` (which gives the 0-based index and the document). The `#` operator does not work on `documents`.

```lua
for id, document in pairs(context.documents) do
	ba.print(id .. ": " .. document.title .. "\n")
end
```

## Methods

The following methods are available.

| Lua method | Brief description |
|---|---|
| AddEventListener(event, listener [, element [, in_capture_phase]]) | Attaches an event listener. `listener` is a Lua function or a string of inline code. If `element` is given, the listener is attached to that element. |
| AddMouseCursor(cursor_document) | Adds a cursor document that was loaded by another context to this context. Returns nothing. |
| CreateDocument([tag]) | Creates a new, empty document with the given tag name (default `"body"`) and returns it. |
| LoadDocument(path) | Loads a document from an RML file and returns it, or nil if it could not be loaded. The document is hidden until you call `Show()` on it. |
| LoadMouseCursor(path) | Loads a mouse cursor from an RML file and returns its document. |
| Render() | Renders the context. Returns true on success. |
| ShowMouseCursor(show) | Shows (true) or hides (false) the mouse cursor. |
| UnloadAllDocuments() | Unloads all loaded documents within the context. |
| UnloadAllMouseCursors() | Unloads all of the context’s mouse cursors. |
| UnloadDocument(document) | Unloads one of the context’s documents. |
| UnloadMouseCursor(name) | Unloads one of the context’s cursors, by name. |
| Update() | Updates the context. Returns true on success. |

> **Known issue:** `context:AddEventListener()` without an `element` argument attaches the listener to the context's root element, and FSO crashes the first time that listener fires. Always pass an element, or call `AddEventListener` on the element (usually the document) directly.

## Creating contexts

Contexts are created with `rocket:CreateContext()`. This function takes the name of the context as a string and the dimensions as a `Vector2i`. The name must be unique; if it is not, nil is returned.

```lua
local new_context = rocket:CreateContext("hud", Vector2i.new(1024, 768))
```

## Accessing contexts

Existing contexts can be accessed in Lua via the contexts member on the rocket module, by name:

```lua
local context = rocket.contexts["menuui"]
```

A context that doesn't exist returns nil.

> **Known issue:** Don't iterate over `rocket.contexts` or look contexts up by number. When there is more than one context, iterating skips the first context and returns the last one twice, and a numeric index that is out of range returns the last context instead of nil. Contexts are also numbered in alphabetical order of their names, not in the order they were created. Look contexts up by name, or keep the context returned by `CreateContext` in a variable (SCPUI keeps its context in `ScpuiSystem.data.Context`).
