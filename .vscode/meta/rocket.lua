--- libRocket Meta File
--- Comprehensive Definitions for Lua Integration
---@meta

--- Main libRocket Module
--- @class Rocket
--- @field CreateContext fun(self: self, name: string, dimensions: Vector2i): Context|nil Creates and returns a new context.
--- @field LoadFontFace fun(self: self, font_path: string): boolean Loads a font face.
--- @field RegisterTag fun(self: self, tag_name: string, class_definition: any) Registers a class for a custom XML tag.
--- @field Log fun(self: self, type: RocketLog, message: string) Sends a log message to libRocket.
rocket = {}
rocket.logtype = {}
rocket.logtype.always = RocketLog
rocket.logtype.error = RocketLog
rocket.logtype.warning = RocketLog
rocket.logtype.info = RocketLog
rocket.logtype.debug = RocketLog

--- Log types in libRocket.
--- @class RocketLog
RocketLog = {}

rocket.key_identifier = {}

--- Keys detectible by libRocket
--- @class RocketKey
RocketKey = nil

rocket.key_identifier.A = RocketKey                -- Alphabet key 'A'
rocket.key_identifier.B = RocketKey                -- Alphabet key 'B'
rocket.key_identifier.C = RocketKey                -- Alphabet key 'C'
rocket.key_identifier.D = RocketKey                -- Alphabet key 'D'
rocket.key_identifier.E = RocketKey                -- Alphabet key 'E'
rocket.key_identifier.F = RocketKey                -- Alphabet key 'F'
rocket.key_identifier.G = RocketKey                -- Alphabet key 'G'
rocket.key_identifier.H = RocketKey                -- Alphabet key 'H'
rocket.key_identifier.I = RocketKey                -- Alphabet key 'I'
rocket.key_identifier.J = RocketKey                -- Alphabet key 'J'
rocket.key_identifier.K = RocketKey                -- Alphabet key 'K'
rocket.key_identifier.L = RocketKey                -- Alphabet key 'L'
rocket.key_identifier.M = RocketKey                -- Alphabet key 'M'
rocket.key_identifier.N = RocketKey                -- Alphabet key 'N'
rocket.key_identifier.O = RocketKey                -- Alphabet key 'O'
rocket.key_identifier.P = RocketKey                -- Alphabet key 'P'
rocket.key_identifier.Q = RocketKey                -- Alphabet key 'Q'
rocket.key_identifier.R = RocketKey                -- Alphabet key 'R'
rocket.key_identifier.S = RocketKey                -- Alphabet key 'S'
rocket.key_identifier.T = RocketKey                -- Alphabet key 'T'
rocket.key_identifier.U = RocketKey                -- Alphabet key 'U'
rocket.key_identifier.V = RocketKey                -- Alphabet key 'V'
rocket.key_identifier.W = RocketKey                -- Alphabet key 'W'
rocket.key_identifier.X = RocketKey                -- Alphabet key 'X'
rocket.key_identifier.Y = RocketKey                -- Alphabet key 'Y'
rocket.key_identifier.Z = RocketKey                -- Alphabet key 'Z'
rocket.key_identifier["0"] = RocketKey             -- Number key '0'
rocket.key_identifier["1"] = RocketKey             -- Number key '1'
rocket.key_identifier["2"] = RocketKey             -- Number key '2'
rocket.key_identifier["3"] = RocketKey             -- Number key '3'
rocket.key_identifier["4"] = RocketKey             -- Number key '4'
rocket.key_identifier["5"] = RocketKey             -- Number key '5'
rocket.key_identifier["6"] = RocketKey             -- Number key '6'
rocket.key_identifier["7"] = RocketKey             -- Number key '7'
rocket.key_identifier["8"] = RocketKey             -- Number key '8'
rocket.key_identifier["9"] = RocketKey             -- Number key '9'
rocket.key_identifier.NUMPAD0 = RocketKey          -- Numpad key '0'
rocket.key_identifier.NUMPAD1 = RocketKey          -- Numpad key '1'
rocket.key_identifier.NUMPAD2 = RocketKey          -- Numpad key '2'
rocket.key_identifier.NUMPAD3 = RocketKey          -- Numpad key '3'
rocket.key_identifier.NUMPAD4 = RocketKey          -- Numpad key '4'
rocket.key_identifier.NUMPAD5 = RocketKey          -- Numpad key '5'
rocket.key_identifier.NUMPAD6 = RocketKey          -- Numpad key '6'
rocket.key_identifier.NUMPAD7 = RocketKey          -- Numpad key '7'
rocket.key_identifier.NUMPAD8 = RocketKey          -- Numpad key '8'
rocket.key_identifier.NUMPAD9 = RocketKey          -- Numpad key '9'
rocket.key_identifier.NUMPADENTER = RocketKey      -- Numpad Enter key
rocket.key_identifier.ADD = RocketKey              -- Numpad '+' key
rocket.key_identifier.SUBTRACT = RocketKey         -- Numpad '-' key
rocket.key_identifier.MULTIPLY = RocketKey         -- Numpad '*' key
rocket.key_identifier.DIVIDE = RocketKey           -- Numpad '/' key
rocket.key_identifier.DECIMAL = RocketKey          -- Numpad '.' key
rocket.key_identifier.LEFT = RocketKey             -- Left arrow key
rocket.key_identifier.RIGHT = RocketKey            -- Right arrow key
rocket.key_identifier.UP = RocketKey               -- Up arrow key
rocket.key_identifier.DOWN = RocketKey             -- Down arrow key
rocket.key_identifier.F1 = RocketKey               -- Function key 'F1'
rocket.key_identifier.F2 = RocketKey               -- Function key 'F2'
rocket.key_identifier.F3 = RocketKey               -- Function key 'F3'
rocket.key_identifier.F4 = RocketKey               -- Function key 'F4'
rocket.key_identifier.F5 = RocketKey               -- Function key 'F5'
rocket.key_identifier.F6 = RocketKey               -- Function key 'F6'
rocket.key_identifier.F7 = RocketKey               -- Function key 'F7'
rocket.key_identifier.F8 = RocketKey               -- Function key 'F8'
rocket.key_identifier.F9 = RocketKey               -- Function key 'F9'
rocket.key_identifier.F10 = RocketKey              -- Function key 'F10'
rocket.key_identifier.F11 = RocketKey              -- Function key 'F11'
rocket.key_identifier.F12 = RocketKey              -- Function key 'F12'
rocket.key_identifier.F13 = RocketKey              -- Function key 'F13'
rocket.key_identifier.F14 = RocketKey              -- Function key 'F14'
rocket.key_identifier.F15 = RocketKey              -- Function key 'F15'
rocket.key_identifier.LCONTROL = RocketKey         -- Left Control key
rocket.key_identifier.RCONTROL = RocketKey         -- Right Control key
rocket.key_identifier.LSHIFT = RocketKey           -- Left Shift key
rocket.key_identifier.RSHIFT = RocketKey           -- Right Shift key
rocket.key_identifier.LMETA = RocketKey            -- Left Meta key (often Left Alt key)
rocket.key_identifier.RMETA = RocketKey            -- Right Meta key (often Right Alt key)
rocket.key_identifier.ESCAPE = RocketKey           -- Escape key
rocket.key_identifier.CAPITAL = RocketKey          -- Caps Lock key
rocket.key_identifier.TAB = RocketKey              -- Tab key
rocket.key_identifier.BACK = RocketKey             -- Backspace key
rocket.key_identifier.RETURN = RocketKey           -- Enter/Return key
rocket.key_identifier.SPACE = RocketKey            -- Spacebar key
rocket.key_identifier.INSERT = RocketKey           -- Insert key
rocket.key_identifier.DELETE = RocketKey           -- Delete key
rocket.key_identifier.HOME = RocketKey             -- Home key
rocket.key_identifier.END = RocketKey              -- End key
rocket.key_identifier.PRIOR = RocketKey            -- Page Up key
rocket.key_identifier.NEXT = RocketKey             -- Page Down key
rocket.key_identifier.PAUSE = RocketKey            -- Pause/Break key
rocket.key_identifier.OEM_MINUS = RocketKey        -- '-' key (Minus)
rocket.key_identifier.OEM_PLUS = RocketKey         -- '=' key (Plus)
rocket.key_identifier.OEM_4 = RocketKey            -- '[' key (Left Bracket)
rocket.key_identifier.OEM_6 = RocketKey            -- ']' key (Right Bracket)
rocket.key_identifier.OEM_5 = RocketKey            -- '\\' key (Backslash)
rocket.key_identifier.OEM_1 = RocketKey            -- ';' key (Semicolon)
rocket.key_identifier.OEM_7 = RocketKey            -- '\'' key (Apostrophe/Single Quote)
rocket.key_identifier.OEM_COMMA = RocketKey        -- ',' key (Comma)
rocket.key_identifier.OEM_PERIOD = RocketKey       -- '.' key (Period)
rocket.key_identifier.OEM_2 = RocketKey            -- '/' key (Forward Slash)

