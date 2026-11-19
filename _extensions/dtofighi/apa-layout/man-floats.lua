-- LaTeX (apaquarto-pdf), man only, and only when the document sets
-- `apa-layout: {man-floats: true}`; latex-header.lua floats man figures under
-- the same option. Runs at post-render, after apaquarto's floatlatex.lua
-- (post-quarto) has written each table as raw LaTeX.
--
-- In man, floatlatex.lua sets a table in the text flow, between
--   \par\addvspace{\baselineskip}\begingroup  ...  \par\endgroup\addvspace{\baselineskip}
-- so a long table can break over pages. A table set as one box cannot break:
-- if it does not fit the rest of the page it moves to the next one and leaves
-- the rest of this page blank. This filter turns such a table into a
-- table[!htbp] float, so text fills the page instead.
--
-- Only a table that is already one box is floated: one whose first block after
-- the opening group is a minipage that sets its longtable as a tabular
-- (\apalongtableastabular). A longtable is never floated; inside a float it is
-- set as one box too, and whatever does not fit the page is dropped without a
-- warning (apaquarto's own note in floatlatex.lua).

local OPEN = "\\par\\addvspace{\\baselineskip}\\begingroup"
local CLOSE = "\\par\\endgroup\\addvspace{\\baselineskip}"
local BOX = "\\noindent\\begin{minipage}{\\linewidth}\\apalongtableastabular"

local function is_raw(b, text)
  return b and b.t == "RawBlock" and b.format:match("^latex") ~= nil
    and (text == nil or b.text == text)
end

local function starts_box(b)
  return is_raw(b) and b.text:sub(1, #BOX) == BOX
end

local enabled = false

local function float_boxed_tables(blocks)
  local changed = false
  local i = 1
  while i <= #blocks do
    if is_raw(blocks[i], OPEN) and starts_box(blocks[i + 1]) then
      local j = i + 2
      while j <= #blocks and not is_raw(blocks[j], CLOSE) do j = j + 1 end
      if j <= #blocks then
        -- \begin{table} and \end{table} each on a line of their own: Quarto's
        -- latex postprocessor pairs them line by line, and an \end{table} that
        -- does not start a line is never found, so everything after the
        -- table's \begin{table} line is dropped from the .tex.
        blocks[i] = pandoc.RawBlock("latex", "\\begin{table}[!htbp]\n\\begingroup")
        blocks[j] = pandoc.RawBlock("latex", "\\par\\endgroup\n\\end{table}")
        changed = true
        i = j
      end
    end
    i = i + 1
  end
  if changed then return blocks end
end

local function man_floats_on(meta)
  local opts = meta["apa-layout"]
  if type(opts) ~= "table" or opts["man-floats"] == nil then return false end
  local v = opts["man-floats"]
  return v == true or pandoc.utils.stringify(v) == "true"
end

if quarto and not quarto.doc.is_format("latex") then return {} end

return {
  { Meta = function(meta)
      local mode = meta.documentmode and pandoc.utils.stringify(meta.documentmode) or "man"
      enabled = mode == "man" and man_floats_on(meta)
    end },
  { Blocks = function(blocks)
      if enabled then return float_boxed_tables(blocks) end
    end },
}
