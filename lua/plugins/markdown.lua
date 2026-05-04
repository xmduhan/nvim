return {
  {
    "preservim/vim-markdown",
    lazy = false,
    dependencies = {
      "godlygeek/tabular",
    },
    config = function()
      -- 你当前“markdown 无法折叠”最常见原因：这里把 vim-markdown 的折叠功能禁用了
      -- 1 = 禁用折叠；0 = 启用折叠
      vim.g.vim_markdown_folding_disabled = 0

      -- 可选：默认折叠级别（越小折叠越多；99 通常等于几乎不折叠）
      -- vim.g.vim_markdown_folding_level = 1

      vim.g.vim_markdown_toc_autofit = 1
      vim.g.vim_markdown_conceal = 0
      vim.g.vim_markdown_conceal_code_blocks = 0
      vim.g.vim_markdown_frontmatter = 1
      vim.g.vim_markdown_strikethrough = 1
      vim.g.vim_markdown_autowrite = 1
      vim.g.vim_markdown_edit_url_in = "tab"
      vim.g.vim_markdown_follow_anchor = 1

      -- 确保 markdown buffer 使用折叠表达式（由 vim-markdown 提供）
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function()
          vim.opt_local.foldmethod = "expr"
          vim.opt_local.foldexpr = "MarkdownFold()"
          -- 需要有折叠才能看到效果；可按需调整
          vim.opt_local.foldlevel = 99
        end,
      })
    end,
  },
  {
    "godlygeek/tabular",
    lazy = false,
    cmd = "Tabularize",
  },
}
