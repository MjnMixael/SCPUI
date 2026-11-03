# RML Events

The event system is based on the extremely flexible DOM event system.

When an event is fired at a target element, it first travels down from the root to the target's parent (the capture phase), is then processed by the target itself, and finally travels back up from the target to the root (the bubble phase). Event listeners can be attached in either capture or bubble phase.

Binding done in RML will always attach to the bubble phase.

Every event bubbles, including ones such as `focus`, `resize` or `change` that don't bubble in HTML. A handler on a parent element (or on the `<body>`, which is the document) therefore also sees these events from all of its children. Check `event.target_element` if you only want the ones aimed at the element itself.

On the target element itself, bubble-phase listeners run before capture-phase listeners.

## RML binding

Event listeners can be bound to an element declared in RML by specifying an attribute with the name of the event to bind to prefixed with on. For example, to bind a listener to the click event, you would declare something like the following:

```html
<button onclick="controller:start_game()">Start Game</button>
```

Note that this is the only time you prefix the event name with on; all other times an event is referenced, it is done so simply with its name.

On `<body>`, the listeners are attached to the document, which is how SCPUI hooks screen-wide events:

```html
<body onload="controller:initialize(document)" onkeydown="controller:global_keydown(element, event)" onunload="controller:unload(); controller = nil">
```

## Events in Lua

Event listeners bound through RML execute Lua code. The attribute's value becomes the body of a Lua function that is called with three parameters:

- `event` - the [event](Librocket-API-Event) being processed. Its parameters are in `event.parameters`.
- `element` - the element that carries the `on*` attribute. This is not necessarily the element the event happened on; that is `event.target_element`.
- `document` - the [document](Librocket-API-Document) the element belongs to.

There is no `self`. Pass `element` and `event` on to your own functions, as SCPUI does. Multiple lines of Lua code can be put on one line, separated by a semicolon:

```html
<div onclick="ba.print('hello\n'); ba.print('goodbye\n')">
```

The code runs in the document's own Lua environment, so it can see globals set by the document's `<script>`, such as SCPUI's `controller`. See [Per-document environment](Librocket#per-document-environment).

Listeners can also be added from Lua with `AddEventListener`. A Lua function given to it is called with the same three parameters; `element` is the element the listener was added to:

```lua
element:AddEventListener("change", function(event, element, document)
	ba.print("New value: " .. tostring(event.parameters.value) .. "\n")
end)
```

`event:StopPropagation()` stops an event from reaching any further listeners. This only works for input events: the keyboard and mouse events, `textinput`, and the drag events other than `dragstart` and `drag`. For all other events, such as `change`, `load`, `focus`, `dragstart` or `tabchange`, it is ignored and the event carries on.

