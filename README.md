# stylish.nvim

Stylish UI components for Neovim

[WIP] This project is in alpha status.

<img src="https://github.com/sunjon/images/blob/master/stylish_ui_menu.gif" alt="screenshot" width="800"/>

<img src="https://github.com/sunjon/images/blob/master/stylish_ui_notifications.gif" alt="screenshot" width="800"/>



## Installation

### [Packer](https://github.com/wbthomason/packer.nvim) 

```lua
use 'sunjon/stylish.nvim'
```

### [Vim-Plug](https://github.com/junegunn/vim-plug)

```lua
Plug 'sunjon/stylish.nvim'
```

## Configuration

### Set Stylish as the vim.ui.* handler:

```lua
vim.ui.menu = require('stylish').ui_menu()
-- vim.ui.select = require('stylish').ui_select()
-- vim.ui.notification = require('stylish').ui_notification()
```

### Testing `vim.ui.menu`

#### Creating Menus:

```lua
vim.cmd [[
amenu Plugin.Fugitive.GFetch :GFetch | amenu Plugin.Fugitive.GPull :GPull | amenu Plugin.Fugitive.GPush :GPush
amenu File.Filetype.One :echo 1 | amenu File.Filetype.Two :echo 2 | amenu File.Filetype.Three :echo 3
amenu Edit.Recent.Foo :echo 'foo' | amenu Edit.Recent.Bar :echo 'bar' | amenu Edit.Recent.Baz :echo 'baz'
amenu Edit.Diff.Revision_1 :echo 'rev_1' | amenu Edit.Diff.Revision_2 :echo 'rev_2' | amenu Edit.Diff.Revision_3 :echo 'rev_3'
]]

for i = 1, 16 do
  vim.cmd('amenu OverflowList.Test_Thing_' .. i .. ' :echo ' .. i)
end
```

See `:h menu` for more details

#### Activation

```lua
vim.api.nvim_set_keymap(
  'n',
  '<F1>',
  "<Cmd>lua vim.ui.menu(vim.fn.menu_get(''), {kind='menu', prompt='Main Menu'}, function(res) print('### ' ..res) end)<CR>",
  { noremap = true, silent = true }
)
```

## TODO:
- [x] vim.ui.menu
- [ ] vim.ui.select
- [ ] vim.ui.notification
- [ ] mouse controls
- [ ] animator
- [ ] documentation
