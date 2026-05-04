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

        -- 提取代码块内容
        local code_lines = {}
        for i = start_line + 1, end_line - 1 do
          table.insert(code_lines, vim.fn.getline(i))
        end

        if #code_lines == 0 then
          vim.notify("No code block found", vim.log.levels.WARN)
          return
        end

        -- 解析语言：允许 ```python linenums / ```bash{...} / ```sh 等
        -- 取 ``` 后的第一个 token，并去掉可能的 {..} 后缀
        local fence = vim.fn.getline(start_line)
        local lang = fence:match("^```%s*([^%s]+)")
        if lang then
          lang = lang:gsub("%b{}", "")
          lang = lang:lower()
        end

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

        -- 根据语言执行（不再直接执行 temp_file，避免 permission denied）
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
        else
          local hint = lang and ("Unknown code block language: " .. lang) or "Missing code block language"
          vim.notify(hint .. ". Please use fenced code block like ```python / ```bash / ```lua", vim.log.levels.WARN)
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
    end,
  },
}
