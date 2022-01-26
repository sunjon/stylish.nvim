local Colors = require 'stylish.common.colors'
local Data = require 'stylish.common.data_rle'
local Window = require 'stylish.common.window'
local Utils = require 'stylish.common.util'
local Styles = require 'stylish.common.styles'
local Timer = require 'stylish.common.timer'

local api = vim.api

-- TODO: find a home for all these vars
local UPDATE_INTERVAL = 1000 / 60 -- animation frame rate
local ANIMATION_FADE_IN_TIME = 0.16
local ANIMATION_BRIGHTNESS_STEPS = 8 -- defines the number of gradient Colors created

local FADE_ENABLED = true
local SHOW_BACKGROUND = true

local BORDER_CHARS = Styles.border_chars
local DEFAULT_TEXT_COLOR = 'yellow'
-- local DEFAULT_TEXT_COLOR = "green"

local CLOCK_TEXT_COLOR = {
  ['green'] = '#829673',
  ['red'] = '#db0013',
  ['yellow'] = '#EFB009',
  ['border'] = '#9A8D7F',
}

local TEXT_COLOR_PREFIX = ('Popup_%s_background'):format(DEFAULT_TEXT_COLOR)

local MASK_BLEND_LEVEL = 20

local FLOATWIN_WIDTH = 76
local FLOATWIN_HEIGHT = 7

-- TODO: move char_map to styles
local char_map = {
  [0] = ' ',
  [1] = '',
  [2] = '█',
  [3] = '',
}

-- TODO: fill_buffer should be a parameter on the window creation function
local filler = (' '):rep(FLOATWIN_WIDTH)
local FILLER_LINES = {}
for i = 1, FLOATWIN_HEIGHT do
  FILLER_LINES[i] = filler
end

