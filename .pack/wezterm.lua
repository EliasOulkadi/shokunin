local wezterm = require 'wezterm'
return {
  font = wezterm.font_with_fallback({
    { family = 'FiraCode Nerd Font' },
    { family = 'Cascadia Code' },
    { family = 'Consolas' },
  }),
  font_size = 11.0,
  color_scheme = 'Catppuccin Mocha',
  window_background_opacity = 0.92,
  text_background_opacity = 0.92,
  window_decorations = 'RESIZE',
  enable_tab_bar = true,
  hide_tab_bar_if_only_one_tab = true,
  tab_max_width = 25,
  keys = {
    { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
    { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab({ confirm = true }) },
    { key = 'Tab', mods = 'CTRL', action = wezterm.action.ActivateTabRelative(1) },
    { key = 'Tab', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  },
  default_prog = { 'pwsh.exe', '-NoLogo' },
}
