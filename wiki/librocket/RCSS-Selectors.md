# RCSS Selectors

Selectors are used to select elements to apply specific rules to. The selector syntax supported in RCSS is as follows:

| Pattern | Meaning |
|---|---|
| E | Matches any element of type E (ie, an element declared in an RML document as `<E>`). |
| E F | Matches any element of type F that is a descendant of an E element. |
| E.foo | Matches any element of type E that has been declared with class foo. |
| E#foo | Matches any element of type E that has been declared with an ID of foo. |
| E:foo | Matches any element of type E that has the pseudo-class foo currently active. |

## Selectors that silently fail

The following are not supported. RCSS does not reject them: the rule is accepted, but the selector never matches anything, and no warning is given. If a rule seems to have no effect, check for these first.

* The universal selector `*`.
* The child (`>`), adjacent sibling (`+`) and general sibling (`~`) combinators. `div > p` matches nothing; use the descendant form `div p`.
* Attribute selectors such as `input[type=checkbox]`. Give the element a class instead.
* Pseudo-elements such as `::before`, `:first-letter` and `:first-line`. Generated content isn't supported.
* Upper-case tag names. RML tag names are converted to lower case when the document loads, but selectors are not, so `DIV` or `Button` never matches. Always write tag names in lower case. Class names and IDs are case-sensitive and must match exactly.

## Pseudo-classes

The following pseudo-classes are supported natively (this includes the full range of proposed structural selectors from CSS3):

| Pseudo-class | Meaning |
|---|---|
| :hover | Matches an element that is currently under the mouse cursor, and all of its ancestors. |
| :active | Matches an element that has been clicked on, only until the button is released. |
| :focus | Matches an element that has input focus. |
| :checked | Matches a checkbox or radio `input` that is checked. Also set on a `select`'s `selectvalue` and `selectarrow` while its drop-down list is open. |
| :selected | Matches the currently selected `tab` in a `tabset`. |
| :disabled | Matches a form control with the `disabled` attribute, and the internal parts of a disabled `select` or range slider. |
| :drag | Matches the clone of an element being dragged with `drag: clone` (see [Cursors, drag and tab](RCSS-CursorsDragTab)). |
| :nth-child(an + b) | Matches an element that has an + b - 1 siblings before it. |
| :nth-last-child(an + b) | Similar to nth-child, but counts backwards. |
| :nth-of-type(an + b) | Similar to nth-child, but only counts sibling elements of the same type. |
| :nth-last-of-type(an + b) | Similar to nth-of-type, but counts backwards. |
| :first-child | Matches an element that is the first child of its parent. |
| :last-child | Matches an element that is the last child of its parent. |
| :first-of-type | Matches an element that is the first child of its type. |
| :last-of-type | Matches an element that is the last child of its type. |
| :only-child | Matches an element that has no sibling elements. |
| :only-of-type | Matches an element that has no sibling elements of its type. |
| :empty | Matches an element that has no child nodes. |

The structural pseudo-classes (`:nth-…`, `:first-…`, `:last-…`, `:only-…` and `:empty`) ignore siblings and children that have `display: none`. Hiding an element therefore changes which of its siblings count as first, last, even or odd.

For a much fuller description of the :nth- style selectors, please refer to the respective page of the CSS3 working draft. even and odd are supported in RCSS.

**Known issue:** only `even` and `odd` work correctly in the `:nth-child`, `:nth-last-child`, `:nth-of-type` and `:nth-last-of-type` selectors. Any other argument is parsed wrongly: `:nth-child(2n+1)` matches only the second child, `:nth-child(1)` matches every child, and `:nth-child(3)` matches every third child. Spaces inside the parentheses (`2n + 1`) also break the selector. Use `even` or `odd`, `:first-child` or `:last-child`, or set a class on the element from Lua.

### Custom pseudo-classes

A pseudo-class doesn't have to be one of the names above. Any name can be used in a selector, and it matches whenever that pseudo-class has been set on the element from Lua with [`SetPseudoClass`](Librocket-API-Element):

```css
.help_text
{
	display: none;
}

.help_text:shown
{
	display: block;
}
```

```lua
element:SetPseudoClass("shown", true)   -- turn on
element:SetPseudoClass("shown", false)  -- turn off
```

You can also set the built-in names yourself. SCPUI does this to make a `button` look pressed by setting `checked` on it, since buttons don't set `:checked` on their own.

## Combining selectors

A simple selector is made up of an optional element type followed by zero or more class selectors, ID selectors and pseudo-class selectors. If an element type is not given, any element type will be matched. So, for example, the selector:

```css
div#level_list:hover
```

will match any element of type div with an ID of level_list that is currently being hovered by the cursor.

A selector is made up of potentially multiple simple selectors separated by whitespace. For an element to be matched by a selector with multiple simple selectors, it itself must match the last simple selector, and it must have ancestors in the RML hierarchy that match, in order, each of the preceding simple selectors. Pseudo-classes work on any part, not just the last, so `button:hover img` matches an image inside a hovered button. For example, the selector:

```css
div#level_list input.select option:nth-child(even)
```

will only match an element of type option that is an even-numbered child of its parent, that has an ancestor of an input element of class select, that itself has an ancestor that is a div element with the ID level_list.

Multiple selectors can be appended with commas, which is equivalent to an OR statement. For example, the following:

```css
div#level_list,
div#weapon_list,
.colour_list
```

will match a div element with ID level_list, or ID weapon_list, or any element that has a class of colour_list.

See the CSS specifications for more thorough documentation and examples on the use of selectors.
