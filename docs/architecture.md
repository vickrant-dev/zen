# Architecture

Five layers, each with one job:

1. **Palette** (`themes/<name>/palette.env`): semantic color tokens. Parsed, never sourced.
2. **Templates** (`templates/<app>/`): the only place that knows an app's config syntax.
3. **Renderer** (`scripts/render.sh`): derives RGB and alpha forms, substitutes tokens, and fails on unknown tokens. Writes to `generated/` only after the whole file renders.
4. **App config** (`apps/<app>/`): behavior, keybinds, layout. Never generated.
5. **Apply** (`scripts/apply.sh`): renders, copies Firefox CSS, and reloads running apps.

## Rules

- Capability first: an app is themed only if it has a template and its `requires` commands exist. Otherwise it is skipped, not forced.
- Apps that can't take a palette directly inherit colors from the terminal (lf, zsh, starship, mise).
- Generated files are never edited by hand and never committed.
- Live files are symlinks into the repo, so git tracks source only.
- Machine-specific values go in `*.local` files, which are gitignored.

## Tokens

Each palette entry `NAME` gives you `${NAME}` (hex, `#rrggbb`), `${NAME_RGB}` (`r,g,b`), `${NAME_RGBA85}` and `${NAME_RGBA93}` (`rgba(r,g,b,a)`). Full list in `themes/<name>/palette.env`.
