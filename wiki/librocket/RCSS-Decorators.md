# RCSS Decorators

Decorators are an extension to CSS for RCSS. A decorator can be declared and named in a style sheet like a property, and then configured with decorator-specific properties. libRocket provides decorators for drawing images, and FSO adds two of its own for drawing lines; together they are how SCPUI draws backgrounds, buttons and frames.

Important: Note that decorators can only be declared and defined in style sheets, not in style defined inline to an element.

## Declaring decorators

The declaration of a decorator is a property of the form:

```css
<name>-decorator: <type>;
```

where &lt;name&gt; is the user-specified name of the decorator to declare, and &lt;type&gt; is the type of decorator. The following decorator types are available in FSO:

- image (libRocket)
- tiled-box (libRocket)
- tiled-horizontal (libRocket)
- tiled-vertical (libRocket)
- corner-borders (FSO)
- underline (FSO)

Type names are case-sensitive: write them in lowercase. A decorator with an unknown type is not drawn, and a warning is written to the log.

The decorator type none is a reserved name that represents no decorator. For example, in the following:

```css
button
{
	icon-decorator: tiled-horizontal;
}
```

the RCSS is attaching a decorator of type tiled-horizontal called ‘icon’ to all button elements. Note that the name ‘icon’ could be anything; it is only used to uniquely identify the decorator for applying properties to it.

Decorator types can be overridden like any other property. So, in the example:

```css
h1
{
	icon-decorator: image;
}

h1:hover
{
	icon-decorator: none;
}
```

all h1 tags will have an image decorator attached, except when they are being hovered, when the decorator will not be rendered.

## Decorator properties

Decorators have their own property specifications with properties and shorthands, and these can be defined for declared decorators just like any other property. Decorator properties are set in the form:

```css
<name>-<property>: <value>;
```

where &lt;name&gt; is the name the decorator was declared under, &lt;property&gt; is the name of the decorator’s property to set, and &lt;value&gt; is the value of the property. For example:

```css
h1
{
	icon-decorator: image;
	icon-image-src: header_arrow.png;
	icon-image-s-begin: 5px;
}
```

an image decorator is declared, called ‘icon’. On this decorator, the properties &lt;name&gt;-image-src is set to ‘header_arrow.png’ and &lt;name&gt;-image-s-begin is set to ‘5px’. The other properties in the image specification are left to their defaults. The properties each decorator type accepts are listed below.

Image file names don't need a path. FSO looks the file up in the game data (mods and VPs) like any other interface image, so SCPUI just writes the bare file name.

The decorator properties behave like other properties, so are subject to precedence and the cascade. For example, if the following RCSS was loaded after the previous example:

```css
h1
{
	icon-image-s-begin: 3px;
}

h1:first-child
{
	icon-decorator: none;
}
```

all h1 tags will have their ‘icon’ decorators defined with an &lt;name&gt;-image-s-begin property of ‘3px’ instead of ‘5px’, and an h1 that is a first child will have no decorator.

Be careful of name conflicts! For example, in the following sample:

```css
h1
{
	icon-decorator: image;
}

.secondary
{
	icon-decorator: tiled-horizontal;
}
```

an element of type h1 with a class of ‘secondary’ will have a single decorator, ‘icon’, of type tiled-horizontal. If the decorators had different names then they both would be present.

### Specifying render order

If an element has more than one decorator on it, you can use the ‘z-index’ decorator property to control the render order in a similar fashion to elements. For example, in this sample:

```css
button
{
	background-decorator: tiled-horizontal;
	background-z-index: 0;

	icon-decorator: image;
	icon-z-index: 1;
}
```

the ‘icon’ decorator will appear on top of the ‘background’ decorator. If no z-index is specified on a decorator, it will have the default z-index of 0.

### Decorators and pseudo-classes

Because of the way libRocket compiles pseudo-class rules within style sheets, overriding decorator properties within dynamic pseudo-classes (:active, :hover and :focus, not any of the structural classes) might not always work the way you think it should.

In a nutshell, each decorator will only process properties from their element’s base rules (ie, those not specifying dynamic pseudo-classes in their final simple selector) and one rule specifying a dynamic pseudo-class (or classes), that with the highest specificity. For example, in the following sample:

