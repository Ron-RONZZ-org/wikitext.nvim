# wikitext.nvim

Heading level shifting and section folding for MediaWiki wikitext, in Neovim.

- `]h` / `[h` demote or promote a whole section (the heading plus every nested
  heading), so the tree never breaks.
- Folding starts fully open; `za` collapses the section under the cursor and
  `zR` / `zM` do the rest.
- Protected regions (`<nowiki>`, `<pre>`, `<source>`, `<syntaxhighlight>`,
  `<code>`, `<math>`, comments, …) are never rewritten or folded.
- Trailers such as `<!-- comment -->` survive a level change.
- Commands accept ranges: `:1,20HeadingDec`.
- Zero dependencies; a Lua foldexpr, so behaviour is identical on Neovim
  0.9–0.11.

```text
== Introduction ==          ]h        === Introduction ===
text                                  text
=== Details ===             ───▶      ==== Details ====
text                                  text
== Next ==                            == Next ==
```

## Requirements

Neovim 0.9 or newer, and `filetype=mediawiki` on the buffer. Neovim 0.11
detects `*.wiki` and `*.mw` automatically; on older versions:

```lua
vim.filetype.add({ extension = { wiki = "mediawiki", mw = "mediawiki" } })
```

## Installation

[lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "Ron-RONZZ-org/wikitext.nvim",
  -- The plugin is tiny; eager loading keeps :h wikitext available before the
  -- first wiki buffer. Use ft = "mediawiki" instead if you prefer lazy loading.
  lazy = false,
  opts = {},
}
```

The Forgejo source of truth works the same way:

```lua
{
  "https://forgejo.ronzz.org/ronzz-org/wikitext.nvim.git",
  lazy = false,
  opts = {},
}
```

packer.nvim:

```lua
use({
  "Ron-RONZZ-org/wikitext.nvim",
  config = function()
    require("wikitext").setup()
  end,
})
```

vim-plug:

```vim
Plug 'Ron-RONZZ-org/wikitext.nvim'
lua require('wikitext').setup()
```

Native packages:

```sh
git clone https://forgejo.ronzz.org/ronzz-org/wikitext.nvim \
  ~/.local/share/nvim/site/pack/plugins/start/wikitext.nvim
```

Then `:helptags ALL` once, if your setup does not do it automatically.

## Usage

Put the cursor on a heading:

| Key | Mode | Action |
|-----|------|--------|
| `]h` | normal | demote section (heading + nested headings) |
| `[h` | normal | promote section |
| `]h` | visual | increase every heading line in the selection |
| `[h` | visual | decrease every heading line in the selection |

Commands:

| Command | Description |
|---------|-------------|
| `:HeadingInc [range]` | increase heading levels in the range |
| `:HeadingDec [range]` | decrease heading levels in the range |
| `:HeadingDemoteSection` | demote the section under the cursor |
| `:HeadingPromoteSection` | promote the section under the cursor |

A change is all-or-nothing: if any heading would leave the configured level
range, nothing is written and an error names the offending line.

## Configuration

```lua
require("wikitext").setup({
  folds = true,          -- section folds, start open
  fold_level = 5,        -- foldlevel applied on open (5 = every section open)
  min_level = 2,         -- MediaWiki reserves "=" for the page title
  max_level = 6,
  mappings = { demote = "]h", promote = "[h" }, -- false to disable all
})
```

`mappings = false` disables every mapping; `mappings = { promote = false }`
disables only one.

## Folding

Folds follow the heading tree: `== H2 ==` is level 1, `=== H3 ===` level 2, …
Opening a buffer leaves everything open, so folding is opt-in per section:

```
za   toggle the fold under the cursor
zc   close it
zo   open it
zR   open everything
zM   close everything
```

The foldexpr is implemented in Lua and caches heading levels per buffer
change. It is mask-aware, so a heading-looking line inside a code sample does
not fold.

## Lua API

```lua
local wikitext = require("wikitext")

wikitext.heading_level("=== Title ===") -- 3
wikitext.demote_section()               -- cursor line; returns #changed
wikitext.promote_section()
wikitext.shift(1, 20, 1)                -- lines 1..20, +1
```

## Limitations

- Source-level only: headings emitted by templates are invisible.
- Matching `=` runs required; `=== Title ==` is left alone.
- A closing delimiter followed by a tag instead of a comment is not rewritten.
- Not repeatable with `.`.
- Syntax highlighting is out of scope; pair with the runtime syntax, a wikitext
  syntax plugin, or a tree-sitter wikitext parser.

`doc/wikitext.txt` is the canonical reference (`:h wikitext`); this README is
the quick start.

## Development

```sh
nvim --headless --clean -l tests/run.lua   # 38 checks, zero dependencies
stylua --check .
```

CI runs the tests on Neovim stable and nightly, checks formatting, and
generates the help tags.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
