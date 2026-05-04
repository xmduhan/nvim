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

local function trim(s)
  return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

-- 用于 <CR>：从当前行按 [空格 或 :] 切分，找出合法路径(文件/目录)，多个则选离光标最近的
local function save_and_goto_nearest_path_in_line()
  local line = vim.api.nvim_get_current_line()
  local col0 = vim.api.nvim_win_get_cursor(0)[2] -- 0-based

  -- 记录候选：{path=..., start=..., finish=..., dist=...}
  local candidates = {}

  local function add_candidate(token, s, e)
    token = trim(token)
    if token == "" then
      return
    end

    -- 常见包裹符号去掉（不改变 start/end 的选择逻辑，只是用于判断路径）
    token = token:gsub("^[%[%(%{%<%\"%']+", ""):gsub("[%]%)%}%>%\"%']+$", "")
    token = trim(token)
    if token == "" then
      return
    end

    -- 展开 ~ 等
    local expanded = vim.fn.expand(token)

    if vim.fn.filereadable(expanded) == 1 or vim.fn.isdirectory(expanded) == 1 then
      -- 到 token 的距离：若光标在 token 内距离为0，否则到最近边界
      local dist
      if col0 >= s and col0 <= e then
        dist = 0
      elseif col0 < s then
        dist = s - col0
      else
        dist = col0 - e
      end

      table.insert(candidates, {
        path = expanded,
        start = s,
        finish = e,
        dist = dist,
      })
    end
  end

  -- 按分隔符(空格或:)扫描 token，同时保留 token 的起止列
  local i = 1
  local n = #line
  while i <= n do
    -- 跳过分隔符
    while i <= n do
      local ch = line:sub(i, i)
      if ch == " " or ch == ":" then
        i = i + 1
      else
        break
      end
    end
    if i > n then
      break
    end

    local start_i = i
    while i <= n do
      local ch = line:sub(i, i)
      if ch == " " or ch == ":" then
        break
      end
      i = i + 1
    end
    local end_i = i - 1

    local token = line:sub(start_i, end_i)
    -- 转为 0-based column 范围
    add_candidate(token, start_i - 1, end_i - 1)
  end

  if #candidates == 0 then
    vim.notify("No valid file path found in current line", vim.log.levels.WARN)
    return
  end

  table.sort(candidates, function(a, b)
    if a.dist ~= b.dist then
      return a.dist < b.dist
    end
    return a.start < b.start
  end)

  local target = candidates[1].path

  -- 先尝试保存（无文件名时静默跳过）
  if vim.bo.modifiable and vim.fn.expand("%:t") ~= "" then
    pcall(vim.cmd, "silent write")
  end

  -- 再跳转
  vim.cmd("edit " .. vim.fn.fnameescape(target))
end

-- 导出函数
local M = {}

M.toggle_line_numbers = toggle_line_numbers
M.open_or_create_file = open_or_create_file
M.touch_file_under_cursor = touch_file_under_cursor
M.insert_datetime = insert_datetime
M.save_and_goto_nearest_path_in_line = save_and_goto_nearest_path_in_line

return M
