return {
  {
    "xmduhan/flycode",
    lazy = false,
    config = function()
      vim.g.flycode_config = {
        default_executor = "auto",
        languages = {
          python = { executor = "python3" },
          javascript = { executor = "node" },
          typescript = { executor = "ts-node" },
          bash = { executor = "bash" },
          sh = { executor = "bash" },
          lua = { executor = "lua" },
          ruby = { executor = "ruby" },
          go = { executor = "go run" },
          rust = { executor = "rustc" },
          java = { executor = "java" },
        },
        output_window = {
          position = "bottom",
          height = 10,
          border = "single",
        },
      }

      vim.api.nvim_create_user_command("FlycodeHealth", function()
        local lines = {}
        local function add(s)
          table.insert(lines, s)
        end

        add("FlycodeHealth")
        add("- nvim: " .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch)
        add("- filetype: " .. tostring(vim.bo.filetype))

        local lazy_ok, lazy = pcall(require, "lazy")
        add("- lazy: " .. (lazy_ok and "OK" or "NOT FOUND"))

        local flycode_loaded = false
        if lazy_ok and type(lazy.plugins) == "function" then
          local p = lazy.plugins()
          if type(p) == "table" then
            for _, pl in pairs(p) do
              if pl and pl.name == "flycode" then
                flycode_loaded = pl._ and pl._.loaded or false
                break
              end
            end
          end
        end
        add("- plugin(flycode) loaded: " .. tostring(flycode_loaded))

        local f8 = vim.fn.maparg("<F8>", "n")
        add("- map <F8> (normal): " .. (f8 ~= "" and f8 or "<none>"))

        local f7 = vim.fn.maparg("<F7>", "n")
        add("- map <F7> (normal): " .. (f7 ~= "" and f7 or "<none>"))

        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
      end, { desc = "Check flycode/keymaps status" })
    end,
  },
}
