-- 键位映射配置
local map = vim.keymap.set

-- 基础映射
map("n", "<leader><CR>", function() require("config.functions").open_or_create_file() end, { desc = "Open or create file" })
map("n", "<leader>t", function() require("config.functions").touch_file_under_cursor() end, { desc = "Touch file under cursor" })
map("n", "<leader>d<CR>", function() require("config.functions").insert_datetime() end, { desc = "Insert datetime" })

-- 标签页导航
map("n", "<C-T>", ":tabnew<CR>", { desc = "New tab" })

-- 折叠
map("n", "<leader><space>", "za", { desc = "Toggle fold" })

-- 删除多余空格
map("n", "<leader>d<space>", ":%s/\\s\\+$//e<CR>", { desc = "Remove trailing spaces" })

-- 缓冲区导航
map("n", "<leader>''", ":w<CR>:b#<CR>", { desc = "Switch to previous buffer" })
map("n", "<leader>q", ":if &modifiable && expand('%:t') != '' | w | endif<CR>:q<CR>", { desc = "Close buffer" })
map("n", "q", function() require("config.functions").close_buffer_alternative() end, { desc = "Close buffer alternative" })

map("n", "<C-N>", ":w<CR>:bn<CR>", { desc = "Next buffer" })
map("n", "<C-P>", ":w<CR>:bp<CR>", { desc = "Previous buffer" })

-- 快速移动
map("n", "<C-H>", "B", { desc = "Move back by WORD" })
map("n", "<C-L>", "W", { desc = "Move forward by WORD" })
map("n", "<C-J>", "12j", { desc = "Move down 12 lines" })
map("n", "<C-K>", "12k", { desc = "Move up 12 lines" })

-- 快速保存
map("n", "<C-S>", ":w<CR>", { desc = "Save file" })

-- 功能键
map("n", "<F3>", function() require("config.functions").toggle_line_numbers() end, { desc = "Toggle line numbers" })

-- F7：执行当前行作为 shell 命令；若以 "!xxx:" 开头则去掉该前缀再执行
map("n", "<F7>", function()
  local line = vim.api.nvim_get_current_line()
  -- 匹配：可选前导空白 + !任意非冒号内容:
  -- 例："!sh: ls -alh" => "ls -alh"
  line = line:gsub("^%s*!([^:]*):%s*", "")
  vim.cmd("execute 'r!' .. " .. vim.fn.string(line))
end, { desc = "Execute current line (strip !xxx: prefix)" })

-- netrw 缓冲区：<Esc> 先切到下一个 buffer，1 秒后删除原 netrw buffer
vim.api.nvim_create_autocmd("FileType", {
  pattern = "netrw",
  callback = function(ev)
    vim.keymap.set("n", "<Esc>", function()
      local bufnr = vim.api.nvim_get_current_buf()
      vim.cmd("bn")
      vim.defer_fn(function()
        if vim.api.nvim_buf_is_valid(bufnr) then
          -- 这里写死了2, 有问题后续思考如何修改
          vim.cmd("bd 2" ) 
        end
      end, 1000)
    end, { desc = "Close netrw buffer after switching", buffer = ev.buf, silent = true })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(ev)
    vim.keymap.set("n", "<F8>", function()
      require("config.functions").execute_markdown_code_block()
    end, {
      desc = "Execute Markdown code block",
      buffer = ev.buf,
      silent = true,
    })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  pattern = "org",
  callback = function(ev)
    vim.keymap.set("n", "<F8>", function()
      require("config.functions").execute_org_src_block()
    end, {
      desc = "Execute Org src block",
      buffer = ev.buf,
      silent = true,
    })
  end,
})

-- <CR>：普通 buffer 中若当前行有可打开路径则跳转；排除 netrw 目录缓冲区，避免覆盖其默认回车行为
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(ev)
    if vim.tbl_contains({ "netrw" }, vim.bo[ev.buf].filetype) then
      return
    end

    local function has_openable_path_in_line()
      local line = vim.api.nvim_get_current_line()
      local function trim(s)
        return (s:gsub("^%s+", ""):gsub("%s+$", ""))
      end

      for token in line:gmatch("[^%s:]+") do
        token = trim(token)
        token = token:gsub("^[%[%(%{%<%\"%']+", ""):gsub("[%]%)%}%>%\"%']+$", "")
        token = trim(token)
        if token ~= "" then
          local expanded = vim.fn.expand(token)
          if vim.fn.filereadable(expanded) == 1 or vim.fn.isdirectory(expanded) == 1 then
            return true
          end
        end
      end
      return false
    end

    vim.keymap.set("n", "<CR>", function()
      if has_openable_path_in_line() then
        require("config.functions").save_and_goto_nearest_path_in_line()
      else
        -- 回退到默认 <CR>
        local keys = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
        vim.api.nvim_feedkeys(keys, "n", false)
      end
    end, { desc = "Goto nearest path in line (fallback to default <CR>)", buffer = ev.buf })
  end,
})

-- 配置编辑
map("n", "<leader>main", ":e ~/.config/nvim/init.lua<CR>", { desc = "Edit main config" })
map("n", "<leader>plugin", ":e ~/.config/nvim/lua/plugins/init.lua<CR>", { desc = "Edit plugin config" })

-- 插入模式映射
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- 可视模式映射
map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
