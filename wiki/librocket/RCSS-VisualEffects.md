# RCSS VisualEffects

## Overflow and clipping

The contents of a block box may extend beyond the content area of the box itself, for example under the following scenarios:

* The contents of an inline box wider than its containing block box cannot be broken.
* A block box has a width greater than its containing block box.
* A block box has an explicit height set, and its contents exceed that height.

When overflow occurs, the ‘overflow-x’ and ‘overflow-y’ properties dictate how the overflow is handled.

### Overflow: the ‘overflow’ property

* overflow-x, overflow-y

| | |
|---|---|
| Value: | visible \| hidden \| auto \| scroll |
| Initial: | visible |
| Applies to: | block-level elements |
| Inherited: | no |
| Percentages: | N/A |

The values have the following meanings:

* visible
  * Overflowing content is visible along this axis.
* hidden
  * Overflowing content is hidden along this axis.
* auto
  * If overflow occurs along this axis, overflowing content is hidden and a scrollbar is generated and positioned along the axis so the hidden content can be scrolled into view.
* scroll
  * A scrollbar is always visible along the axis, allowing hidden content to be scrolled into view. This will eliminate ‘popping’ if content suddenly overflows and a scrollbar appears.

Note that, unlike CSS, if either of overflow-x or overflow-y is set to a value other than ‘visible’, clipping will occur on both axes.

An element only clips while its content actually overflows it. While its in-flow content fits, nothing is clipped, even with `overflow: hidden`. For example, an absolutely positioned child that sticks out of the element is drawn in full until the element's normal content grows large enough to overflow, at which point it is suddenly clipped too.

* overflow

Shorthand for overflow-x overflow-y. If two values are specified, the first will be used to specify overflow-x and the second overflow-y. If one value is specified, if will be used to specify both.

```css
/* Hide horizontal overflowing content and generate a scrollbar (if required) along the vertical axis. */
div#content
{
	overflow: hidden auto;
}
```

### Clipping: the ‘clip’ property

This property is completely different from the CSS clip property. Instead of defining the clipping region of an element, this property defines how the element interacts with the clipping regions of its ancestors.

In RCSS, the clipping region of an element is always its content area, not including its padding. When an element is clipping, its content is not drawn over its padding.

* clip

| | |
|---|---|
| Value: | auto \| none \| &lt;number&gt; |
| Initial: | auto |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | N/A |

The values have the following meanings:

* auto
  * The element is subjected to all the clipping regions put in place by its ancestors.
* none
  * The element is never clipped (except by the context).
* &lt;number&gt;
  * The element is subjected to the clipping regions of its ancestors, except it skips the closest &lt;number&gt; ancestors that could have put in place a clipping region (ie, those ancestors with an overflow-x or overflow-y other than visible).

Because `clip` is inherited, setting it on an element also applies to all of its descendants unless they set their own value. For example, `clip: none` on a popup container lets everything inside it draw outside any scrolling panel it sits in. An ancestor's own `clip` also carries down the tree: if an ancestor skips clipping regions, its descendants skip at least as many.

### Visibility: the ‘visibility’ property

* visibility

| | |
|---|---|
| Value: | visible \| hidden |
| Initial: | visible |
| Applies to: | all elements |
| Inherited: | no |
| Percentages: | N/A |

Values have the following meanings:

* visible
  * The generated box is visible.
* hidden
  * The generated box, and all of its descendants, is hidden. Note that the box still has an impact on layout, it is just not rendered.

Unlike CSS, a descendant of a hidden element can't make itself visible again: `visibility: visible` on a child of a `visibility: hidden` element has no effect. To hide only part of an element, set `visibility: hidden` on the individual children instead.
