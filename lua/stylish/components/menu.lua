local api = vim.api

local ContextManager = require 'stylish.common.context'
local KeyHandler = require 'stylish.common.key_handler'
local Styles = require 'stylish.common.styles'
local Canvas = require 'stylish.common.canvas'
local MouseHandler = require 'stylish.common.mouse_hover_handler'
local Util = require 'stylish.common.util'

--
local XDOTOOL = Util.file_exists('/usr/bin/xdotool')

local function get_raw_menu(tbl, stack)
  local stack_idx
  for i = 1, #stack - 1 do
    stack_idx = stack[i].viewport.selected_idx
    tbl = tbl[stack_idx].submenus
  end
  return tbl
end

local function get_menu_items(tbl)
  local items = {}
  for i, item in ipairs(tbl) do
    items[i] = {
      name = item.name,
      has_submenus = item.submenus and true or false,
    }
  end
  return items
end

local function init_viewport(menu_items, max_visible_items)
  local total_items = #menu_items
  local total_visible_items = (total_items < max_visible_items) and total_items or max_visible_items
  return {
    items_visible = total_visible_items,
    items_above = 0,
    items_below = total_items - total_visible_items,
    selected_idx = 1,
    top_visible_idx = 1,
  }
end

local function get_viewport_row(row, num_items)
  local floor = math.floor
  -- print(row .. ':' ..col)
  local start_row = 4
  local idx = floor((row + 2 - start_row) / 2)
  return (idx > 0 and idx <= num_items) and idx or nil
end

local Menu = {}

Menu.__index = Menu
Menu.key_handler = KeyHandler.key_handler

