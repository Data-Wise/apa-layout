-- LaTeX jou mode only; must run at post-render, after apaquarto's apanote.lua
-- and formatlatex.lua.
--
-- apaquarto writes a code-chunk figure's apa-note after \end{figure}: right for
-- man, where the figure is [H] and a long note may break across pages, but in
-- jou latex-header.lua lets figures float [tbp], and a note outside the float
-- is left behind in the text column. Move the \end{figure} that closes a float
-- to after the note that follows it.

if not quarto.doc.is_format("latex") then return {} end

local jou = false

local function is_end_figure(b)
  return b and b.t == "RawBlock" and b.text:match("^%s*\\end{figure}%s*$")
end

-- The note, either still a FigureNote Div or already wrapped by
-- formatlatex.lua in an apafloatnote environment.
local function is_note(b)
  if not (b and b.t == "Div") then return false end
  if b.classes:includes("FigureNote") then return true end
  local found = false
  b:walk { RawBlock = function(r)
    if r.text:match("\\begin{apafloatnote}") then found = true end
  end }
  return found
end

-- The float as floatlatex.lua leaves it: a Div (possibly inside the code
-- cell's Div) whose last block closes the figure. Returns the block list that
-- holds that closing block.
local function float_end(b)
  while b and b.t == "Div" and #b.content > 0 do
    local last = b.content[#b.content]
    if is_end_figure(last) then return b.content end
    b = last
  end
end

local function move_notes(blocks)
  if not jou then return nil end
  local out = pandoc.Blocks({})
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    local inner = float_end(b)
    if (inner or is_end_figure(b)) and is_note(blocks[i + 1]) then
      local closer
      if inner then
        closer = inner:remove(#inner)
        out:insert(b)
      else
        closer = b
      end
      out:insert(blocks[i + 1])
      out:insert(closer)
      i = i + 2
    else
      out:insert(b)
      i = i + 1
    end
  end
  return out
end

return {
  { Meta = function(meta)
      jou = meta.documentmode ~= nil
        and pandoc.utils.stringify(meta.documentmode) == "jou"
    end },
  { Blocks = move_notes },
}
