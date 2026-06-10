-- TODO: Test
return {
  "folke/todo-comments.nvim",
  cmd = "TodoTelescope",
  dependencies = { "nvim-lua/plenary.nvim" },
  event = { "BufReadPost", "BufNewFile" },
  keys = {
    {
      "<leader>fd",
      "<cmd>TodoTelescope<cr>",
      desc = "Todo (Telescope)",
    },
  },
  config = function()
    require("todo-comments").setup()
  end,
}
