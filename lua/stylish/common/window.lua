local function set_autocmds(winid)
  -- TODO: `ModeChanged` doesn't detect Replace/Select modes
  vim.cmd('au! BufLeave,ModeChanged <buffer> lua require"stylish".event_listener(' .. winid .. ', "FocusLost")')
end

local Window = {}
Window.__index = Window

function Window:create(width, height, pos, opts, focus_window)
  local this = {}
  setmetatable(this, self)
  self.__index = self

  local nvim_open_win = vim.api.nvim_open_win
  local nvim_create_buf = vim.api.nvim_create_buf

  opts = opts or {}
  focus_window = focus_window == nil and true or focus_window

  local padding = 2
  local default_opts = {}
  default_opts.relative = 'cursor'
  default_opts.style = 'minimal'
  default_opts.focusable = false
  default_opts.border = 'shadow'
  default_opts.row = pos.row
  default_opts.col = pos.col
  default_opts.width = width
  default_opts.height = height

  opts = vim.tbl_extend('force', default_opts, opts)

  -- print(vim.inspect(opts))

  -- create the window
  local bufnr = nvim_create_buf(false, true)
  this = {
    winid = nvim_open_win(bufnr, focus_window, opts),
    bufnr = bufnr,
    width = width,
    height = height,
    padding = padding,
  }

  local nvim_win_set_option = vim.api.nvim_win_set_option
  local win_settings = {
    { 'winhighlight', 'Normal:PopupNormal' },
    { 'winblend', 0 },
    { 'scrolloff', 999 },
  }
  for _, option in pairs(win_settings) do
    local key, val = option[1], option[2]
    nvim_win_set_option(this.winid, key, val)
  end

  set_autocmds(this.winid)
  -- vim.cmd [[nmapclear <buffer>]]
  return this
end

return Window
