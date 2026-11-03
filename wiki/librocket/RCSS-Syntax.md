# RCSS Syntax

A style sheet is made up of a number of rules. Each rule has a number of selectors, which define which elements the rule applies to, and properties, which are applied to those elements.

The basic syntax of a rule is as follows:

```css
selector1,
selector2,
selector3
{
	property1: value1;
	property2: value2;
	property3: value3;
}
```

Selectors are comma-separated, followed by the rule block which is defined by curly braces. Inside the rule block is a list of semi-colon separated property declarations; each property declaration is made up of the property to set, a colon, and a space-separated list of the values to assign to that property. The values accepted by each property, and how many it requires, is specific to that property.

## Comments

Comments can be included in a style sheet using the C-style /* and */ characters. `//` line comments are not supported.

## Errors and unsupported syntax

RCSS is less forgiving than a web browser, and many mistakes fail without any message:

* **Unknown property names are silently ignored.** A typo such as `widht: 50%;`, or a CSS property that RCSS doesn't have (there is no `border` shorthand, for example), produces no warning; the declaration simply does nothing. Check names against the [property index](RCSS-Properties).
* **A bad value for a known property** (for example `display: flex;` or `color: Red;`) is rejected and logs a libRocket warning naming the file and line.
* **Selectors that RCSS doesn't understand match nothing**, again without a warning. See [Selectors](RCSS-Selectors).
* There is no `!important`. Don't use it: at best it is ignored, at worst it makes the value invalid.
* There are no `@` rules (`@import`, `@media`, `@font-face` and so on). They aren't understood and can break the rule that follows them. To combine style sheets, link several from the document (see below). Fonts don't need declaring: FSO loads every `.ttf` and `.otf` file in its `data/fonts` folders automatically (see [Fonts](RCSS-Fonts)).

## Values

Which values each property accepts is given in their definition. Values may be keywords, which are set as specific strings such as auto, left, etc, or generic strings (such as font names or file paths), or one of the types described below.

### Numbers

Specified as &lt;number&gt; in a property's Values list. A number can be an integer or real number.

`z-index: 16;`

### Lengths

Specified as &lt;length&gt; in a property's Values list. A length is a horizontal or vertical measurement consisting of a number and a unit. RCSS recognises the following units:

* px: One px is equivalent to one pixel on the output medium. A number with no unit is also read as px.
* em: One em is equivalent to the font size of the element. When used in `font-size` itself, it is the font size of the parent element.
* rem: One rem is equivalent to the font size of the document's root (body) element.
* in, cm, mm, pt, pc: Physical units. FSO converts these at 96 pixels per inch multiplied by the operating system's display scale, so `1in` is 96px at 100% scaling and 144px at 150%, and `1pt` is 1/72 of that. Because they change with the player's display scaling, they are rarely what you want for UI layout.

`width: 125px;`

**Known issue:** a number followed by a unit RCSS doesn't know is read as a plain number, i.e. pixels, with no warning. This includes `ex`, `vw`, `vh` and `ch`: `width: 50vw;` is 50 pixels, not half the screen. Use percentages instead.

### Percentages

Specified as &lt;percentage&gt; in the property’s Values list. A percentage value is evaluated relative to some other value, which is specified in each property that supports a percentage. For example, width can be expressed as a percentage, which is evaluated against the width of the element’s containing block.

`min-height: 50%;`

### Colors

Specified as &lt;color&gt; in the property’s Values list. Colors represent a RGBA value, and can be declared in numerous ways:

* As the name of one of the 16 colors defined in the HTML 4.0 specification (aqua, black, blue, fuchsia, gray, green, lime, maroon, navy, olive, purple, red, silver, teal, white, and yellow), plus grey (alias for gray), orange and transparent. Color names are case-sensitive and must be lower case: `Red` or `RED` is rejected.
* Prefixed with the ‘#’ character, followed by 3, 4, 6 or 8 hexadecimal digits (upper or lower case). 3 or 6 digits represent an RGB triplet, and will have 255 attached as the opacity. If only 3 are specified, each digit will be replicated before being read; for example, #FE0 is equivalent to #FFEE00. 4 or 8 digits allow the specification of a translucent color, with the alpha last (#RGBA or #RRGGBBAA).
* In the format rgb(r, g, b) or rgba(r, g, b, a), where each of red, green, blue (and optionally alpha) is specified as a value from 0 to 255. An rgb value has an alpha of 255 attached.
* In the format rgb(r%, g%, b%) or rgba(r%, g%, b%, a%), where each of red, green, blue (and optionally alpha) is specified as a percentage value from 0 to 100. An rgb value will have full opacity.

Important: the alpha channel in rgba is **0 to 255** (or a percentage), not 0 to 1 as in CSS. `rgba(255, 0, 0, 0.5)` is read as an alpha of 0, which is fully transparent. Write `rgba(255, 0, 0, 128)` or `rgba(100%, 0%, 0%, 50%)` instead.

**Known issue:** the color name `fuchsia` is not recognised and the declaration is rejected. Use `#FF00FF` instead.

So, for example, the following color declarations are identical:

```css
color: red;
color: #F00;
color: #FF0000FF;
color: rgb(100%, 0%, 0%);
color: rgba(100%, 0%, 0%, 100%);
color: rgba(255, 0, 0, 255);
```

## Referencing RCSS from RML

A style sheet can be either stored in an external file (usually with the extension .rcss) and referenced from an RML file, or declared inline inside an RML file. Referencing an external RCSS file is done using the &lt;link&gt; tag in the following manner:

```html
<html>
	<head>
		<link type="text/rcss" href="sample.rcss" />

	...
```

The type may be either `text/rcss` or `text/css`.

File paths are **not** relative to the referencing document. FSO passes the path to its own file system, which finds the file by name across all of its data locations (the game's and any active mods' data folders and VP archives), the same way it finds any other game file. In practice:

* Use a bare file name, as SCPUI does: `href="common.rcss"`. Where the file actually sits (normally `data/interface/css/`) doesn't matter, and a mod can replace a style sheet by shipping a file with the same name.
* Because files are found by name, two style sheets with the same name in different folders collide. Give yours distinctive names.
* Use forward slashes only. Backslashes and trailing slashes are reported as errors.

The same lookup applies to every other file referenced from RCSS, such as decorator images.

Declaring an inline style sheet is done using the &lt;style&gt; tag, also within the &lt;head&gt; tag:

```html
<html>
	<head>
		<style>
			body
			{
				margin: 0px;
			}
		</style>

	...
```

Multiple style sheets can be included in a single document and combined with inline style declarations. When two rules of equal specificity set the same property, the one declared later wins. Linked sheets are combined in the order of their `<link>` tags, and **all `<style>` blocks are applied after all linked sheets**, wherever they appear in the head. So a `<style>` block always overrides a linked sheet at equal specificity, even if the `<link>` comes after it.

Also, style sheet properties can be declared directly on an element. This is done by inserting semi-colon separated style sheet property declarations into the style attribute of an element. For example, the following RML fragment:

```html
<div style="width: 25%; min-width: 55px;">
</div>
```

sets the width property to ‘25%’ and the min-width property to ‘55px’ on the div element. Properties set in a style attribute override any style sheet rule.
