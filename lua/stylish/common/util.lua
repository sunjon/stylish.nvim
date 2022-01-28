local api = vim.api
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

function Util.lerp(v0, v1, t)
  return v0 * (1 - t) + v1 * t
end

-- TODO: this was the lerp used to create the color gradients in kraft notifications
local function lerp2(a, b, interp)
  return a + (b - a) * interp
end

function Util.extmark_create_batch(bufnr, nsid, n)
  local extmark_ids = {}
  for i = 1, n do
    extmark_ids[i] = api.nvim_buf_set_extmark(bufnr, nsid, i, 0, { virt_text_pos = 'overlay' })
  end

  return extmark_ids
end

function Util.get_time()
  local uv = vim.loop
  return uv.now() / 1000
end



return Util