```css
button
{
	background-decorator: tiled-horizontal;
	background-image-src: button.png;
	background-image-s-end: 128px;
}

button:hover
{
	background-image-t-begin: 32px;
	background-image-t-end: 64px;
}

button:active
{
	background-image-s-begin: 128px;
	background-image-s-end: 256px;
}
```

if both the :hover and :active pseudo-classes are active on a button element, the &lt;name&gt;-image-s-begin and &lt;name&gt;-image-s-end properties from the :active rule will be set, but the &lt;name&gt;-image-t-begin and &lt;name&gt;-image-t-end properties from the :hover rule will be ignored. The :active rule is used as it has higher precedence that the :hover rule, appearing further down the file. If you wanted both the s and t properties set, you could create another rule:

```css
button:active:hover
{
	background-image-t-begin: 32px;
	background-image-t-end: 64px;
	background-image-s-begin: 128px;
	background-image-s-end: 256px;
}
```

## libRocket decorators

libRocket comes with several built-in decorators for displaying images and tiled images behind elements. They draw over the element’s padding box (content plus padding).

- image decorator, for displaying a single image.
- tiled-horizontal decorator, for tiling images horizontally.
- tiled-vertical decorator, for tiling images vertically.
- tiled-box decorator, for tiling images across a box.

### Tiles

Each of these decorators is made of one or more named tiles, and each tile is set with the same group of properties, prefixed by the tile name:

| Decorator | Tiles |
|---|---|
| image | `image` |
| tiled-horizontal | `left-image`, `right-image`, `center-image` |
| tiled-vertical | `top-image`, `bottom-image`, `center-image` |
| tiled-box | `top-left-image`, `top-right-image`, `bottom-left-image`, `bottom-right-image`, `left-image`, `right-image`, `top-image`, `bottom-image`, `center-image` |

For a tile called `<tile>` on a decorator called `<name>`, the properties are:

| Property | Value | Initial | Meaning |
|---|---|---|---|
| `<name>-<tile>-src` | &lt;string&gt; | (empty) | The image file. |
| `<name>-<tile>-s-begin` | &lt;number&gt; | 0 | Left edge of the part of the image to use. |
| `<name>-<tile>-t-begin` | &lt;number&gt; | 0 | Top edge of the part of the image to use. |
| `<name>-<tile>-s-end` | &lt;number&gt; | 1 | Right edge of the part of the image to use. |
| `<name>-<tile>-t-end` | &lt;number&gt; | 1 | Bottom edge of the part of the image to use. |
| `<name>-<tile>-repeat` | stretch \| clamp-stretch \| clamp-truncate \| repeat-stretch \| repeat-truncate | stretch | How the tile fills its area. Only on the tiles that stretch with the element: `center-image` on all three tiled decorators, and the edge tiles (`left-image`, `right-image`, `top-image`, `bottom-image`) of tiled-box. |

The s and t coordinates pick a region of the image. A value in `px` is a pixel position in the image. A plain number is a fraction of the image size (0 is the left or top edge, 1 the right or bottom edge), and a percentage is the same thing out of 100%. The defaults select the whole image.

There are also shorthands:

- `<name>-<tile>-s: <s-begin> <s-end>;` and `<name>-<tile>-t: <t-begin> <t-end>;`
- `<name>-<tile>: <src> <s-begin> <t-begin> <s-end> <t-end>;`, or for tiles with a repeat mode, `<name>-<tile>: <src> <repeat> <s-begin> <t-begin> <s-end> <t-end>;`. Values left off the end keep their defaults, so `<name>-<tile>: file.png;` uses the whole image.

The repeat modes are:

- stretch
  - The tile is stretched to fill its whole area.
- clamp-stretch
  - The tile is drawn once at its natural size, and the rest of the area is filled by stretching the tile’s last row or column of pixels. If the area is smaller than the tile, the tile is squashed to fit.
- clamp-truncate
  - As clamp-stretch, but if the area is smaller than the tile, the tile is cut off instead of squashed.
- repeat-stretch
  - The tile is repeated at its natural size; the last copy is squashed to fit the remaining space.
