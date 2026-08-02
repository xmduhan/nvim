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

local function is_directory_viewer_buffer()
  local buftype = vim.bo.buftype
  local filetype = vim.bo.filetype
  local name = vim.api.nvim_buf_get_name(0)

  -- netrw 打开的目录 buffer 通常 filetype=netrw；buffer name 可能为空，因此不能依赖名称判断。
  -- nvim-tree / neo-tree / oil 等目录查看器也通常有独立 filetype。
  if vim.tbl_contains({ "netrw", "NvimTree", "neo-tree", "oil" }, filetype) then
    return true
  end

  -- 某些情况下直接 :edit 目录时，buffer name 仍然是目录路径
  if name ~= "" and vim.fn.isdirectory(name) == 1 then
    return true
  end

  return buftype == "nofile" and name ~= "" and vim.fn.isdirectory(vim.fn.expand("%:p")) == 1
end


-- 关闭当前 buffer，并尽量保持窗口布局/跳转到相邻 buffer
local function close_buffer_alternative()
  if is_directory_viewer_buffer() then
    return
  end

  if vim.bo.modifiable and vim.fn.expand("%:t") == "" then
    vim.cmd("write")
  end

  vim.cmd("bp")
  vim.cmd("sp")
  vim.cmd("bn")
  vim.cmd("bd")
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

local function shell_join(args)
  local escaped = {}
  for _, a in ipairs(args or {}) do
    table.insert(escaped, vim.fn.shellescape(a))
  end
  return table.concat(escaped, " ")
end

local persistent_terminal = {
  buf = nil,
  win = nil,
  job = nil,
}

local function is_terminal_buf_valid(buf)
  return buf and vim.api.nvim_buf_is_valid(buf)
end

local function is_terminal_win_valid(win)
  return win and vim.api.nvim_win_is_valid(win)
end

local function ensure_persistent_terminal_window()
  if is_terminal_win_valid(persistent_terminal.win) and is_terminal_buf_valid(persistent_terminal.buf) then
    return persistent_terminal.win, persistent_terminal.buf
  end

  if is_terminal_buf_valid(persistent_terminal.buf) then
    vim.cmd("vsplit")
    vim.cmd("wincmd L")
    local win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(win, persistent_terminal.buf)
    vim.cmd("vertical resize " .. math.floor(vim.o.columns / 2))
    persistent_terminal.win = win
    return persistent_terminal.win, persistent_terminal.buf
  end

  vim.cmd("vsplit")
  vim.cmd("wincmd L")
  vim.cmd("vertical resize " .. math.floor(vim.o.columns / 2))

  local win = vim.api.nvim_get_current_win()
  vim.cmd("terminal")
  local buf = vim.api.nvim_get_current_buf()
  local job = vim.b.terminal_job_id

  persistent_terminal.win = win
  persistent_terminal.buf = buf
  persistent_terminal.job = job

  vim.bo[buf].bufhidden = "hide"
  vim.bo[buf].modified = false

  vim.api.nvim_create_autocmd({ "BufWipeout", "TermClose" }, {
    buffer = buf,
    once = false,
    callback = function()
      if persistent_terminal.buf == buf then
        persistent_terminal.buf = nil
        persistent_terminal.win = nil
        persistent_terminal.job = nil
      end
    end,
  })

  return persistent_terminal.win, persistent_terminal.buf
end

local function focus_persistent_terminal_insert()
  local win, _ = ensure_persistent_terminal_window()
  if is_terminal_win_valid(win) then
    vim.api.nvim_set_current_win(win)
    vim.cmd("startinsert")
  end
end

local function send_command_to_persistent_terminal(cmd)
  local _, buf = ensure_persistent_terminal_window()
  local job = persistent_terminal.job

  if (not job or job <= 0) and is_terminal_buf_valid(buf) then
    job = vim.b[buf].terminal_job_id
    persistent_terminal.job = job
  end

  if not job or job <= 0 then
    vim.notify("Terminal job is not available", vim.log.levels.ERROR)
    return false
  end

  local ok = vim.fn.chansend(job, cmd .. "\n")
  if ok == 0 then
    vim.notify("Failed to send command to terminal", vim.log.levels.ERROR)
    return false
  end

  focus_persistent_terminal_insert()
  return true
end

local function open_terminal_with_cmd(cmd)
  return send_command_to_persistent_terminal(cmd)
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

local function parse_markdown_fence(fence_line)
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
  local rest = line:match("^%s*#%+begin_src%s+(.*)$")
    or line:match("^%s*#%+BEGIN_SRC%s+(.*)$")
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

local function build_code_block_command(lang, args, temp_file)
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
  local lang, args = parse_markdown_fence(fence)
  local temp_file = write_temp_file(code_lines, ".flycode")
  if not temp_file then
    return
  end

  local cmd = build_code_block_command(lang, args, temp_file)
  if not cmd then
    return
  end

  open_terminal_with_cmd(cmd)
end

local function is_org_src_begin_line(line)
  return line:match("^%s*#%+begin_src\b") ~= nil
    or line:match("^%s*#%+BEGIN_SRC\b") ~= nil
end

local function is_org_src_end_line(line)
  return line:match("^%s*#%+end_src\b") ~= nil
    or line:match("^%s*#%+END_SRC\b") ~= nil
end

local function is_org_heading_line(line)
  return line:match("^%*+%s") ~= nil
end

local function is_org_meta_line(line)
  return line:match("^%s*#%+") ~= nil
end

local function is_plain_code_terminator(line)
  local t = trim(line)
  if t == "" then
    return true
  end
  if is_org_heading_line(line) then
    return true
  end
  if is_org_meta_line(line) then
    return true
  end
  if t == "输出：" or t:match("^输出[:：]") then
    return true
  end
  if t:match("^[0-9一二三四五六七八九十]+[%.、]") then
    return true
  end
  if t:match("^[-=]+$") then
    return true
  end
  return false
