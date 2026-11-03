# RML StyleSheets

Styles can be included in an RML document in three ways: included from an external style sheet, declared in the header, or declared inline inside a specific tag.

## External Style Sheets

Style sheets are included from an external source with the `<link>` tag in the document's `<head>`. See [Documents](RML-Documents#link).

```html
<head>
	<link type="text/rcss" href="default.rcss"/>
	<link type="text/rcss" href="common.rcss"/>
	<link type="text/rcss" href="options.rcss"/>
</head>
```

Sheets are combined in the order they are linked, so a later sheet wins over an earlier one when two rules are equally specific. Use bare file names; see [Documents](RML-Documents#file-paths).

## Header Style Information

RCSS can be included directly inside the header, with the `<style>` tag. Header styles are applied after all linked sheets.

- No attributes

```html
<head>
	<style>
		#title { color: #ffd700; }
	</style>
</head>
```

`<style>` only works inside `<head>`. In the body it is treated as an ordinary element and its contents show up as text.

## Inline Style Declaration

RCSS can be declared directly inside an element with the style attribute.

### Attributes

#### style

This attribute specifies a list of RCSS properties to be applied to the current element.

```html
<div style="width: 50%; color: red;">...</div>
```

See [RCSS](Librocket#rcss) for the style language itself and the [Property Index](RCSS-Properties) for the available properties.
