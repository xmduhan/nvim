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

      -- 修复/增强 org 中 TODO / DONE 等关键字高亮（避免在 molokai 下不清晰）
      -- 同时增强 agenda 里的 scheduled 标记（你 Inspect 看到的是 @org.agenda.scheduled）
      local function set_org_todo_highlight()
        -- 这些 group 名称以 orgmode 的 Treesitter/语法高亮为准；若某些版本不存在，nvim 会忽略。
        local ok_hl = pcall(vim.api.nvim_set_hl, 0, "OrgTodo", { fg = "#000000", bg = "#ffaf00", bold = true })
        if not ok_hl then
          return
        end

        pcall(vim.api.nvim_set_hl, 0, "OrgDone", { fg = "#000000", bg = "#5fd700", bold = true })
        pcall(vim.api.nvim_set_hl, 0, "OrgAgendaTodo", { link = "OrgTodo" })
        pcall(vim.api.nvim_set_hl, 0, "OrgAgendaDone", { link = "OrgDone" })

        -- Agenda: scheduled（更亮一些，molokai 下更清晰）
        -- 你的 Inspect：@org.agenda.scheduled org_agenda
        -- 这里同时覆盖 TS capture 与可能存在的传统 group
        pcall(vim.api.nvim_set_hl, 0, "OrgAgendaScheduled", { fg = "#ffffff", bold = true })
        pcall(vim.api.nvim_set_hl, 0, "@org.agenda.scheduled", { link = "OrgAgendaScheduled" })

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
