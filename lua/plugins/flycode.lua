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

        -- 取第一个 token 作为 lang，其余作为 args（简单按空白切分）
        local tokens = {}
        for t in rest:gmatch("%S+") do
          table.insert(tokens, t)
        end

        local lang = tokens[1]
        if not lang or lang == "" then
          return nil, {}
        end

        -- 去掉 { ... } 配置块，例如：bash{cmd} / flycode{...}
        lang = lang:gsub("%b{}", "")
        lang = lang:lower()

        local args = {}
        for i = 2, #tokens do
          table.insert(args, tokens[i])
        end

        return lang, args
      end

      -- 自定义函数：执行当前 Markdown 代码块
      local function execute_markdown_code_block()
        vim.cmd("w")

        local current_line = vim.fn.line(".")

        -- 查找代码块开始
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

        -- 查找代码块结束
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

        -- 提取代码块内容
        local code_lines = {}
        for i = start_line + 1, end_line - 1 do
          table.insert(code_lines, vim.fn.getline(i))
        end

        -- 若块内全是空行，也视为未找到可执行内容
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

        -- 解析语言与参数
        local fence = vim.fn.getline(start_line)
        local lang, args = parse_fence(fence)

        -- 创建临时文件
        local temp_file = vim.fn.tempname() .. ".flycode"

        -- 写入代码到临时文件
        local file = io.open(temp_file, "w")
        if not file then
          vim.notify("Failed to create temp file: " .. temp_file, vim.log.levels.ERROR)
          return
        end
        for _, line in ipairs(code_lines) do
          file:write(line .. "\n")
        end
        file:close()

        -- 根据语言执行
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
          -- 支持形如：```flycode flycode.JSONFlow Poe:gpt-5.2
          -- 行为：把代码块写入 tmpfile，然后执行：flycode <arg1> <arg2> ... <tmpfile>
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
          return
        end

        -- 执行命令并显示结果
        vim.cmd("new")
        vim.cmd("term " .. cmd)
        vim.cmd("startinsert")
      end

      -- 设置 F8 映射
      vim.keymap.set("n", "<F8>", execute_markdown_code_block, { desc = "Execute Markdown code block" })

      -- 设置 F7 映射（已在 keymaps.lua 中配置，这里确保插件加载后可用）
      vim.keymap.set("n", "<F7>", ":execute 'r!'.getline('.')<CR>", { desc = "Execute current line" })

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

        vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
      end, { desc = "Check flycode/keymaps status" })
    end,
  },
}
