local Config = require 'stylish.common.config'
local ContextManager = require 'stylish.common.context'
local Menu = require 'stylish.components.menu'
require('stylish.common.colors').setup()

--
vim.cmd 'au! CmdlineLeave : lua require"stylish".event_listener(vim.Nil, "CmdlineLeave")'

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
  -- print(vim.inspect(merged))
  ContextManager.config = merged_config
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
  -- print("EVENT: " .. event)
  if event and event == 'FocusLost' then
    local context = ContextManager.get(winid)
    if context then
      context:close 'lost_focus'
    end
  end
end

return Stylish
