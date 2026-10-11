# Theme support

| App | Support | How |
|---|---|---|
| Hyprland (borders, shadow) | full | `templates/hypr`, sourced by `hyprland.conf` |
| Waybar | full | `templates/waybar`, reloaded with SIGUSR2 |
| Mako | full | `templates/mako`, reloaded with `makoctl reload` |
| Rofi | full | `templates/rofi`, applied on next open |
| Kitty | full | `templates/kitty`, included by `kitty.conf`, reloaded with SIGUSR1 |
| Neovim | full | `templates/nvim`; needs `require("config.colors")` in `init.lua` |
| Thunar (GTK) | partial | GTK theme name, only if that theme is installed |
| Firefox | partial | `userChrome.css`, copied into each profile; needs `toolkit.legacyUserProfileCustomizations.stylesheets` set to true |
| Hyprlock | not yet | colors are in its own config; can be templated later |
| lf, zsh, starship, mise | inherit | use kitty's ANSI colors |
| Hyprpaper | n/a | wallpaper only |
