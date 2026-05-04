return {
  {
    "nvim-orgmode/orgmode",
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        org_agenda_files = { "~/org/**/*" },
        org_default_notes_file = "~/org/notes.org",
        win_split_mode = "vertical",
      })

      -- Org 折叠（你这里的 *.org 里用的是 "*" 标题；需要用 expr 折叠，而不是全局的 indent 折叠）
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "org" },
        callback = function()
          -- orgmode 提供的折叠表达式函数
          vim.opt_local.foldmethod = "expr"
          vim.opt_local.foldexpr = "OrgFoldExpr()"
          -- 默认先全部展开；需要折叠再用 zc/za
          vim.opt_local.foldlevel = 99
          vim.opt_local.foldenable = true
        end,
      })

      -- 修复/增强 org 中 TODO / DONE 等关键字高亮（避免在 molokai 下不清晰）
      local function set_org_todo_highlight()
        -- 这些 group 名称以 orgmode 的 Treesitter/语法高亮为准；若某些版本不存在，nvim 会忽略。
        local ok_hl = pcall(vim.api.nvim_set_hl, 0, "OrgTodo", { fg = "#000000", bg = "#ffaf00", bold = true })
        if not ok_hl then
          return
        end

        pcall(vim.api.nvim_set_hl, 0, "OrgDone", { fg = "#000000", bg = "#5fd700", bold = true })
        pcall(vim.api.nvim_set_hl, 0, "OrgAgendaTodo", { link = "OrgTodo" })
        pcall(vim.api.nvim_set_hl, 0, "OrgAgendaDone", { link = "OrgDone" })

        -- 兼容一些旧/不同命名的 group
        pcall(vim.api.nvim_set_hl, 0, "org_todo_keyword", { link = "OrgTodo" })
        pcall(vim.api.nvim_set_hl, 0, "org_done_keyword", { link = "OrgDone" })
        pcall(vim.api.nvim_set_hl, 0, "@org.keyword.todo", { link = "OrgTodo" })
        pcall(vim.api.nvim_set_hl, 0, "@org.keyword.done", { link = "OrgDone" })
      end

      set_org_todo_highlight()

      -- 切换 colorscheme 后需要重新应用自定义高亮
      vim.api.nvim_create_autocmd("ColorScheme", {
        pattern = "*",
        callback = set_org_todo_highlight,
      })
    end,
  },
}
