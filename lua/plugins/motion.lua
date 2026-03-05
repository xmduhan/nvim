return {
  {
    "easymotion/vim-easymotion",
    keys = {
      { "<leader>s", "<Plug>(easymotion-s2)", mode = { "n", "x", "o" } },
      { "<leader>w", "<Plug>(easymotion-w)", mode = { "n", "x", "o" } },
      { "<leader>b", "<Plug>(easymotion-b)", mode = { "n", "x", "o" } },
    },
    config = function()
      vim.g.EasyMotion_do_mapping = 0 -- 禁用默认映射
      vim.g.EasyMotion_smartcase = 1
    end,
  },
}
