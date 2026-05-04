-- Markdown ftplugin (override / ensure folding works)
-- This runs after plugins/ftplugins, and is a reliable place to enforce buffer-local options.

-- Ensure vim-markdown folding is enabled
vim.g.vim_markdown_folding_disabled = 0

-- Use vim-markdown fold expression
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "MarkdownFold()"

-- Make sure folding is enabled and not fully open/closed by default
vim.opt_local.foldenable = true
vim.opt_local.foldlevel = 99