--- A dictionary of active libRocket contexts.
---@type table<string|number, Context>
rocket.contexts = {}

--- Vector2i Class
Vector2i = {}
---@class Vector2i
---@field x? integer
---@field y? integer
---@field new fun(x: integer, y: integer): Vector2i Constructs a 2D integer vector.

--- Vector2f Class
Vector2f = {}
---@class Vector2f
---@field x? number
---@field y? number
---@field new fun(x: number, y: number): Vector2f Constructs a 2D floating-point vector.

--- Colourb Class
Colourb = {}
---@class Colourb
---@field red integer
---@field green integer
---@field blue integer
---@field alpha integer
---@field new fun(red: integer, green: integer, blue: integer, alpha: integer): Colourb Constructs a color with four channels.

--- DataSource Class
DataSource = {}
---@class DataSource
---@field new fun(name: string): DataSource Creates a new data source.
---@field GetNumRows fun(self: self, table_name: string): integer Returns the number of rows in a table.
---@field GetRow fun(self: self, table_name: string, index: integer, columns: table<string>): table<string> Returns column values as strings.
---@field NotifyRowAdd fun(self: self, table_name: string, first_row_added: integer, num_rows_added: integer) Notifies listeners about added rows.
---@field NotifyRowRemove fun(self: self, table_name: string, first_row_removed: integer, num_rows_removed: integer) Notifies listeners about removed rows.
---@field NotifyRowChange fun(self: self, table_name: string) Notifies listeners about changed rows.
---@field NotifyRowChange fun(self: self, table_name: string, first_row_changed: integer, num_rows_changed: integer) Notifies listeners about changed rows.