local function textrow_to_chunks(row_values, row_len, hl_callback)
  local chunks = {}
  local chunk_virt_text, chunk_hl_group, cell_value, last_cell_value

  chunk_virt_text = ''
  for i = 1, #row_values + 1 do
    cell_value = row_values[i]

    if cell_value == last_cell_value then
      chunk_virt_text = chunk_virt_text .. char_map[cell_value]
    else
      if chunk_virt_text ~= '' then
        chunk_hl_group = hl_callback(last_cell_value)
        chunks[#chunks + 1] = { chunk_virt_text, chunk_hl_group }
      end

      last_cell_value = cell_value
      chunk_virt_text = char_map[cell_value]
    end
  end

  -- pad to row_len with zeros
  for _ = #row_values, row_len do
    chunks[#chunks + 1] = { ' ', hl_callback(0) }
  end

  return chunks
end

-- import font data
local function load_font()
  local file = 'clock_font.bin'
  local plugin_dir = vim.g.stylish_data_dir
  local filepath = ('%s%s'):format(plugin_dir, file)
  local font_data = Data.import_datafile(filepath)
  if not font_data then
    error('Error: unable to load logo data: ' .. filepath)
    return
  end
  return font_data
end

-- 'explodes' a string of numbers into a table of [0-9] values
local function str_decimal_explode(str)
  local res = {}
  for num in str:gmatch '%d' do
    res[#res + 1] = tonumber(num)
  end

  return res
end

--
local function create_line_indents()
  local res = {}
  for line = 1, 7 do -- TODO: replace hardcoded `7` with font height
    local row_indents = {}
    for i = 1, 4 + (FLOATWIN_HEIGHT - line) do
      row_indents[i] = 0
    end
    res[line] = row_indents
  end

  return res
end

-- TODO: make this a metamethod of the `clock_lines` table?
local function join_table_lines(table_a, table_b)
  for row, row_values in ipairs(table_b) do
    for _, val in ipairs(row_values) do
      table_a[row][#table_a[row] + 1] = val
    end
  end

  --   return table_a
end

-- blur background using box-blur algorithm
local function box_blur(grid_lines, animation_timer)
  local floor = math.floor

  local surrounding_cells = { { -1, 0 }, { -1, 1 }, { 0, 1 }, { 1, 1 }, { 1, 0 }, { 1, -1 }, { -1, -1 } }
  local elapsed_proportion = animation_timer and (animation_timer.elapsed / ANIMATION_FADE_IN_TIME) or 1
  -- print(elapsed_proportion)

  local blur_value, blur_average, blur_color_idx
  local blur_lines = {}
  for row = 2, #grid_lines - 1 do
    local blur_row = {}
    for col = 2, FLOATWIN_WIDTH - 1 do
      blur_average = 0
      for _, offset in ipairs(surrounding_cells) do
        blur_value = grid_lines[row + offset[1]][col + offset[2]] == 0 and 0 or 1
        blur_average = blur_average + blur_value
      end

      blur_average = blur_average / #surrounding_cells
      blur_color_idx = floor(Utils.lerp(12, 19, blur_average))

      -- taper left edge
      if col <= 2 then
        blur_color_idx = blur_color_idx + (3 - col)
      end
      -- annnd a bit off the top
      if row <= 4 then
        blur_color_idx = blur_color_idx + (5 - row)
      end

      blur_color_idx = (blur_color_idx > 19) and 19 or blur_color_idx -- limit:HACK

      -- fade-in animation
      if not (animation_timer == nil) then
        blur_color_idx = floor(Utils.lerp(19, blur_color_idx, elapsed_proportion))
      end

      blur_row[col] = blur_color_idx
    end

    blur_lines[#blur_lines + 1] = blur_row
  end

  return blur_lines
end

local function update_time_display(state)
  local buf_set_extmark = vim.schedule_wrap(api.nvim_buf_set_extmark)
  local buf_add_hl = vim.schedule_wrap(api.nvim_buf_add_highlight)
  local buf_clear_namespace = vim.schedule_wrap(api.nvim_buf_clear_namespace)

  local floor = math.floor
  local date = os.date
  local update_delta_time = Timer.update_delta_time
  local explode = str_decimal_explode

  local time_str = date '%H%M%S'

  -- don't update time matches already displayed, unless in animation phase
  if (time_str == state.last_displayed_time) and not state.animation_timer then
    return
  end

  -- UPDATE DISPLAY

  state.last_displayed_time = time_str
  local time_tbl = explode(time_str)

  -- set brightness if fading in/out
  local brightness
  if state.animation_timer and FADE_ENABLED then
    update_delta_time(state.animation_timer)
    local elapsed
    if state.animation_timer.elapsed > ANIMATION_FADE_IN_TIME then
      elapsed = ANIMATION_FADE_IN_TIME
      -- clear completed timers
      state.animation_timer = nil
    else
      elapsed = state.animation_timer.elapsed
    end
    brightness = floor(0.5 + Utils.lerp(1, ANIMATION_BRIGHTNESS_STEPS, elapsed / ANIMATION_FADE_IN_TIME))
  else
    brightness = ANIMATION_BRIGHTNESS_STEPS
  end
  -- print('brightness:' .. brightness)

  --
  if not state.animation_timer then
    buf_clear_namespace(state.display.bufnr, state.nsid, 0, -1)
    -- print('clear: ' .. os.clock())
  end

  -- print(vim.inspect(clock_lines))

  local font_data = state.font_data
  -- insert line indents in numerical form
  local clock_lines = create_line_indents()

  -- join font character tables
  local font_size, font_idx, str_idx
  for i = 1, 5, 2 do
    font_size = (i <= 3) and 'large' or 'small'
    if i > 1 then
      join_table_lines(clock_lines, font_data.separator[font_size])
    end

    for j = 0, 1 do
      str_idx = i + j
      font_idx = time_tbl[str_idx] == 0 and 10 or time_tbl[str_idx]
      join_table_lines(clock_lines, font_data[font_size][font_idx])
    end
  end

  if SHOW_BACKGROUND then
    -- apply blur highlighting to floatwin background
    local blur_lines = box_blur(clock_lines, state.animation_timer)
    -- local blur_lines = clock_lines
    local blur_val, hl_group
    for row = 1, #blur_lines do
      for col = 1, FLOATWIN_WIDTH do
        blur_val = blur_lines[row][col]
        hl_group = blur_val and TEXT_COLOR_PREFIX .. blur_val or ''
        buf_add_hl(state.display.bufnr, state.nsid, hl_group, row, col - 1, col)
      end
    end
  end

  -- convert array of integers to mapped character extmark-chunks
  local row_chunks, opts
  for row, row_values in ipairs(clock_lines) do
    row_chunks = textrow_to_chunks(row_values, FLOATWIN_WIDTH, function(val)
      return (val == 0)
          and (((SHOW_BACKGROUND and ((row == 1) or (row == FLOATWIN_HEIGHT))) or (not SHOW_BACKGROUND)) and 'WidgetClockMask' or state.hl_groups[brightness])
        or state.hl_groups[brightness]
    end)

    opts = {
      id = state.display.extmarks[row],
      virt_text = row_chunks,
      virt_text_pos = 'overlay',
      hl_mode = 'combine',
    }
    buf_set_extmark(state.display.bufnr, state.nsid, row - 1, 0, opts)
  end
end

--

local function init_window(nsid)
  -- create the floating window
  -- TODO: allow for preset clock positions
  local parent_win_width = vim.o.columns
  local clock_pos = { row = 2, col = parent_win_width - FLOATWIN_WIDTH - 2 }
  local floatwin = Window:new(FLOATWIN_WIDTH, FLOATWIN_HEIGHT, clock_pos, { border = BORDER_CHARS }, false)

  -- fill the buffer with characters for extmarks to overlay
  api.nvim_buf_set_lines(floatwin.bufnr, 0, FLOATWIN_HEIGHT - 1, false, FILLER_LINES)

  -- setup window decorations
  api.nvim_win_set_option(floatwin.winid, 'winhighlight', 'Normal:WidgetClockBackground')
  -- api.nvim_win_set_option(floatwin.winid, "winblend", 50) -- ?
  api.nvim_win_set_option(floatwin.winid, 'cursorline', false)

  local extmark_ids = Utils.extmark_create_batch(floatwin.bufnr, nsid, FLOATWIN_HEIGHT)

  return {
    winid = floatwin.winid,
    bufnr = floatwin.bufnr,
    extmarks = extmark_ids,
  }
end

--

local M = {}

function M.setup(self, user_config)
  user_config = user_config or {}

  local nsid = api.nvim_create_namespace 'WidgetClock'

  -- create highlight groups
  -- local user_color_valid = user_config.color and Colors.validate_hex_color(user_config.color)
  -- local color_hex_str = user_color_valid and user_config.color or TEXT_COLORS[DEFAULT_TEXT_COLOR]
  local color_hex_str = CLOCK_TEXT_COLOR.yellow

  local clock_hl_groups = Colors.create_gradient_map(
    'WidgetClock',
    'text',
    { color_hex_str },
    ANIMATION_BRIGHTNESS_STEPS
  ).fg[1]

  vim.cmd('hi! WidgetClockMask       guibg=background blend=' .. MASK_BLEND_LEVEL) -- NOTE: Masking blocks doesn't work at the same time as blur bg
  vim.cmd 'hi! WidgetClockBackground guibg=background blend=0'
  vim.cmd 'hi! WidgetClockBorder guifg=#544E4A guibg=background'

  local font_data = load_font()
  return {
    nsid = nsid,
    hl_groups = clock_hl_groups,
    font_data = font_data,
  }
end

function M.toggle(self)
  self.state = self.state or self.setup(self)

  if not self.state.display and not self.state.timer then
    self.state.display = init_window(self.state.nsid)

    self.state.animation_timer = {
      elapsed = 0,
      last_frame = Timer.get_time(),
    }

    self.state.timer = vim.loop.new_timer()
    -- TODO: need separate timer_interval for update_display and animations
    self.state.timer:start(0, UPDATE_INTERVAL, function()
      update_time_display(self.state)
    end)
  else
    self.state.timer:stop()
    self.state.timer = nil

    api.nvim_buf_clear_namespace(self.state.display.bufnr, self.state.nsid, 0, -1)
    api.nvim_win_close(self.state.display.winid, true)
    self.state.display = nil
  end
end

return M
