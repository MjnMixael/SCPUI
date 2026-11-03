# RML Forms

A form is a collection of input elements inside a `<form>` element - when the form is "submitted", the value of each named input element inside it is passed to the form's `submit` event.

You don't need a `<form>` to use the controls. `<input>`, `<textarea>`, `<select>` and `<dataselect>` work anywhere in a document, and SCPUI never uses `<form>`: it reacts to each control's `change` event and reads values from Lua instead. A `<form>` is only needed for submit buttons and for grouping radio buttons.

## `<form>`

### Attributes

- onsubmit - Lua code to run when the form is submitted, like any other `on*` attribute (see [Events](RML-Events)). The values of the form's controls are in `event.parameters`, keyed by each control's `name`.

```html
<form onsubmit="controller:login(event)">
	<input type="text" name="callsign"/>
	<input type="password" name="password"/>
	<input type="submit" name="action" value="login">Log in</input>
</form>
```

```lua
function Controller:login(event)
	local callsign = event.parameters.callsign
	local action   = event.parameters.action -- "login"
end
```

What gets submitted:

- Every named control in the form that isn't disabled. Controls without a `name` are skipped.
- Checkboxes and radio buttons only if they are checked.
- The submit button that was clicked, under its `name` (or under `submit` if it has no name), with its `value`.
- If several controls share a name, their values are joined with `", "`.

### `<form>` Children

There are four elements that function as children to a `<form>` element: the `<input>`, `<textarea>`, `<select>` and `<dataselect>` elements. These have many common attributes which are listed below. Any specific attributes are listed afterwards under their own headings.

#### Attributes

##### name

The name of the input element. This is used to look up the element's value when the form is submitted. For types of radio it is used to group together radio buttons so that only one with the same name can be checked at once.

##### value

For types of text, password and range, this is used as the initial value of the element. For the radio and checkbox types this is used as the value that is submitted (and sent with `change`) if the input is checked. For `<option>` elements, this is the value that is submitted by the parent `<select>`, if it is the selected option.

##### disabled

If this attribute is set, then the input element is unable to be changed by user input, and it is left out when the form is submitted. Disabled controls have the `:disabled` pseudo-class for styling.

### Reading and setting values from Lua

Cast the element to its control type to get at its value and other properties. `element.value` on a plain element is not the control's value.

```lua
local input = Element.As.ElementFormControlInput(document:GetElementById("chat_input"))
local text = input.value
input.value = ""
```

The control's `change` event also carries the new value as `event.parameters.value`. See [Events](RML-Events#change).

## `<input>`

### Attributes

#### type

The type of the input field. Must be one of the types below. Without a `type` the input is a text field. The input also gets a class with the same name as its type (`text`, `range`, `checkbox` and so on), so `input.range` selects range inputs in RCSS.

> **Known issue:** changing an input's `type` from Lua works for every type except back to `text`; setting `type` to `text` on an input that is currently another type does nothing. Create a new input instead.

#### text

A one-line text-entry field.

#### password

Like text, but replaces the entered text with asterisks.

#### radio

A radio button.

#### checkbox

A checkbox.

#### range

A slider bar.

#### submit

A button for submitting the form. Clicking it submits the enclosing `<form>`; outside a form it does nothing.

#### button

A plain button. It does nothing by itself and isn't submitted with the form; use its `onclick`. A disabled button doesn't send `click` events.

### Text and Password types

#### size

For types of text and password, defines the length (in characters) of the element. The default is 20.

#### maxlength

For types of text and password, defines the maximum length (in characters) that the element will accept.

### Radio and Checkbox types

#### checked

For types of radio and checkbox, if this attribute is set then the element is "on". Checked inputs have the `:checked` pseudo-class.

From Lua, use the `checked` property of the cast element:

```lua
local box = Element.As.ElementFormControlInput(element)
if box.checked then ... end
```

Radio buttons are only grouped by `name` inside a `<form>`. Outside a form, checking one radio button doesn't uncheck the others; you have to do that yourself from Lua.

