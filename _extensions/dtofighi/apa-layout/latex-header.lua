-- LaTeX (apaquarto-pdf), jou always, man on request. floatsintext makes apaquarto set every
-- figure and in-flow table [H] (floatlatex.lua). In two columns an [H] float
-- that does not fit the rest of a column jumps to the next one and leaves a
-- blank pocket (jou columns are flush-bottom, so the space is spread inside the
-- column); let figures and tables float [tbp] instead. A float
-- that asks to span both columns (apa-twocolumn) is a starred environment with
-- its own placement and is untouched. Wrapped in \AtBeginDocument so it does
-- not matter where Quarto places this text relative to apaquarto's template.
--
-- Only [H] (what floatsintext sets) and an empty placement are rewritten; any
-- other placement is kept. apaquarto sets the author/correspondence note as a
-- \begin{figure}[b] float so it lands at the foot of the first column, and
-- rewriting every placement to [tbp] floated it to the top, under the abstract.
--
-- man keeps [H] unless the document sets `apa-layout: {man-floats: true}`. An
-- [H] figure taller than the rest of a man page moves to the next page and
-- leaves the rest of this one blank; with the option, man figures and tables
-- float [!htbp], so they stay where they are when they fit and text fills the
-- page when they do not. In-flow man tables are not `table` environments;
-- man-floats.lua floats the ones that are a single box.
--
-- Retired in 0.2.0, fixed upstream in apaquarto v7.0.0 (2026-10-06): the
-- \Needspace before in-flow table titles (apaquarto#170). Its stated cause was
-- wrong: the stranded title came from longtable's \LT@start, which checks
-- whether the head, first row and foot fit on the rest of the page and forces a
-- page break if not, after the title and caption are already set.

if not quarto.doc.is_format("latex") then return {} end

-- The figure and table redefinitions, with [H] and an empty placement
-- rewritten to `pl`.
local function float_block(pl)
  return ([[
\makeatletter
\AtBeginDocument{%
  \def\apalayout@H{H}%
  \let\apalayout@figure\figure
  \renewcommand{\figure}[1][]{%
    \def\apalayout@pl{#1}%
    \ifx\apalayout@pl\apalayout@H \apalayout@figure[PL]%
    \else\ifx\apalayout@pl\@empty \apalayout@figure[PL]%
    \else \apalayout@figure[#1]\fi\fi}%
  \let\apalayout@table\table
  \renewcommand{\table}[1][]{%
    \def\apalayout@pl{#1}%
    \ifx\apalayout@pl\apalayout@H \apalayout@table[PL]%
    \else\ifx\apalayout@pl\@empty \apalayout@table[PL]%
    \else \apalayout@table[#1]\fi\fi}}
\makeatother
]]):gsub("PL", pl)
end

-- true when the document sets apa-layout: {man-floats: true}
local function man_floats_on(meta)
  local opts = meta["apa-layout"]
  if type(opts) ~= "table" or opts["man-floats"] == nil then return false end
  local v = opts["man-floats"]
  return v == true or pandoc.utils.stringify(v) == "true"
end

return {
  { Meta = function(meta)
      local mode = meta.documentmode and pandoc.utils.stringify(meta.documentmode) or "man"
      if mode == "jou" then
        quarto.doc.include_text("in-header", (float_block("tbp")))
      elseif mode == "man" and man_floats_on(meta) then
        quarto.doc.include_text("in-header", (float_block("!htbp")))
      end
    end },
}
