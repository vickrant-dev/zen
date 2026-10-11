# Migrating from the old setup

Not included in this repo, copy them in yourself:

1. `~/.config/waybar/config.jsonc` into `apps/waybar/config.jsonc`. The old waybar style is kept in your backup; the new style comes from the template.
2. `~/.config/nvim/` (everything except `lua/theme.lua` and `lua/plugins/colorscheme.lua`) into `apps/nvim/`. Add `require("config.colors")` to `init.lua`. The gruvbox fallback is gone.
3. `~/.config/hypr/hyprlock.conf` into `apps/hypr/hyprlock.conf` if you want it. Its colors aren't themed yet.
4. Create `~/.gitconfig.local` with your `[user]` name and email.

Then:

```bash
cd ~/desktop && ./scripts/install.sh && desktop theme catppuccin-mocha && desktop doctor
```

Keep `~/.dotfiles` as a backup until everything works. Once it does, untrack the generated files there and retire the `config` alias.
