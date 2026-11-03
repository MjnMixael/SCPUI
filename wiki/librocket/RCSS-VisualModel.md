# RCSS VisualModel

The visual formatting model used in RCSS is almost identical to that of CSS, and it is recommended you read that for a detailed explanation of how libRocket builds and places element boxes. A short summary can be found below.

The differences between CSS and RCSS are:

* The dimensions of the viewport are defined as the dimensions of the context the document is being rendered in.
* The document element (the root) is always positioned (as absolute), and can be positioned within its context using top, right, bottom and left.
* Compact and run-in boxes are not yet supported.
* Generated content is not yet supported.

## Introduction to the visual formatting model

During document layout, each element generates zero or more boxes. How these boxes are sized and laid out within their document is governed by:

* The box type (either block, for boxes generally laid out top-to-bottom, or inline, for boxes laid out along a line).
* The box size; this could either be derived from intrinsic dimensions for elements such as images and form controls, or specified directly through RCSS properties, or determined by the contents of the box.
* Relationships of the box to other boxes in the document tree, such as floating boxes.

### Containing blocks

Every box has a ‘containing block’, a rectangular box with a fixed width and height. The dimensions of this box are used to evaluate such things as relative widths and margins. In general, a box will establish the containing block for its descendant elements, depending on the box’s type.

A box is not necessarily constrained by the dimensions of its containing block, it may overflow along the x- or y-axes.

The containing block of the root document element is set by the dimensions of the document’s context. The document element will generally establish a containing block for its descendants. However, it if does not have a fixed height, the height of the context will be used.

## Controlling box generation

### Block level elements and block boxes

Block-level elements are those that are formatted as blocks, flowing visually down the document from top to bottom (such as paragraphs). Elements with a display of block generate block boxes, as do any absolute or fixed positioned elements and floating elements.

Block-level elements generate exactly one block box that itself contains only block boxes. If any inline elements are inside this block box, an anonymous block box is created (one not representing any specific element) to hold and position the inline content. The anonymous block box is positioned with the original block box just like any other block box.

So, while processing the following RML fragment (assuming div and p elements are block, and img elements are inline):

```html
<div>
	<div>
	</div>
	<p>
		<img />
	</p>
</div>
```

the first div would generate a block box. This box would establish the containing block for its descendants. The second div would generate a block box using the first’s containing block, as would the p element. The img element would be placed inside an anonymous block box, which would be positioned within the p tag and generated with its containing block.

### Inline-level elements and inline boxes

Inline-level elements are those elements that do not generate blocks of content, but flow their content into lines contained by a block box. Elements with a display property of inline or inline-block generate inline boxes.

Loose text within elements also generates inline boxes.

The ‘display’ property

* display

| | |
|---|---|
| Value: | inline \| block \| inline-block \| none |
| Initial: | inline |
| Applies to: | all elements |
| Inherited: | no |
| Percentages: | N/A |

The values have the following meanings:

* block
  * This element generates a block box.
* inline
  * This element generates one or more inline boxes.
* inline-block
  * This element generates a block box, which its descendants are positioned within, but is positioned itself as a single inline box. This is similar to the behaviour of replaced elements (those with intrinsic widths).
* none
  * This element (and all of its descendants) generate no boxes, and are not displayed. Note this will mean the element will not affect layout. The ‘visibility’ property can be used to make an element affect layout but not be rendered.

The only difference between this and the CSS display property is the reduced range of values allowed.

## Positioning schemes

RCSS can position elements according to three schemes:

* Normal flow, which includes placement of block boxes, the flowing of inline boxes and relative positioning of either.
* Floats. Floating elements are placed as normal, then shifted as far to the left or right as possible within their containing block. Inline content is then flowed around floating boxes.
* Absolute positioning. Elements that are positioned with absolute or fixed are removed from the normal flow (therefore having no impact on the layout of other elements) and placed at an explicit location relative to their containing block.

### Choosing a positioning scheme: ‘position’ property

