# RML Images

Librocket within FSO supports two types of image tags.

## `<img>`

The `<img>` element is used to include still images in the document.

```html
<img src="ops-panel-large-l.png"></img>
```

## `<ani>`

The `<ani>` element is used for animated images and can load APNG, EFF, or ANI files. The animation plays in a loop. SCPUI usually creates these from Lua:

```lua
local ani_el = document:CreateElement("ani")
ani_el:SetAttribute("src", "static.png")
wrapper_el:AppendChild(ani_el)
```

If an animation is given to `<img>` instead, it shows a single frame and does not play.

## Attributes

These attributes apply to both types of images.

### src

The filename of the image or animation. Use a bare file name; FSO searches its data paths for it (see [Documents](RML-Documents#file-paths)).

The extension is ignored. FSO strips it and loads the file through its normal image loading, so `src="foo.png"` finds `foo.dds`, `foo.png` or any other image format FSO supports, whichever it finds first, just as FSO does for its own graphics.

Two special forms load an image that isn't a file:

- `data:image/bmpman,N` shows FSO texture handle `N`. Get this URL from Lua with `ui.linkTexture(texture)`; SCPUI uses it for the briefing map and loading bar, which are drawn to textures at runtime.
- `data:image/png;base64,…` shows a PNG given as base64 text.

```lua
local url = ui.linkTexture(my_texture)
img_el:SetAttribute("src", url)
```

### width

The width to force the element to, in pixels. If this is unspecified, it will default to the width of the image.

### height

The height to force the element to, in pixels. If this is unspecified, it will default to the height of the image.

### coords

Shows only part of the image: four comma-separated pixel values `left, top, right, bottom`. Without `width`/`height`, the element is sized to that region.

```html
<img src="buttons.png" coords="0, 0, 64, 32"></img>
```

## Sizing with RCSS

The RCSS `width` and `height` properties override the attributes. If only one of them is set, the other is scaled to keep the image's aspect ratio.

For images, the RCSS size includes padding and borders: padding and borders take space out of the image rather than adding to the outside of it.

> **Known issue:** on an `<img>` or `<ani>` left at the default `display: inline`, `min-height` and `max-height` have no effect, and the height is limited by `min-width` and `max-width` instead. Give the image `display: block` or `display: inline-block` if you need min/max height, or set an explicit `height`.