end

local function looks_like_python_line(line)
  local t = trim(line)
  if t == "" then
    return false
  end

  if t:match("^import%s+[%w_%.]+") then
    return true
  end
  if t:match("^from%s+[%w_%.]+%s+import%s+") then
    return true
  end
  if t:match("^print%(") then
    return true
  end
  if t:match("^[%w_]+%s*=%s*") then
    return true
  end
  if t:match("^for%s+.+:%s*$") or t:match("^while%s+.+:%s*$") or t:match("^if%s+.+:%s*$") then
    return true
  end
  if t:match("^def%s+[%w_]+%s*%(") or t:match("^class%s+[%w_]+") then
    return true
  end
  return false
end

local function looks_like_lua_line(line)
  local t = trim(line)
  if t == "" then
    return false
  end

  if t:match("^local%s+") then
    return true
  end
  if t:match("^print%(") then
    return true
  end
  if t:match("^function%s+") or t:match("^for%s+") or t:match("^if%s+") then
    return true
  end
  return false
end

local function looks_like_shell_line(line)
  local t = trim(line)
  if t == "" then
    return false
  end

  if t:match("^echo%s+") or t:match("^cd%s+") or t:match("^ls%s*") then
    return true
  end
  if t:match("^[%w_]+=%S+") then
    return true
  end
  if t:match("^if%s+") or t:match("^for%s+") then
    return true
  end
  return false
end

local function looks_like_javascript_line(line)
  local t = trim(line)
  if t == "" then
    return false
  end

  if t:match("^const%s+") or t:match("^let%s+") or t:match("^var%s+") then
    return true
  end
  if t:match("^console%.log%(") then
    return true
  end
  if t:match("^function%s+") or t:match("=>") then
    return true
  end
  return false
end

local function detect_code_language(lines)
  local score = {
    python = 0,
    lua = 0,
    sh = 0,
    javascript = 0,
  }

  for _, line in ipairs(lines) do
    if looks_like_python_line(line) then
      score.python = score.python + 2
    end
    if looks_like_lua_line(line) then
      score.lua = score.lua + 1
    end
    if looks_like_shell_line(line) then
      score.sh = score.sh + 1
    end
    if looks_like_javascript_line(line) then
      score.javascript = score.javascript + 1
    end
  end

  local best_lang = nil
  local best_score = 0
  for lang, s in pairs(score) do
    if s > best_score then
      best_lang = lang
      best_score = s
    end
  end

  if best_score <= 0 then
    return nil
  end

  return best_lang
end

local function collect_plain_org_code_block()
  local current_line = vim.fn.line(".")
  local total_lines = vim.fn.line("$")
  local current_text = vim.fn.getline(current_line)

  if is_plain_code_terminator(current_text) then
    return nil, nil
  end

  local start_line = current_line
  while start_line > 1 do
    local prev = vim.fn.getline(start_line - 1)
    if is_plain_code_terminator(prev) then
      break
    end
    start_line = start_line - 1
  end

  local end_line = current_line
  while end_line < total_lines do
    local nxt = vim.fn.getline(end_line + 1)
    if is_plain_code_terminator(nxt) then
      break
    end
    end_line = end_line + 1
  end

  local code_lines = {}
  for i = start_line, end_line do
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
    return nil, nil
  end

  local lang = detect_code_language(code_lines)
  if not lang then
    return nil, nil
  end

  return code_lines, lang
end

local function execute_org_src_block()
  vim.cmd("w")

  local current_line = vim.fn.line(".")
  local total_lines = vim.fn.line("$")

  local start_line = current_line
  while start_line >= 1 do
    local line_content = vim.fn.getline(start_line)
    if is_org_src_begin_line(line_content) then
      break
    end
    if start_line ~= current_line and is_org_src_end_line(line_content) then
      break
    end
    start_line = start_line - 1
  end

  if start_line >= 1 and is_org_src_begin_line(vim.fn.getline(start_line)) then
    local end_line = start_line + 1
    while end_line <= total_lines do
      local line_content = vim.fn.getline(end_line)
      if is_org_src_end_line(line_content) then
        break
      end
      end_line = end_line + 1
    end

    if end_line > total_lines then
      vim.notify("Unclosed org src block (missing #+end_src)", vim.log.levels.WARN)
      return
    end

    if current_line > end_line then
      vim.notify("Cursor is not inside an org src block", vim.log.levels.WARN)
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

    local cmd = build_code_block_command(lang, args, temp_file)
    if not cmd then
      return
    end

    open_terminal_with_cmd(cmd)
    return
  end

  local plain_code_lines, detected_lang = collect_plain_org_code_block()
  if not plain_code_lines or not detected_lang then
    vim.notify("No org src block found, and no runnable plain code block detected", vim.log.levels.WARN)
    return
  end

  local temp_file = write_temp_file(plain_code_lines, ".orgplain")
  if not temp_file then
    return
  end

  local cmd = build_code_block_command(detected_lang, {}, temp_file)
  if not cmd then
    return
  end

  open_terminal_with_cmd(cmd)
end

-- 导出函数
local M = {}

M.toggle_line_numbers = toggle_line_numbers
M.open_or_create_file = open_or_create_file
M.touch_file_under_cursor = touch_file_under_cursor
M.insert_datetime = insert_datetime
M.close_buffer_alternative = close_buffer_alternative
M.save_and_goto_nearest_path_in_line = save_and_goto_nearest_path_in_line
M.execute_markdown_code_block = execute_markdown_code_block
M.execute_org_src_block = execute_org_src_block
M.focus_persistent_terminal_insert = focus_persistent_terminal_insert

return M
