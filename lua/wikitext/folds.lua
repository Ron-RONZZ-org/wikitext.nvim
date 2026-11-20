-- Section folding for MediaWiki wikitext.
--
-- Folds are defined by heading level (an `== H2 ==` starts a level 1 fold, an
-- `=== H3 ===` a level 2 fold, ...) and start fully open, so folding is opt-in
-- per section with |za|. Protected regions never start a fold.
local protect = require("wikitext.protect")

local M = {}

-- bufnr -> { tick = changedtick, levels = { ... } }. The foldexpr is evaluated
-- once per line; parsing the whole buffer once per change keeps that linear.
M.cache = {}

local function levels_for(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local entry = M.cache[buf]
  if entry and entry.tick == tick then
    return entry.levels
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  entry = { tick = tick, levels = protect.levels(lines) }
  M.cache[buf] = entry
  return entry.levels
end

-- foldexpr entry point. Returns '>N' to start a section fold at level N and
-- '=' to inherit the previous line's level, which keeps body text and
-- protected regions inside the surrounding section.
function M.expr(lnum)
  local level = levels_for(vim.api.nvim_get_current_buf())[lnum]
  if not level or level < 2 then
    return "="
  end
  return ">" .. (level - 1)
end

-- Apply the section folds to the window showing `buf`.
function M.attach(buf, fold_level)
  local win = vim.api.nvim_get_current_win()
  if vim.api.nvim_win_get_buf(win) ~= buf then
    return
  end
  vim.wo[win].foldmethod = "expr"
  vim.wo[win].foldexpr = "v:lua.require'wikitext.folds'.expr(v:lnum)"
  vim.wo[win].foldlevel = fold_level
end

function M.setup()
  local group = vim.api.nvim_create_augroup("WikitextFolds", { clear = true })
  vim.api.nvim_create_autocmd("BufDelete", {
    group = group,
    callback = function(args)
      M.cache[args.buf] = nil
    end,
  })
end

return M
