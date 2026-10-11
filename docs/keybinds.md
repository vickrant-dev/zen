# Keybinds

The source is `apps/hypr/keybinds.conf`. Run `desktop keys` for the live list. The set is inspired by Omarchy's layout (SUPER-based, SPACE launcher, SUPER+CTRL+L lock), but I didn't check each bind against Omarchy, so treat it as a starting point.

Groups:

- **Apps:** RETURN terminal, SPACE launcher, E Thunar, SHIFT+E lf in kitty, B browser, / cheatsheet, CTRL+SPACE theme picker.
- **Windows:** W close, F fullscreen, T float, SHIFT+Q exit.
- **Focus and move:** H J K L focus, SHIFT+H J K L move the window.
- **Resize:** ALT+arrows.
- **Workspaces:** 1 to 0 switch, SHIFT+1 to 0 move.
- **Capture:** Print full screen, SHIFT+S area, V clipboard history.

To add a bind, write a `# description` line above it. `desktop keys` picks it up automatically.
