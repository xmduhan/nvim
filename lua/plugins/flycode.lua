return {
  {
    "xmduhan/flycode",
    lazy = false,
    config = function()
      -- 配置 flycode
      vim.g.flycode_config = {
        -- 默认执行器配置
        default_executor = "auto",
        -- 支持的语言
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
        -- 输出窗口配置
        output_window = {
          position = "bottom",
          height = 10,
          border = "single",
        },
      }

      local function trim(s)
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
      end

      local function shell_join(args)
        local escaped = {}
        for _, a in ipairs(args) do
          table.insert(escaped, vim.fn.shellescape(a))
        end
        return table.concat(escaped, " ")
      end

      local function open_terminal_with_cmd(cmd)
        vim.cmd("new")
        vim.cmd("term " .. cmd)
        vim.cmd("startinsert")
      end

      local function write_temp_file(lines, suffix)
        local temp_file = vim.fn.tempname() .. suffix
        local file = io.open(temp_file, "w")
        if not file then
          vim.notify("Failed to create temp file: " .. temp_file, vim.log.levels.ERROR)
          return nil
        end
        for _, line in ipairs(lines) do
          file:write(line .. "\n")
        end
        file:close()
        return temp_file
      end

      local function build_command(lang, args, temp_file)
        local cmd
        if lang == "python" or lang == "py" then
          cmd = "python3 " .. vim.fn.shellescape(temp_file)
        elseif lang == "javascript" or lang == "js" then
          cmd = "node " .. vim.fn.shellescape(temp_file)
        elseif lang == "typescript" or lang == "ts" then
          cmd = "ts-node " .. vim.fn.shellescape(temp_file)
        elseif lang == "bash" or lang == "sh" or lang == "shell" or lang == "zsh" then
          cmd = "bash " .. vim.fn.shellescape(temp_file)
        elseif lang == "lua" then
          cmd = "lua " .. vim.fn.shellescape(temp_file)
        elseif lang == "ruby" or lang == "rb" then
          cmd = "ruby " .. vim.fn.shellescape(temp_file)
        elseif lang == "flycode" then
          local fly_args = {}
          for _, a in ipairs(args or {}) do
            table.insert(fly_args, a)
          end
          table.insert(fly_args, temp_file)
          cmd = "flycode " .. shell_join(fly_args)
        else
          local hint = lang and ("Unknown code block language: " .. lang) or "Missing code block language"
          vim.notify(
            hint .. ". Supported: python/js/ts/bash/sh/lua/ruby/flycode. Example: ```flycode <subcmd> <model>",
            vim.log.levels.WARN
          )
          return nil
        end

        return cmd
      end

      -- 解析 fence 行：```lang args... 或 ```lang{...}
      -- 返回：lang, args(list)
      local function parse_fence(fence_line)
        local rest = fence_line:match("^```%s*(.*)$")
        if not rest then
          return nil, {}
        end
        rest = trim(rest)
        if rest == "" then
          return nil, {}
        end

        local tokens = {}
        for t in rest:gmatch("%S+") do
          table.insert(tokens, t)
        end

        local lang = tokens[1]
        if not lang or lang == "" then
          return nil, {}
        end

        lang = lang:gsub("%b{}", "")
        lang = lang:lower()

        local args = {}
        for i = 2, #tokens do
          table.insert(args, tokens[i])
        end

        return lang, args
      end

      local function parse_org_src_begin(line)
        local rest = line:match("^%s*#%+src_begin%s+(.*)$") or line:match("^%s*#%+SRC_BEGIN%s+(.*)$")
        if not rest then
          return nil, {}
        end

        rest = trim(rest)
        if rest == "" then
          return nil, {}
        end

        local tokens = {}
        for t in rest:gmatch("%S+") do
          table.insert(tokens, t)
        end

        local lang = tokens[1]
        if not lang or lang == "" then
          return nil, {}
        end

        lang = lang:lower()

        local args = {}
        for i = 2, #tokens do
          table.insert(args, tokens[i])
        end

        return lang, args
      end

      local function execute_markdown_code_block()
        vim.cmd("w")

        local current_line = vim.fn.line(".")

        local start_line = current_line
        while start_line > 1 do
          local line_content = vim.fn.getline(start_line)
          if line_content:match("^```") then
            break
          end
          start_line = start_line - 1
        end

        if start_line == 1 and not vim.fn.getline(start_line):match("^```") then
          vim.notify("No fenced code block found (missing ```)", vim.log.levels.WARN)
          return
        end

        local end_line = current_line
        local total_lines = vim.fn.line("$")
        while end_line <= total_lines do
          local line_content = vim.fn.getline(end_line)
          if line_content:match("^```") and end_line ~= start_line then
            break
          end
          end_line = end_line + 1
        end

        if end_line > total_lines then
          vim.notify("Unclosed fenced code block (missing closing ```)", vim.log.levels.WARN)
          return
        end

        local code_lines = {}
        for i = start_line + 1, end_line - 1 do
          table.insert(code_lines, vim.fn.getline(i))
        end

        local has_nonempty = false
        for _, l in ipairs(code_lines) do
          if trim(l) ~= "" then
            has_nonempty = true
            break
          end
        end

        if not has_nonempty then
          vim.notify("No code found in this fenced block", vim.log.levels.WARN)
          return
        end

        local fence = vim.fn.getline(start_line)
        local lang, args = parse_fence(fence)
        local temp_file = write_temp_file(code_lines, ".flycode")
        if not temp_file then
          return
        end

        local cmd = build_command(lang, args, temp_file)
        if not cmd then
          return
        end

        open_terminal_with_cmd(cmd)
      end

      local function execute_org_src_block()
        vim.cmd("w")

        local current_line = vim.fn.line(".")
        local total_lines = vim.fn.line("$")

        local start_line = current_line
        while start_line >= 1 do
          local line_content = vim.fn.getline(start_line)
          if line_content:match("^%s*#%+src_begin\b") or line_content:match("^%s*#%+SRC_BEGIN\b") then
            break
          end
          start_line = start_line - 1
        end

        if start_line < 1 then
          vim.notify("No org src block found (missing #+src_begin)", vim.log.levels.WARN)
          return
        end

        local end_line = current_line
        while end_line <= total_lines do
          local line_content = vim.fn.getline(end_line)
          if end_line ~= start_line and (line_content:match("^%s*#%+src_end\b") or line_content:match("^%s*#%+SRC_END\b")) then
            break
          end
          end_line = end_line + 1
        end

        if end_line > total_lines then
          vim.notify("Unclosed org src block (missing #+src_end)", vim.log.levels.WARN)
          return
        end

        local code_lines = {}
        for i = start_line + 1, end_line - 1 do
          table.insert(code_lines, vim.fn.getline(i))
        end

        local has_nonempty = false
        for _, l in ipairs(code_lines) do
          if trim(l) ~= "" then
            has_nonempty = true
            break
          end
        end

        if not has_nonempty then
          vim.notify("No code found in this org src block", vim.log.levels.WARN)
          return
        end

        local begin_line = vim.fn.getline(start_line)
        local lang, args = parse_org_src_begin(begin_line)
        local temp_file = write_temp_file(code_lines, ".orgsrc")
        if not temp_file then
          return
        end

        local cmd = build_command(lang, args, temp_file)
        if not cmd then
          return
        end

        open_terminal_with_cmd(cmd)
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "markdown",
        callback = function(ev)
          vim.keymap.set("n", "<F8>", execute_markdown_code_block, {
            desc = "Execute Markdown code block",
            buffer = ev.buf,
          })
        end,
      })

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "org",
        callback = function(ev)
          vim.keymap.set("n", "<F8>", execute_org_src_block, {
            desc = "Execute Org src block",
            buffer = ev.buf,
          })
        end,
      })

      -- F7 映射在 keymaps.lua 中统一配置（避免重复/覆盖）

      -- 自检命令：快速判断是否加载/是否有映射/当前 ft
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
