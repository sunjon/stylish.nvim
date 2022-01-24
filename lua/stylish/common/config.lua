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
}

defaults.keymaps = {
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
      local msg = ("Stylish: Ignoring invalid config parameter `%s`"):format(key)
      nvim_notify(msg, 2, {})
      user_opts[key] = nil
    end
  end

  return user_opts
end

function validate.keymaps(user_keymap)
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
  user_config.keymaps = user_config.keymaps or {}

  for key, v in pairs(user_config) do
      user_config[key] = validate[key](v)
  end

  return {
    opts = vim.tbl_extend('force', defaults.opts, user_config.opts),
    keymaps = vim.tbl_extend('force', defaults.keymaps, user_config.keymaps)
  }
end

return Config
