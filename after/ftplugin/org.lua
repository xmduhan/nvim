-- Org filetype local settings
-- Put fold settings here to ensure they are applied reliably every time
-- an org buffer is opened.

-- Use orgmode's fold expression
vim.opt_local.foldmethod = "expr"
vim.opt_local.foldexpr = "OrgFoldExpr()"

-- Start unfolded by default (adjust as you like)
vim.opt_local.foldlevel = 99
vim.opt_local.foldenable = true
