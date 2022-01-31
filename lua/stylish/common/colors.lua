local api = vim.api
local utils = require 'stylish.common.util'

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

DEFAULT_BG = 1710618

local hl_groups = {}
hl_groups.menu = {
  PopupNormal = { fg = palette.grey_2, bg = palette.grey_1 },
  PopupTitle = { fg = palette.grey_4 },
  PopupTitleSubmenu = { fg = palette.green_light },
  MenuBackIndicatorInactive = { fg = palette.grey_3 },
  MenuBackIndicatorActive = { fg = palette.green_light },
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

--
local function rgb_split(hex_color)
  return {
    r = tonumber("0x" .. hex_color:sub(1, 2)),
    g = tonumber("0x" .. hex_color:sub(3, 4)),
    b = tonumber("0x" .. hex_color:sub(5, 6)),
  }
end

local function lerp_color_gradient(color_1, color_2, interp)
  local floor = math.floor
  local lerp = utils.lerp

  local color_1_rgb = rgb_split(color_1:sub(2, -1))
  local color_2_rgb = rgb_split(color_2:sub(2, -1))

  local r = floor(lerp(color_1_rgb.r, color_2_rgb.r, interp))
  local g = floor(lerp(color_1_rgb.g, color_2_rgb.g, interp))
  local b = floor(lerp(color_1_rgb.b, color_2_rgb.b, interp))

  return ("#%02x%02x%02x"):format(r, g, b)
end


local function rgb_to_hex(color)
  local i = color.r
  i = bit.lshift(i, 8) + color.g
  i = bit.lshift(i, 8) + color.b
  return ("#%06x"):format(i)
end

-- TODO: why two gradient methods...
Colors.create_gradient = function(hl_start, hl_end, steps)
  local lerp = utils.lerp
  local gradient = {}
  for i=0, steps-1 do
    local step_color = {}
    local offset = (1/(steps-1)) * i
    for _, c in pairs({'r', 'g' , 'b'}) do
      step_color[c] = lerp(hl_start[c], hl_end[c], offset)
    end
    gradient[i+1] = rgb_to_hex(step_color)
  end

  return gradient
end
--
function Colors.setup()
  -- local nvim_set_hl = vim.api.nvim_set_hl
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

local function hexstring_to_int(hexstr)
  return (tonumber(hexstr, 16) + 2^31) % 2^32 - 2^31
end

function Colors.create_gradient_map(prefix, color_name, palette, max_brightness)
  -- get the user set background color
  local bg_val = api.nvim_get_hl_by_name("Normal", true).background or DEFAULT_BG
  print(vim.inspect(bg_val))
  local user_background = ("#%06x"):format(bg_val)

  --
  local hl_groups = {}
  hl_groups.fg = {}
  hl_groups.bg = {}
  local group_name, color_hexstr
  for color_idx, base_color_hexstr in ipairs(palette) do
    base_color_hexstr = (base_color_hexstr == "background") and user_background or base_color_hexstr

    for _, attr in pairs { "fg", "bg" } do
      hl_groups[attr][color_idx] = {}

      -- create a highlight for each brightness level
      for brightness_level = 1, max_brightness do
        color_hexstr = lerp_color_gradient(user_background, base_color_hexstr, (1/ max_brightness) * brightness_level)

        group_name = ("%s_%s_%s%d_%d"):format(prefix, attr, color_name, color_idx, brightness_level)
        vim.cmd(("hi! %s gui%s=%s"):format(group_name, attr, color_hexstr))

        -- store the hl id
        hl_groups[attr][color_idx][brightness_level] = vim.api.nvim_get_hl_id_by_name(group_name)
      end
    end
  end

  return hl_groups
end

return Colors
