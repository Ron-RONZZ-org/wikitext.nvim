-- Detection of heading-looking lines inside content that MediaWiki does not
-- parse as wikitext.
--
-- Only source-faithful parsing is attempted here: the goal is to keep a
-- `== foo ==` line inside a code sample or an HTML comment from being rewritten
-- or folded, not to expand templates or understand extensions.
local heading = require("wikitext.heading")

local M = {}

-- Tags whose content is literal (not parsed as wikitext).
local PROTECTED = {
  chem = true,
  code = true,
  graph = true,
  hiero = true,
  mapframe = true,
  maplink = true,
  math = true,
  nowiki = true,
  pre = true,
  score = true,
  source = true,
  syntaxhighlight = true,
  templatedata = true,
  timeline = true,
}

-- Return the visible (non-protected) text of a line. `state` carries
-- multi-line open tags and comments between calls.
function M.visible(line, state)
  local out = {}
  local pos = 1
  local lower = line:lower()

  while pos <= #line do
    if state.tag then
      local _, stop = lower:find("</" .. state.tag .. ">", pos, true)
      if not stop then
        return table.concat(out)
      end
      pos = stop + 1
      state.tag = nil
    elseif state.comment then
      local _, stop = lower:find("-->", pos, true)
      if not stop then
        return table.concat(out)
      end
      pos = stop + 1
      state.comment = false
    else
      local start = lower:find("<", pos, true)
      if not start then
        out[#out + 1] = line:sub(pos)
        return table.concat(out)
      end
      out[#out + 1] = line:sub(pos, start - 1)
      if lower:sub(start, start + 3) == "<!--" then
        state.comment = true
        pos = start + 4
      else
        local name = lower:sub(start + 1):match("^(%a[%w%-]*)")
        local stop = name and lower:find(">", start + #name + 1, true)
        if name and PROTECTED[name] and stop then
          state.tag = name
          pos = stop + 1
        else
          out[#out + 1] = "<"
          pos = start + 1
        end
      end
    end
  end

  return table.concat(out)
end

-- Heading level of every line in `lines`, ignoring protected regions.
local function levels(lines)
  local result = {}
  local state = { tag = nil, comment = false }
  for i, line in ipairs(lines) do
    result[i] = heading.parse(M.visible(line, state))
  end
  return result
end

return { visible = M.visible, levels = levels }
