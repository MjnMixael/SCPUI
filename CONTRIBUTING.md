# Contributing to SCPUI

Open pull requests against `development`. `master` only receives releases.

Issues and PRs follow the [AI Usage Policy](AI_POLICY.md): write your own posts and PR descriptions, disclose any AI-written code, and don't submit large AI-written PRs.

### Documenting your change

The [SCPUI wiki](https://github.com/MjnMixael/SCPUI/wiki) is published from the `wiki/` folder on `development`: each `.md` file there is one wiki page, and every push to `development` that changes `wiki/` updates the wiki. Edit `wiki/`, not the wiki itself; edits made on the wiki are overwritten.

The wiki documents `development`, so it can describe things the latest release doesn't have yet. Mark anything new with the Development badge, on its own line under the field or section heading (never inside a heading), or at the start of a list item:

```markdown
![Development](https://raw.githubusercontent.com/wiki/MjnMixael/SCPUI/images/badges/scpui-development.svg)
```

When a release ships, its Development badges become that version's badge (`scpui-X.Y.Z.svg` in `wiki/images/badges/`; copy an existing one and change the text, width and file name).

- **New or changed features, settings or extensions:** update the matching section of `wiki/Home.md`.
- **New or changed tables:** update the table's page in `wiki/tables/`, following the layout of the existing pages. After changing a table page's fields, run `node .github/scripts/wiki-field-index.js` to update the page's Field index; the **Documentation** check fails if it is out of date. A new table also needs a row in `wiki/Tables.md`.
- **libRocket (RML, RCSS and the Lua API):** update the matching page in `wiki/librocket/`.
- **New page:** add it to `wiki/_Sidebar.md`. File names must be unique across all of `wiki/`, because the wiki links pages by name, not folder.

The **Documentation** check fails until the PR changes something under `wiki/`. If there is nothing to document (bug fixes that don't change documented behavior, CI or internal changes), a maintainer adds the `no-docs` label instead.
