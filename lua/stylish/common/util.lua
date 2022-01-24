local Util = {}

function Util.table_join(a, b)
  for i = 1, #b do
    a[#a + 1] = b[i]
  end
  return a
end
--
function Util.center_text(str, width)
  local pad_width = (width - #str) / 2
  local left_pad = (' '):rep(pad_width)
  return string.format('%s%s', left_pad, str)
end

return Util
