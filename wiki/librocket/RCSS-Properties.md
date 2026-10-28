# RCSS Properties

Following is a full index of properties recognised by RCSS in FSO, including the ones added by libRocket's controls plugin and by FSO itself. The Notes column details important changes from the CSS specification, and the last column links to the page that describes each property.

For decorators’ properties see [RCSS Decorators](RCSS-Decorators); for font effects’ properties see [RCSS FontEffects](RCSS-FontEffects).

A property name that isn't in this table is silently ignored (there is no `border` shorthand, for example), as is a value the property doesn't accept. A number with an unrecognised unit is read as pixels.

| Name | Values | Initial value | Applies to | Inherited? | Percentages | Notes | Page |
|---|---|---|---|---|---|---|---|
| background | background-color | | | | | Excludes images. Use a decorator for background images. | [RCSS ColorsBackgrounds](RCSS-ColorsBackgrounds) |
| background-color | &lt;colour&gt; | transparent | all | no | | | [RCSS ColorsBackgrounds](RCSS-ColorsBackgrounds) |
| border-color | border-top-color border-right-color border-bottom-color border-left-color | | | | | | [RCSS BoxModel](RCSS-BoxModel) |
| border-top border-right border-bottom border-left | border-&lt;edge&gt;-width border-&lt;edge&gt;-color | | | | | Excludes border style. | [RCSS BoxModel](RCSS-BoxModel) |
| border-top-color border-right-color border-bottom-color border-left-color | &lt;colour&gt; | black | all | no | N/A | | [RCSS BoxModel](RCSS-BoxModel) |
| border-top-width border-right-width border-bottom-width border-left-width | &lt;length&gt; \| &lt;percentage&gt; | 0px | all | no | width of containing block | | [RCSS BoxModel](RCSS-BoxModel) |
| border-width | border-top-width border-right-width border-bottom-width border-left-width | | all | | | | [RCSS BoxModel](RCSS-BoxModel) |
| bottom | &lt;length&gt; \| &lt;percentage&gt; \| auto | auto | positioned elements | no | height of containing block | | [RCSS VisualModel](RCSS-VisualModel) |
| clear | left \| right \| both \| none | none | block-level elements | no | N/A | | [RCSS VisualModel](RCSS-VisualModel) |
| clip | &lt;number&gt; \| auto \| none | auto | all | yes | N/A | Controls interaction with ancestor element’s clipping regions. | [RCSS VisualEffects](RCSS-VisualEffects) |
| color | &lt;colour&gt; | white | all | yes | N/A | | [RCSS ColorsBackgrounds](RCSS-ColorsBackgrounds) |
| cursor | &lt;string&gt; \| auto | auto | all | yes | N/A | &lt;string&gt; refers to title of cursor document. | [RCSS CursorsDragTab](RCSS-CursorsDragTab) |
| display | inline \| block \| inline-block \| none | inline | all | no | N/A | | [RCSS VisualModel](RCSS-VisualModel) |
| drag | none \| drag \| drag-drop \| clone \| block | none | all | no | N/A | Introduced for RCSS. Controls generation of drag messages; `clone` also attaches a copy of the element to the cursor. | [RCSS CursorsDragTab](RCSS-CursorsDragTab) |
| float | left \| right \| none | none | all | no | N/A | | [RCSS VisualModel](RCSS-VisualModel) |
| focus | none \| auto | auto | all | yes | N/A | Introduced for RCSS. Controls whether the element can receive input focus. | [RCSS CursorsDragTab](RCSS-CursorsDragTab) |
| font | font-style font-weight font-size font-family font-charset | | | | | | [RCSS Fonts](RCSS-Fonts) |
| font-charset | &lt;urange&gt; | U+0020-007E | all | yes | N/A | Introduced for RCSS. Specifies required range of characters. | [RCSS Fonts](RCSS-Fonts) |
| font-family | &lt;string&gt; | (empty) | all | yes | N/A | Only single family supported. The family name stored in the font file, exact and case-sensitive. No fallback: text with no loaded family isn't rendered. | [RCSS Fonts](RCSS-Fonts) |
| font-size | &lt;number&gt; \| &lt;length&gt; \| &lt;percentage&gt; | 12 (px) | all | yes | size of parent font | `em` is relative to the parent’s font, `rem` to the document’s. | [RCSS Fonts](RCSS-Fonts) |
| font-style | normal \| italic | normal | all | yes | N/A | ‘oblique’ not supported. Italic with no italic face loaded renders no text. | [RCSS Fonts](RCSS-Fonts) |
| font-weight | normal \| bold | normal | all | yes | N/A | Intermediate weights not supported. | [RCSS Fonts](RCSS-Fonts) |
| height | &lt;length&gt; \| &lt;percentage&gt; \| auto | auto | block and replaced inline elements | no | height of containing block | | [RCSS VisualModel](RCSS-VisualModel) |
| left | &lt;length&gt; \| &lt;percentage&gt; \| auto | auto | positioned elements | no | width of containing block | | [RCSS VisualModel](RCSS-VisualModel) |
| line-height | &lt;number&gt; \| &lt;length&gt; \| &lt;percentage&gt; | 1.2 | all | yes | font size | ‘normal’ not supported. | [RCSS VisualModel](RCSS-VisualModel) |
| margin | margin-top margin-right margin-bottom margin-left | | | | | | [RCSS BoxModel](RCSS-BoxModel) |
| margin-top margin-right margin-bottom margin-left | &lt;length&gt; \| &lt;percentage&gt; \| auto | 0px | all | no | width of containing block | | [RCSS BoxModel](RCSS-BoxModel) |
| max-height | &lt;length&gt; \| &lt;percentage&gt; | -1 | block and replaced inline elements | no | height of containing block | ‘none’ not supported. The initial -1 means no maximum only while unset; never set a negative value, override with a large one instead. | [RCSS VisualModel](RCSS-VisualModel) |
| min-height | &lt;length&gt; \| &lt;percentage&gt; | 0px | block and replaced inline elements | no | height of containing block | | [RCSS VisualModel](RCSS-VisualModel) |
| max-width | &lt;length&gt; \| &lt;percentage&gt; | -1 | block and replaced inline elements | no | width of containing block | ‘none’ not supported. The initial -1 means no maximum only while unset; never set a negative value, override with a large one instead. | [RCSS VisualModel](RCSS-VisualModel) |
| min-width | &lt;length&gt; \| &lt;percentage&gt; | 0px | block and replaced inline elements | no | width of containing block | | [RCSS VisualModel](RCSS-VisualModel) |
| min-rows | &lt;number&gt; | 0 | datagrid elements | no | N/A | Added by the controls plugin. The grid’s body stays hidden until at least this many rows have loaded. | [RML DataDisplay](RML-DataDisplay) |
| overflow | overflow-x overflow-y | | | | | One value sets both. | [RCSS VisualEffects](RCSS-VisualEffects) |
| overflow-x | visible \| hidden \| scroll \| auto | visible | block elements | no | N/A | Content clipped if either axis is not ‘visible’. | [RCSS VisualEffects](RCSS-VisualEffects) |
| overflow-y | visible \| hidden \| scroll \| auto | visible | block elements | no | N/A | Content clipped if either axis is not ‘visible’. | [RCSS VisualEffects](RCSS-VisualEffects) |
| padding | padding-top padding-right padding-bottom padding-left | | | | | | [RCSS BoxModel](RCSS-BoxModel) |
| padding-top padding-right padding-bottom padding-left | &lt;length&gt; \| &lt;percentage&gt; | 0px | all | no | width of containing block | | [RCSS BoxModel](RCSS-BoxModel) |
| position | static \| relative \| absolute \| fixed | static | all | no | N/A | ‘fixed’ is positioned like ‘absolute’ but ignores scrolling. | [RCSS VisualModel](RCSS-VisualModel) |
| right | &lt;length&gt; \| &lt;percentage&gt; \| auto | auto | positioned elements | no | width of containing block | | [RCSS VisualModel](RCSS-VisualModel) |
| scrollbar-margin | &lt;length&gt; \| &lt;percentage&gt; | 0 | scrollbarvertical and scrollbarhorizontal elements | no | length of the scrolling element along the scrollbar | Introduced for RCSS. Specifies a bottom / right margin (depending on orientation); the scrollbar is shortened by the larger of this and the corner size. | [RCSS Scrollbars](RCSS-Scrollbars) |
| tab-index | none \| auto | none | all | no | N/A | Introduced for RCSS. Controls order of focus switching when the tab key is pressed. | [RCSS CursorsDragTab](RCSS-CursorsDragTab) |
| text-align | left \| right \| center \| justify | left | block-level elements | yes | N/A | ‘justify’ is accepted but renders as left. | [RCSS Text](RCSS-Text) |
| text-decoration | underline \| none | none | all | yes | N/A | ‘overline’, ‘line-through’ not supported. | [RCSS Text](RCSS-Text) |
| text-transform | none \| capitalize \| uppercase \| lowercase | none | all | yes | N/A | ‘capitalize’ is accepted but does nothing. Only A–Z are converted. | [RCSS Text](RCSS-Text) |
| top | &lt;length&gt; \| &lt;percentage&gt; \| auto | auto | positioned elements | no | height of containing block | | [RCSS VisualModel](RCSS-VisualModel) |
| vertical-align | baseline \| sub \| super \| text-top \| text-bottom \| middle \| top \| bottom \| &lt;percentage&gt; \| &lt;length&gt; | baseline | inline-level elements | no | line-height | | [RCSS VisualModel](RCSS-VisualModel) |
| visibility | visible \| hidden | visible | all | no | N/A | | [RCSS VisualEffects](RCSS-VisualEffects) |
| white-space | normal \| pre \| nowrap \| pre-wrap \| pre-line | normal | block-level elements | yes | N/A | ‘pre-wrap’ and ‘pre-line’ from CSS3. | [RCSS Text](RCSS-Text) |
| width | &lt;length&gt; \| &lt;percentage&gt; \| auto | auto | block and replaced inline elements | no | width of containing block | | [RCSS VisualModel](RCSS-VisualModel) |
| z-index | &lt;number&gt; \| auto \| top \| bottom | auto | all | no | N/A | Applies to all elements. ‘top’ and ‘bottom’ introduced. For documents, ‘auto’ allows pulling to front, otherwise remains at top or bottom. | [RCSS VisualModel](RCSS-VisualModel) |
| click-sound dblclick-sound mouseover-sound mouseout-sound mouseup-sound mousedown-sound mousescroll-sound scrollchange-sound | &lt;sound&gt; [, (&lt;state&gt;)&lt;sound&gt; ...] | none | all | no | N/A | Added by FSO. Plays an interface sound for the event. | [Interface sounds](#interface-sounds) |

## Interface sounds

FSO adds eight properties that play an interface sound (from `sounds.tbl`) when something happens to an element. They are the main way SCPUI gives its buttons sound.

| Property | Plays when |
|---|---|
| `click-sound` | the element is clicked |
| `dblclick-sound` | the element is double-clicked |
| `mouseover-sound` | the mouse pointer moves onto the element |
| `mouseout-sound` | the mouse pointer moves off the element |
| `mousedown-sound` | a mouse button is pressed over the element |
| `mouseup-sound` | a mouse button is released over the element |
| `mousescroll-sound` | the mouse wheel is turned over the element |
| `scrollchange-sound` | a scrollbar or range slider moves (set it on the `scrollbarvertical` / `scrollbarhorizontal` element or the `input.range` element; see [RCSS Scrollbars](RCSS-Scrollbars)) |

### Values

A value is a comma-separated list of sounds:

- one optional **default sound**, written as the sound’s name, which plays automatically when the event happens, and
- any number of **state sounds**, written `(state)sound`, which only play when a script asks for them (see below). The state names are your own choice.

A sound is named by its name in the interface sounds section of `sounds.tbl`. The retail sounds are named by their index number, so SCPUI uses numbers such as `17` (the mouse-over sound) and `0` (the click). A sound file name without its extension also works, for interface sounds that have a single file.

```css
/* Click and mouse-over sounds on every button. */
button
{
	mouseover-sound: 17;
	click-sound: 0;
}

/* A click sound, plus "error" and "commit" sounds a script can choose between. */
.commit_button
{
	click-sound: 0,(error)15,(commit)7;
}

/* No automatic click sound: the script plays "error" or "commit" depending on the outcome. */
.accept_button
{
	click-sound: (error)15,(commit)7;
}
```

If any sound in the value can’t be found, or the value lists more than one default sound, the whole declaration is rejected and a message is written to the log; the element keeps whatever value it would otherwise have.

### Playing state sounds from Lua

State sounds are played with `ui.playElementSound(element, event, state)`, where `event` is the property name without `-sound` (for example `"click"`) and `state` is the name in brackets. It returns `true` if a sound was played. Leave out `state` to play the default sound. SCPUI’s controllers do this when the outcome of a click decides the sound:

```lua
if not ok then
    ui.playElementSound(element, "click", "error")
    return
end
ui.playElementSound(element, "click", "commit")
```

The sound is looked up on the element you pass, not on its parents.

> **Known issue:** `event` must be one of the eight names in the table above. Any other name (a typo such as `"onclick"`, for instance) crashes the game.

### Behaviour

- The properties aren’t inherited, but most events bubble up from the element under the mouse to its parents. Clicking a `<span>` inside a button therefore plays the button’s `click-sound`. If the span and the button both have a `click-sound`, both play.
- `mouseover-sound` and `mouseout-sound` are the exception: they only play when the pointer enters or leaves that element itself, not when it moves between the element’s children.
- `scrollchange-sound` isn’t replayed until the previous scroll sound has finished, so dragging a scrollbar doesn’t produce a burst of overlapping sounds.
- There is no value that switches a sound off: `none` and `-1` are rejected like any other unknown sound name. To silence a sound set by a broader rule, give the more specific rule only state sounds (for example `click-sound: (unused)0;`), which leaves it with no default sound.
