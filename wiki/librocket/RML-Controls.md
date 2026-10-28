# RML Controls

Controls are used to allow dragging and tabbing elements.

## `<handle>`

The `<handle>` element can be used to move or change the size of elements. Dragging the handle moves or resizes its targets.

### Attributes

#### move_target

If specified, the handle will move the element with this ID when dragged. The ID is written without a `#`. Three special values are also accepted: `#document` (the handle's document), `#parent` (the handle's parent element) and `#self` (the handle itself).

The handle moves its target by setting the target's `left` and `top` properties, so the target needs a `position` that uses them (such as `absolute` or `relative`).

#### size_target

If specified, the handle will size the element with this ID when dragged. Accepts the same special values as `move_target`.

```html
<handle move_target="#document">
	<div id="title">My document</div>
</handle>
```

A handle always has `drag: drag` (set on the element itself, so RCSS can't change it). While dragging, it sends a `handledrag` event; see [Events](RML-Events#handle-events).

## `<tabset>`

A `<tabset>` element contains `<tab>` elements and `<panel>` elements.

```html
<tabset id="ops_tabs_cont">
	<tab id="basic_btn" class="button_1 tab">
		<span class="button_text">XSTR("Basic", 888153)</span>
	</tab>
	<panel class="options_panel">
		<include src="options_basic_tab.rml"/>
	</panel>
	<tab id="misc_btn" class="button_1 tab">
		<span class="button_text">XSTR("Misc", 888040)</span>
	</tab>
	<panel class="options_panel">
		<include src="options_misc_tab.rml"/>
	</panel>
</tabset>
```

Tabs and panels are paired by order: the first `<tab>` shows the first `<panel>`, the second the second, and so on. They can be written in any order (all the tabs first, or each tab next to its panel, as above). libRocket moves all the tabs into a `<tabs>` element and all the panels into a `<panels>` element inside the tabset, which you can style with `tabset tabs` and `tabset panels`.

The first tab is active when the document loads.

### `<tab>`

Each `<tab>` element acts as a button, that when clicked will hide the currently visible panel and show its corresponding panel. The active tab has the `:selected` pseudo-class:

```css
#basic_btn:selected #basic_img { ... }
```

Tabs are given `display: inline-block` on the element itself, so RCSS can't change their `display`.

### `<panel>`

A `<panel>` element is the body of the tabset. The visibility of the panel is controlled by the tab elements in the parent tabset.

The tabset shows and hides panels by setting `display` (`inline-block` for the active panel, `none` for the others) on the panel itself. RCSS can't override this, so don't try to style a panel's `display`; wrap its content in a `<div>` if you need a block.

When the active tab changes, the tabset sends a `tabchange` event; see [Events](RML-Events#tabset-events).

### Tabsets in Lua

Cast the element with `Element.As.ElementTabSet` to control it from Lua. Tab indexes here are 0-based.

```lua
local tabset = Element.As.ElementTabSet(document:GetElementById("ops_tabs_cont"))
tabset.active_tab = 2          -- show the third tab
local count = tabset.num_tabs
tabset:SetTab(-1, "New tab")   -- add a tab with this RML as its title
tabset:SetPanel(-1, "<p>New panel</p>")
```

> **Known issue:** `SetTab` and `SetPanel` with the index of an existing tab add a new tab or panel instead of replacing that one. Only use them to add (index -1); to change an existing tab, change its contents directly, for example with `inner_rml`.
