# RCSS CursorsDragTab

## Cursors: the ‘cursor’ property

- cursor

| | |
|---|---|
| Value: | &lt;string&gt; \| auto |
| Initial: | auto |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | N/A |

This property defines the cursor to display while the mouse is hovering over the element. Values have the following meanings:

- auto
  - The default cursor is used.
- &lt;string&gt;
  - The RML document loaded as a cursor and with &lt;string&gt; as a title is used as a cursor. If none exists, the default cursor is used.

Cursor documents are loaded from Lua with `context:LoadMouseCursor(path)`.

Note that FSO draws its own mouse cursor, and libRocket cursor documents are untested in FSO; SCPUI doesn't use them.

## Drag & drop: the ‘drag’ property

The drag property is a new property, not shared by CSS. It controls the generation of events as the mouse cursor begins a drag over an element (ie, clicks the left mouse button and moves the mouse), drags over elements (moves the mouse with the button depressed) and finishes a drag, or ‘drops’, an element over another. The events themselves are described in [RML Events](RML-Events).

- drag

| | |
|---|---|
| Value: | none \| drag \| drag-drop \| clone \| block |
| Initial: | none |
| Applies to: | all elements |
| Inherited: | no |
| Percentages: | N/A |

Values have the following meanings:

- none
  - If the mouse begins a drag over this element, the element is not dragged and does not generate any drag messages. However, it does not prevent an ancestor element from being dragged.
- drag
  - If the mouse begins a drag over this element, the element will begin spawning drag messages. However, no messages will be directed to other elements relating to the drag or the eventual drop.
- drag-drop
  - If the mouse begins a drag over this element, the element will begin spawning drag messages. Messages will also be directed to over elements if the dragged element is dragged over them.
- clone
  - As drag-drop, and in addition a copy of the element is attached to the mouse cursor for the duration of the drag, so the player can see what they are dragging. The original element stays where it is.
- block
  - If the mouse begins a drag over this element, the element is not dragged and neither is any ancestor element.

The element itself never moves during a drag; if you want it to, move it from Lua in the drag event handlers, or use `clone`.

SCPUI uses `clone` for its draggable ship and weapon icons (the `.drag` class in `common.rcss`). About the clone:

- It is a copy of the element as it was when the drag started, positioned so that it keeps the same offset from the mouse pointer.
- It has the `:drag` pseudo-class set, so you can style it differently from the original, e.g. `div:drag { ... }` as SCPUI's `ship_select.rcss` does.
- It lives in a separate document attached to the cursor, not under the original element's parents. It uses the same style sheet, but rules that depend on the original's ancestors (such as `#ship_list .icon`) no longer match it. Style it with selectors that match the element on its own.
- It is removed when the drag ends.

## Tab index: the ‘tab-index’ property

The ‘tab-index’ property is introduced for RCSS. It controls the generation of a tab order, which is an ordered list of elements within a document that gain input focus in turn as the ‘tab’ key is pressed.

- tab-index

| | |
|---|---|
| Value: | none \| auto |
| Initial: | none |
| Applies to: | all elements |
| Inherited: | no |
| Percentages: | N/A |

Values have the following meanings:

- none
  - The element is not part of the tabbing order.
- auto
  - The element inserts itself into the tabbing order in a location relative to its order in the element hierarchy.

Shift+Tab moves through the order backwards. Pressing Enter while an element with `tab-index: auto` has focus clicks it.

## Focus: the ‘focus’ property

The ‘focus’ property is introduced for RCSS. It controls whether an element can receive input focus.

- focus

| | |
|---|---|
| Value: | none \| auto |
| Initial: | auto |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | N/A |

Values have the following meanings:

- auto
  - The element can receive focus, for example when it is clicked.
- none
  - The element can't receive focus. When it is clicked, focus goes to its nearest ancestor that can take focus instead. If a document has `focus: none`, nothing in it takes focus when clicked.

Because the property is inherited, setting `focus: none` on an element also applies to everything inside it unless a descendant sets `focus: auto` again.