* position

| | |
|---|---|
| Value: | static \| relative \| absolute \| fixed |
| Initial: | static |
| Applies to: | all elements |
| Inherited: | no |
| Percentages: | N/A |

The values have the following meanings:

* static
  * The element generates boxes that are positioned according to normal flow.
* relative
  * The element generates boxes that are positioned according to normal flow, but then offset according to the values of the ‘top’, ‘right’, ‘bottom’ and ‘left’ properties. Other elements are positioned as though the box was in its original location.
* absolute
  * The element generates a block box that is removed from normal flow. The top, right, bottom and left properties will position the box relative to the edges of its containing block.
* fixed
  * The element is positioned like an absolute box, but will not scroll along with other content if it is within an overflowing box.

### Box offsets: ‘top’, ‘right’, ‘bottom’, ‘left’

* top, bottom

| | |
|---|---|
| Value: | &lt;length&gt; \| &lt;percentage&gt; \| auto |
| Initial: | auto |
| Applies to: | positioned elements |
| Inherited: | no |
| Percentages: | relative to the height of the containing block |

* left, right

| | |
|---|---|
| Value: | &lt;length&gt; \| &lt;percentage&gt; \| auto |
| Initial: | auto |
| Applies to: | positioned elements |
| Inherited: | no |
| Percentages: | relative to the width of the containing block |

The values have the following meanings:

* &lt;length&gt;
  * The edge is offset a fixed distance from the reference edge.
* &lt;percentage&gt;
  * The edge is offset from the reference edge a distance relative to the dimensions of the containing block.
* auto
  * The edge is not set. An absolutely positioned box with all offsets on an axis set to auto stays where it would have been placed in normal flow along that axis (its "static position"); a relatively positioned box is not moved along that axis.

