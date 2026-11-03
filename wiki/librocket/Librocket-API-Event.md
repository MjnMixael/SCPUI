# Librocket API Event

When an event is sent to Lua, the handler is called with three parameters, in this order:

- `event` - The event object
- `element` - The element the handler is attached to (the element carrying the on* attribute, or the element `AddEventListener()` was called on). This is not necessarily the element the event happened on; use `event.target_element` for that.
- `document` - The document that element belongs to

These are function parameters, not global variables, and there is no `self`. Inline on* handlers can use the names directly; a function passed to `AddEventListener()` receives them as its arguments:

```html
<button id="accept_btn" onclick="controller:accept_pressed(element)">Accept</button>
```

```lua
document:GetElementById("accept_btn"):AddEventListener("click", function(event, element, document)
	ba.print("Clicked " .. element.id .. "\n")
end)
```

## Event Interface

### Properties

| Lua property | Brief description | Equivalent method |
|---|---|---|
| current_element | The current element in the event propagation. Read-only. | GetCurrentElement() |
| target_element | The element the event was originally targeted at. Read-only. | GetTargetElement() |
| type | The type of the event, such as `"click"`. Read-only. | GetType() |
| parameters | Dictionary style container of all the parameters in the event. Read-only. | GetParameters() |

`parameters` is indexed by parameter name, for example `event.parameters.key_identifier` or `event.parameters.mouse_x`. A parameter the event doesn't have returns nil. Loop over all of them with `pairs`; it can't be indexed by number, and `ipairs` and `#` don't work on it. The parameters each event provides are listed in [RML Events](RML-Events).

Flags such as `ctrl_key` and `shift_key` are the numbers `1` and `0`, not booleans. Both are true in Lua, so compare them with `== 1`:

```lua
function Controller:global_keydown(element, event)
	if event.parameters.key_identifier == rocket.key_identifier.ESCAPE then
		event:StopPropagation()
		-- close the screen
	elseif event.parameters.key_identifier == rocket.key_identifier.S and event.parameters.ctrl_key == 1 then
		-- Ctrl+S
	end
end
```

> **Known issue:** Two parameters don't reach Lua correctly. The `data` parameter of `textinput` events is always nil, so read the control's `value` in a `change` handler instead. The `drag_element` parameter of drag events is a raw pointer that can't be used as an element. To know which element is being dragged, store `event.target_element` in a `dragstart` handler and use that.

### Methods

Events have a single method, `StopPropagation()`, which interrupts the event propagation if allowed by the event (ie, if it is interruptible). Call it as `event:StopPropagation()`.

Events created from Lua with `DispatchEvent()` are never interruptible, so `StopPropagation()` does nothing on them.
