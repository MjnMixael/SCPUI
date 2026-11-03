# RCSS FontEffects

Font effects are an extension to CSS for RCSS for applying effects, such as outlining or shadowing, to text. Similarly to decorators, font effects are declared and named in a style sheet like a property, and configured with font-effect-specific properties.

Note that SCPUI doesn't use font effects itself, so they are less tested in FSO than the rest of RCSS.

## Properties

Font effects are declared and configured within style sheets in exactly the same manner as decorators (see [RCSS Decorators](RCSS-Decorators)), except they are declared as &lt;name&gt;-font-effect rather that &lt;name&gt;-decorator, including the z-index property to resolve an ambiguous render order. The only exceptions are noted below:

### Color

All font effects have a &lt;name&gt;-color property which is applied multiplicatively over the entire effect. The initial value is white, so an effect with no colour set is drawn in white.

### Render order

Unlike decorators, which default to a z-index of 0, the built-in font effects default to a &lt;name&gt;-z-index of -1, which draws them behind the text. The text itself is drawn at 0, so give an effect a z-index of 0 or more to draw it over the text.

### Inheritance

Unlike decorators, font effects are inherited from parent elements. For example, the following declaration:

```css
h1
{
	header-font-effect: outline;
	header-width: 2px;
	header-color: black;
}
```

will add an outline effect on the text within all h1 elements and their descendants. To prevent inheritance, override the effect with none. For example, to prevent the h1 outline effect from affecting span elements, you could specify the following:

```css
h1 span
{
	header-font-effect: none;
}
```

When an element and its ancestors declare effects with the same name, the declaration from the most specific selector wins, not the one on the nearest element; the nearest element only wins a tie. In the example above `h1 span` is more specific than `h1`, so it wins. But if the outline were declared on `h1.title`, a plain `span { header-font-effect: none; }` would not remove it, because `span` is less specific than `h1.title`.

## Effects

libRocket comes with two built-in font effects:

- shadow effect, for rendering shadows.
- outline effect, for outlining text.

Their sizes are whole pixels: any unit is ignored and the value is rounded to an integer.

### The shadow effect

Draws a copy of the text, offset from it.

| Property | Value | Initial | Meaning |
|---|---|---|---|
| `<name>-offset-x` | &lt;number&gt; | 0 | Horizontal offset in pixels; positive is to the right. |
| `<name>-offset-y` | &lt;number&gt; | 0 | Vertical offset in pixels; positive is down. |
| `<name>-offset` | &lt;offset-x&gt; &lt;offset-y&gt; | | Shorthand for both. |

```css
h1
{
	darken-font-effect: shadow;
	darken-offset: 2px 2px;
	darken-color: grey;
}
```

### The outline effect

Draws an outline around each glyph.

| Property | Value | Initial | Meaning |
|---|---|---|---|
| `<name>-width` | &lt;number&gt; | 1 | Outline width in pixels. Must be greater than 0; an outline with a width of 0 or less is not drawn. |
