local function set_autocmds(winid)
  -- TODO: `ModeChanged` doesn't detect Replace/Select modes
  local au_cmd = ('au BufLeave,ModeChanged <buffer> lua require"stylish".event_listener(%d, "FocusLost")'):format(winid)
  local au_statement = 'augroup StylishCanvas\nau!\n' .. au_cmd .. '\naugroup END'
  vim.cmd(au_statement)
end

-- TODO: create Canvas:close()
local Canvas = {}
Canvas.__index = Canvas

-- function Canvas:new(width, height, pos, user_win_opts, user_win_settings, focus_window)
function Canvas:new(config)
  local this = {}
  setmetatable(this, self)
  self.__index = self

  -- TODO: verify opts
  local nvim_open_win = vim.api.nvim_open_win
  local nvim_create_buf = vim.api.nvim_create_buf

  config = config or {}
  config.win_opts = config.win_opts or {}
  config.win_settings = config.win_settings or {}

  if not config.win_opts.width or not config.win_opts.height then
    error 'width, height must be specified.'
  end

  this.width = config.win_opts.width
  this.height = config.win_opts.height

  -- if screenposition not explicitly set, position at top left of current window
  local screenrow = config.win_opts.row
  local screencol = config.win_opts.col
  if (not screenrow or screenrow == -1) or (not screencol or screencol == -1) then
    local wininfo = vim.fn.win_screenpos(0)
    screenrow, screencol = wininfo[1], wininfo[2]
  end

  this.screenpos = {
    row = screenrow,
    col = screencol
  }
  this.focusable = config.win_opts.focusable
  -- this.padding = padding

  local win_opts = {
    width = this.width,
    height = this.height,
    row = this.screenpos.row,
    col = this.screenpos.col,
    relative = config.win_opts.relative or 'editor',
    style = 'minimal',
    focusable = this.focusable or false,
    border = config.win_opts.border or 'shadow',

  }

  -- create the window
  this.bufnr = nvim_create_buf(false, true)
  this.winid = nvim_open_win(this.bufnr, config.focus_window, win_opts)
  vim.api.nvim_buf_set_var(this.bufnr, 'modifiable', false)

  local nvim_win_set_option = vim.api.nvim_win_set_option
  local default_win_settings = {
    { 'winhighlight', 'Normal:None' },
    { 'winblend', 0 },
    { 'scrolloff', 999 },
  }

  local win_settings = vim.tbl_extend('force', default_win_settings, config.win_settings)

  -- print(vim.inspect(win_settings))
  for _, option in pairs(win_settings) do
    local key, val = option[1], option[2]
    nvim_win_set_option(this.winid, key, val)
  end

  this.nsid = vim.api.nvim_create_namespace('StylishCanvas_' .. this.winid)

  if this.focusable then
    set_autocmds(this.winid)
  end
  -- vim.cmd [[nmapclear <buffer>]]
  return this
end

function Canvas:close()
  -- destroy buffer
  -- destroy extmarks
  -- destroy namespace
  if vim.api.nvim_buf_is_valid(self.bufnr) then
    vim.api.nvim_buf_delete(self.bufnr, { force = true })
  end
  if vim.api.nvim_win_is_valid(self.winid) then
    vim.api.nvim_win_close(self.winid, true)
  end
  self = nil
end

return Canvas
