-- LaTeX (apaquarto-pdf) only. Adds two preamble fixes, each wrapped in
-- \AtBeginDocument so it does not matter where Quarto places this text
-- relative to apaquarto's own template (apalatex.tex):
--
-- 1. jou only: floatsintext makes apaquarto set every figure [H]
--    (floatlatex.lua). In two columns an [H] figure that does not fit the rest
--    of a column jumps to the next one and leaves a blank pocket; let figures
--    float [tbp] instead. man keeps [H]. Pair with jou-float-notes.lua, which
--    keeps a figure's note inside the float that now moves.
--
-- 2. All modes: an in-flow table's title and caption end in \nopagebreak, but
--    the \addcontentsline that follows leaves a legal page break before the
--    longtable, so a caption can be stranded at a page foot. Before a title set
--    outside any float, ask for room for the title, caption and a short table.
--    Floats are untouched: \@captype is defined only inside them.

if not quarto.doc.is_format("latex") then return {} end

local needspace = [[
\usepackage{needspace}
\makeatletter
\AtBeginDocument{%
  \@ifundefined{apafloattitle}{}{%
    \let\apalayout@apafloattitle\apafloattitle
    \renewcommand{\apafloattitle}[1]{%
      \@ifundefined{@captype}{\par\Needspace{14\baselineskip}}{}%
      \apalayout@apafloattitle{#1}}}}
\makeatother
]]

local jou_floats = [[
\makeatletter
\AtBeginDocument{%
  \let\apalayout@figure\figure
  \renewcommand{\figure}[1][]{\apalayout@figure[tbp]}}
\makeatother
]]

return {
  { Meta = function(meta)
      local mode = meta.documentmode and pandoc.utils.stringify(meta.documentmode) or "man"
      quarto.doc.include_text("in-header", needspace)
      if mode == "jou" then
        quarto.doc.include_text("in-header", jou_floats)
      end
    end },
}
