# RML DataDisplay

Data grids are a kind of table display.

SCPUI itself doesn't use data grids, so this element is not tested in FSO as thoroughly as the rest; the behaviour below is what libRocket's code does.

## `<datagrid>`

`<datagrid>` represents an element capable of fetching, positioning and rendering dynamic tabulated data. It gets its rows from a data source created in Lua, and each `<col>` defines one column.

```html
<datagrid id="score_grid" source="scores.pilots">
	<col fields="name" width="60%">Pilot</col>
	<col fields="kills" width="40%">Kills</col>
</datagrid>
```

### Attributes

#### source

The data source and table that the rows of the data grid will be fetched from, written `source_name.table_name`. The data source is created in Lua; see below.

### `<col>`

The `<col>` element represents a column in the datagrid. Each column displays information about each row in the data source in the form of one or more fields. The content of the `<col>` element is the column's header.

#### Attributes

##### fields

A comma-separated list of fields that this column will fetch from the data source about each row and display.

##### formatter

The name of the data formatter to use to turn the raw field information into RML. If not set (or the formatter can't be found) then the raw values are displayed, separated by commas.

##### width

The width (in px or %) of the column. The default is 100%, so set it on every column.

## Data sources and formatters in Lua

Data sources are created with `DataSource.new(name)`, the same way as for a `<dataselect>`; see [Forms](RML-Forms#data-sources-in-lua) for the full description. A short version for the grid above:

```lua
local pilots = { { name = "Alpha 1", kills = 12 }, { name = "Alpha 2", kills = 7 } }

scores_source = DataSource.new("scores")
scores_source.GetNumRows = function(table_name)
	return #pilots
end
scores_source.GetRow = function(table_name, index, columns)
	local row = {}
	for i, column in ipairs(columns) do
		row[i] = tostring(pilots[index][column] or "")
	end
	return row
end
```

After the data changes, tell the grid with `scores_source:NotifyRowChange("pilots")` (all rows), or with `NotifyRowAdd`, `NotifyRowRemove` and `NotifyRowChange` and a first row and count.

A data formatter turns a cell's raw fields into RML. Create one with `DataFormatter.new(name, function)` and use its name in the column's `formatter` attribute. The function receives a table of the raw field values and returns an RML string.

```lua
kills_formatter = DataFormatter.new("kills", function(raw)
	return "<span class='kills'>" .. raw[0] .. "</span>"
end)
```

```html
<col fields="kills" formatter="kills" width="40%">Kills</col>
```

The raw field table passed to a formatter is **0-based**: the first field is `raw[0]`, and `#raw` and `ipairs` miss it.

### Building the grid from Lua

Cast the element with `Element.As.ElementDataGrid` to set its source or add columns:

```lua
local grid = Element.As.ElementDataGrid(document:GetElementById("score_grid"))
grid:AddColumn("name", "", 60, "Pilot")   -- fields, formatter, width, header RML
grid:SetDataSource("scores.pilots")
```

The `width` argument of `AddColumn` is not applied to the layout; a column added from Lua gets the default width of 100%. Prefer `<col>` elements in the RML when you need column widths.

## Child rows

A row can have its own child rows, shown under it. If a row returns a value for the special field `#child_data_source` (another `source_name.table_name`), that table's rows become its children. The special fields `#depth` and `#num_children` can be used in a column's `fields` to get the row's depth in the tree and how many children it has, usually for a formatter to indent rows or show an expand button.

### `<datagridexpand>`

Put a `<datagridexpand>` element in a cell (typically from a formatter) to get a button that expands and collapses that row's children. It has the class `collapsed` or `expanded` to show its state.

## Events

Data grids send `columnadd`, `rowadd`, `rowremove`, `rowchange` and `rowupdate` events. See [Events](RML-Events#datagrid-events).