### Range type

#### min

For the range type, defines the value at the lowest (left or top) end of the slider. The default is 0.

#### max

For the range type, defines the value at the highest (right or bottom) end of the slider. The default is 100.

#### step

For the range type, defines the increment that the slider will move by. The default is 1.

#### orientation

For the range type, specifies if it is a vertical or horizontal slider. Values can be horizontal or vertical.

The `change` event of a range input reports the slider's *position* from 0 to 1 in `event.parameters.value`, not a value between `min` and `max`. Read the cast element's `value` if you need the actual value. SCPUI's sliders use `min="0" max="1"`, so the two are the same.

## `<textarea>`

### Attributes

#### cols

The width of the visible area of the textarea, as a number of columns of text. The default is 20.

#### rows

The height of the visible area of the textarea, as a number of text rows. The default is 2.

#### wrap

If set nowrap, the textarea will not wrap unbroken lines to a new row.

#### maxlength

The maximum length (in characters) that the element will accept.

## `<select>`

`<select>` is a drop-down list of `<option>` elements. It has no additional attributes.

```html
<select id="difficulty" onchange="controller:difficulty_changed(event)">
	<option value="easy">Easy</option>
	<option value="medium" selected>Medium</option>
	<option value="hard">Hard</option>
</select>
```

From Lua, cast it with `Element.As.ElementFormControlSelect`. Note the mixed indexing: `selection` is 1-based (and -1 when nothing is selected), but `options[]` is 0-based, so the selected option is `options[selection - 1]`:

```lua
local select_el = Element.As.ElementFormControlSelect(element)
local option = select_el.options[select_el.selection - 1]
```

## `<option>`

### Attributes

#### selected

If set, then the option is selected when the `<select>` element is first loaded.

#### unselectable

If set, then the option is not selectable by the user. Useful for labelling groups of options.

## `<dataselect>`

A `<dataselect>` is a `<select>` whose options come from a data source instead of `<option>` elements. SCPUI uses it for the drop-downs in the options screen.

### Attributes

#### source

The data source and table to read the options from, written `source_name.table_name`. The source must exist when the dataselect is first updated; you can also set it later from Lua with `SetDataSource`.

#### fields

A comma-separated list of fields to fetch from the data source and to display for each option (or optionally to be sent through the data formatter). Without a formatter, only the first field is shown.

#### valuefield

The field from the data source to use as the option's value. If not set, then the first field in the fields attribute is used.

#### formatter

The name of the data formatter to use to process the raw fields information into RML. If not set, then the first field is displayed as raw text.

### Data sources in Lua

Data sources and formatters are created in Lua with `DataSource.new` and `DataFormatter.new`. A data source needs two functions: `GetNumRows(table_name)` returns the number of rows, and `GetRow(table_name, index, columns)` returns a table of strings, one per requested column, in the same order. `index` is 1-based.

This is how SCPUI's options screen feeds its drop-downs:

```html
<dataselect class="dropdown_dataselect_el" fields="display" valuefield="serialized"></dataselect>
```

```lua
local values = { { Display = "Low", Serialized = "0" }, { Display = "High", Serialized = "1" } }

local source = DataSource.new("Graphics_Detail")
source.GetNumRows = function(table_name)
	return #values
end
source.GetRow = function(table_name, index, columns)
	local val = values[index]
	local out = {}
	for _, column in ipairs(columns) do
		if column == "serialized" then
			table.insert(out, val.Serialized)
		elseif column == "display" then
			table.insert(out, val.Display)
		else
			table.insert(out, "")
		end
	end
	return out
end

local select_el = Element.As.ElementFormControlDataSelect(element)
select_el:SetDataSource("Graphics_Detail.Default")
```

The table name ("Default" here) is passed to your functions; a single-table source can ignore it. When the data changes, call `source:NotifyRowChange("Default")` and the dataselect rebuilds its options. Keep a reference to the data source for as long as it is in use.

See [Data Display](RML-DataDisplay) for data formatters.
