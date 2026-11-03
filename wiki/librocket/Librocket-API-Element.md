# Librocket API Element

The LUA interface for libRocket elements closely resembles Gecko’s HTML DOM element interface.

Methods are called with `:` (`element:Focus()`). A call with `.` silently does nothing and returns nil.

## Properties

| libRocket property | Brief description | Equivalent DOM property |
|---|---|---|
| attributes | All attributes associated with an element. Read-only. | attributes |
| child_nodes | All child nodes of an element. Read-only. | childNodes |
| class_name | Gets/sets the class of the element. | className |
| client_height | The inner height of an element. Read-only. | clientHeight |
| client_left | The width of the left border of an element. Read-only. | clientLeft |
| client_top | The width of the top border of an element. Read-only. | clientTop |
| client_width | The inner width of an element. Read-only. | clientWidth |
| first_child | The first direct child node of an element, or nil. Read-only. | firstChild |
| id | Gets/sets the id of the element. | id |
| inner_rml | Gets/sets the markup and content of the element. | innerHTML |
| last_child | The last direct child node of an element, or nil. Read-only. | lastChild |
| next_sibling | The node immediately following the given one in the tree, or nil. Read-only. | nextSibling |
| offset_height | The height of an element, relative to the layout. Read-only. | offsetHeight |
| offset_left | The distance from this element’s left border to its offset parent’s left border. Read-only. | offsetLeft |
| offset_parent | The element from which all offset calculations are currently computed, or nil. Read-only. | offsetParent |
| offset_top | The distance from this element’s top border to its offset parent’s top border. Read-only. | offsetTop |
| offset_width | The width of an element, relative to the layout. Read-only. | offsetWidth |
| owner_document | The document that this node is in, or nil. Read-only. | ownerDocument |
| parent_node | The parent element of this node, or nil. Read-only. | parentNode |
| previous_sibling | The node immediately preceding the given one in the tree, or nil. Read-only. | previousSibling |
| scroll_height | The scroll view height of an element. Read-only. | scrollHeight |
| scroll_left | Gets/sets the left scroll offset of an element. | scrollLeft |
| scroll_top | Gets/sets the top scroll offset of an element. | scrollTop |
| scroll_width | The scroll view width of an element. Read-only. | scrollWidth |
| style | An object representing the declarations of an element’s style attributes. | style |
| tag_name | The name of the tag for the given element. Read-only. | tagName |

Writing to a read-only property, or to a property name that doesn't exist, is silently ignored.

### Array properties

#### child_nodes

`child_nodes` holds the element's children. It is indexed numerically and is **0-based**: the first child is `element.child_nodes[0]`. Negative indices return nil. The `#` operator does not work on it, so loop over it with `ipairs` or `pairs`, which give the 0-based index and the child.

The children include hidden ones (for example elements with `display: none`) and text nodes. Only librocket's internal elements, such as scrollbars, are left out.

The following example iterates over all of an element’s children, printing their tag names, ids and classes:

```lua
for _, child in ipairs(element.child_nodes) do
	local address = child.tag_name

	if child.id ~= "" then
		address = address .. "#" .. child.id
	end

	for class in string.gmatch(child.class_name, "%S+") do
		address = address .. "." .. class
	end

	ba.print(address .. "\n")
end
```

#### attributes

`attributes` maps attribute names to their values. Index it by name to read a value, or loop over it with `pairs`, which gives the name and the value. It can't be indexed by number, and the `#` operator does not work on it. To change attributes, use `SetAttribute()` and `RemoveAttribute()`.

The following example iterates over an element’s attributes, printing their names and values:

```lua
for name, value in pairs(element.attributes) do
	ba.print(name .. ": " .. tostring(value) .. "\n")
end
```

### The style property

The style property operates much like its counterpart in Javascript. Properties are accessed as members of the style property by name and can be read or written to. The value of a property is always an unparsed string in this context; ie, 200px, center, rgb(255,0,0), etc. Property names that contain a hyphen must be written with brackets, as in `element.style["font-size"]`.

- Reading a property returns the value currently in effect for the element (from the element itself, a style sheet, its parent or the default). It returns nil for a name that isn't a property, including shorthands such as `margin`; read the individual properties instead.
- Writing a string sets the property on the element itself, overriding the style sheet. An invalid value is silently ignored.
- Writing nil removes the property from the element, so the style sheet value applies again.
- `pairs(element.style)` loops over the properties set on the element and by style sheets, giving the name and value. The `#` operator does not work on it.

The following example demonstrates uses of the style property:

```lua
element.style.width = "150px"
if element.style.float ~= "none" then
	element.style.clear = "left"
end

-- go back to whatever the style sheet says
element.style.width = nil
```

## Methods

