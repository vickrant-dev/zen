vim.g.mapleader = " "
vim.g.maplocalleader = " "
vim.opt.clipboard = "unnamedplus"

require("config.options")
require("config.keymaps")
require("config.lazy")
require("config.autocmds")
local theme_file = vim.fn.stdpath("config") .. "/lua/theme.lua"
if vim.fn.filereadable(theme_file) == 1 then
  dofile(theme_file).apply()
end
