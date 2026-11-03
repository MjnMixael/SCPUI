# RCSS ColorsBackgrounds

## Foreground colour: the ‘color’ property

* color

| | |
|---|---|
| Value: | &lt;colour&gt; |
| Initial: | white |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | N/A |

This property sets the colour of rendered text and text decorations. Unlike CSS, the initial colour is white, not black.

See [Syntax](RCSS-Syntax#colors) for the ways a colour can be written.

**Known issue:** the colour name `fuchsia` is not recognised and the declaration is rejected. Use `#FF00FF` instead.

## Background colour

In RCSS, an element’s background can be set as a flat colour but not an image. This functionality (and much more!) instead lies with [decorators](RCSS-Decorators).

* background-color

| | |
|---|---|
| Value: | &lt;colour&gt; |
| Initial: | transparent |
| Applies to: | all elements |
| Inherited: | no |
| Percentages: | N/A |

This property sets the color of the element’s generated boxes. The background colour is rendered under a box’s padded area.

* background
  * An alias for background-color. It accepts only a colour; CSS's `background: url(...)` and other background values are rejected.