--- Element Class
Element = {}
---@class Element
---@field id string The ID of the element, or the empty string if the element has no ID.
---@field attributes table<string, any> The array of attributes on the element. Each element has the read-only properties name and value. Read-only.
---@field child_nodes table<number, Element> The array of child nodes on the element. Read-only.
---@field class_name string The space-separated list of classes on the element.
---@field client_left number The element's left offset from its client area.
---@field client_height number The element's height of its client area.
---@field client_top number The element's top offset from its client area.
---@field client_width number The element's width of its client area.
---@field first_child Element The first child node of the element. Read-only.
---@field inner_rml string The inner RML of the element.
---@field last_child Element The last child node of the element. Read-only.
---@field maxlength number The maximum number of characters allowed in a text field.
---@field next_sibling Element The next sibling node of the element. Read-only.
---@field offset_height number The element's height.
---@field offset_left number The element's left offset.
---@field offset_parent Element The element's offset parent.
---@field offset_top number The element's top offset.
---@field offset_width number The element's width.
---@field owner_document Document The document containing the element. Read-only.
---@field parent_node Element The parent node of the element.
---@field previous_sibling Element The previous sibling node of the element. Read-only.
---@field scroll_height number The element's scroll height.
---@field scroll_left number The element's scroll left.
---@field scroll_top number The element's scroll top.
---@field scroll_width number The element's scroll width.
---@field style table<string, string> An object used to access this element’s style information. Individual RCSS properties can be accessed by using the name of the property as a Python property on the object itself (ie, element.style.width = “40px”).
---@field tag_name string The tag name of the element.
---@field type string The input type for a text field.
---@field AddEventListener addEventListener Adds an event listener to this element.
---@field AppendChild fun(self: self, element: Element) Appends a child to this element.
---@field Blur fun(self: self) Removes input focus from this element.
---@field Click fun(self: self) Fakes a click on this element.
---@field DispatchEvent fun(self: self, event: string, parameters: table<string, any>, interruptible: boolean) Dispatches an event to this element.
---@field Focus fun(self: self) Focuses this element.
---@field Clone fun(): Element Clones the element.
---@field GetAttribute fun(self: self, name: string): any Gets an attribute by name.
---@field GetElementById fun(self: self, id: string): Element Gets an element by ID.
---@field GetElementsByClassName fun(self: self, class_name: string): Element[] Gets elements by class name.
---@field GetElementsByTagName fun(self: self, tag_name: string): table<number, Element> Gets elements by tag name.
---@field HasAttribute fun(self: self, name: string): boolean Checks if an attribute exists.
---@field HasChildNodes fun(self: self): boolean Checks if the element has child nodes.
---@field InsertBefore fun(self: self, new_element: Element, reference_element: Element) Inserts a new element before a reference element.
---@field IsClassSet fun(self: self, class_name: string): boolean Checks if a class is set on the element.
---@field RemoveAttribute fun(self: self, name: string) Removes an attribute by name.
---@field RemoveChild fun(self: self, element: Element) Removes a child from this element.
---@field ReplaceChild fun(self: self, new_element: Element, old_element: Element) Replaces a child with a new element.
---@field ScrollIntoView fun(self: self, align_top?: boolean) Scrolls the element into view.
---@field SetAttribute fun(self: self, name: string, value: any) Sets an attribute by name.
---@field SetClass fun(self: self, class_name: string, set: boolean) Sets a class on the element.
---@field SetPseudoClass fun(self: self, psuedo_class: string, set: boolean) Sets a psuedo class on the element.
---@field As any Casts this element to a specific derived type.

