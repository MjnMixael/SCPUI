# Librocket API Reference

Below is full reference of valid API methods and properties.

Some general rules apply to everything on this page:

- Methods are called with `:` (`document:Show()`). A call with `.` silently does nothing and returns nil. The exceptions are constructors and other functions on a type's global table, such as `Vector2i.new()`, `Log.Message()` and `Element.As.Document()`, which use `.`.
- Values that are missing are returned as nil.
- Properties marked read-only can't be changed. Writing to them, or to a name that doesn't exist, is silently ignored.
- The collections returned by properties (`child_nodes`, `attributes`, `style`, `documents`, `parameters`, `options`, `rocket.contexts`) are not Lua tables. Loop over them with `pairs` or `ipairs`; the `#` operator doesn't work on them. Check each entry below for whether it is indexed from 0 or 1.
- The API doesn't check the types of the objects you pass in. Passing the wrong kind of object, or using `Element.As` to cast an element to the wrong type, can crash FSO.

## Module

These are members of the global `rocket` object.

- CreateContext(name, dimensions)
  - Creates and returns a new context called name, with initial dimensions of dimensions. The dimensions are a `Vector2i`. The name of the context must be unique; if it is not, nil will be returned.
  - Example: `rocket:CreateContext("menuui", Vector2i.new(gr.getScreenWidth(), gr.getScreenHeight()))`
- LoadFontFace(font_path)
  - Loads the font face at font_path. The function will return true if the font face was loaded, false if not. FSO already loads the fonts the mod defines, so this is rarely needed.
