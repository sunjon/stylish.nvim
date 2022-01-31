# stylish.nvim

_A collection of Stylish UI components for Neovim_

Components are rendered using ASCII characters in the terminal. A font that supports glyphs introduced in [Unicode version 13.0](https://unicode.org/versions/Unicode13.0.0/) is required for some effects.

This project is alpha/WIP. Feel free to open issues to contribute ideas.

### stylish.ui.splashlogo (soon™)

<img src="https://raw.githubusercontent.com/sunjon/images/master/stylish_ui_splashlogo.png" alt="screenshot" width="800"/>

### stylish.ui.clock

<img src="https://raw.githubusercontent.com/sunjon/images/master/stylish_ui_clock.gif" alt="screenshot" width="800"/>

### stylish.ui.menu

<img src="https://raw.githubusercontent.com/sunjon/images/master/stylish_ui_mousemenu.gif" alt="screenshot" width="800"/>

### stylish.ui.graph (soon™)

<img src="https://raw.githubusercontent.com/sunjon/images/master/stylish_ui_graph.png" alt="screenshot" width="800"/>

### stylish.ui.keyboard_stats (soon™)

<img src="https://raw.githubusercontent.com/sunjon/images/master/stylish_ui_keyboard_heatmap.png" alt="screenshot" width="800"/>

### stylish.ui.notify (soon™)

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

### Testing `stylish.ui_menu`

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

#### Configuration: Menu

```lua
local menu_opts = {
  kind = 'menu',
  prompt = 'Main menu',
  experimental_mouse = true
}

vim.api.nvim_set_keymap(
  'n',
  '<F1>',
  "<Cmd>lua require'stylish'.ui_menu(vim.fn.menu_get(''), menu_opts, function(res) print('### ' ..res) end)<CR>",
  { noremap = true, silent = true }
)
```

NOTE: `experimental_mouse` only works with Linux and `xdotool` installed.

### Testing `stylish.ui_clock`

#### Configuration: Clock

```lua

vim.api.nvim_set_keymap(
  'n',
  '<F12>',
  '<Cmd>lua require"stylish".ui_clock()<CR>',
  { noremap = true, silent = true }
)
```

## TODO:
- [x] vim.ui.menu
- [x] vim.ui.clock (fading not working, no background)
- [ ] vim.ui.select # in development
- [ ] vim.ui.notify # in development
- [ ] vim.ui.input
- [ ] mouse controls
- [ ] animator
- [ ] documentation
