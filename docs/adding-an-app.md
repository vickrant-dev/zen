# Adding an app

1. **Theme it (optional):** create `templates/<config-dir>/` with the files you want generated, named with a `.tmpl` suffix. Put the command the app needs in `templates/<config-dir>/requires`. The directory name must match the config directory under `~/.config`.
2. **Configure it:** put behavior and keybinds in `apps/<config-dir>/`. These are linked as-is.
3. **Reload it (optional):** add a reload line to `scripts/apply.sh`, guarded so it does nothing when the app isn't running.
4. **Document it:** add a row to `docs/theme-support.md`.

If the app can't use colors from a palette, skip step 1. It still gets its behavior config.
