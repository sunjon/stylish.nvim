local ContextManager = require 'stylish.common.context'

local M = {}

function M.set_keymaps(winid, bufnr)
  local cmd, escaped_key
  local map_opts = { noremap = true, nowait = true, silent = true }

  local key_config = ContextManager.config.keymaps -- Argh! stop passing this around
  for key, _ in pairs(key_config) do
    escaped_key = key:gsub('<', '<lt>')
    cmd = ([[<cmd>lua require('stylish.components.menu').key_handler(%d, '%s')<CR>]]):format(winid, escaped_key)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', key, cmd, map_opts)
  end
end

function M.key_handler(winid, key)
  local key_config = ContextManager.config.keymaps -- Argh! stop passing this around
  -- print(vim.inspect(key_config))
  local key_action = key_config[key] -- TODO: default_config should have been translated to current_config (merged/overriden with user config)
  if not key_action then
    print('invalid key: ' .. key)
    return ''
  end
  -- print(vim.inspect(key_action))
  -- TODO: send context, not winid
  local context = ContextManager.get(winid)
  if not context then
    error('Unknown winid: ' ..winid)
    return
  end

  if key_action.arg then
    key_action.on_key(context, key_action.arg)
  else
    key_action.on_key(context)
  end
end

return M
