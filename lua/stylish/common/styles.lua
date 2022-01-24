local Util = require 'stylish.common.util'

local float_border = {
  top = '▔',
  right = '▕',
  bot = '▁',
  left = '▏',
  top_left = '🭽',
  top_right = '🭾',
  bot_left = '🭼',
  bot_right = '🭿',
}

local ascii = {
  SPACE = ' ',
  FULL_BLOCK = '█',
  LEFT_HALF_BLOCK = '▌',
  RIGHT_HALF_BLOCK = '▐',
  LOWER_THIRD = '🬭',
  UPPER_THIRD = '🬂',
  SPLIT_THIRD = '🬰',
  -- ITEM_ACTIVE = "►",
  -- ITEM_INACTIVE = "►",
  ITEM_ACTIVE = '❯',
  ITEM_INACTIVE = '❯',
  ITEM_LOADED = '━',
  -- MENU_BACK = 'ﰯ',
  MENU_BACK = '◄',
  -- MENU_BACK = '',
  -- MENU_BACK = "🬋",
  HAS_SUBMENU = '',
  MENU_OVERFLOW_UP = '',
  MENU_OVERFLOW_DOWN = '',
  -- MENU_OVERFLOW_UP = '',
  -- MENU_OVERFLOW_DOWN = '',
  foo = '',
  -- MENU_BACK = '',
  -- ITEM_LOADED = '',
  -- ITEM_LOADED = '',
  -- ITEM_LOADED = '',
  -- ITEM_LOADED = '⏽',
  -- ITEM_LOADED = '樂',
  -- ITEM_LOADED = '',
}
-- local toggle_widget = { {' ', 'ToggleButton'},  {'', 'ToggleButtonInner' }, {'█', 'ToggleButtonEdge' } }

--TODO: this function is pretty worthless!
-- local function horizontal_pad(str, n)
--   n = n or 1
--   local pad = (' '):rep(n)
--   return ('%s%s%s'):format(pad, str, pad)
-- end

local function add_inner_border(str, chars)
  chars = chars or { left = float_border.left, right = float_border.right }
  return ('%s%s%s'):format(chars.left, str, chars.right)
end

-- local Styles = {}

-- Styles.default = {
  -- format_top_border = function(width)
  --   local line = float_border.top:rep(width)
  --   -- line = add_inner_border(line, {left=float_border.top_left, right=float_border.top_right})
  --   line = add_inner_border(line, {left=float_border.top_left, right=float_border.top_right})
  --   return { line }
  -- end,
  -- format_title = function(width)
  --   --TODO: better way of compiling styles
  --   local blank_line = ascii.SPACE:rep(width)
  --   blank_line = add_inner_border(blank_line)
  --   return {
  --     blank_line,
  --   }
  -- end,
  -- format_scroll_indicator = function(width)
  --   local indicator_line = (' '):rep(width)
  --   indicator_line = add_inner_border(indicator_line)
  --   return { indicator_line }
  -- end,
  -- format_list_pre = function(width)
  -- local line = ascii.LOWER_THIRD:rep(width)
  -- line = add_inner_border(line)
  -- return { line }
  -- end,
  -- format_list_item = function(width)
  --   local line_1 = ascii.FULL_BLOCK:rep(width)
  --   local line_2 = ascii.SPLIT_THIRD:rep(width)
  --   line_1 = add_inner_border(line_1)
  --   line_2 = add_inner_border(line_2)

  --   return {
  --     line_1,
  --     line_2,
  --   }
  -- end,
  -- format_list_post = function(width)
  --   -- complete last item
  --   local line_1 = ascii.FULL_BLOCK:rep(width)
  --   local line_2 = ascii.UPPER_THIRD:rep(width)

  --   line_1 = add_inner_border(line_1)
  --   line_2 = add_inner_border(line_2)

  --   return {
  --     line_1,
  --     line_2,
  --   }
  -- end,

  -- format_bottom_border = function(width)
  --   local line = float_border.bot:rep(width)
  --   line = add_inner_border(line, { left = float_border.bot_left, right = float_border.bot_right })
  --   return { line }
  -- end,

local Styles = {}
Styles.default = {}

Styles.default.symbols = {
  ITEM_ACTIVE = ascii.ITEM_ACTIVE,
  ITEM_INACTIVE = ascii.ITEM_INACTIVE,
  ITEM_LOADED = ascii.ITEM_LOADED,
  MENU_BACK = ascii.MENU_BACK,
  HAS_SUBMENU = ascii.HAS_SUBMENU,
}

Styles.default.apply = function(width, total_items, max_display_items)
  local table_join = Util.table_join

  -- width = width- self.window.padding
  width = width- 2
  -- local padding = 1

  local content_lines = {}

  -- top border
  local top_border = float_border.top:rep(width)
  top_border = add_inner_border(top_border, { left = float_border.top_left, right = float_border.top_right })
  content_lines = table_join(content_lines, {top_border})
  -- print(vim.inspect(content_lines))
  -- print("------------------")

  -- title box
  local blank_line = ascii.SPACE:rep(width)
  blank_line = add_inner_border(blank_line)
  content_lines = table_join(content_lines, {blank_line})

  -- scroll indicator
  if total_items > max_display_items then
    local indicator_line = (' '):rep(width)
    indicator_line = add_inner_border(indicator_line)
    content_lines = table_join(content_lines, {indicator_line})
  end

  -- start of first item
  local first_item_header = ascii.LOWER_THIRD:rep(width)
  first_item_header = add_inner_border(first_item_header)
  content_lines = table_join(content_lines, {first_item_header})

  -- item boxes
  for _ = 1, max_display_items - 1 do
    local line_1 = ascii.FULL_BLOCK:rep(width)
    local line_2 = ascii.SPLIT_THIRD:rep(width)
    line_1 = add_inner_border(line_1)
    line_2 = add_inner_border(line_2)

    content_lines = table_join(content_lines, { line_1, line_2 })
  end

  -- remainder of bottom item
  local line_1 = ascii.FULL_BLOCK:rep(width)
  local line_2 = ascii.UPPER_THIRD:rep(width)

  line_1 = add_inner_border(line_1)
  line_2 = add_inner_border(line_2)

  content_lines = table_join(content_lines, { line_1, line_2 })
  -- styled_lines = self.selected_style.format_list_post(width)
  -- content_lines = table_join(content_lines, styled_lines)

  -- bottom scroll indicator
  if total_items > max_display_items then
    local indicator_line = (' '):rep(width)
    indicator_line = add_inner_border(indicator_line)
    content_lines = table_join(content_lines, {indicator_line})
  end

  --   styled_lines = self.selected_style.format_scroll_indicator(width, true)
  --   content_lines = table_join(content_lines, styled_lines)

  -- bottom border
  local line = float_border.bot:rep(width)
  line = add_inner_border(line, { left = float_border.bot_left, right = float_border.bot_right })
  content_lines = table_join(content_lines, {line})

  return content_lines
end

function Styles.foo()
end

return Styles