| libRocket methods | Brief description | Equivalent DOM method |
|---|---|---|
| AddEventListener(event, listener [, in_capture_phase]) | Register an event handler to a specific event type on the element. `listener` is a Lua function or a string of inline code. | addEventListener() |
| AppendChild(element) | Insert a node as the last child node of this element. | appendChild() |
| Blur() | Removes keyboard focus from the current element. | blur() |
| Click() | Simulates a click on the current element. | click() |
| Clone() | Returns a copy of this element, its attributes and its content. Listeners added with `AddEventListener()` are not copied. The copy is not part of the document until you add it. | cloneNode() |
| DispatchEvent(event, parameters) | Dispatch an event to this node in the DOM. | dispatchEvent() |
| Focus() | Gives keyboard focus to the current element. | focus() |
| GetAttribute(name) | Retrieve the value of the named attribute from the current node, or nil if it isn't set. | getAttribute() |
| GetElementById(id) | Returns the descendant element with the given id, or nil. | getElementById() |
| GetElementsByClassName(class_name) | Returns a table of all descendant elements with the given class. | getElementsByClassName() |
| GetElementsByTagName(tag_name) | Returns a table of all descendant elements with the given tag name. | getElementsByTagName() |
| HasAttribute(name) | Check if the element has the specified attribute, or not. | hasAttribute() |
| HasChildNodes() | Check if the element has any child nodes, or not. | hasChildNodes() |
| InsertBefore(element, adjacent_element) | Inserts `element` as a child of this element, directly before the child `adjacent_element`. | insertBefore() |
| IsClassSet(name) | Check if the element has the given class, or not. | classList.contains() |
| RemoveAttribute(name) | Remove the named attribute from the current node. | removeAttribute() |
| RemoveChild(element) | Removes a child node from the current element. Returns true if it was removed. | removeChild() |
| ReplaceChild(inserted_element, replaced_element) | Replaces one child node in the current element with another. Returns true if it was replaced. | replaceChild() |
| ScrollIntoView([align_with_top]) | Scrolls the page until the element gets into the view. | scrollIntoView() |
| SetAttribute(name, value) | Set the value of the named attribute on the current node. | setAttribute() |
| SetClass(name, value) | Adds (true) or removes (false) the given class on the element. | classList.toggle() |
| SetPseudoClass(name, value) | Sets (true) or clears (false) a pseudo-class, such as `hover` or `checked`, on the element. | |

`GetElementsByClassName()` and `GetElementsByTagName()` return ordinary Lua tables, indexed from **1** like any Lua list, so `#` and `ipairs` work on them as usual.

> **Known issue:** `ScrollIntoView()` with no argument aligns the element with the **bottom** of the view, not the top. Pass `true` to align it with the top: `element:ScrollIntoView(true)`.

## Element types

Element methods return plain elements. To use the extra properties and methods of a specific kind of element, such as a form control's `value`, cast it with the `Element.As` table:

```lua
local input = Element.As.ElementFormControlInput(document:GetElementById("pilot_name_input"))
ba.print(input.value .. "\n")
```

The available casts are `Element.As.Document`, `ElementText`, `ElementForm`, `ElementFormControl`, `ElementFormControlInput`, `ElementFormControlSelect`, `ElementFormControlDataSelect`, `ElementFormControlTextArea`, `ElementTabSet`, `ElementDataGrid` and `ElementDataGridRow`. Their members are listed in the [API Reference](Librocket-API-Reference).

The cast does not check the element. Casting an element to the wrong type (for example a `<div>` to `ElementFormControlInput`) and then using it can crash FSO, so only cast elements whose tag you know.

## Dispatching events

Events can be generated on an element from within Lua with the `DispatchEvent()` function. The parameters are given as a Lua table with string keys. Pass `{}` if there are no parameters.

```lua
element:DispatchEvent("open", { object = "trapdoor", priority = 11 })
```

Values can be strings, numbers or booleans. Tables and functions are ignored, and elements arrive in the listener as raw pointers that Lua can't use, so pass the element's id instead. Numbers arrive in the listener as floating-point, and booleans arrive as the numbers `1` and `0` (both of which are true in Lua, so compare with `== 1`).

Events dispatched from Lua can't be interrupted: calling `event:StopPropagation()` on them does nothing.

## Creating elements

Elements can be created dynamically in Lua using the document’s `CreateElement()` or `CreateTextNode()` method. The following code sample uses `CreateElement()` to dynamically create a form control.

```lua
local input_element = document:CreateElement("input")
input_element:SetAttribute("type", "radio")
input_element:SetAttribute("name", "graphics")
input_element:SetAttribute("value", "ok")
document:AppendChild(input_element)

local text_element = document:CreateTextNode("OK")
document:AppendChild(text_element)
```

Often it is simpler to build the markup as a string and assign it to a container's `inner_rml`.

`Element.new(tag)` also creates an element, but always a plain one, even for tags like `input` that normally make a control. Use the document's `CreateElement()` instead.
