# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-11-20

### Added

- Section-aware heading level shifting: `]h` / `[h` demote and promote the
  heading under the cursor together with every nested heading.
- Range commands `:HeadingInc` and `:HeadingDec`, plus
  `:HeadingDemoteSection` / `:HeadingPromoteSection`.
- Visual-mode mappings that shift every heading line in the selection.
- Section folding driven by a mask-aware Lua `foldexpr`, starting fully open
  (`za`, `zc`, `zo`, `zR`, `zM`).
- Protection for headings inside `<nowiki>`, `<pre>`, `<source>`,
  `<syntaxhighlight>`, `<code>`, `<math>`, `<chem>`, `<templatedata>`,
  `<mapframe>`, `<maplink>`, `<graph>`, `<score>`, `<timeline>`, `<hiero>` and
  HTML comments, including multi-line regions.
- Preservation of trailing HTML comments on heading lines.
- Configuration for fold level, minimum and maximum heading levels, and
  mappings.
- Lua API: `heading_level()`, `shift()`, `demote_section()`,
  `promote_section()`.

[0.1.0]: https://forgejo.ronzz.org/ronzz-org/wikitext.nvim/releases/tag/v0.1.0
