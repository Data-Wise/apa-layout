-- Typst-only math clean-up.
-- pandoc's texmath writes \bigl( etc. as a #scale(...) box that keeps the
-- unscaled width, leaving a visible gap inside the delimiter, and writes
-- \!\left( as #h(-0.167em) before an auto-sized paren, so the preceding symbol
-- (\Phi) collides with it. Typst sizes matched delimiters itself, so dropping
-- both is safe. \biggl/\biggr are left alone: they render correctly.
if FORMAT ~= "typst" then return {} end

function Math(el)
  local t = el.text
  t = t:gsub("\\[Bb]ig[lr]?(%A)", "%1")
  t = t:gsub("\\!%s*\\left", "\\left")
  el.text = t
  return el
end
