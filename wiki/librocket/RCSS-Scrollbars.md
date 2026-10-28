# RCSS Scrollbars

libRocket and the controls plugin feature several functional elements that need to be sized and decorated with RCSS properties, such as scrollbars, sliders and drop-down boxes. This document will go over all these elements and give recommendations on how you should style them.

## Scrollbars

Any element with scrolling overflow (a value of scroll or auto on either of the overflow-x or overflow-y properties) may generate scrollbars along its bottom or right side. By default, these are simple block elements with no background colour or decorator.

### Generated elements

The scrollbar elements are tagged scrollbarhorizontal or scrollbarvertical, depending on their orientation. They are hidden elements parented directly to the scrolling element. Each scrollbar element contains four child elements:

- sliderarrowdec: The button at the top (or left) of the scrollbar which can be clicked to scroll further up (or to the left) the element.
- sliderarrowinc: The button at the bottom (or right) of the scrollbar which can be clicked to scroll further down (or to the right) the element.
- slidertrack: The track that runs between the two arrow buttons.
- sliderbar: The bar that runs on the track. It represents the size and position of the visible segment of the element’s content. It can be dragged to scroll the visible window around. libRocket always sets `drag: drag` on the bar so that it can be dragged; don’t override its `drag` property.

When both horizontal and vertical scrollbars are present on an element, they are both shortened by the amount necessary to avoid an intersection. Another element is created and placed in this intersection point, placed and sized appropriately. This corner element is tagged scrollbarcorner and exists only for decoration purposes.

### Applying RCSS properties

All of these elements can be styled through RCSS to be sized, positioned and rendered appropriately. The recommended method for configuring a scrollbar is given below (note that this is for a vertical scrollbar; for a horizontal, swap width and height):

1. Set the width property of the scrollbarvertical element to the appropriate value for your interface design. This should be enough to encompass the arrows, track and bar.
2. Set the width and height properties of the sliderarrowdec and sliderarrowinc elements as appropriate. Set them to 0 if you don’t want buttons.
3. Set the width property of the slidertrack as appropriate. The height value will be ignored for the track and will always be set internally. Use margin-left (or `margin: auto` to centre it) to position the track within the scrollbar.
4. Set the width property of the sliderbar as appropriate. The height of the bar will be generated internally, but you can override this with the height property, or use the min-height and max-height properties to influence it.
5. Apply decorators to the elements as appropriate (see [RCSS Decorators](RCSS-Decorators)).

SCPUI’s scrollbar style sheet, `data/interface/css/scroll_bars.rcss`, is a complete working example; see below.

### Sounds

