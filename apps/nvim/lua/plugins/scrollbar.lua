return {
  "petertriho/nvim-scrollbar",

  dependencies = {
    "lewis6991/gitsigns.nvim",
  },

  config = function()
    require("scrollbar").setup({
      show = true,

      handlers = {
        cursor = true,
        diagnostic = true,
        gitsigns = true,
      },
    })

    require("scrollbar.handlers.gitsigns").setup()
  end,
}
