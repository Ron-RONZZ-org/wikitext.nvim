-- wikitext.nvim -- heading level shifting and section folding for MediaWiki
-- wikitext. See :h wikitext for the full documentation.
local folds = require("wikitext.folds")
local heading = require("wikitext.heading")
local protect = require("wikitext.protect")

local M = {}

local defaults = {
  folds = true,
  fold_level = 5,
  min_level = 2,
  max_level = 6,
  mappings = { demote = "]h", promote = "[h" },
}

local config = vim.deepcopy(defaults)
local commands_created = false

local function notify_error(msg)
  vim.notify("wikitext: " .. msg, vim.log.levels.ERROR)
end

local function cursor_row()
  return vim.api.nvim_win_get_cursor(0)[1]
end

local function clamp_message(delta, row)
  return ("cannot %s the heading on line %d past level %d"):format(
    delta > 0 and "demote" or "promote",
    row,
    delta > 0 and config.max_level or config.min_level
  )
end

-- Shift every heading in [first, last] by delta. Nothing is written unless
-- every heading in the range can be shifted.
local function shift_range(buf, first, last, delta)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local levels = protect.levels(lines)
  local out = {}
  local changed = 0

  for row = first, last do
    if levels[row] then
      local shifted = heading.shift(lines[row], delta, config.min_level, config.max_level)
      if not shifted then
        notify_error(clamp_message(delta, row))
        return 0
      end
      out[#out + 1] = shifted
      changed = changed + 1
    else
      out[#out + 1] = lines[row]
    end
  end

  if changed == 0 then
    notify_error(first == last and "not on a heading line" or "no heading in the selection")
    return 0
  end

  vim.api.nvim_buf_set_lines(buf, first - 1, last, false, out)
  return changed
end

-- Shift the heading on `row` together with every nested heading.
local function shift_section(buf, row, delta)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local levels = protect.levels(lines)
  local level = levels[row]
  if not level then
    notify_error("not on a heading line")
    return 0
  end

  local last = #lines
  for r = row + 1, #lines do
    if levels[r] and levels[r] <= level then
      last = r - 1
      break
    end
  end

  return shift_range(buf, row, last, delta)
end

local function create_commands()
  if commands_created then
    return
  end
  commands_created = true

  vim.api.nvim_create_user_command("HeadingInc", function(opts)
    shift_range(0, opts.line1, opts.line2, 1)
  end, { range = true, desc = "Increase wiki heading level in range" })

  vim.api.nvim_create_user_command("HeadingDec", function(opts)
    shift_range(0, opts.line1, opts.line2, -1)
  end, { range = true, desc = "Decrease wiki heading level in range" })

  vim.api.nvim_create_user_command("HeadingDemoteSection", function()
    shift_section(0, cursor_row(), 1)
  end, { desc = "Demote wiki section (heading and nested headings)" })

  vim.api.nvim_create_user_command("HeadingPromoteSection", function()
    shift_section(0, cursor_row(), -1)
  end, { desc = "Promote wiki section (heading and nested headings)" })
end

local function map_buffer(buf)
  local mappings = config.mappings
  if not mappings then
    return
  end

  if mappings.demote then
    vim.keymap.set("n", mappings.demote, function()
      shift_section(buf, cursor_row(), 1)
    end, { buffer = buf, desc = "Demote wiki section" })
    vim.keymap.set("x", mappings.demote, ":<C-u>'<,'>HeadingInc<CR>", {
      buffer = buf,
      desc = "Increase wiki heading levels",
    })
  end

  if mappings.promote then
    vim.keymap.set("n", mappings.promote, function()
      shift_section(buf, cursor_row(), -1)
    end, { buffer = buf, desc = "Promote wiki section" })
    vim.keymap.set("x", mappings.promote, ":<C-u>'<,'>HeadingDec<CR>", {
      buffer = buf,
      desc = "Decrease wiki heading levels",
    })
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  folds.setup()
  create_commands()

  local group = vim.api.nvim_create_augroup("Wikitext", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "mediawiki",
    callback = function(args)
      map_buffer(args.buf)
      if config.folds then
        folds.attach(args.buf, config.fold_level)
      end
    end,
  })

  vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    callback = function(args)
      if config.folds and vim.bo[args.buf].filetype == "mediawiki" then
        folds.attach(args.buf, config.fold_level)
      end
    end,
  })

  -- setup() may run after the FileType event (e.g. lazy-loading on FileType),
  -- so apply the buffer-local parts to the current buffer as well.
  if vim.bo.filetype == "mediawiki" then
    local buf = vim.api.nvim_get_current_buf()
    map_buffer(buf)
    if config.folds then
      folds.attach(buf, config.fold_level)
    end
  end

  return M
end

function M.heading_level(line)
  return heading.level(line)
end

function M.demote_section()
  return shift_section(0, cursor_row(), 1)
end

function M.promote_section()
  return shift_section(0, cursor_row(), -1)
end

function M.shift(first, last, delta)
  return shift_range(0, first, last, delta)
end

return M
