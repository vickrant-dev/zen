# desktop

One palette drives the look of the whole desktop: Hyprland, waybar, mako, rofi, kitty, Neovim, GTK (Thunar), and Firefox. Apps that can't take a theme are left alone.

## Quick start

```bash
git clone <this repo> ~/desktop
cd ~/desktop
./scripts/install.sh          # links configs into $HOME (backs up existing files)
desktop theme catppuccin-mocha
desktop doctor                # checks tools and broken links
```

Then add `~/.local/bin` to your PATH (already in the included `.zshrc`).

## Daily use

| Command | What it does |
|---|---|
| `desktop theme <name>` | render and apply a theme |
| `SUPER+CTRL+SPACE` | pick a theme from a menu |
| `desktop keys` | list all keybinds |
| `SUPER+/` | show keybinds in rofi |
| `desktop doctor` | check tools and broken links |

## Layout

```
themes/<name>/     palette.env (colors) and theme.env (fonts, GTK names)
templates/<app>/   config with ${TOKEN} placeholders; requires = commands to check
apps/<app>/        hand-written config that is never generated
apps/home/         files linked into $HOME
generated/         rendered output, gitignored
scripts/           render, install, apply, keys, doctor
bin/desktop        the one command you use
docs/              architecture, adding themes and apps, support matrix, keybinds
```

Read `docs/architecture.md` first.
