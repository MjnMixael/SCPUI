# Librocket API Document

Documents derive from elements, so inherit their interface; everything on the [Elements](Librocket-API-Element) page also works on a document. The document is the `<body>` element of an RML file, so its `id` is the body's id.

Inline event handlers and listeners receive the document as their `document` parameter. If you have the document as a plain element (for example from `element.parent_node`), use `element.owner_document` or cast it with `Element.As.Document(el)` to get the document methods.

## Properties

| Lua property | Brief description | Access |
|---|---|---|
| context | Retrieves the document’s context. | Read-only |
| title | Gets / sets the document’s title. | Read/write |

## Methods

| Lua method | Brief description |
|---|---|
| CreateElement(tag_name) | Creates an element with the given tag and returns it. The element is not part of the document until you add it with `AppendChild()` or `InsertBefore()`. |
| CreateTextNode(text) | Creates a text element containing `text` and returns it. Add it to the document the same way as `CreateElement()`. |
| Close() | Closes the document and destroys all child elements. |
| Hide() | Hides the document. |
| PullToFront() | Pulls to the document to the front of others with a similar z-index. |
| PushToBack() | Pushes to the document behind others with a similar z-index. |
| Show([flags]) | Shows the document, optionally with focus flags. |

The flags available for `Show()` are in the global `DocumentFocus` table:

- `DocumentFocus.NONE` - Show the document without giving it focus.
- `DocumentFocus.FOCUS` - Show the document and give it focus. This is the default.
- `DocumentFocus.MODAL` - Show the document, give it focus and keep the focus there. Other documents in the context can't take the focus or receive mouse input while it is shown. This also blocks the librocket debugger, so SCPUI's dialogs use `FOCUS` instead.

```lua
local dialog_doc = context:LoadDocument("data/interface/markup/dialog.rml")
dialog_doc:Show(DocumentFocus.FOCUS)
```

## Text elements

`CreateTextNode()` returns an `ElementText`. It is an element with one extra property, `text`, which reads or replaces the element's text (in UTF-8):

```lua
local label = document:CreateTextNode("OK")
document:GetElementById("button_label"):AppendChild(label)

label.text = "Cancel"
```

A text element you get from `child_nodes` or `first_child` comes back as a plain element; cast it with `Element.As.ElementText(el)` to use `text`.
