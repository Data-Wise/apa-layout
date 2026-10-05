-- docx only; must run at post-render, after apaquarto's docxlayout.lua. docxlayout.lua gives every table inside a FigureWithNote /
-- FigureWithoutNote float the borderless FigureLayout style, meant for the
-- layout table of a multipanel figure; data tables get caught too and lose the
-- APA rules of the reference document's Table style. Return any FigureLayout
-- table that holds no image to the default Table style.
if FORMAT ~= "docx" then return {} end

function Table(tbl)
  if tbl.attributes["custom-style"] ~= "FigureLayout" then return nil end
  local has_image = false
  tbl:walk {
    Image = function() has_image = true end,
    Figure = function() has_image = true end,
  }
  if has_image then return nil end
  tbl.attributes["custom-style"] = nil
  return tbl
end
