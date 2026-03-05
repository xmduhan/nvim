-- 自定义函数

-- 切换行号显示模式
local function toggle_line_numbers()
  local number_status = vim.opt.number:get()
  local relativenumber_status = vim.opt.relativenumber:get()
  
  if number_status and not relativenumber_status then
    -- 当前是绝对行号，切换到相对行号
    vim.opt.relativenumber = true
    vim.notify("Relative line numbers enabled")
  elseif number_status and relativenumber_status then
    -- 当前是相对行号，切换到关闭行号
    vim.opt.number = false
    vim.opt.relativenumber = false
    vim.notify("Line numbers disabled")
  else
    -- 当前关闭行号，切换到绝对行号
    vim.opt.number = true
    vim.notify("Absolute line numbers enabled")
  end
end

-- 创建光标下的文件
local function open_or_create_file()
  local file = vim.fn.expand("<cfile>")
  if vim.fn.filereadable(file) == 1 or vim.fn.isdirectory(file) == 1 then
    vim.cmd("edit " .. file)
  else
    -- 创建父目录
    local dir = vim.fn.fnamemodify(file, ":h")
    if dir ~= "." and dir ~= "" then
      vim.fn.mkdir(dir, "p")
    end
    vim.cmd("edit " .. file)
    vim.notify("File created: " .. file)
  end
end

-- 创建光标下的文件（touch）
local function touch_file_under_cursor()
  local file_path = vim.fn.expand("<cfile>")
  if file_path ~= "" then
    local cmd = "touch " .. vim.fn.shellescape(file_path)
    vim.fn.system(cmd)
    vim.notify("File touched: " .. file_path)
  else
    vim.notify("No valid file path under cursor", vim.log.levels.WARN)
  end
end

-- 插入当前日期时间
local function insert_datetime()
  local datetime = vim.fn.system('date +"%Y-%m-%d %H:%M:%S"')
  datetime = datetime:gsub("\n$", "")
  vim.api.nvim_put({ datetime }, "c", false, true)
end

-- 导出函数
local M = {}

M.toggle_line_numbers = toggle_line_numbers
M.open_or_create_file = open_or_create_file
M.touch_file_under_cursor = touch_file_under_cursor
M.insert_datetime = insert_datetime

return M