If both `left` and `right` are set, `left` wins and `right` is ignored for positioning; likewise `top` wins over `bottom`. The exception is sizing: an absolutely positioned box with an auto `width` and both `left` and `right` set is sized to fit between them, and one with an auto `height` and both `top` and `bottom` set is stretched to fit between those. See [Absolute positioning](#absolute-positioning).

## Normal flow

### Block formatting

When formatting block boxes, boxes are laid out vertically one after the other. The bottom edge of a block box will touch the top edge of the block box following it. The left edge of a block box will touch the left edge of its containing block. Block elements do not themselves flow around floating elements, but their inline content will.

### Inline formatting

Inline boxes are positioned horizontally on a line, one after the other, from the top of the containing block. Horizontal padding, borders and margins are respected when positioning the boxes. Inline boxes on a single line are said to be laid out in a line box.

Each line box is generally the same width as its containing block, with its left edge touching the left edge of the containing block and its right edge touching the right edge of the containing block. However, floating elements may force a line box to be shorter along one or both of its edges. The height of a line box is governed by the height of the box’s inline content. Inline boxes are positioned vertically through the line box using the vertical-align property.

If several inline boxes cannot fit horizontally onto a single line box, they are flowed into several vertically-stacked line boxes.

The text-align property governs how the excess horizontal space between the widths of the inline boxes and the width of the line box is distributed.

Inline boxes may be split across several line boxes. When this occurs, any horizontal margins, borders and padding will only be present at the beginning and end of the inline box, not on each line.

### Relative positioning

Once a block or inline box has been positioned, it can be moved from its location if its position is set to relative. It is offset from its position using the top, right, bottom and left properties. Note that it affects the positioning of further elements from its original location, not its new one. If both `left` and `right` are set, only `left` is used; if both `top` and `bottom` are set, only `top` is used.

## Floats

A float is a box that is shifted horizontally to the left or right edge of its containing block. They do not affect placement of further block boxes, however line boxes will be shortened to avoid running over them. In this way, inline content will be flowed around them. Block boxes can be forced vertically past floating boxes using the clear property.

See the CSS2 documentation on floating elements for a description on the full float model, and interesting uses of floats.

Differences from CSS to be aware of:

* **Floats are contained.** A block box with an auto height grows to include the floats inside it. In CSS the floats would hang out of the bottom of their parent (and you'd need a "clearfix"); in RCSS no clearing trick is needed, and none is needed for a background or border on the parent to surround its floats.
* **Give floats an explicit width.** Size a float with `width` rather than relying on its content, so that it takes up the space you expect at every resolution.
* Floats on the same row line up along their top edges. To lower a shorter float within the row, give it `padding-top`; a percentage `margin-top` resolves against a height (see [Box model](RCSS-BoxModel)) and will drift with resolution.

### Positioning the float: the ‘float’ property

* float

| | |
|---|---|
| Value: | left \| right \| none |
| Initial: | none |
| Applies to: | all but absolutely positioned elements |
| Inherited: | no |
| Percentages: | N/A |

The values of this property have the following meanings:

* left
  * The element generates a block box that is floated to the left.
* right
  * The element generates a block box that is floated to the right.
* none
  * The element’s boxes are not floated.

### Controlling flow next to floats: the ‘clear’ property

* clear

| | |
|---|---|
| Value: | left \| right \| both \| none |
| Initial: | none |
| Applies to: | block-level elements |
| Inherited: | no |
| Percentages: | N/A |

The values of this property have the following meanings:

* left
  * The box’s position is pushed far enough vertically so its top edge is below the bottom edge of all previously placed left-floating elements.
* right
  * The box’s position is pushed far enough vertically so its top edge is below the bottom edge of all previously placed right-floating elements.
* both
  * The box’s position is pushed far enough vertically so its top edge is below the bottom edge of all previously placed floating elements.
* none
  * The box’s position is placed irrespective of floating elements.

Floating boxes themselves can be cleared.

Note that RCSS ignores floating elements placed within a sibling’s containing block.

## Absolute positioning

An absolutely positioned box (one with a position of absolute or fixed) is explicitly offset from the edges of its containing block. Floating boxes are ignored when laying out its inline content.

Note that in RCSS, fixed positioned boxes are not placed relative to the viewport, but identically to absolute boxes.

The containing block of an absolutely positioned box is the padding box (content plus padding) of its nearest ancestor whose `position` is not `static`, or the document if there is none. To position something against a particular element, give that element `position: relative`. Note that:

* The containing block's height comes only from that ancestor's in-flow content and floats. Absolutely positioned children don't add to it, so a positioned ancestor whose only children are absolutely positioned has a height of 0 unless you give it one.
* Unlike in-flow boxes, an absolutely positioned box does not look further up the tree for a fixed height. A percentage `height`, `top` or `bottom` inside a positioned ancestor with an auto height resolves against that ancestor's content height, which may not be what you expect. If you need a percentage height, make sure the positioned ancestor has a known height, or wrap the content in an in-flow `position: relative` element of known size.

**Give absolutely positioned elements an explicit width.** Don't rely on an absolutely positioned box with `width: auto` either shrinking to fit its content (as in CSS) or filling its containing block; set `width`, or set both `left` and `right`. This matters most when its children are sized in percentages, since those percentages resolve against the absolute box's width.

## Layered presentation

Each box has a stacking level within a single stacking context. Boxes within a stacking context are rendered in stacking level order, from lowest to highest (so boxes with the highest stacking level will appear on top). All the boxes within a single stacking context are rendered at once; they will not intermingle rendering with the members of another stacking context.

Within a stacking context, boxes that share a stacking level are drawn in this order, from bottom to top: block boxes, then floats, then inline boxes (including inline-block), then positioned boxes (relative, absolute or fixed). Boxes of the same kind are drawn in document order. So a positioned element is drawn over an in-flow sibling that comes after it, even without a z-index.

The root element of a document establishes a stacking context for its descendants. Other elements within a document may establish local stacking contexts of their own. An element which does so has two stacking levels; one within the stacking context it is a member of (given by the z-index property) and another inside the stacking context it establishes (always ‘0’).

### Specifying the stacking level: the ‘z-index’ property

* z-index

| | |
|---|---|
| Value: | &lt;number&gt; \| auto \| top \| bottom |
| Initial: | auto |
| Applies to: | all elements |
| Inherited: | no |
| Percentages: | N/A |

Values have the following meanings:

* &lt;number&gt;
  * The number is the stack level within the current stacking context. It may be negative or fractional (for example `1.5`). It also establishes a local stacking context in which its own stack level is ‘0’.
* top
  * The box is placed above every other box in its stacking context. Like a number, it establishes a local stacking context.
* bottom
  * The box is placed below every other box in its stacking context. Like a number, it establishes a local stacking context.
* auto
  * The stack level of the box is the same as its parent’s. It does not establish a local stacking context.

Boxes with a negative stack level are drawn underneath their stacking context's own background and decorators.

Note that in RCSS any element can have the z-index property, not just positioned elements.

The z-index of a document's root (body) element also orders documents within the context. A document whose body has `z-index: auto` is brought to the front whenever something in it gains focus; giving the body a z-index stops that. SCPUI's screens give `body` a low z-index (`bottom` or a negative number) so that they stay behind other documents, such as popups, opened over them.

# Visual Formatting Model Details

## Definition of ‘containing block’

During layout, the containing block of an element is fixed when the element is encountered in the document tree. It is sized as follows:

* For the root element of the document (the body element), the containing block is the size of the document’s context.
* For other elements (other than absolutely positioned elements), the containing block is the size of the nearest block ancestor’s content area, minus the space taken by any scrollbars on that ancestor. If the block ancestor does not have a fixed height (ie, its height property is set to auto), the height of the containing block is given by the height of the nearest block ancestor’s fixed content area. This may end up as the height of the context.
* If the element is positioned fixed or absolute, its containing block is given by the padded size of the nearest element with a position other than static, or the root if no such element exists. Its height is that ancestor's height once laid out, which comes from its in-flow content and floats only. Unlike other elements, absolutely positioned elements do **not** look further back in order to get a fixed height.

## Content width: the ‘width’ property

* width

| | |
|---|---|
| Value: | &lt;length&gt; \| &lt;percentage&gt; \| auto |
| Initial: | auto |
| Applies to: | block and replaced inline elements |
| Inherited: | no |
| Percentages: | relative to the width of the containing block |

This property only applies to block boxes and inline boxes with an intrinsic width. Other inline boxes are sized by their content.

Values have the following meaning:

* &lt;length&gt;
  * Specifies a fixed width.
* &lt;percentage&gt;
  * Specifies a width relative to the width of the box’s containing block.
* auto
  * The width depends on the values of other properties. See below.

```css
/* Fixes the width of input elements of class 'text' to 12 times their font size. */
input.text
{
	width: 12em;
}
```

## Computing widths and margins

If any of a box’s width, margin-left or margin-right are set to auto, then they are evaluated when the box is sized. Depending on the box type, they are set as follows:

* For an inline non-replaced box, any auto margins are set to ‘0’. width is ignored.
* For an inline replaced box, auto margins are set to ‘0’. A width of auto is set to the element’s intrinsic width.
* For a block box, the formula margin-left + border-left-width + padding-left + 'width' + padding-right + border-right-width + margin-right = containing block width must hold true. If width is auto, then any auto margins are set to ‘0’ and the box width is set to the appropriate value. Otherwise, the inequality in the equation is split evenly between the auto-margins.
* For an absolutely positioned box with an auto width, any `left` and `right` offsets that are set are subtracted from the containing block width as well.

This is different from the CSS equation in the following ways:

* Floating and positioned boxes are evaluated like normal boxes. Give floats and absolutely positioned boxes an explicit width (see [Absolute positioning](#absolute-positioning)).

## Minimum and maximum widths: ‘min-width’ and ‘max-width’

* min-width

| | |
|---|---|
| Value: | &lt;length&gt; \| &lt;percentage&gt; |
| Initial: | 0px |
| Applies to: | block and replaced inline elements |
| Inherited: | no |
| Percentages: | relative to the width of the containing block |

* max-width

| | |
|---|---|
| Value: | &lt;length&gt; \| &lt;percentage&gt; |
| Initial: | -1 |
| Applies to: | block and replaced inline elements |
| Inherited: | no |
| Percentages: | relative to the width of the containing block |

Values have the following meaning:

* &lt;length&gt;
  * Specifies a fixed minimum or maximum width.
* &lt;percentage&gt;
  * Specifies a minimum or maximum width relative to the width of the containing block.

Note that there is no auto or none value for max-width. The initial value of -1 means there is no maximum width, but only while max-width is left unset: if you set `max-width: -1` (or any negative value) explicitly, it is used as a real maximum and the element ends up with no usable width. To remove a max-width set by another rule, override it with a large value such as `max-width: 100000px`.

When evaluating width, if the computed width is greater than max-width, then the width is computed again, this time substituting max-width for width. If the computed value is less than min-width, then the width is computed again, this time substituting min-width for width.

**Known issue:** for inline replaced elements such as `img`, the height is clamped by `min-width` and `max-width` instead of `min-height` and `max-height`, which are ignored. For example, `max-width: 100px` on an image limits both its width and its height to 100px, while `max-height` does nothing. To limit an image's size, set `width` and/or `height` directly (setting only one keeps the aspect ratio), or make it `display: block` or `inline-block`, where min/max-height work normally.

## Content height: the ‘height’ property

* height

| | |
|---|---|
| Value: | &lt;length&gt; \| &lt;percentage&gt; \| auto |
| Initial: | auto |
| Applies to: | block and replaced inline elements |
| Inherited: | no |
| Percentages: | relative to the height of the containing block |

This property only applies to block boxes and inline boxes with an intrinsic height. Other inline boxes are sized by their content.

Values have the following meaning:

* &lt;length&gt;
  * Specifies a fixed height.
* &lt;percentage&gt;
  * Specifies a height relative to the height of the box’s containing block.
* auto
  * The height depends on the values of other properties. See below.

```css
/* Fixes the height of the background div to 100% of its containing block. */
div#background
{
	height : 100%;
}
```

## Computing heights and margins

If any of a box’s height, margin-top or margin-bottom are set to auto, then they are evaluated when the box is sized. Depending on the box type, they are set as follows:

* For an inline non-replaced box, any auto margins are set to ‘0’. height is ignored.
* For an inline replaced box, auto margins are set to ‘0’. A height of auto is set to the element’s intrinsic height. If only one of width and height is set, the other is scaled to keep the intrinsic aspect ratio.
* For a block box with a fixed height, the formula margin-top + border-top-width + padding-top + height + padding-bottom + border-bottom-width + margin-bottom = containing block height must hold true. The inequality in the equation is split evenly between the auto-margins.
* For a block box with an auto height, any auto margins are set to ‘0’, and the height will stretch to fit the box’s content exactly (including any floats inside it).
* For an absolutely positioned box with an auto height and both `top` and `bottom` set, the height stretches to fill the space between them. With only one of them set, the height fits the content.

This is different from the CSS equation in the following ways:

* Floating and positioned boxes are evaluated like normal boxes.
* Block boxes with a fixed height will resolve auto vertical margins similarly to horizontal margins.
* Percentage vertical margins on block-level boxes resolve against the containing block's height (see [Box model](RCSS-BoxModel)).

## Minimum and maximum heights: ‘min-height’ and ‘max-height’

* min-height

| | |
|---|---|
| Value: | &lt;length&gt; \| &lt;percentage&gt; |
| Initial: | 0px |
| Applies to: | block and replaced inline elements |
| Inherited: | no |
| Percentages: | relative to the height of the containing block |

* max-height

| | |
|---|---|
| Value: | &lt;length&gt; \| &lt;percentage&gt; |
| Initial: | -1 |
| Applies to: | block and replaced inline elements |
| Inherited: | no |
| Percentages: | relative to the height of the containing block |

Values have the following meaning:

* &lt;length&gt;
  * Specifies a fixed minimum or maximum height.
* &lt;percentage&gt;
  * Specifies a minimum or maximum height relative to the height of the containing block.

Note that there is no auto or none value for max-height. As with max-width, the initial -1 means no maximum only while max-height is left unset; don't set a negative max-height explicitly. Override an unwanted max-height with a large value instead.

When evaluating height, if the computed height is greater than max-height, then the height is computed again, this time substituting max-height for height. If the computed value is less than min-height, then the height is computed again, this time substituting min-height for height. A block box with a height of auto will never set its height below min-height or above max-height; this may result in overflow.

## Line height calculations: the ‘line-height’ and ‘vertical-align’ properties

The height of a line box is determined as follows:

* The height of each inline element is calculated.
* The inline boxes are aligned vertically (by their vertical-align property)
* The line box height is given by distance between the top edge of the highest box and the bottom edge of the lowest box.

Note that vertical padding, margins and borders of inline boxes are not taken into account when determining line box height, although they are rendered. The exception is inline replaced elements (such as images) and inline-block elements: for these, the whole margin box (content, padding, border and margin) counts towards the line height.

See the known issue under [min-width and max-width](#minimum-and-maximum-widths-min-width-and-max-width) for how image heights are clamped.

* line-height

| | |
|---|---|
| Value: | &lt;number&gt; \| &lt;length&gt; \| &lt;percentage&gt; |
| Initial: | 1.2 |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | relative to the line height of the element's font |

This property determines the minimal height of the element’s inline boxes.

Values for this property have the following meanings:

* &lt;number&gt;
  * The line height is set to the line height of the element's font (the spacing the font itself specifies, which is usually somewhat larger than the font size) scaled by this number.
* &lt;length&gt;
  * The line height is set to this fixed value. The exception is `em` (and `rem`), which, unlike CSS, scales the font's line height in the same way as a number.
* &lt;percentage&gt;
  * The line height is set to the line height of the element's font scaled by the percentage.

```css
/* Three ways of setting the same line-height. */
div
{
	line-height: 1.3;
	line-height: 1.3em;
	line-height: 130%;
}
```

* vertical-align

| | |
|---|---|
| Value: | baseline \| sub \| super \| text-top \| text-bottom \| middle \| top \| bottom \| &lt;percentage&gt; \| &lt;length&gt; |
| Initial: | baseline |
| Applies to: | inline-level elements |
| Inherited: | no |
| Percentages: | relative to the line-height of the parent element |

This property affects the vertical positioning of an inline box within the line box.

The values have the following meanings:

* baseline
  * Align the baseline of the inline box with the baseline of the line box.
* sub
  * Set the baseline of the inline box to an appropriate height for rendering subscript.
* super
  * Set the baseline of the inline box to an appropriate height for rendering superscript.
* text-top
  * Align the top of the inline box with the top of the parent box’s font.
* text-bottom
  * Align the bottom of the inline box with the bottom of the parent box’s font.
* middle
  * Align the midpoint of the box with the baseline of the parent box plus half the x-height of the parent's font.
* top
  * Align the top of the inline box with the top of the line box.
* bottom
  * Align the bottom of the inline box with the bottom of the line box.
* &lt;percentage&gt;
  * Raise or lower the element from the baseline by the parent's line-height scaled by this percentage.
* &lt;length&gt;
  * Raise or lower the element from the baseline by a fixed amount.

```css
/* Sample RCSS for defining a superscript tag. */
super
{
	vertical-align: super;
}
```

```html
<!-- Sample RML demonstrating rendering a superscript. -->
<p>
	Better than ever before!<super>*</super>
</p>
```