For full details on Lua events see [Lua API](Librocket#lua-api).

## Events

Below is a list of events and their associated event parameters. Parameters are read from `event.parameters`, for example `event.parameters.mouse_x`.

### Key modifiers

A number of input events send through key modifiers. In this case the following parameters are set to 1 if the key modifier is active when the action takes place, and 0 if it isn't:

- ctrl_key
- shift_key
- alt_key
- meta_key
- caps_lock_key
- num_lock_key
- scroll_lock_key

These are numbers, not booleans, and **0 is true in Lua**. Always compare with 1:

```lua
if event.parameters.shift_key == 1 then
	-- shift is held
end
```

### General Events

#### show

Sent to a document when it is made visible.

#### hide

Sent to a document when it is made invisible.

#### resize

Sent to an element when it resizes.

#### scroll

Sent to an element when it is scrolled.

#### scrollchange

Sent to a scrollbar (and from there bubbles to the element being scrolled) when the scrollbar's position changes.

- value: The new position, from 0 (top or left) to 1 (bottom or right).

#### focus

Sent to an element when it becomes the main focus. Its ancestors that weren't already in the focus chain receive it too.

#### blur

Sent to an element when it has focus removed. Its ancestors that are leaving the focus chain receive it too.

### Keyboard Events

#### keydown

Sent to the focus element when a key is pressed.

- key_identifier: A number identifying the key. Compare it with the values in `rocket.key_identifier`.
- Key modifiers: See above.

```lua
function Controller:global_keydown(element, event)
	if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
		event:StopPropagation()
		ba.postGameEvent(ba.GameEvents["GS_EVENT_PREVIOUS_STATE"])
	end
end
```

Key names in `rocket.key_identifier` follow libRocket's names: letters `A`-`Z`; digits `"0"`-`"9"` (use brackets: `rocket.key_identifier["1"]`); `F1`-`F24`; `RETURN`, `ESCAPE`, `SPACE`, `TAB`, `BACK` (backspace), `DELETE`, `INSERT`, `HOME`, `END`, `PRIOR` (page up), `NEXT` (page down); `UP`, `DOWN`, `LEFT`, `RIGHT`; `NUMPAD0`-`NUMPAD9`, `NUMPADENTER`, `ADD`, `SUBTRACT`, `MULTIPLY`, `DIVIDE`, `DECIMAL`; `LSHIFT`, `RSHIFT`, `LCONTROL`, `RCONTROL`, `LMENU`, `RMENU` (the Alt keys); and the punctuation keys `OEM_1` to `OEM_8`, `OEM_PLUS`, `OEM_COMMA`, `OEM_MINUS`, `OEM_PERIOD` and `OEM_102`. To see them all, loop over the table with `pairs(rocket.key_identifier)`.

#### keyup

Sent to the focus element when a key is released.

- key_identifier: As for keydown.
- Key modifiers: See above.

#### textinput

Sent to the focus element when a text character is entered.

- data: The character that was entered.

> **Known issue:** `data` is always nil in Lua, so the character can't be read from this event. To react to typing, use the text field's `change` event and read `event.parameters.value`, or use `keydown`.

### Mouse Events

All mouse events except mousescroll send through key modifiers. `mouse_x` and `mouse_y` are in pixels within the context.

FSO numbers the mouse buttons 0 for left, 1 for right, 2 for middle, and 3 and 4 for the two extra (X1/X2) buttons.

#### click

Sent when the left mouse button is clicked. A click is defined as a button press followed by a button release over the same element. Other buttons don't send click; use mousedown or mouseup for them.

The click is sent to the element under the cursor, or if that element has `focus: none`, to its nearest ancestor that can take focus. In a document with `focus: none`, no click events are sent at all. See [RCSS Cursors, Dragging and Tabbing](RCSS-CursorsDragTab).

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- button: The button that was clicked (always 0).

#### dblclick

Sent to the element under the mouse cursor when the left mouse button is double clicked (two presses on the same element within half a second).

dblclick is sent on the second button *press*, so it comes between two click events: mousedown, mouseup, click, mousedown, **dblclick**, mouseup, click. If you handle both click and dblclick on one element, the click handler runs twice.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- button: The button that was clicked (always 0).

#### mouseover

Sent to an element as the mouse cursor moves onto it.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.

It is sent to every element the cursor has entered, including ancestors that weren't hovered before, and like every event it then bubbles up. So a parent's `onmouseover` also runs when the cursor moves between its children. Check `event.target_element == element` to react only to the cursor entering the element itself.

#### mouseout

Sent to an element as the mouse cursor moves off it. Like mouseover, it is sent to every element the cursor has left, and bubbles.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.

#### mousemove

Sent to the element under the mouse cursor when the mouse is moved.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.

#### mouseup

Sent to the element under the mouse cursor when a mouse button is released.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- button: The button that was released.

#### mousedown

Sent to the element under the mouse cursor when a mouse button is pressed down.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- button: The button that was pressed.

#### mousescroll

Sent to the element under the mouse cursor when the mouse's scroll wheel is scrolled.

- wheel_delta: An integer value representing how far the wheel has been scrolled. In FSO, positive values mean the wheel was scrolled down (towards the user) and negative values up.
- Key modifiers: See above. There are no mouse position parameters.

### Dragging Events

An element can only be dragged if its RCSS `drag` property is set; see [RCSS Cursors, Dragging and Tabbing](RCSS-CursorsDragTab). All mouse drag events send through key modifiers.

#### dragstart

Sent to an element when it is first dragged, before the first drag event. `mouse_x` and `mouse_y` are where the mouse was when the drag began.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- drag_element: The element that is being dragged.

#### dragend

Sent to the dragged element when the mouse button is released.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- drag_element: The element that is being dragged.

#### drag

Sent to the dragged element when the mouse is moved.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- drag_element: The element that is being dragged.

The following events are only sent if the dragged element has a drag property of `drag-drop` or `clone`. They are sent to elements other than the dragged element, usually as the mouse moves across them.

#### dragover

Sent during a drag operation to an element when the mouse cursor is moved onto the element (similarly to the mouseover event).

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- drag_element: The element that is being dragged.

#### dragout

Sent during a drag operation to an element when the mouse cursor is moved off the element (similarly to the mouseout event).

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- drag_element: The element that is being dragged.

#### dragmove

Sent during a drag operation to the top-most element being hovered over (excluding the dragged element) when the mouse is moved.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- drag_element: The element that is being dragged.

#### dragdrop

Sent at the end of a drag operation to the element the cursor is hovering over.

- mouse_x: The mouse x position within the context.
- mouse_y: The mouse y position within the context.
- drag_element: The element that is being dragged.

> **Known issue:** `drag_element` can't be used from Lua; it arrives as a raw pointer, not an Element. In `dragstart`, `drag` and `dragend` the dragged element is the element receiving the event, so use the handler's `element` (or `event.target_element`). For `dragover`, `dragout`, `dragmove` and `dragdrop`, remember which element is being dragged in your `dragstart` handler. SCPUI's weapon select works this way:
>
> ```html
> <div id="primary_one" class="weapon_slot" ondragstart="controller:on_drag_start(element, 1)" ondragdrop="controller:on_drag_drop(element, 1)" ondragend="controller:drag_from_slot_to_slot_or_pool(element, 1)">
> ```

### Form Events

#### submit

Sent to the form when it is submitted. See [Forms](RML-Forms).

- parameters: `event.parameters` holds one entry for each named value in the form.

### Form Control Events

#### change

Sent to a form control when its value is changed.

- value: The new value.

What `value` holds depends on the control:

- **Text, password and textarea:** the full new text. change is sent on every edit, once per character typed or deleted, not only when editing finishes.
  - linebreak: 1 when the player pressed Enter in a single-line text field (the text itself didn't change), 0 otherwise. Compare with 1, as with key modifiers. SCPUI uses this to submit chat lines:

    ```lua
    function Controller:input_change(event)
    	if event.parameters.linebreak ~= 1 then
    		self.ChatValue = event.parameters.value
    	else
    		self:sendChat()
    	end
    end
    ```

- **Checkbox and radio:** the control's `value` attribute when it becomes checked, or an empty string when it becomes unchecked. Also sent when `checked` is changed from Lua. Give checkboxes a `value` (or read the cast element's `checked`), since a checkbox without one sends an empty string either way.
- **Select and dataselect:** the value of the newly selected option.
- **Range:** the slider position from 0 to 1, not a value between `min` and `max`.

### Document Events

#### load

Sent to a document when it is initially loaded. It comes after the document's scripts have run and before the document is first shown.

#### unload

Sent to a document when it is unloaded.

### Handle Events

#### handledrag

Sent to the handle when it is moved.

- handle_x: How far the handle has been dragged horizontally since the drag began, in pixels.
- handle_y: How far the handle has been dragged vertically since the drag began, in pixels.

### DataGrid Events

#### columnadd

Sent to the data grid when a column is added.

- index: Index of the column that was added.

#### rowupdate

Sent to the data grid when any rows in the table are loaded.

#### rowadd

Sent to the data grid when rows are added to the table.

- first_row_added: Index of the first row added.
- num_rows_added: The number of rows added after the first row.

#### rowremove

Sent to the data grid when rows are removed from the table.

- first_row_removed: Index of the first row removed.
- num_rows_removed: The number of rows removed after the first row.

#### rowchange

Sent to the data grid when rows in the table change.

- first_row_changed: Index of the first row changed.
- num_rows_changed: The number of rows changed.

### TabSet Events

#### tabchange

Sent to the tab set when the active tab is changed.

- tab_index: The new tab index (0 for the first tab).

## Event sounds

FSO can play an interface sound when an element receives certain events, set with an RCSS property named after the event with `-sound` on the end. The events that support this are `click`, `dblclick`, `mouseover`, `mouseout`, `mousedown`, `mouseup`, `mousescroll` and `scrollchange`.

```css
.button_1 {
	mouseover-sound: 17;
	click-sound: 0;
}
```

The value is an interface sound from `sounds.tbl`. It can also list sounds for named states, played from Lua with `ui.playElementSound(element, event, state)` instead of automatically:

```css
#commit_btn {
	click-sound: (error)10, (success)18;
}
```

```lua
ui.playElementSound(element, "click", "error")
```

`mouseover-sound` and `mouseout-sound` only play for the element the cursor actually entered or left. The other sounds also play for ancestors that have the property when the event bubbles up to them. `scrollchange-sound` doesn't restart until the previous sound has finished.
