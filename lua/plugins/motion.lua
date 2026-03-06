return {
  {
    "easymotion/vim-easymotion",
    keys = {
      { "<leader>f", "<Plug>(easymotion-overwin-w)", mode = { "n", "x", "o" } },
      { "<leader>j", "<Plug>(easymotion-bd-jk)", mode = { "n", "x", "o" } },
    },
    config = function()
      vim.g.EasyMotion_do_mapping = 0 -- 禁用默认映射
      vim.g.EasyMotion_smartcase = 1
    end,
  },
}
