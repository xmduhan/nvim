return {
  {
    "junegunn/vim-easy-align",
    lazy = false,
    keys = {
      { "ga", "<Plug>(EasyAlign)", mode = { "n", "x" } },
    },
    config = function()
      -- 启动交互式EasyAlign
      vim.keymap.set("x", "ga", "<Plug>(EasyAlign)", { desc = "EasyAlign" })
      vim.keymap.set("n", "ga", "<Plug>(EasyAlign)", { desc = "EasyAlign" })
    end,
  },
}

