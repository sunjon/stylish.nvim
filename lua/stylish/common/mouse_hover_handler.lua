local Timer = require 'stylish.common.timer'
local POLL_RATE = 1000 / 60

local mouse_buttons = {
  LEFT = 1,
  MIDDLE = 2,
  RIGHT = 3,
}

local drag_button = mouse_buttons.MIDDLE
local mousedown_cmd = 'xdotool mousedown ' .. drag_button
local mouseup_cmd = 'xdotool mouseup ' .. drag_button

--
-- TODO: FocusLost doesn't trigger because MiddleMouseHandler is held down via xdotool
vim.cmd [[
nnoremap <MiddleMouse> <NOP>
augroup MouseHandlerPoller
au!
" au FocusLost * lua require'stylish.common.mouse_handler'.stop_tracker()
au VimLeave * lua os.execute('xdotool mouseup 2')
augroup END
]]

--

local function getpos(winid, last_pos, callback)
  local vim_getmousepos = vim.fn.getmousepos
  local mp = vim_getmousepos()
  if winid == mp.winid then
    local is_same_pos = ((mp.winrow == last_pos.winrow) and (mp.wincol == last_pos.wincol))
    if not is_same_pos then
      last_pos.winrow = mp.winrow
      last_pos.wincol = mp.wincol
      callback(mp.winrow, mp.wincol)
    end
  end
end

local function track_window(context)
  local report_mouse = vim.schedule_wrap(getpos)
  local winid = context.winid
  local cb = context.callback
  while true do
    report_mouse(winid, context.last_pos, cb)
    coroutine.yield()
  end
end

local MouseHandler = {}
MouseHandler.__index = MouseHandler

-- TODO: pass list of regions within window to callback upon
function MouseHandler:new(winid, callback)
  local this = {}
  setmetatable(this, self)
  self.__index = self

  if not callback then
    error 'no callback specified'
  end

  local context = {
    winid = winid,
    last_pos = {winrow=-1, wincol=-1},
    callback = callback,
  }
  this.tracker = Timer:new(coroutine.create(track_window), context, POLL_RATE)

  return this
end

function MouseHandler:start()
  os.execute(mousedown_cmd) -- begin drag mode
  self.tracker:start()
end

function MouseHandler:rehash()
end

function MouseHandler:stop()
  os.execute(mouseup_cmd) -- stop drag mode
  vim.cmd('echon', '') -- clear any debug output
  self.tracker:stop()
end

return MouseHandler
