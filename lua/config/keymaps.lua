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
-- 注意：orgmode 常用 <CR>/<TAB> 做折叠/展开；全局覆盖 <CR> 会导致 org 里“回车折叠”失效。
-- 这里改为：非 org 文件才映射 <CR>，org 文件保持默认行为。
vim.api.nvim_create_autocmd("FileType", {
  pattern = "*",
  callback = function(ev)
    if vim.bo[ev.buf].filetype == "org" then
      return
    end
    vim.keymap.set(
      "n",
      "<CR>",
      function() require("config.functions").save_and_goto_nearest_path_in_line() end,
      { desc = "Save and goto nearest path in line", buffer = ev.buf }
    )
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
