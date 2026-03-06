return {
  {
    "nvim-orgmode/orgmode",
    lazy = false,
    ft = { "org" },
    config = function()
      require("orgmode").setup({
        org_agenda_files = { "~/org/**/*" },
        org_default_notes_file = "~/org/notes.org",
      })
     vim.lsp.enable('org')
    end,
  },
}

