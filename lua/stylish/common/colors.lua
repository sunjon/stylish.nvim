local Colors = {}

local function create_hl_groups()
  vim.cmd [[
hi! CursorOff             blend=100
hi! PopupNormal           guifg=#323134 guibg=#222124
hi! PopupTitle            guifg=#ac9e8a
hi! PopupTitleSubmenu     guifg=#8ec07c
hi! MenuBackIndicator     guifg=#68645e
hi! ItemIndicatorInactive guifg=#222124 guibg=#323134
hi! ItemIndicatorActive   guifg=#8ec07c guibg=#323134
hi! ItemIndicatorSelected guifg=#E0B828 guibg=#323134
" hi! ItemIndicatorSelected guifg=#CD9A13 guibg=#323134
" hi! ItemIndicatorSelected guifg=#E9772a guibg=#323134
hi! ItemIndicatorNotSelected guifg=#222124 guibg=#323134
" hi! ItemTextActive        guifg=#ebdbb2 guibg=#323134
hi! ItemTextActive        guifg=#8ec07c guibg=#323134
hi! ItemTextActive        guifg=#eddeb8 guibg=#323134
hi! ItemTextInactive      guifg=#68645e guibg=#323134
hi! ItemTextSelected      guifg=#E0B828 guibg=#323134

hi! ScrollIndicatorActive guifg=#ac9e8a

" ToolbarLine and ToolbarButton
hi! link ToolbarLine PopupNormal
hi! ButtonEdge guibg=#323134
hi! ButtonText guifg=#68645e guibg=#323134

hi! ButtonSelectedEdge guibg=#323134
hi! ButtonSelectedText guifg=#eddeb8 guibg=#323134

hi! SubmenuIndicator guibg=#323134 guifg=#222124
" hi! SubmenuIndicatorActive guibg=#323134 guifg=#6A7D7F
" hi! SubmenuIndicatorActive guibg=#323134 guifg=#6D6A5a
" hi! SubmenuIndicatorActive guibg=#323134 guifg=#486852
hi! SubmenuIndicatorActive guibg=#323134 guifg=#ac9e8a

hi! ToggleButton guifg=#bdae92 guibg=#323134
hi! ToggleButtonInner guifg=#bdae92 guibg=#1a1a1a
hi! ToggleButtonEdge guibg=#323134 guifg=#1a1a1a
hi! ToggleButtonSelector guifg=#ebdbb2 guibg=#222124

" hi! ItemIndicatorLoaded   guifg=#496544 guibg=#323134
]]
end
-- " hi! ItemIndicatorLoaded   guifg=#efb009 guibg=#323134

function Colors.setup()
  create_hl_groups()
end

return Colors
