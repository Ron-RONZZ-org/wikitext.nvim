# wikitext.nvim

Small neovim plugin focused on efficient wikitext editing for heavy users.

## Features

- Quickly toggle heading levels: Nested subheadings handled automatically
- Ergonomic section folding
- (Suggest a new one, or even better, implement one and PR!)

## Highlights

- Protected regions: `<nowiki>`, `<pre>`, `<source>`, `<syntaxhighlight>`,
  `<code>`, `<math>`, comments, …
  - never risk false match inside code blocks when toggling heading levels.
- Trailing comments `== Title == <!-- comment -->` preserved
- Zero dependencies; whole plugin is a Lua foldexpr: consistent behaviour on Neovim
  0.9–0.11.

```text
== Introduction ==          ]h        === Introduction ===
text                                  text
=== Details ===             ───▶      ==== Details ====
text                                  text
== Next ==                            == Next ==
```

## Requirements

Neovim 0.9 or newer.

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

Then run `:helptags ALL` once to load helpstrings, if your setup does not do it automatically.

<blockquote>
On neovim 0.9-0.10:

```lua
vim.filetype.add({ extension = { wiki = "mediawiki", mw = "mediawiki" } })
```

Neovim 0.11 handles `*.wiki` and `*.mw` natively so this step is unnecessary.
</blockquote>

## Usage

### Quick start

```
:help wikitext
```

### Headings

Put the cursor on a heading:

| Key | Mode | Action |
|-----|------|--------|
| `]h` | normal | demote heading under cursor + nested headings |
| `[h` | normal | promote heading under cursor + nested headings |
| `]h` | visual | increase every heading line in the selection |
| `[h` | visual | decrease every heading line in the selection |

### Folding

| Key | Action |
|-----|--------|
| `za` | toggle the fold under the cursor |
| `zc` | close the fold under the cursor |
| `zo` | open the fold under the cursor |
| `zR` | open every fold |
| `zM` | close every fold |

Context-aware, `==` inside code snippets ignored.

### Commands

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

## Lua API

```lua
local wikitext = require("wikitext")

wikitext.heading_level("=== Title ===") -- 3
wikitext.demote_section()               -- cursor line; returns #changed
wikitext.promote_section()
wikitext.shift(1, 20, 1)                -- lines 1..20, +1
```

## Edge behaviour

- Uneven title levels such as `=== Title ==` is left alone.

## Limitations

- Commands not repeatable with `.`.

`doc/wikitext.txt` is the canonical reference (`:h wikitext`); this README is
the quick start.

## Development

```sh
nvim --headless --clean -l tests/run.lua   # 43 checks. No dependencies beyond nvim itself.
stylua --check .
```

CI runs the tests on Neovim stable and nightly, checks formatting, and
generates the help tags.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
