-- Zero-dependency test runner.
--
--   nvim --headless --clean -l tests/run.lua
--
-- Exits non-zero when a check fails.
local root = vim.fn.getcwd()
vim.opt.rtp:prepend(root)

local wikitext = require("wikitext")

local notes = {}
vim.notify = function(msg)
  notes[#notes + 1] = tostring(msg)
end

local failures = 0
local checks = 0

local function check(name, ok, detail)
  checks = checks + 1
  if ok then
    io.write("ok   " .. name .. "\n")
  else
    failures = failures + 1
    io.write("FAIL " .. name .. "\n")
    if detail then
      io.write("     " .. tostring(detail) .. "\n")
    end
  end
end

local function buf_lines(buf)
  return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

local function eq(name, got, want)
  check(
    name,
    vim.deep_equal(got, want),
    "got " .. vim.inspect(got) .. ", want " .. vim.inspect(want)
  )
end

local function has_map(buf, mode, lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, mode)) do
    if map.lhs == lhs then
      return true
    end
  end
  return false
end

-- Fresh buffer configured like a .wiki file.
local function new_buffer(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "mediawiki"
  return buf
end

local function at(row)
  vim.api.nvim_win_set_cursor(0, { row, 0 })
end

-- ---------------------------------------------------------------------------
-- parsing
-- ---------------------------------------------------------------------------
wikitext.setup()

eq("H2 level", wikitext.heading_level("== A =="), 2)
eq("H6 level", wikitext.heading_level("====== A ======"), 6)
eq("mismatched delimiters are not a heading", wikitext.heading_level("=== A =="), nil)
eq("indented line is not a heading", wikitext.heading_level("  == A =="), nil)
eq("empty title is not a heading", wikitext.heading_level("===="), nil)

-- ---------------------------------------------------------------------------
-- section shifting
-- ---------------------------------------------------------------------------
local buf = new_buffer({ "== A ==", "text", "=== B ===", "text", "== C ==" })
at(1)
wikitext.demote_section()
eq("demote section", buf_lines(buf), { "=== A ===", "text", "==== B ====", "text", "== C ==" })

wikitext.promote_section()
eq("promote section", buf_lines(buf), { "== A ==", "text", "=== B ===", "text", "== C ==" })

notes = {}
wikitext.promote_section()
eq(
  "promote past min_level refused",
  buf_lines(buf),
  { "== A ==", "text", "=== B ===", "text", "== C ==" }
)
check(
  "promote error message",
  tostring(notes[#notes] or ""):find("cannot promote", 1, true) ~= nil,
  notes[#notes]
)

-- ---------------------------------------------------------------------------
-- range shifting
-- ---------------------------------------------------------------------------
buf = new_buffer({ "== A ==", "text", "=== B ===", "text", "== C ==" })
wikitext.shift(1, 3, 1)
eq("public shift range", buf_lines(buf), { "=== A ===", "text", "==== B ====", "text", "== C ==" })

buf = new_buffer({ "== A ==", "text", "=== B ===", "text", "== C ==" })
vim.cmd("1,3HeadingInc")
eq("command shift range", buf_lines(buf), { "=== A ===", "text", "==== B ====", "text", "== C ==" })

notes = {}
vim.cmd("1HeadingInc")
check("command works on current range", #notes == 0, notes[#notes])

-- ---------------------------------------------------------------------------
-- protected regions and comments
-- ---------------------------------------------------------------------------
buf = new_buffer({
  '<syntaxhighlight lang="bash">',
  "== not a heading ==",
  "</syntaxhighlight>",
  "== real ==",
})
at(4)
wikitext.demote_section()
eq("section skips code sample", buf_lines(buf), {
  '<syntaxhighlight lang="bash">',
  "== not a heading ==",
  "</syntaxhighlight>",
  "=== real ===",
})

buf = new_buffer({
  '<syntaxhighlight lang="bash">',
  "== not a heading ==",
  "</syntaxhighlight>",
  "== real ==",
})
vim.cmd("1,4HeadingInc")
eq("range skips code sample", buf_lines(buf), {
  '<syntaxhighlight lang="bash">',
  "== not a heading ==",
  "</syntaxhighlight>",
  "=== real ===",
})

buf = new_buffer({ "<!--", "== x ==", "-->", "== y ==" })
at(4)
wikitext.demote_section()
eq("multi-line comment skipped", buf_lines(buf), { "<!--", "== x ==", "-->", "=== y ===" })

buf = new_buffer({ "== A == <!-- keep -->" })
vim.cmd("HeadingInc")
eq("trailing comment preserved", buf_lines(buf), { "=== A === <!-- keep -->" })

buf = new_buffer({ "== A = B ==" })
vim.cmd("HeadingInc")
eq("= inside title preserved", buf_lines(buf), { "=== A = B ===" })

buf = new_buffer({ "====== deep ======" })
notes = {}
vim.cmd("HeadingInc")
eq("max_level clamp", buf_lines(buf), { "====== deep ======" })
check(
  "max_level error message",
  tostring(notes[#notes] or ""):find("cannot demote", 1, true) ~= nil,
  notes[#notes]
)

-- A tag after the closing '=' run makes the line a paragraph, not a heading.
buf = new_buffer({ "== A ==<nowiki>=</nowiki>" })
notes = {}
at(1)
wikitext.demote_section()
eq("trailing tag is not rewritten", buf_lines(buf), { "== A ==<nowiki>=</nowiki>" })
check(
  "trailing tag reports not a heading",
  tostring(notes[#notes] or ""):find("not on a heading", 1, true) ~= nil,
  notes[#notes]
)
check("trailing tag does not start a fold", vim.fn.foldlevel(1) == 0, vim.fn.foldlevel(1))

-- The same tag before the closing '=' run is inside the title and is fine.
buf = new_buffer({ "== A <nowiki>=</nowiki> ==" })
vim.cmd("HeadingInc")
eq("tag inside the title still shifts", buf_lines(buf), { "=== A <nowiki>=</nowiki> ===" })

-- A line that is not a heading must not end the section for subtree moves.
buf = new_buffer({ "== A ==", "text", "== Fake ==<nowiki>=</nowiki>", "text", "=== C ===" })
at(1)
wikitext.demote_section()
eq("paragraph does not end the section", buf_lines(buf), {
  "=== A ===",
  "text",
  "== Fake ==<nowiki>=</nowiki>",
  "text",
  "==== C ====",
})

-- ---------------------------------------------------------------------------
-- commands and mappings
-- ---------------------------------------------------------------------------
check("command exists", vim.fn.exists(":HeadingDemoteSection") == 2)
check("normal mapping exists", has_map(buf, "n", "]h"))
check("visual mapping exists", has_map(buf, "x", "]h"))
check("promote mapping exists", has_map(buf, "n", "[h"))

-- ---------------------------------------------------------------------------
-- folding
-- ---------------------------------------------------------------------------
buf = new_buffer({ "== A ==", "text", "=== B ===", "text", "== C ==" })
eq("foldmethod", vim.wo.foldmethod, "expr")
eq("foldlevel starts open", vim.wo.foldlevel, 5)
eq("no closed folds on open", vim.fn.foldclosed(1), -1)

at(1)
vim.cmd("normal! za")
check("za closes the section under the cursor", vim.fn.foldclosed(1) == 1, vim.fn.foldclosed(1))
vim.cmd("normal! zR")
check("zR opens everything", vim.fn.foldclosed(1) == -1)

buf = new_buffer({
  '<syntaxhighlight lang="bash">',
  "== not a heading ==",
  "</syntaxhighlight>",
  "== real ==",
})
check("protected line is not folded", vim.fn.foldlevel(2) == 0, vim.fn.foldlevel(2))
check("heading after a protected region folds", vim.fn.foldlevel(4) == 1, vim.fn.foldlevel(4))

-- ---------------------------------------------------------------------------
-- configuration
-- ---------------------------------------------------------------------------
wikitext.setup({ min_level = 1, mappings = { demote = "]d", promote = "[p" } })
buf = new_buffer({ "== A ==" })
at(1)
wikitext.promote_section()
eq("min_level = 1 allows H1", buf_lines(buf), { "= A =" })
check("custom demote mapping", has_map(buf, "n", "]d"))
check("custom promote mapping", has_map(buf, "n", "[p"))

wikitext.setup({ mappings = false })
buf = new_buffer({ "== A ==" })
check("mappings = false disables normal mapping", not has_map(buf, "n", "]h"))
check("mappings = false disables visual mapping", not has_map(buf, "x", "]h"))

-- setup() runs after the FileType event when the plugin is lazy-loaded on
-- FileType; it must still configure the buffer that triggered the load.
buf = new_buffer({ "== A ==" })
check("no mapping before setup", not has_map(buf, "n", "]h"))
wikitext.setup()
check("setup configures the current buffer", has_map(buf, "n", "]h"))
eq("setup applies folds to the current buffer", vim.wo.foldmethod, "expr")

io.write(("\n%d checks, %d failure(s)\n"):format(checks, failures))
os.exit(failures == 0 and 0 or 1)