- RegisterTag(tag_name, instancer)
  - Registers an `ElementInstancer` to create the element whenever the tag is encountered in an RML file. See [ElementInstancer](#elementinstancer).
- contexts
  - The active libRocket contexts. Index it by name to get the context with that name, or nil if there is none.
  - **Known issue:** Don't iterate over `rocket.contexts` or index it by number. When there is more than one context, iterating skips the first one and returns the last one twice. A numeric index that is out of range returns the last context instead of nil, and numbers follow the alphabetical order of the context names. Look contexts up by name instead, or keep the context returned by `CreateContext()`.
- key_identifier
  - A table of key codes, for comparing against the `key_identifier` parameter of key events. The names don't have a prefix: `rocket.key_identifier.ESCAPE`, `rocket.key_identifier.RETURN`, `rocket.key_identifier.A`, `rocket.key_identifier.F1`, `rocket.key_identifier.UP`, `rocket.key_identifier.NUMPAD0`, and so on.
- key_modifier
  - A table of key modifier flags: `CTRL`, `SHIFT`, `ALT`, `META`, `CAPSLOCK`, `NUMLOCK` and `SCROLLLOCK`. Key events also provide the separate `ctrl_key`, `shift_key`, `alt_key` and `meta_key` parameters, which are usually easier to use.

## Log

`Log` is a global table, not part of `rocket`.

- Log.Message(type, message)
  - Sends a log message to libRocket (and the attached debugger if present). Errors appear as FSO warnings, warnings appear as warnings in debug builds, and the other types go to the FSO log. type should be one of:
    - Log.logtype.always
    - Log.logtype.error
    - Log.logtype.warning
    - Log.logtype.info
    - Log.logtype.debug
  - Example: `Log.Message(Log.logtype.warning, "Something looks wrong")`

For ordinary debug output, FSO's own `ba.print()` and `ba.warning()` work just as well.

## Basic Types

### Vector2i

- Vector2i.new(x, y)
  - Constructs a two-dimensional integral vector.
- x, y
  - The components, as integers. Read/write.
- magnitude
  - The length of the vector. Read-only.
- Operators: `a + b` and `a - b` (with another `Vector2i`), `v * n` and `v / n` (with a number), and `a == b`.

### Vector2f

- Vector2f.new(x, y)
  - Constructs a two-dimensional floating-point vector.
- x, y
  - The components. Read/write.
- magnitude
  - The length of the vector. Read-only.
- DotProduct(other)
  - Returns the dot product of this vector and another `Vector2f`.
- Normalise()
  - Returns a new vector of length 1 pointing the same way.
- Rotate(angle)
  - Returns a new vector rotated by angle, in radians.
- Operators: `a + b` and `a - b` (with another `Vector2f`), `v * n` and `v / n` (with a number), and `a == b`.

### Colourb

- Colourb.new(red, green, blue, alpha)
  - Constructs a colour with four channels, each from 0 to 255. All four are required.
- red, green, blue, alpha
  - The channels. Read/write.
- Operators: `a + b` (with another `Colourb`), `c * n` (with a number), and `a == b`.
- The `rgba` property doesn't work from Lua; use the individual channels.

### Colourf

- Colourf.new(red, green, blue, alpha)
  - Constructs a colour with four floating-point channels, each from 0 to 1. All four are required.
- red, green, blue, alpha
  - The channels. Read/write.
- Operators: `a == b`.
- The `rgba` property doesn't work from Lua; use the individual channels.

## DataSource

### DataSource

- DataSource.new(name)
  - Creates a data source with the given name. Data grids and data selects refer to it in RML as `source="name.table"`.

You supply the data by assigning two functions to the data source (with `.` and `=`, not `:`). They are called with the following arguments:

- GetNumRows = function(table_name)
  - Must return the number of rows in the given table.
- GetRow = function(table_name, index, columns)
  - Must return a table of the column values in string form, one for each name in `columns`, in the same order. `index` is **1-based**, so it can index a Lua list directly. `columns` is a 1-based list of column names.

When your data changes, tell the controls that use it:

- NotifyRowAdd(table_name, first_row_added, num_rows_added)
  - Notify listeners that rows have been added to the data source.
- NotifyRowRemove(table_name, first_row_removed, num_rows_removed)
  - Notify listeners that rows have been removed from the data source.
- NotifyRowChange(table_name, first_row_changed, num_rows_changed)
  - Notify listeners that rows have been changed on the data source.
- NotifyRowChange(table_name)
  - Notify listeners that all rows on the data source have changed.

The row numbers passed to the Notify methods are **0-based**, unlike the index `GetRow` receives: the first row is 0.

```lua
local values = { "Easy", "Medium", "Hard" }
local source = DataSource.new("difficulty")

source.GetNumRows = function(table_name)
	return #values
end

source.GetRow = function(table_name, index, columns)
	local out = {}
	for _, column in ipairs(columns) do
		if column == "display" then
			table.insert(out, values[index])
		else
			table.insert(out, "")
		end
	end
	return out
end

-- after changing the values
source:NotifyRowChange("default")
```

### DataFormatter

A data formatter turns the raw column values of a row into the RML that is displayed for it. Data grid columns and data selects refer to it by name with their `formatter` attribute.

- DataFormatter.new(name [, format_function])
  - Creates a data formatter with the given name.
- FormatData = function(raw_data)
  - Must return the RML string to display. It can also be passed to `DataFormatter.new()`. `raw_data` is a table of the column values, as strings, indexed from **0**: the first value is `raw_data[0]`, so `ipairs` skips it.

```lua
local formatter = DataFormatter.new("bold", function(raw_data)
	return "<b>" .. raw_data[0] .. "</b>"
end)
```

## ElementInstancer

An element instancer creates elements for a tag registered with `rocket:RegisterTag()`.

- ElementInstancer.new([instance_function])
  - Creates an element instancer.
- InstanceElement = function(tag_name)
  - Must return the new element. It can also be passed to `ElementInstancer.new()`.

From Lua the instancer can only create plain elements with `Element.new(tag_name)`, so this is of limited use.

## Element

### Element

- The Element class is normally instantiated through a Document object, with `CreateElement()`. `Element.new(tag_name)` also creates one, but always as a plain element even for tags like `input`. It has the following methods and properties:

- AddEventListener(event, listener [, in_capture_phase])
  - Attaches listener to this element, listening for occurrences of event in either the bubble or capture phase. listener is a Lua function, called with `(event, element, document)`, or a string of inline code. If not specified, in_capture_phase will default to false. NOTE: Listeners added from Lua cannot be removed.
- AppendChild(element)
  - Appends element as a child to this element.
- Blur()
  - Removes input focus from this element.
- Click()
  - Fakes a click on this element.
- Clone()
  - Returns a copy of this element, with its attributes and content. Listeners added with AddEventListener are not copied.
- DispatchEvent(event, parameters)
  - Dispatches an event to this element. The event is of type event. Parameters to the event are given in the table parameters, which is required (pass `{}` for none); it must only contain string keys and string, number or boolean values. Booleans arrive in the listener as the numbers 1 and 0. Events dispatched from Lua cannot be stopped with StopPropagation().
- Focus()
  - Gives input focus to this element.
- GetAttribute(name)
  - Returns the value of the attribute named name. If no such attribute exists, nil will be returned.
- GetElementById(id)
  - Returns the descendant element with an id of id, or nil.
- GetElementsByClassName(class_name)
  - Returns a Lua table, indexed from 1, of all descendant elements with the class class_name.
- GetElementsByTagName(tag_name)
  - Returns a Lua table, indexed from 1, of all descendant elements with the tag of tag_name.
- HasAttribute(name)
  - Returns true if the element has a value for the attribute named name, false if not.
- HasChildNodes()
  - Returns true if the element has at least one child node, false if not.
- InsertBefore(element, adjacent_element)
  - Inserts the element element as a child of this element, directly before adjacent_element in the list of children.
- IsClassSet(name)
  - Returns true if the class name is set on the element, false if not.
- RemoveAttribute(name)
  - Removes the attribute named name from the element.
- RemoveChild(element)
  - Removes the child element element from this element. Returns true if it was removed.
- ReplaceChild(inserted_element, replaced_element)
  - Replaces the child element replaced_element with inserted_element in this element’s list of children. If replaced_element is not a child of this element, inserted_element will be appended onto the list instead. Returns true if replaced_element was replaced.
- ScrollIntoView([align_with_top])
  - Scrolls this element into view if its ancestors have hidden overflow. If align_with_top is true, the element’s top edge will be aligned with the top (or as close as possible to the top) of its ancestors’ viewing windows. If false, its bottom edge will be aligned to the bottom.
  - **Known issue:** If align_with_top is left out, it is treated as false and the element is aligned to the bottom. Pass `true` explicitly to align it with the top.
- SetAttribute(name, value)
  - Sets the value of the attribute named name to value.
- SetClass(name, value)
  - Sets (if value is true) or clears (if value is false) the class name on the element.
- SetPseudoClass(name, value)
  - Sets (if value is true) or clears (if value is false) the pseudo-class name (such as `hover` or `checked`) on the element.
- attributes
  - The attributes on the element, indexed by name: `element.attributes["type"]` gives the value of the `type` attribute, or nil. `pairs()` gives each name and value. Read-only; use SetAttribute() and RemoveAttribute() to change attributes.
- child_nodes
  - The child nodes of the element, indexed from **0**. Negative or out-of-range indices return nil. It includes hidden children and text nodes, but not internal elements such as scrollbars. Read-only.
- class_name
  - The space-separated list of classes on the element.
- client_left
  - The distance between the left border edge and the left client edge of the element. Read-only.
- client_height
  - The height of the element’s client area. Read-only.
- client_top
  - The distance between the top border edge and the top client edge of the element. Read-only.
- client_width
  - The width of the element’s client area. Read-only.
- first_child
  - The first child of the element, or nil if the element has no children. Read-only.
- id
  - The ID of the element, or the empty string if the element has no ID.
- inner_rml
  - The element’s RML content.
- last_child
  - The last child of the element, or nil if the element has no children. Read-only.
- next_sibling
  - The element’s next sibling, or nil if it is the last sibling. Read-only.
- offset_height
  - The height of the element, excluding margins. Read-only.
- offset_left
  - The distance between the element’s offset parent’s left border edge and this element’s left border edge. Read-only.
- offset_parent
  - The element’s offset parent, or nil. Read only.
- offset_top
  - The distance between the element’s offset parent’s top border edge and this element’s top border edge. Read-only.
- offset_width
  - The width of the element, excluding margins. Read-only.
- owner_document
  - The document this element is part of, or nil. Read-only.
- parent_node
  - The element this element is directly parented to, or nil. Read-only.
- previous_sibling
  - The element’s previous sibling, or nil if it is the first sibling. Read-only.
- scroll_height
  - The height of this element’s content. This will be at least as high as the client height. Read-only.
- scroll_left
  - The offset between the left edge of this element’s client area and the left edge of the content area.
- scroll_top
  - The offset between the top edge of this element’s client area and the top edge of the content area.
- scroll_width
  - The width of this element’s content. This will be at least as wide as the client width. Read-only.
- style
  - An object used to access this element’s style information. Individual RCSS properties can be accessed by using the name of the property as a field on the object itself (ie, `element.style.width = "40px"`, or `element.style["font-size"]` for names with a hyphen). Values are strings. Reading gives the value in effect, assigning a string sets it on the element, and assigning nil removes it again.
- tag_name
  - The tag name used to instance this element. Read-only.

### Element.As

Element methods and properties return plain elements. To reach the members of a more specific type, cast the element with one of the functions in the `Element.As` table, named after the type:

```lua
local select_el = Element.As.ElementFormControlDataSelect(document:GetElementById("difficulty_cont").first_child)
```

Available: `Element.As.Document`, `ElementText`, `ElementForm`, `ElementFormControl`, `ElementFormControlInput`, `ElementFormControlSelect`, `ElementFormControlDataSelect`, `ElementFormControlTextArea`, `ElementTabSet`, `ElementDataGrid` and `ElementDataGridRow`. The cast doesn't check the element, and using an element cast to the wrong type can crash FSO.

## ElementText

### ElementText

- ElementText derives from Element. A text element is created through a Document object with `CreateTextNode()`. It has the following property:

- text
  - The raw text content of the text element in UTF-8 encoding. Read/write.

## Document

### Document

- Document derives from Element. Document has no constructor; it must be instantiated through a Context object instead, either by loading an external RML file or creating an empty document. It has the following methods and properties:

- PullToFront()
  - Pulls the document in front of other documents within its context with a similar z-index.
- PushToBack()
  - Pushes the document behind other documents within its context with a similar z-index.
- Show([flags])
  - Shows the document. flags is one of `DocumentFocus.NONE`, `DocumentFocus.FOCUS` or `DocumentFocus.MODAL`, and defaults to `DocumentFocus.FOCUS`. MODAL keeps the focus in this document, but also stops the librocket debugger from being used.
- Hide()
  - Hides the document.
- Close()
  - Hides and closes the document, destroying its contents.
- CreateElement(tag_name)
  - Instances and returns an element with a tag of tag_name.
- CreateTextNode(text)
  - Instances and returns a text element (ElementText) containing the string text.
- title
  - The title of the document, as initially set by the `<title>` tag in the document’s header.
- context
  - The context the document belongs to. Read-only.

## Event

### Event

- The Event class has no constructor; it is generated internally and passed to event handlers as the `event` parameter. It has the following methods and properties:

- StopPropagation()
  - Stops the propagation of the event through the event cycle, if allowed. Events dispatched from Lua with DispatchEvent() can't be stopped.
- current_element
  - The element the event has propagated to. Read-only.
- type
  - The string name of the event. Read-only.
- target_element
  - The element the event was originally targeted at. Read-only.
- parameters
  - The parameters of the event, indexed by name (for example `event.parameters.mouse_x`). `pairs()` gives each name and value; it can't be indexed by number. Flags such as `ctrl_key` are the numbers 1 and 0. Read-only.
  - **Known issue:** The `data` parameter of `textinput` events is always nil, and the `drag_element` parameter of drag events is a raw pointer that can't be used as an element.

## Context

### Context

- The Context class has no constructor; it must be instantiated through the CreateContext() function. A context only receives input once it has been passed to `ui.enableInput()`. It has the following methods and properties:

- AddEventListener(event, listener [, element [, in_capture_phase]])
  - Adds listener, a Lua function or a string of inline code, as an event listener. If element is given, the listener is attached to that element and runs as if it had been added with element:AddEventListener().
  - **Known issue:** Without an element, the listener is attached to the context's root element and FSO crashes when it fires. Always pass an element.
- AddMouseCursor(cursor_document)
  - Adds a cursor document loaded by another context into this context. Returns nothing.
- CreateDocument([tag])
  - Creates and returns a new document with the tag name of tag. tag defaults to `"body"`.
- LoadDocument(document_path)
  - Attempts to load a document from the RML file found at document_path. Returns the document, or nil if it could not be loaded. The document is hidden until Show() is called.
- LoadMouseCursor(cursor_document_path)
  - Attempts to load a document from the RML file found at cursor_document_path as a cursor. Returns the cursor’s document, or nil.
- Render()
  - Renders the context. Returns true on success.
- ShowMouseCursor(show)
  - If show is true, this shows the mouse cursor, otherwise hides it.
- UnloadAllDocuments()
  - Closes all documents currently loaded with the context.
- UnloadAllMouseCursors()
  - Unloads all cursors currently loaded with the context.
- UnloadDocument(document)
  - Unloads a specific document within the context.
- UnloadMouseCursor(cursor_name)
  - Unloads a specific cursor by name.
- Update()
  - Updates the context. Returns true on success.
- dimensions
  - The dimensions of the context, as a Vector2i. To change them, assign a new Vector2i (`context.dimensions = Vector2i.new(w, h)`); changing `context.dimensions.x` directly does not update the layout.
- documents
  - The documents within the context. Index it by the id of a document's `<body>` (`context.documents["main_background"]` or `context.documents.main_background`), or by number starting from **0**. `pairs()` gives each id and document, `ipairs()` each 0-based index and document. Read-only.
- focus_element
  - Returns the leaf of the context’s focus tree. Read-only.
- hover_element
  - Returns the element under the context’s cursor. Read-only.
- name
  - The name of the context, specified at construction. Read-only.
- root_element
  - Returns the context’s root element. Read-only.

## ElementForm

### ElementForm

- ElementForm derives from Element. The form element has the following method:

- Submit([name [, value]])
  - Submits the form. name and value, which default to empty strings, are passed on as the name and value of the submit control.

## ElementFormControl

### ElementFormControl

- ElementFormControl derives from Element. It is the base of all form controls, and has the following properties:

- disabled
  - The disabled status of the control, either true or false.
- name
  - The name of the control, initial set with the “name” attribute.
- value
  - The current value of the control, as a string.

## ElementFormControlSelect

### ElementFormControlSelect

- ElementFormControlSelect derives from ElementFormControl. The control has the following methods and properties:

- Add(rml, value [, before])
  - Adds a new option to the select box. The new option has the string value of value and is represented by the elements created by the RML string rml. The new option will be inserted before the option with the **0-based** index before; if this is out of bounds (the default), then the new option will be appended onto the list. The 0-based index of the new option will be returned.
- Remove(index)
  - Removes the option with the **0-based** index from the selection box.
- options
  - The options available in the select box, indexed from **0**. Each entry is a table with the fields value, the string value of the option, and element, the root of the element hierarchy that represents the option in the list. Loop over it with `ipairs()` or `pairs()`, which give the 0-based index and the entry.
  - **Known issue:** Indexing `options` past the last option crashes FSO. Only index options you know exist, or loop over them with `ipairs()`.
- selection
  - The index of the currently selected option, **1-based**, or -1 if nothing is selected. Assigning 0 or a negative number clears the selection.

Note that `selection` counts from 1 while `options`, `Add()` and `Remove()` count from 0. The selected option is `options[select_el.selection - 1]`.

## ElementFormControlDataSelect

### ElementFormControlDataSelect

- ElementFormControlDataSelect derives from ElementFormControlSelect. It has the following additional method:

- SetDataSource(data_source_name)
  - Sets the data source and table to be used by the select box, in the form `"source.table"`.

## ElementFormControlInput

### ElementFormControlInput

- ElementFormControlInput derives from ElementFormControl. The control has the following properties, only appropriate on the relevant types:

- checked
  - Relevant for radio and checkbox types. The checked status of the input, either true or false.
- maxlength
  - Relevant for text types. The maximum number of characters permitted in the text field, or -1 for no limit.
- size
  - Relevant for text types. The approximate number of characters the text field shows horizontally at once.
- max
  - Relevant for range types. The value of the control on the bottom / right of the slider. An integer.
- min
  - Relevant for range types. The value of the control on the top / left of the slider. An integer.
- step
  - Relevant for range types. The step the control’s value changes in. An integer.

## ElementFormControlTextArea

### ElementFormControlTextArea

- ElementFormControlTextArea derives from ElementFormControl. The control has the following properties:

- cols
  - The approximate number of characters the text area shows horizontally at once.
- maxlength
  - The maximum number of characters permitted in the text area.
- rows
  - The number of lines the text area shows at once.
- wordwrap
  - true if lines are split to fit into the text area, false if not.

## ElementTabSet

### ElementTabSet

- ElementTabSet derives from Element. Tab and panel indices are **0-based**. The control has the following methods and properties:

- SetPanel(index, rml)
  - Sets the contents of a panel to the RML content rml. If index is out-of-bounds, a new panel will be added at the end.
- SetTab(index, rml)
  - Sets the contents of a tab to the RML content rml. If index is out-of-bounds, a new tab will be added at the end.
- active_tab
  - Index of the active panel. Read/write.
- num_tabs
  - The number of tabs in the tab set. Read-only.

## ElementDataGrid

### ElementDataGrid

- ElementDataGrid derives from Element. The data grid has the following methods and properties:

- AddColumn(fields, formatter, initial_width, header_rml)
  - Adds a new column to the data grid. The column will read the columns fields (in CSV format) from the grid’s data source, processing it through the data formatter named formatter (pass `""` for none). header_rml specifies the RML content of the column’s header. All four arguments are required.
- SetDataSource(data_source_name)
  - Sets the data source and table to be used by the data grid, in the form `"source.table"`.
- rows
  - Returns a Lua table containing all the rows in the data grid. The first row is at index **0**, so `ipairs()` skips it. Use `pairs()`, or count from 0 until you reach nil: `local i = 0; while rows[i] do ... i = i + 1 end`.

## ElementDataGridRow

### ElementDataGridRow

- ElementDataGridRow derives from Element. The data grid row has the following properties:

- row_expanded
  - The expanded state of the row, either true or false. Read/write.
- parent_relative_index
  - The **0-based** index of the row, relative to its parent row. So if you are the third row in your parent, then it will be 2.
- table_relative_index
  - The **0-based** index of the row, relative to the data grid it is in. This takes into account all previous rows and their children.
- parent_row
  - The parent row of this row. For a top-level row this is the grid's hidden root row, not nil.
- parent_grid
  - The data grid that this row belongs to.
