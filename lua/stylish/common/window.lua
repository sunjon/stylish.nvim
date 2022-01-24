local function set_autocmds(winid)
  -- TODO: `ModeChanged` doesn't detect Replace/Select modes
  vim.cmd('au! BufLeave,ModeChanged <buffer> lua require"stylish".event_listener(' .. winid .. ', "FocusLost")')
end

local Window = {}
Window.__index = Window

function Window:create(width, height, col, row, extra_opts)
  local this = {}
  setmetatable(this, self)
  self.__index = self

  local nvim_open_win = vim.api.nvim_open_win
  local nvim_create_buf = vim.api.nvim_create_buf

  local default_extra_opts = {
    { 'winhighlight', 'Normal:PopupNormal' },
    { 'winblend', 0 },
    { 'scrolloff', 999 },
  }

  -- TODO: extend defaults with user values
  extra_opts = extra_opts or default_extra_opts

  local padding = 2
  local window_opts = {}
  window_opts.relative = 'editor'
  window_opts.style = 'minimal'
  window_opts.focusable = false
  window_opts.border = 'shadow'
  window_opts.row = row
  window_opts.col = col
  window_opts.width = width
  window_opts.height = height

  -- create the window
  local focus_window = true
  local bufnr = nvim_create_buf(false, true)
  this = {
    id = nvim_open_win(bufnr, focus_window, window_opts),
    bufnr = bufnr,
    width = width,
    height = height,
    padding = padding,
  }

  local nvim_win_set_option = vim.api.nvim_win_set_option
  for _, option in pairs(extra_opts) do
    local key, val = option[1], option[2]
    nvim_win_set_option(this.id, key, val)
  end

  set_autocmds(this.id)
  -- vim.cmd [[nmapclear <buffer>]]
  return this
end

return Window
