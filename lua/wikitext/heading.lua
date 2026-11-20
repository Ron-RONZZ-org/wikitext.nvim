-- Parsing and rewriting of MediaWiki heading lines.
--
-- A heading is `= Title =` .. `====== Title ======` with matching delimiters.
-- The title may contain `=`; only the outermost runs count. Lines indented by
-- whitespace are <pre> blocks, not headings.
local M = {}

local MAX_HEADING = 6 -- MediaWiki renders at most six levels

-- Split a line into the part that carries the '=' delimiters and a trailing
-- HTML comment, which survives a rewrite.
function M.split_suffix(line)
  local body, suffix = line:match("^(.-)(%s*<!%-%-.*%-%->%s*)$")
  if body then
    return body, suffix
  end
  return (line:gsub("%s+$", "")), ""
end

-- Heading level of a line body, or nil when it is not a heading.
function M.parse(body)
  local open = body:match("^(=+)")
  if not open then
    return nil
  end
  local close = body:match("(=+)%s*$")
  if not close or #close ~= #open or #open > MAX_HEADING then
    return nil
  end
  if body:sub(#open + 1, #body - #close):match("^%s*$") then
    return nil
  end
  return #open
end

function M.level(line)
  return M.parse((M.split_suffix(line)))
end

-- Rewrite a heading by delta, or return nil when the line is not a heading or
-- the new level would leave [min_level, max_level].
function M.shift(line, delta, min_level, max_level)
  local body, suffix = M.split_suffix(line)
  local level = M.parse(body)
  if not level then
    return nil
  end
  local new_level = level + delta
  if new_level < min_level or new_level > max_level then
    return nil
  end
  local title = body:sub(level + 1, #body - level)
  return string.rep("=", new_level) .. title .. string.rep("=", new_level) .. suffix
end

return M
