# stylish.nvim

Stylish UI components for Neovim

[WIP] This project is in alpha status.

<img src="https://github.com/sunjon/images/blob/master/stylish_ui_menu.gif" alt="screenshot" width="800"/>

## Installation

### [Packer](https://github.com/wbthomason/packer.nvim) 

```lua
use 'sunjon/stylish.nvim'
```

### [Vim-Plug](https://github.com/junegunn/vim-plug)

```lua
Plug 'sunjon/stylish.nvim'
```

### Configuration

#### Set Stylish as the vim.ui.* handler:

```lua
vim.ui.menu = require('stylish').ui_menu()
-- vim.ui.select = require('stylish').ui_select()
-- vim.ui.notification = require('stylish').ui_notification()
```

#### Testing:

```lua
vim.api.nvim_set_keymap(
  'n',
  '<F1>',
  "<Cmd>lua vim.ui.menu(vim.fn.menu_get(''), {kind='menu', prompt='Main Menu'}, function(res) print('### ' ..res) end)<CR>",
  { noremap = true, silent = true }
)
```

### TODO:
- [x] vim.ui.menu
- [ ] vim.ui.select
- [ ] vim.ui.notification
- [ ] mouse controls
- [ ] animator
- [ ] documentation
