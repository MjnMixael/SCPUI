# RCSS Fonts

RCSS implements a simpler version of the CSS2 font model when dealing with text rendering. This is for two reasons:

- The document renderer is fully under the control of the author, so (for example) a specific font can be assumed to exist.
- Improved performance.

Fonts are specified in a similar fashion.

## Loading fonts in FSO

You don't load fonts yourself. When SCPUI starts, FSO loads every `.ttf` and `.otf` file in `data/fonts` (from any mod folder or VP), and each one becomes available to RCSS under the font's internal family name (see `font-family` below). Each file is one face of a family: regular, bold, italic or bold italic. If you want bold or italic text in a family, ship the matching font file too.

## Font specification properties

### Font family: the ‘font-family’ property

- font-family

| | |
|---|---|
| Value: | &lt;string&gt; |
| Initial: | (empty) |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | N/A |

This property specifies the name of a family of fonts to be used to render sections of text descending from the element. Note that, unlike CSS, only a single font family can be specified with this property, not a comma-delimited font set.

The name is the family name stored inside the font file, not the file name, and it must match exactly, including case and spaces. For example, SCPUI ships `bnkgothm.ttf` and selects it in `custom.rcss` with:

```css
body
{
	font-family: BankGothic Md BT;
}
```

There is no fallback font. The initial value is empty, so text in an element whose `font-family` (set or inherited) doesn't name a loaded family is not rendered at all. Set the family on `body` so everything inherits it, as SCPUI's `custom.rcss` does.

### Font styling: the ‘font-style’ and ‘font-weight’ properties

- font-style

| | |
|---|---|
| Value: | normal \| italic |
| Initial: | normal |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | N/A |

This property can be used to request normal or italicised versions of a font from within a font-family. Note that RCSS does not yet support oblique font styles.

> **Known issue:** if the family has no italic face loaded, `font-style: italic` makes the text disappear instead of falling back to the regular face. Only use `italic` (including through SCPUI's default `em` style) with a family whose italic font file you ship.

- font-weight

| | |
|---|---|
| Value: | normal \| bold |
| Initial: | normal |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | N/A |

This property can be used to request normal or bolded versions of a font from within a font-family. Note that RCSS only supports bold and non-bold fonts, and not different strengths of boldness.

If the family has no bold face loaded, `bold` falls back to the regular face: the text still renders, just not in bold.

### Font size: the ‘font-size’ property

- font-size

| | |
|---|---|
| Value: | &lt;number&gt; \| &lt;length&gt; \| &lt;percentage&gt; |
| Initial: | 12 (pixels) |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | refer to the parent element’s font size |

Values have the following meanings:

- &lt;number&gt; or &lt;length&gt;
  - The font is generated at the requested size in pixels. A plain number and `px` both mean pixels. `em` is relative to the parent element’s font size and `rem` to the document’s font size. Absolute units (`pt`, `pc`, `in`, `cm`, `mm`) are converted to pixels.
- &lt;percentage&gt;
  - The font size is the parent element’s font size, scaled by the percentage.

The resulting size is rounded to a whole number of pixels. SCPUI's font size classes (`font_sizes.rcss`) use `em`, so text scales with whatever base size the document sets.

### Font charset: the ‘font-charset’ property

- font-charset

| | |
|---|---|
| Value: | &lt;urange&gt; |
| Initial: | U+0020-007E |
| Applies to: | all elements |
| Inherited: | yes |
| Percentages: | N/A |

This property allows elements to request a font that is capable of rendering characters within a range (or ranges). Because fonts are rasterised and rendered to texture before they can be used, this can be quite useful in limiting the size of textures used by the font engine. For example, a large font used for titles could be restricted to only capital letters.

The value of font-charset is a comma-separated list of Unicode ranges, each of which is in one of the forms:

- U+xxxx, to specify a single character (where x is any hexadecimal digit).
- U+xxxx-yyyy, to specify the range of xxxx through yyyy.
- U+xx??, to specify the range of xx00 through xxFF. The wildcard ‘?’ can be used to substitute any digits, but must appear in an uninterrupted range at the end of the specifier.

`U+` must be written in uppercase. The initial range covers only basic ASCII, so characters outside it (accented letters, for example) are not rendered unless you widen the range. SCPUI's `common.rcss` requests Basic Latin through Latin Extended-B:

```css
font-charset: U+0020-024F;
```

For more information, see the CSS specification of unicode-range.