function Menu:new(menu_data, opts, on_choice)
  local this = {}
  setmetatable(this, self)
  self.__index = self

  -- TODO: decide on window management strategy
  local current_winid = vim.api.nvim_get_current_win()
  local current_bufnr = vim.api.nvim_get_current_buf()

  if ContextManager.get(current_winid) then
    return
  end
  -- print(vim.inspect(opts))

  -- TODO: make ContextManager return menu_opts, or select_opts, or <widget>_opts
  this.config = ContextManager.config.opts
  -- TODO: move cursor to aucmd
  vim.cmd [[hi Cursor blend=100]]

  opts = opts or {}

  this.default_prompt = opts.prompt
  this.title = opts.prompt
  this.kind = opts.kind or 'default'
  this.experimental_mouse = (XDOTOOL and opts.experimental_mouse)

  local screenrow = opts.position and opts.position.screenrow
  local screencol = opts.position and opts.position.screencol
  -- TODO: validate menu_data
  this._menu_data = menu_data

  local canvas_config = {
    win_opts = {
      height = 1,
      width = 1,
      row = screenrow or -1,
      col = screencol or -1,
      -- relative = (opts.position) and 'editor' or 'cursor',
      relative = 'editor',
      bufpos = (not opts.position) and { 0, 0 },
      focusable = true,
    },
    focus_window = true,
    win_settings = { { 'winhighlight', 'Normal:PopupNormal' } },
  }

  this.canvas = Canvas:new(canvas_config)
  this.nsid = vim.api.nvim_create_namespace(('stylish_menu_%d'):format(this.canvas.winid))
  this.active_style = Styles.default
  this.on_choice = on_choice

  local items = get_menu_items(this._menu_data)
  local viewport = init_viewport(items, this.config.max_visible_items)
  this.stack = {
    { title = 'Menu Root', items = items, viewport = viewport },
  }

  --
  this:update()

  -- print(vim.inspect(ContextManager.config.keymap))
  -- TODO: Config table needs to be avail here
  local key_config = ContextManager.config.keymap
  KeyHandler.set_keymap(this.canvas.winid, this.canvas.bufnr, key_config)

  local function mouse_hover_callback(row, col)
    local vp = this.stack[#this.stack].viewport
    local total_items = vp.items_visible
    local viewport_idx = get_viewport_row(row, total_items)

    local back_button = { start_col = 2, end_col = 3 } -- TODO:set from style
    local back_button_hover_state = ((col >= back_button.start_col) and (col <= back_button.end_col))
    -- TODO: don't update if viewport state didn't change

    if (viewport_idx ~= vp.select_idx) or (back_button_hover_state ~= vp.back_button_hover_state) then
      if viewport_idx then
        local idx = vp.top_visible_idx + viewport_idx - 1
        vp.selected_idx = idx
      end
      vp.back_button_hover_state = back_button_hover_state
      this:update()
    end
  end

  -- make sure the mouse pointer is within the neovim window,
  -- otherwise chaos when mousedown hack is enabled

    local mouse_config = ContextManager.config.mousemap
    KeyHandler.set_keymap(this.canvas.winid, this.canvas.bufnr, mouse_config)
  if this.experimental_mouse then
    local nvim_x11_winid = os.getenv 'WINDOWID'
    local win_info = vim.fn.system('xwininfo -id ' .. nvim_x11_winid)

    local dims = {
      x = tonumber(win_info:match 'Absolute upper%-left X:%s*(%d+)'),
      y = tonumber(win_info:match 'Absolute upper%-left Y:%s*(%d+)'),
      width = tonumber(win_info:match 'Width:%s+(%d+)'),
      height = tonumber(win_info:match 'Height:%s+(%d+)'),
    }

    local mouse_pos = vim.fn.system 'xdotool getmouselocation'
    local mouse_x, mouse_y
    mouse_x = tonumber(mouse_pos:match 'x:(%d+)')
    mouse_y = tonumber(mouse_pos:match 'y:(%d+)')
    if not Util.is_in_rectangle(dims.x, dims.y, dims.x + dims.width, dims.y + dims.height, mouse_x, mouse_y) then
      local reset_mouse = ('xdotool mousemove --window 0x%x 0 0'):format(nvim_x11_winid)
      os.execute(reset_mouse)
    end

    this.mouse_hover_handler = MouseHandler:new(this.canvas.winid, mouse_hover_callback)
    this.mouse_hover_handler:start()
  end

  -- store the popup details in the registry
  ContextManager.add(this)

  return this
end

--
--
--
function Menu:set_styled_labels()
  local active_menu = self.stack[#self.stack]
  local viewport = active_menu.viewport
  local total_items = #active_menu.items
  -- TODO: use/reuse extmark IDs

  local function set_extmark(row, col, chunks, mark_id)
    local nvim_buf_set_extmark = vim.api.nvim_buf_set_extmark
    mark_id = nvim_buf_set_extmark(
      self.canvas.bufnr,
      self.canvas.nsid,
      row,
      0,
      { id = mark_id, virt_text = chunks, virt_text_pos = 'overlay', virt_text_win_col = col }
    )
    return mark_id
  end

  -- back indicator and title
  local back_indicator = self.active_style.symbols.MENU_BACK
  if active_menu.title then
    local chunks
    local back_marker = #self.stack > 1 and back_indicator or (' '):rep(vim.api.nvim_strwidth(back_indicator))
    local back_marker_hl = viewport.back_button_hover_state and 'MenuBackIndicatorActive' or 'MenuBackIndicatorInactive'
    chunks = { { back_marker, back_marker_hl } }
    set_extmark(1, 1, chunks)

    --
    local title_hl = 'PopupTitle'
    chunks = { { active_menu.title, title_hl } }
    set_extmark(1, 3, chunks)
  end

  -- scroll indicators
  local overflow_top = viewport.items_above > 0
  local overflow_bot = viewport.items_below > 0
  if overflow_top or overflow_bot then
    -- item count
    local count_msg = ('%d/%d'):format(viewport.selected_idx, total_items)
    local chunks = { { count_msg, 'ScrollIndicatorActive' } }
    local col = self.canvas.width - vim.api.nvim_strwidth(count_msg) - 1
    set_extmark(2, col, chunks)

    --

    local scroll_indicator_hl_top = overflow_top and 'ScrollIndicatorActive' or 'MenuBackIndicator'
    local scroll_indicator_hl_bot = overflow_bot and 'ScrollIndicatorActive' or 'MenuBackIndicator'
    -- TODO: put markers in styles
    local marker_char_top = ''
    local marker_char_bot = '  '

    -- local padding = 1

    local marker_len = vim.api.nvim_strwidth(marker_char_top)
    col = math.floor(self.canvas.width / 2) - marker_len

    chunks = { { marker_char_top, scroll_indicator_hl_top } }
    set_extmark(2, col, chunks)

    chunks = { { marker_char_bot, scroll_indicator_hl_bot } }
    set_extmark(16, col, chunks)
  end

  -- list items
  local item_is_active, item_is_selected
  local submenu_indicator_hl, submenu_indicator_icon -- TODO: move to styles
  local row, message, message_hl

  local extmark_ids = {}
  local entry_extmarks -- ???

  -- local row_offset = self.title and 1 or 0
  local row_offset = 1

  local idx_start, idx_end
  if total_items > self.viewport.items_visible then
    row_offset = row_offset + 1
  end

  idx_start = active_menu.viewport.top_visible_idx
  local virt_idx_end = idx_start + self.viewport.items_visible - 1
  idx_end = math.min(virt_idx_end, total_items)

  local display_count = 1
  for i = idx_start, idx_end do
    row = row_offset + (display_count * 2)

    -- print(i)
    entry_extmarks = extmark_ids[i] or {}
    item_is_active = i == active_menu.viewport.selected_idx
    message = active_menu.items[i].name
    message_hl = item_is_selected and 'ItemTextSelected' or item_is_active and 'ItemTextActive' or 'ItemTextInactive'

    -- row = ((active_menu.viewport.top_visible_idx - i) * 2) + row_offset

    --
    if item_is_active then
      local chunks = { { '▎', 'ItemIndicatorSelected' } }
      -- entry_extmarks.active_indicator = nvim_buf_set_extmark(bufnr, nsid, row, 0, {
      set_extmark(row, 1, chunks)
    end

    -- entry_extmarks.message_text = nvim_buf_set_extmark(bufnr, nsid, row, 0, {
    local chunks = { { message, message_hl } }
    set_extmark(row, 3, chunks)

    if active_menu.items[i].has_submenus then
      submenu_indicator_hl = item_is_active and 'SubmenuIndicatorActive' or 'SubmenuIndicator'
      submenu_indicator_icon = self.active_style.symbols.HAS_SUBMENU

      -- extmark_ids.submenu_indicator = nvim_buf_set_extmark(bufnr, nsid, row, 0, {
      local col = self.canvas.width - 3
      chunks = { { submenu_indicator_icon, submenu_indicator_hl } }
      set_extmark(row, col, chunks)
    end

    extmark_ids[i] = entry_extmarks
    display_count = display_count + 1
  end
end

--
--
--

function Menu:set_styled_base() -- TODO: rename this, it sents content based on items/size; it doesn't style anything
  local nvim_buf_set_lines = vim.api.nvim_buf_set_lines
  local active_menu = self.stack[#self.stack]
  local content_lines = self.active_style.apply(self.canvas.width, #active_menu.items, self.viewport.items_visible)
  nvim_buf_set_lines(self.canvas.bufnr, 0, -1, false, content_lines)
end

--
function Menu:clear_styled_labels()
  local nvim_buf_clear_namespace = vim.api.nvim_buf_clear_namespace
  nvim_buf_clear_namespace(self.canvas.bufnr, self.canvas.nsid, 0, -1)
end

--
function Menu:clear_styled_base()
  local nvim_buf_set_lines = vim.api.nvim_buf_set_lines
  nvim_buf_set_lines(self.canvas.bufnr, 0, -1, false, {})
end

--
-- TODO: make this a Menu:func() so we don't have to pass vars? or keep this simple way of private funcs?
-- resize popup window to contain updated content
function Menu:_resize_window()
  local nvim_strwidth = vim.api.nvim_strwidth

  local active_menu = self.stack[#self.stack]
  self.viewport = init_viewport(active_menu.items, self.config.max_visible_items)

  -- TODO: use config and style data for title_height, padding and border
  local title_height = 2
  local padding = 1
  local border = 1

  --
  local longest_len = self.config.min_width
  local item_len
  for _, item in ipairs(active_menu.items) do
    item_len = nvim_strwidth(item.name)
    if item_len > longest_len then
      longest_len = item_len
    end
  end

  local scroll_marker_height = #active_menu.items > self.viewport.items_visible and 2 or 0

  local win_width = longest_len + 6
  win_width = win_width + (2 * padding) + 2 -- TODO: make borders/padding configurable? (or set per theme)
  local win_height = (self.viewport.items_visible * 2) + title_height + padding + border + scroll_marker_height

  -- TODO: prefer odd numbers for winsize.width, so that overflow indicator is correctly centered
  self.canvas.width = win_width
  self.canvas.height = win_height
  api.nvim_win_set_config(self.canvas.winid, { width = self.canvas.width, height = self.canvas.height })
  -- print( self.canvas.width .. ' x ' .. self.canvas.height )
end

-- Update 'mono-menu'
function Menu:_redraw_display()
  self:clear_styled_labels()
  self:clear_styled_base()

  self:set_styled_base()
  self:set_styled_labels()
end

function Menu:update()
  -- TODO: reset mouse_hover_handler

  self:_resize_window()
  self:_redraw_display()
end
--

function Menu:close(event)
  -- TODO: which objects need setting to nil for GC?
  if self.mouse_hover_handler then
    self.mouse_hover_handler:stop()
  end

  local nvim_buf_clear_namespace = vim.api.nvim_buf_clear_namespace
  local nvim_buf_delete = vim.api.nvim_buf_delete

  nvim_buf_clear_namespace(self.canvas.bufnr, self.canvas.nsid, 0, -1)
  nvim_buf_delete(self.canvas.bufnr, { force = true })

  ContextManager.remove(self.canvas.winid)
  vim.api.nvim_command 'hi! Cursor blend=0'
end

--

Menu.actions = {}

-- TODO: this should be usable by ui.select!
function Menu.actions:change_selection(direction, context)
  context = self.stack and self or context
  local loop_selection = context.config.loop_selection

  if context.viewport.items_visible <= 1 then
    return
  end

  -- TODO: this is still a mess
  local active_menu = context.stack[#context.stack]
  local viewport = active_menu.viewport

  local new_selection_idx = viewport.selected_idx + direction
  local new_top_visible_idx = viewport.top_visible_idx
  local total_items = #active_menu.items

  local bot_visible_idx

  if (new_selection_idx < 1) or (new_selection_idx > total_items) then
    -- wrap round or stop
    if direction == 1 then
      new_selection_idx = loop_selection and 1 or total_items
      new_top_visible_idx = loop_selection and 1 or active_menu.viewport.top_visible_idx
    else
      new_selection_idx = loop_selection and total_items or 1
      new_top_visible_idx = loop_selection and (total_items + 1 - viewport.items_visible) or 1
    end
  else
    -- move selection and scroll in [direction]
    bot_visible_idx = (viewport.top_visible_idx + viewport.items_visible - 1)
    if direction == 1 and (new_selection_idx > bot_visible_idx) then
      new_top_visible_idx = viewport.top_visible_idx + 1
    elseif (viewport.top_visible_idx > 1) and (new_selection_idx < viewport.top_visible_idx) then
      new_top_visible_idx = viewport.top_visible_idx - 1
    end
  end

  -- update viewport
  viewport.selected_idx = new_selection_idx
  viewport.top_visible_idx = new_top_visible_idx
  viewport.items_above = new_top_visible_idx - 1
  viewport.items_below = total_items - (new_top_visible_idx + viewport.items_visible - 1)

  context:_redraw_display()
end

--TODO: this is for ui.select!
-- function Menu.actions:toggle_selection(context, direction)
--   local active = context.canvased_items[context.active_list_idx]
--   if not active.is_loaded and (direction == 1 or (direction == -1 and active.is_selected == true)) then
--     context.canvased_items[context.active_list_idx].is_selected = not active.is_selected
--   end
--   Menu.actions:change_selection(context.canvas.winid, direction)
-- end

function Menu.actions:accept_selection(context)
  context = self.stack and self or context

  local raw_menu = get_raw_menu(context._menu_data, context.stack)
  local viewport = context.stack[#context.stack].viewport
  local selected_item = raw_menu[viewport.selected_idx]
  -- print(vim.inspect(selected_item))
  if selected_item.submenus then
    -- TODO: create add_stack method
    local submenu_items = get_menu_items(selected_item.submenus)
    context.stack[#context.stack + 1] = {
      title = selected_item.name,
      items = submenu_items,
      viewport = init_viewport(submenu_items, context.config.max_visible_items),
    }
    context:update()
  else
    local nvim_get_mode = vim.api.nvim_get_mode
    local mode = nvim_get_mode().mode
    local rhs = selected_item.mappings[mode].rhs
    context:close 'menu_accept'
    print(rhs)
    -- return via callback
    context.on_choice(rhs)
  end
end

function Menu.actions:back(context)
  context = self.stack and self or context
  if #context.stack > 1 then
    table.remove(context.stack, #context.stack)
    context:update()
  end
end

function Menu.actions:close_window()
  self:close 'keypress'
end

-- TODO: do this in key/mouse handler
function Menu.actions:mouse_select()
  local title_column = 2 -- TODO: set from style
  local back_button = { start_col = 2, end_col = 3 } -- set from style
  local mouse_click = vim.fn.getmousepos()
  if mouse_click.winid == self.canvas.winid then
    local context = self.stack[#self.stack]
    local item_idx = get_viewport_row(mouse_click.winrow, #context.items)

    -- TODO: clean up this logic
    if self.experimental_mouse and item_idx then
      Menu.actions:accept_selection(self) -- FIX: Argh!.. this sending the context nonsense
    elseif
      self.experimental_mouse and
      mouse_click.winrow == title_column
      and (mouse_click.wincol >= back_button.start_col)
      and (mouse_click.wincol <= back_button.end_col)
    then
      self.actions:back(self)
    else
      self.is_dragging = true --
      self.drag_anchor_pos = { row = mouse_click.screenrow, col = mouse_click.screencol }
    end
  else
    self:close()
  end
end

function Menu.actions:mouse_drag()
  local win_set_config = vim.api.nvim_win_set_config
  local getmousepos = vim.fn.getmousepos
  local click_pos = getmousepos()

  if self.is_dragging then
    -- print(vim.inspect(self.drag_anchor_pos))
    local row_offset = click_pos.screenrow - self.drag_anchor_pos.row
    local col_offset = click_pos.screencol - self.drag_anchor_pos.col
    -- print(row_offset, col_offset)
    -- print('canvas.screenpos')
    -- print(vim.inspect(self.canvas.screenpos))
    local new_wincfg = {
      relative = 'editor',
      row = self.canvas.screenpos.row + row_offset,
      col = self.canvas.screenpos.col + col_offset,
    }
    -- print(vim.inspect(new_wincfg))
    win_set_config(self.canvas.winid, new_wincfg)
    self.canvas.screenpos.row = new_wincfg.row
    self.canvas.screenpos.col = new_wincfg.col
    self.drag_anchor_pos.row = click_pos.screenrow
    self.drag_anchor_pos.col = click_pos.screencol
  end
end

function Menu.actions:mouse_release()
  if self.is_dragging then
    self.is_dragging = false
    self.drag_anchor_pos = {}
  end
end

function Menu.actions:mouse_scroll_up()
  self.actions:change_selection(-1, self)
end

function Menu.actions:mouse_scroll_down()
  self.actions:change_selection(1, self)
end

function Menu.actions:nop()
  --
end

return Menu
