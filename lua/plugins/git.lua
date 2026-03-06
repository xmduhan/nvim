return {
  {
    "tpope/vim-fugitive",
    lazy = false,
    cmd = { "G", "Git", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse" },
    config = function()
      -- 添加自定义映射
      vim.keymap.set("n", "<leader>gs", ":Git<CR>", { desc = "Git status" })
      vim.keymap.set("n", "<leader>gc", ":Git commit<CR>", { desc = "Git commit" })
      vim.keymap.set("n", "<leader>gp", ":Git push<CR>", { desc = "Git push" })
      vim.keymap.set("n", "<leader>gl", ":Git log<CR>", { desc = "Git log" })
    end,
  },
}