FSO’s `scrollchange-sound` property plays an interface sound whenever the scroll position changes, whether from the arrows, the wheel or dragging the bar. Set it on the scrollbar element (SCPUI uses `scrollchange-sound: 9;` on scrollbarvertical). So that dragging or wheeling doesn't produce a burst of overlapping sounds, it isn't replayed until the previous one has finished playing. The arrows can have `click-sound` and `mouseover-sound` like any other element. See [RCSS Properties](RCSS-Properties#interface-sounds) for the sound properties.

### The ‘scrollbar-margin’ property

As described above, the scrollbar elements (scrollbarvertical and scrollbarhorizontal) will shorten themselves automatically to avoid a corner intersection. This can lead to scenarios where a scrollbar is popping on and off (during a window resize, for example) and causing the other scrollbar to rapidly change size. To avoid this, and force a scrollbar to always shorten itself for a corner, you can use the numerical scrollbar-margin property on a scrollbar element. An element will shorten itself (on the bottom or right side, as appropriate) by the larger of the scrollbar margin and the corner dimension (which is 0 when the other scrollbar isn’t shown). A percentage is relative to the length of the scrolling element along the scrollbar.

### Example RCSS

The following is SCPUI’s `scroll_bars.rcss`, which styles every vertical scrollbar in the interface.

```css
/*General Scrollbar*/

scrollbarvertical
{
	margin-top: -1%;
	margin-bottom: -1%;
	margin-right: -2.5%;
	width: 5%;
	scrollchange-sound: 9;
	z-index: 5;
	color: white;
}

scrollbarvertical slidertrack
{
	background-decorator: image;
	background-image: scroll-bar-line.png;
	width: 10%;
	margin: auto;
}

scrollbarvertical sliderbar
{
	width: 65%;
	height: 15%;
	background-decorator: image;
	background-image: scroll-button.png;
	margin-left: 20%;
}

scrollbarvertical sliderbar:hover
{
	background-image: scroll-button-h.png;
}

scrollbarvertical sliderbar:active
{
	background-image: scroll-button-o.png;
}

scrollbarvertical sliderarrowdec
{
	width: 100%;
	height: 25%;
	mouseover-sound: 17;
	click-sound: 0;
	icon-decorator: image;
	icon-image: arrow-dbl-up.png;
}

scrollbarvertical sliderarrowinc
{
	width: 100%;
	height: 25%;
	mouseover-sound: 17;
	click-sound: 0;
	icon-decorator: image;
	icon-image: arrow-dbl-down.png;
}

scrollbarvertical sliderarrowdec:hover
{
	icon-image: arrow-dbl-up-h.png;
}

scrollbarvertical sliderarrowinc:hover
{
	icon-image: arrow-dbl-down-h.png;
}

scrollbarvertical sliderarrowdec:active
{
	icon-image: arrow-dbl-up-o.png;
}

scrollbarvertical sliderarrowinc:active
{
	icon-image: arrow-dbl-down-o.png;
}
```

Individual screens then adjust it for specific scrolling elements with more specific selectors, such as `#brief_text scrollbarvertical slidertrack` in `briefing.rcss`.

## Sliders

The controls plugin adds support for range sliders; these are instanced through the RML tag `<input type="range" ... />`. Internally these are very similar to scrollbars, and contain identical child elements, i.e.:

- sliderarrowdec
- sliderarrowinc
- slidertrack
- sliderbar

These are styled in the same way you style scrollbars. Note that for input types, the controls plugin automatically sets the type attribute of an `<input>` element as a class to ease their specification in a style sheet. So the following rule will apply properties to an input’s slider track:

```css
input.range slidertrack
{
	...
}
```

A slider fires the same scroll change as a scrollbar when its value changes, so `scrollchange-sound` on the `input.range` element plays a sound as it moves. SCPUI’s `hud_config.rcss` has a complete slider style.

## Drop-down selection boxes

The controls plugin adds support for drop-down boxes; these are instanced through the RML tag `<select>`, with individual options specified within the selection element with `<option>` tags.

### Generated elements

The select element generates three hidden elements:

- selectvalue: The container element for the selected option.
- selectarrow: The button rendered to the right of the value element.
- selectbox: The box containing the options. The visibility of this element is toggled when the arrow or value elements are clicked on, or when an option is selected.

While the selection box is open, both selectvalue and selectarrow have the `:checked` pseudo-class set, so you can style the open state. When the select is disabled, both have `:disabled`.

### Example RCSS

The following is a simplified version of SCPUI’s select style from `common.rcss`:

```css
/* The value field: a bordered, darkened box. */
selectvalue
{
	border-color: rgba(127,127,127,200);
	border-width: 1px;
	width: 75%;
	height: 100%;
	background-color: rgba(0,0,0,100);
	text-align: center;
}

/* Highlight the value field when it is hovered. */
selectvalue:hover
{
	border-color: rgba(127,127,127,255);
	background-color: rgba(255,255,255,50);
}

/* Size the arrow and decorate it. */
selectarrow
{
	icon-decorator: image;
	icon-image: arrow-dbl-down.png;
	width: 20%;
}

selectarrow:hover
{
	icon-image: arrow-dbl-down-h.png;
}

/* Change the arrow when the button is pressed or the box is open. */
selectarrow:active,
selectarrow:checked
{
	icon-image: arrow-dbl-down-o.png;
}

/* The drop-down box itself. */
selectbox
{
	width: 75%;
	text-align: center;
	background-color: rgba(0,0,0,220);
	border-color: rgba(127,127,127,255);
	border-width: 1px;
}

/* Highlight the option under the mouse. */
selectbox option:hover
{
	color: white;
}
```
