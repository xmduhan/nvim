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
map("n", "q", ":if &modifiable && expand('%:t') == '' | w | endif<CR>:bp<bar>sp<bar>bn<bar>bd<CR>", { desc = "Close buffer alternative" })

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
map("n", "<F7>", ":execute 'r!'.getline('.')<CR>", { desc = "Execute current line" })

-- 回车键增强：从本行按 [空格 或 :] 切分，找最近的合法路径(文件/目录)并保存跳转
-- 说明：orgmode 常用 <CR>/<TAB> 做折叠/展开。
-- 这里的策略是：
-- - 若当前行能解析出“存在的文件/目录路径”，则执行跳转
-- - 否则回退到该 filetype 原本的 <CR> 行为（不影响 org 的回车折叠/新行等）
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(ev)
    local rhs = function()
      local ok = pcall(function()
        require("config.functions").save_and_goto_nearest_path_in_line()
      end)

      -- 没有找到路径时 save_and_goto... 会 notify(WARN)；这里用启发式：
      -- 若执行失败(异常)则直接回退；正常情况下若无路径也不应阻断默认回车。
      if not ok then
        local keys = vim.api.nvim_replace_termcodes("<CR>", true, false, true)
        vim.api.nvim_feedkeys(keys, "n", false)
        return
      end

      -- 如果没有跳转，函数内部会提示 warn，但我们仍应回退到默认 <CR>
      -- 通过检测当前 buffer/光标是否变化不可靠，这里采用更简单的方式：
      -- 当本行不存在任何可打开的路径时，save_and_goto... 会提前 return。
      -- 为了不影响 org 的默认行为，我们在调用前先快速探测一次是否存在候选。
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
