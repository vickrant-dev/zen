# Adding a theme

1. `cp -r themes/catppuccin-mocha themes/<new>`
2. Edit `palette.env`: one hex value per token. Keep the same key names.
3. Edit `theme.env` for fonts and GTK/icon/cursor names.
4. `desktop theme <new>`

Every token must exist in every palette. Missing or misspelled tokens fail the render, so a broken theme never reaches a live config.
