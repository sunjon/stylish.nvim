local Config = require 'stylish.common.config'
local ContextManager = require 'stylish.common.context'

-- TODO: only require components configured by user
local Menu = require 'stylish.components.menu'
local Clock = require 'stylish.components.clock'
local Nyan = require 'stylish.components.nyan'
-- print(vim.inspect(Clock))


--
vim.cmd 'au! CmdlineLeave : lua require"stylish".event_listener(vim.Nil, "CmdlineLeave")'

require('stylish.common.colors').setup()
-- vim.cmd 'au! ColorScheme * lua require"stylish.common.colors".setup()'

-- local plugin_dir = vim.fn.expand('<sfile>:p:h:h') .."/data/" -- todo: better way to resolve plugin path?
-- vim.g.stylish_plugin_dir = plugin_dir
-- print("!!!! " ..  vim.g.stylish_plugin_dir)
-- vim.api.nvim_set_var('stylish_plugin_dir', vim.fn.expand('<sfile>:p:h:h') .."/data/")

-- local function ui_menu(list, opts, cb)
--   return select
-- end

local Stylish = {}

-- TODO: store the
function Stylish.setup(opts)
  opts = opts or {}

  -- merge validated user options with defaults
  local merged_config = Config.generate(opts)
  if not merged_config then
    vim.api.nvim_notify('Stylish: Setup error.')
  end
  -- local merged = Config.merge(opts)
  -- print("## MERGED ##")
  -- print(vim.inspect(merged_config))
  ContextManager.config = merged_config
  -- print(vim.inspect(merged_config))
end

local function ensure_configured()
  if not ContextManager.config then
    Stylish.setup()
  end
end

function Stylish:ui_menu()
  ensure_configured()
  -- menu specific init
  if ContextManager.size() > 0 then
    print 'already open'
    return
  end
  -- print(vim.inspect(Menu))

  -- Ensure plugin is setup

  return function(list, opts, cb)
    local new_menu = Menu:new(list, opts, cb)
    -- TODO: create new_menu:select()
  end
end

function Stylish:ui_select(...)
  require('stylish.components').select(...)
end


local my_clock
function Stylish:ui_clock()
  -- local new_clock = Clock:toggle()
  -- print("New clock!")
  if my_clock then
    my_clock:stop()
    my_clock = nil
  else
    my_clock = Clock:new()
    my_clock:start()
  end
  -- print(vim.inspect(Clock))
end

function Stylish:ui_nyan()
  Nyan:new()
end
--

-- function Stylish.window_focusleave(winid)
-- end

-- Pick up changes from `amenu`
-- function Stylish.on_vimcommand()
--   local cmdline = vim.fn.getcmdline()
--   local cmd = cmdline:match '^(a?menu%s)'
--   if cmd then
--     print(':::: ' .. cmd)
--   end
-- end

function Stylish.event_listener(winid, event)
  local get_current_win = vim.api.nvim_get_current_win
  if not winid == get_current_win() then
    return
  end

  -- print("OMG: " .. os.clock())
  -- print(vim.inspect(event))
  if event and event == 'KeyPress' then
    local key = vim.api.nvim_get_vvar('char')
    print("!!!!!!! " .. key)
  end
  -- print("EVENT: " .. event)
  if event and event == 'FocusLost' then
    local context = ContextManager.get(winid)
    if context then
      context:close 'lost_focus'
    end
  end
end

return Stylish
