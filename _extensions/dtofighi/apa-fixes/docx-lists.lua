-- docx only. Pandoc writes a tight list's items in Word's single-spaced
-- Compact style, so a tight list comes out cramped beside the double-spaced
-- body and any loose list.
-- Loosen every list (Plain -> Para) so its items take the manuscript's
-- double-spaced body style, as APA asks. The PDF builds are unaffected.
if FORMAT ~= "docx" then return {} end

local function loosen(list)
  list.content = list.content:map(function(item)
    return item:map(function(block)
      if block.t == "Plain" then return pandoc.Para(block.content) end
      return block
    end)
  end)
  return list
end

return {
  { OrderedList = loosen, BulletList = loosen }
}
