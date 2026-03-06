return {
  {
    "flazz/vim-colorschemes",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme("molokai")
      -- 可选: gruvbox配置
      -- vim.o.background = "light"
      -- vim.cmd.colorscheme("gruvbox")
    end,
  },
}