--- Casts this element as Form
---@param element Element
---@return ElementForm
function Element.As.ElementForm(element) end

--- Casts this element as FormControl
---@param element Element
---@return ElementFormControl
function Element.As.ElementFormControl(element) end

--- Casts this element as FormControlInput
---@param element Element
---@return ElementFormControlInput
function Element.As.ElementFormControlInput(element) end

--- Casts this element as FormControlSelect
---@param element Element
---@return ElementFormControlSelect
function Element.As.ElementFormControlSelect(element) end

--- Casts this element as FormControlDataSelect
---@param element Element
---@return ElementFormControlDataSelect
function Element.As.ElementFormControlDataSelect(element) end

--- Casts this element as Text
---@param element Element
---@return ElementText
function Element.As.ElementText(element) end

--- Casts this element as TabSet
---@param element Element
---@return ElementTabSet
function Element.As.ElementTabSet(element) end

--- Casts this element as DataGrid
---@param element Element
---@return ElementDataGrid
function Element.As.ElementDataGrid(element) end

--- Casts this element as DataGridRow
---@param element Element
---@return ElementDataGridRow
function Element.As.ElementDataGridRow(element) end

--- ElementText Class
ElementText = {}
---@class ElementText : Element
---@field text string

--- Document Class
Document = {}
---@class Document : Element
---@field title string
---@field context Context
---@field PullToFront fun(self: self) Pulls the document to the front.
---@field PushToBack fun(self: self) Pushes the document to the back.
---@field Show fun(self: self, flags?: doc_focus_type) Shows the document.
---@field Hide fun(self: self) Hides the document.
---@field Close fun(self: self) Closes the document.
---@field CreateElement fun(self: self, tag_name: string): Element Creates a new element.
---@field CreateTextNode fun(self: self, text: string): ElementText Creates a new text node.

--- Context Class
Context = {}
---@class Context
---@field name string
---@field dimensions Vector2i
---@field documents table<string, Document> Returns an array of the documents within the context. This can be looked up as an array or a dictionary. Read-only.
---@field root_element Element Returns the context’s root element. Read-only.
---@field hover_element Element Returns the element under the context’s cursor. Read-only.
---@field focus_document Document Returns the document with focus. Read-only.
---@field AddEventListener addEventListener Adds an event listener to this context.
---@field AddMouseCursor fun(self: self, cursor_document: Document): Document Adds a mouse cursor to this context.
---@field CreateDocument fun(self: self, tag: string): Document Creates a new document.
---@field LoadDocument fun(self: self, document_path: string): Document Loads a document from an RML file.
---@field LoadMouseCursor fun(self: self, cursor_path: string): Document Loads a mouse cursor from an RML file.
---@field Render fun(self: self) Renders the context.
---@field ShowMouseCursor fun(self: self, show: boolean) Shows or hides the mouse cursor.
---@field UnloadAllDocuments fun(self: self) Unloads all documents from the context.
---@field UnloadAllMouseCursors fun(self: self) Unloads all mouse cursors from the context.
---@field UnloadDocument fun(self: self, document: Document) Unloads a document from the context.
---@field UnloadMouseCursor fun(self: self, cursor_document: Document) Unloads a mouse cursor from the context.
---@field Update fun(self: self) Updates the context.

---@alias eventListener fun(event:Event, element: Document | Element, userData: any): nil
---@alias addEventListener fun(self: self, event: string, listener: eventListener, in_capture_phase?: boolean): nil

--- ElementForm Class
ElementForm = {}

---@class ElementForm : Element
---@field Submit fun(self: self, submit_value: string) Submits the form.

