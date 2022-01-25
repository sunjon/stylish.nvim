local Colors = {}

local palette = {
  green_light = '#8ec07c',
  orange_light = '#e0b828',
  background = '#1a1a1a',
  grey_1 = '#222124',
  grey_2 = '#323134',
  grey_3 = '#68645e',
  grey_4 = '#ac9e8a',
  grey_5 = '#eddeb8',
  grey_6 = '#bdae92',
}

-- local function hextobin(hex)
--   hex = hex:gsub('^#', '')
--   return tonumber(hex, 16)
-- end
-- -- convert hex vals to bin
-- for i, color in pairs(palette) do
--   palette[i] = hextobin(color)
-- end
-- print(vim.inspect(palette))

local hl_groups = {}
hl_groups.menu = {
  PopupNormal = { fg = palette.grey_2, bg = palette.grey_1 },
  PopupTitle = { fg = palette.grey_4 },
  PopupTitleSubmenu = { fg = palette.green_light },
  MenuBackIndicator = { fg = palette.grey_3 },
  ItemIndicatorInactive = { fg = palette.grey_1, bg = palette.grey_2 },
  ItemIndicatorActive = { fg = palette.green_light, bg = palette.grey_3 },
  ItemIndicatorSelected = { fg = palette.orange_light, bg = palette.grey_2 },
  ItemIndicatorNotSelected = { fg = palette.grey_1, bg = palette.grey_2 },
  -- ItemTextActive = { fg = palette.green_light, bg = palette.grey_2 },
  ItemTextActive = { fg = palette.grey_5, bg = palette.grey_2 },
  ItemTextInactive = { fg = palette.grey_3, bg = palette.grey_2 },
  ItemTextSelected = { fg = palette.orange_light, bg = palette.grey_2 },
  ScrollIndicatorActive = { fg = palette.grey_4 },
  SubmenuIndicator = { fg = palette.grey_1, bg = palette.grey_2 },
  SubmenuIndicatorActive = { fg = palette.grey_4, bg = palette.grey_2 },
  ToggleButton = { fg = palette.grey_6, bg = palette.grey_2 },
  ToggleButtonInner = { fg = palette.grey_6, bg = palette.background },
  ToggleButtonEdge = { fg = palette.background, bg = palette.grey_2 },
  ToggleButtonSelector = { fg = palette.grey_5, bg = palette.grey_1 },
}

function Colors.setup()
  local nvim_set_hl = vim.api.nvim_set_hl
  Colors.nsid = vim.api.nvim_create_namespace 'fooey'

  -- create_hl_groups()

  -- for group, attrs in pairs(hl_groups.menu) do
  --   local cmd = ('nvim_set_hl(%d, "%s", %s)'):format(Colors.nsid, group, type(attrs))
  --   nvim_set_hl(Colors.nsid, group, attrs)
  --   print(cmd)
  --   print(vim.inspect(attrs))
  -- end
  local cmd, fg, bg
  for group, attrs in pairs(hl_groups.menu) do
    fg = attrs.fg and ('guifg=%s'):format(attrs.fg) or ''
    bg = attrs.bg and ('guibg=%s'):format(attrs.bg) or ''
    cmd = ('hi! %s %s %s'):format(group, fg, bg)
    vim.cmd(cmd)
  end
end

return Colors
