local actions = require('stylish.components.menu').actions
local actions_LUT = {}
for _, func in pairs(actions) do
  actions_LUT[func] = true
end

local defaults = {}
defaults.opts = {
  hide_cursor = true,
  loop_selection = true,
  max_visible_items = 6,
  min_width = 8,
  experimental_mouse = false
}

defaults.keymap = {
  ['<Esc>'] = { on_key = actions.close_window },
  ['q'] = { on_key = actions.close_window },
  ['k'] = { on_key = actions.change_selection, arg = -1 },
  ['j'] = { on_key = actions.change_selection, arg = 1 },
  ['<Up>'] = { on_key = actions.change_selection, arg = -1 },
  ['<Down>'] = { on_key = actions.change_selection, arg = 1 },
  ['<Tab>'] = { on_key = actions.toggle_selection, arg = 1 },
  ['<S-Tab>'] = { on_key = actions.toggle_selection, arg = -1 },
  ['<CR>'] = { on_key = actions.accept_selection },
  ['<Space>'] = { on_key = actions.accept_selection },
  ['<BS>'] = { on_key = actions.back },
  ['l'] = { on_key = actions.accept_selection },
  ['h'] = { on_key = actions.back },
}

defaults.mouse = {
  ['<LeftMouse>'] = { on_key = actions.mouse_select },
  ['<LeftDrag>'] = { on_key = actions.mouse_drag },
  ['<LeftRelease>'] = { on_key = actions.mouse_release },
  ['<2-LeftMouse>'] = { on_key = actions.nop },
  ['<3-LeftMouse>'] = { on_key = actions.nop },
  ['<4-LeftMouse>'] = { on_key = actions.nop },
  ['<ScrollWheelUp>'] = { on_key = actions.mouse_scroll_up },
  ['<ScrollWheelDown>'] = { on_key = actions.mouse_scroll_down },
  -- https://github.com/neovim/neovim/issues/6211
  ['<2-ScrollWheelUp>'] = { on_key = actions.nop },
  ['<3-ScrollWheelUp>'] = { on_key = actions.nop },
  ['<4-ScrollWheelUp>'] = { on_key = actions.nop },
  ['<2-ScrollWheelDown>'] = { on_key = actions.nop },
  ['<3-ScrollWheelDown>'] = { on_key = actions.nop },
  ['<4-ScrollWheelDown>'] = { on_key = actions.nop },
}

local Config = {}

local validate = {}
function validate.opts(user_opts)
  local validate_type, nvim_notify = vim.validate, vim.api.nvim_notify

  local option_type
  for key, val in pairs(user_opts) do
    if defaults.opts[key] then
      option_type = type(defaults.opts[key])
      validate_type { [key] = { val, option_type } }
    else
      local msg = ('Stylish: Ignoring invalid config parameter `%s`'):format(key)
      nvim_notify(msg, 2, {})
      user_opts[key] = nil
    end
  end

  return user_opts
end

function validate.keymap(user_keymap)
  local validate_type, nvim_notify = vim.validate, vim.api.nvim_notify
  local on_key, direction
  for key, val in pairs(user_keymap) do
    on_key = val.on_key
    direction = val.arg or 1
    validate_type {
      ['key'] = { key, 'string' },
      ['on_key'] = { on_key, 'function' },
      ['val'] = { val, 'table' },
      ['direction'] = { direction, 'number' },
    }

    if not actions_LUT[on_key] then
      user_keymap[key] = nil
      local msg = ('Stylish: Invalid `on_key` value for keymap: %s'):format(key)
      nvim_notify(msg, 2, {})
    end
  end

  return user_keymap
end

function Config.generate(user_config)
  user_config = user_config or {}
  user_config.opts = user_config.opts or {}
  user_config.keymap = user_config.keymap or {}

  for key, v in pairs(user_config) do
    user_config[key] = validate[key](v)
  end

  return {
    opts = vim.tbl_extend('force', defaults.opts, user_config.opts),
    keymap = vim.tbl_extend('force', defaults.keymap, user_config.keymap),
    mousemap = defaults.mouse,
  }
end

return Config