--- Event Class
Event = {}
---@class Event
---@field type string The string name of the event. Read-only.
---@field current_element Element The element that is currently handling the event. Read-only.
---@field target_element Element The element the event was originally targeted at. Read-only.
---@field parameters event_parameters A dictionary like object containing all the parameters in the event.
---@field StopPropagation fun(self: self) Stops propagation of the event.

--- Event Parameters Class
Event.parameters = {}
---@class event_parameters
---@field key_identifier RocketKey The key that was pressed, if any
---@field linebreak number If a linebreak was pressed, this will be 1
---@field value any The value of the event, often a string
---@field mouse_x number The x position of the mouse
---@field mouse_y number The y position of the mouse
---@field button number The mouse button that was pressed. 0 for left, 1 for middle, 2 for right -- UNCONFIRMED
---@field wheel_delta number The amount the mouse wheel was moved. Positive for up, negative for down -- UNCONFIRMED
---@field character number The character code of the key that was pressed -- UNCONFIRMED
---@field element Element The element that the event was triggered on -- UNCONFIRMED
---@field ctrl_key boolean If the control key was pressed -- UNCONFIRMED
---@field shift_key boolean If the shift key was pressed -- UNCONFIRMED
---@field alt_key boolean If the alt key was pressed -- UNCONFIRMED
---@field meta_key boolean If the meta key was pressed -- UNCONFIRMED
---@field delta_time number The time since the last event of the same type in milliseconds -- UNCONFIRMED

--- ElementFormControl Classes
ElementFormControl = {}
---@class ElementFormControl : Element
---@field disabled boolean
---@field name string
---@field value any

--- ElementFormControlInput Class
ElementFormControlInput = {}
---@class ElementFormControlInput : ElementFormControl
---@field checked boolean
---@field max_length integer
---@field size integer
---@field max number
---@field min number
---@field step number
---@field value any

--- ElementFormControlDataInput Class
ElementFormControlSelect = {}
---@class ElementFormControlSelect : ElementFormControl
---@field Add fun(self: self, rml: string, value: string, before?: integer) Adds a new option to the select box. If before is specified, the new option will be inserted before it.
---@field Remove fun(self: self, index: integer) Removes an option from the select box.
---@field options table<number, {value: string, element: Element}> The array of options available in the select box. Each entry in the array has the property value, the string value of the option, and element, the root of the element hierarchy that represents the option in the list.
---@field selection integer The index of the currently selected option.

--- ElementFormControlDataInput Class
ElementFormControlDataSelect = {}
---@class ElementFormControlDataSelect : ElementFormControlSelect
---@field SetDataSource fun(self: self, data_source: string) Sets the name and table of the new data source to be used by the select box.

--- ElementTabSet Class
ElementTabSet = {}
---@class ElementTabSet : Element
---@field active_tab integer
---@field num_tabs integer The number of tabs in the tab set. Read-only.
---@field SetPanel fun(self: self, index: integer, rml: string) Sets the contents of a panel to the RML content rml. If index is out-of-bounds, a new panel will be added at the end.
---@field SetTab fun(self: self, index: integer, rml: string) Sets the contents of a tab to the RML content rml. If index is out-of-bounds, a new tab will be added at the end.

--- ElementDataGrid Class
ElementDataGrid = {}
---@class ElementDataGrid : Element
---@field rows table<number, ElementDataGridRow>
---@field AddColumn fun(self: self, fields: string, formatter: string, initial_width: number, header_rml: string) Adds a new column to the data grid. The column will read the columns fields (in CSV format) from the grid’s data source, processing it through the data formatter named formatter. header_rml specifies the RML content of the column’s header.
---@field SetDataSource fun(self: self, data_source: string) Sets the name and table of the new data source to be used by the data grid.

--- ElementDataGridRow Class
ElementDataGridRow = {}
---@class ElementDataGridRow : Element
---@field row_expanded boolean
---@field parent_relative_index integer The index of the row, relative to its parent row. So if you are the third row in your parent, then it will be 3.
---@field table_relative_index integer The index of the row, relative to the data grid it is in. This takes into account all previous rows and their children.
---@field parent_row ElementDataGridRow The parent row of this row. None if it at the top level.
---@field parent_grid ElementDataGrid The data grid that this row belongs to.

--- Document Focus Class
DocumentFocus = {}
--- @class DocumentFocus
--- @field NONE doc_focus_type
--- @field FOCUS doc_focus_type
--- @field MODAL doc_focus_type

--- Class for the document focus enum elements
--- @class doc_focus_type