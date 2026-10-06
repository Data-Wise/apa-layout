-- LaTeX (apaquarto-pdf), jou only. floatsintext makes apaquarto set every
-- figure and in-flow table [H] (floatlatex.lua). In two columns an [H] float
-- that does not fit the rest of a column jumps to the next one and leaves a
-- blank pocket (jou columns are flush-bottom, so the space is spread inside the
-- column); let figures and tables float [tbp] instead. man keeps [H]. A float
-- that asks to span both columns (apa-twocolumn) is a starred environment with
-- its own placement and is untouched. Wrapped in \AtBeginDocument so it does
-- not matter where Quarto places this text relative to apaquarto's template.
--
-- Retired in 0.2.0, fixed upstream in apaquarto v7.0.0 (2026-10-06): the
-- \Needspace before in-flow table titles (apaquarto#170). Its stated cause was
-- wrong: the stranded title came from longtable's \LT@start, which checks
-- whether the head, first row and foot fit on the rest of the page and forces a
-- page break if not, after the title and caption are already set.

if not quarto.doc.is_format("latex") then return {} end

local jou_floats = [[
\makeatletter
\AtBeginDocument{%
  \let\apalayout@figure\figure
  \renewcommand{\figure}[1][]{\apalayout@figure[tbp]}%
  \let\apalayout@table\table
  \renewcommand{\table}[1][]{\apalayout@table[tbp]}}
\makeatother
]]

return {
  { Meta = function(meta)
      local mode = meta.documentmode and pandoc.utils.stringify(meta.documentmode) or "man"
      if mode == "jou" then
        quarto.doc.include_text("in-header", jou_floats)
      end
    end },
}