- repeat-truncate
  - The tile is repeated at its natural size; the last copy is cut off.

For example, SCPUI’s scrollbar style uses the image shorthand with just a file name:

```css
scrollbarvertical slidertrack
{
	background-decorator: image;
	background-image: scroll-bar-line.png;
}
```

### The image decorator and ‘image-fit’

The image decorator draws a single tile, `image`. FSO’s libRocket adds one more property to it:

| Property | Value | Initial |
|---|---|---|
| `<name>-image-fit` | stretch \| contain \| fill | stretch |

The values must be written in lowercase. They mean:

- stretch
  - The image is stretched to the element’s padding box, ignoring its aspect ratio.
- contain
  - The image is scaled up or down, keeping its aspect ratio, until it fits entirely inside the element, and centred. Any space left over on two sides is left empty.
- fill
  - The image is scaled, keeping its aspect ratio, until it covers the whole element, and centred. The parts that stick out on two sides are not cut off at the element’s edges, so use this where the overflow is hidden by something else, or where it doesn’t matter.

```css
.general_bg
{
	background-decorator: image;
	background-image: 2_preload.png;
	background-image-fit: contain;
}
```

## FSO decorators

FSO adds two decorators that draw lines rather than images. Both draw relative to the element’s content box (inside the padding), and all their sizes are in pixels.

> **Known issue:** these decorators ignore units. Every number is taken as pixels, whatever unit follows it: `0.6%` is 0.6 pixels and `2em` is 2 pixels. They don’t scale with the screen resolution, so write plain pixel values.

### The corner-borders decorator

Draws an L-shaped bracket in each of the four corners of the element, like the frames around SCPUI’s ship and weapon icons.

| Property | Value | Initial | Meaning |
|---|---|---|---|
| `<name>-thickness` | &lt;number&gt; | 1 | Line thickness. The brackets are inset from the corners by this amount, and the lines are drawn roughly twice this wide. |
| `<name>-length-h` | &lt;number&gt; | 10 | Length of each bracket’s horizontal arm. |
| `<name>-length-v` | &lt;number&gt; | 10 | Length of each bracket’s vertical arm. |
| `<name>-color` | &lt;colour&gt; | white | Line colour. |
| `<name>-shorthand` | &lt;thickness&gt; &lt;length-h&gt; &lt;length-v&gt; | | Sets all three sizes at once. |

> **Known issue:** a `<name>-length` property is accepted, but it never has any effect. Use `<name>-length-h` and `<name>-length-v`.

```css
.available
{
	cborder-decorator: corner-borders;
	cborder-thickness: 1;
	cborder-length-h: 12;
	cborder-length-v: 8;
	cborder-color: teal;
}
```

### The underline decorator

Draws a horizontal line along the bottom of the element’s content box, across its full width. Unlike `text-decoration: underline` (see [RCSS Text](RCSS-Text)), it underlines the element rather than the text, and it can be dashed or dotted and have its own colour.

| Property | Value | Initial | Meaning |
|---|---|---|---|
| `<name>-style` | solid \| dashed \| dotted | solid | Line style. |
| `<name>-thickness` | &lt;number&gt; | 1 | Line thickness. The line sits this far up from the bottom of the content box. |
| `<name>-length` | &lt;number&gt; | 5 | Length of each dash. Used by dashed only. |
| `<name>-space` | &lt;number&gt; | 3 | Gap between dashes or dots. Used by dashed and dotted. |
| `<name>-color-setting` | default \| element | default | `default` uses `<name>-color`; `element` uses the element’s text colour (its `color` property). |
| `<name>-color` | &lt;colour&gt; | white | Line colour when `<name>-color-setting` is `default`. |
| `<name>-shorthand` | &lt;style&gt; &lt;thickness&gt; &lt;length&gt; &lt;space&gt; | | Sets the style and sizes at once. |

Dotted lines are drawn as square dots `thickness` wide, `space` apart. A solid line ignores `length` and `space`.

```css
.link
{
	line-decorator: underline;
	line-style: dashed;
	line-thickness: 2;
	line-length: 6;
	line-space: 4;
	line-color-setting: element;
}
```
