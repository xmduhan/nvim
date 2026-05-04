-- 目标：尽量用 Neovim 内置能力覆盖 Markdown 的
-- 1) 大纲折叠 2) 代码块折叠 3) 语法高亮 4) 尽量不和现有设置冲突
--
-- 说明：
-- - 这个文件【不是插件 spec】；它是“运行时配置模块”。
-- - lazy.nvim 需要的插件 spec 是 { "author/repo", ... } 这种表。
-- - 因此该模块需要由你的 init 或其它地方 require() 来执行 setup。
--
-- 功能：
-- - 折叠：对 markdown buffer 使用 foldmethod=expr + 自定义 foldexpr
-- - 大纲：#..###### 与 Setext(===/---)
-- - 代码块：```/~~~ fenced code block
-- - 高亮：优先内置 Tree-sitter（若无 parser 则退回 syntax）
-- - 操作：在 markdown buffer 用 <Tab> 开/关当前 fold（更顺手）

local M = {}

local function count_indent(s)
  local _, n = s:find("^%s+")
  return n or 0
end

local function is_blank(s)
  return s:match("^%s*$") ~= nil
end

local function is_fence_line(s)
  -- ``` 或 ~~~，允许前置空白
  return s:match("^%s*```+") ~= nil or s:match("^%s*~~~+") ~= nil
end

local function is_atx_heading(s)
  local hashes = s:match("^%s*(#+)%s+")
  if not hashes then
    return nil
  end
  local level = #hashes
  if level >= 1 and level <= 6 then
    return level
  end
  return nil
end

local function is_setext_underline(s)
  -- setext: 下一行是 === 或 ---
  if s:match("^%s*===+%s*$") then
    return 1
  end
  if s:match("^%s*---+%s*$") then
    return 2
  end
  return nil
end

-- Foldexpr：返回
--  - ">N" 开始一个 N 级 fold
--  - "aN" 延续/调整 fold 级别
--  - "=" 保持
--  - "0" 不折叠
function M.markdown_foldexpr(lnum)
  local line = vim.fn.getline(lnum)

  -- fenced code block：扫描到当前行来判断是否在 fence 内（简单可靠）
  local in_fence = false
  local fence_indent = 0
  for i = 1, lnum do
    local l = vim.fn.getline(i)
    if is_fence_line(l) then
      local ind = count_indent(l)
      if not in_fence then
        in_fence = true
        fence_indent = ind
      else
        if ind <= fence_indent then
          in_fence = false
          fence_indent = 0
        end
      end
    end
  end

  -- fence 行：若是 opening fence 则开 fold
  if is_fence_line(line) then
    local was_in_fence = false
    local was_fence_indent = 0
    for i = 1, lnum - 1 do
      local l = vim.fn.getline(i)
      if is_fence_line(l) then
        local ii = count_indent(l)
        if not was_in_fence then
          was_in_fence = true
          was_fence_indent = ii
        else
          if ii <= was_fence_indent then
            was_in_fence = false
            was_fence_indent = 0
          end
        end
      end
    end

    if not was_in_fence then
      return ">7" -- opening fence
    end
    return "=" -- closing fence
  end

  if in_fence then
    return "a7"
  end

  local h = is_atx_heading(line)
  if h then
    return ">" .. tostring(h)
  end

  local next_line = vim.fn.getline(lnum + 1)
  if next_line and next_line ~= "" then
    local setext = is_setext_underline(next_line)
    if setext and not is_blank(line) then
      return ">" .. tostring(setext)
    end
  end

  return "="
end

local function toggle_fold_under_cursor()
  -- foldclosed('.') != -1 表示当前行在一个“已关闭”的 fold 里
  if vim.fn.foldclosed(".") ~= -1 then
    vim.cmd("normal! zo")
  else
    -- 若当前行不在 fold 内，zc 不会做任何事；但这是预期行为
    vim.cmd("normal! zc")
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "markdown" },
    callback = function(ev)
      vim.opt_local.foldmethod = "expr"
      vim.opt_local.foldexpr = "v:lua.require('plugins.markdown').markdown_foldexpr(v:lnum)"

      vim.opt_local.foldlevel = 99
      vim.opt_local.foldenable = true

      -- 用 <Tab> 开/关折叠（仅 markdown buffer，不影响你其它文件类型/现有映射）
      vim.keymap.set("n", "<Tab>", toggle_fold_under_cursor, { desc = "Toggle fold", buffer = ev.buf, silent = true })

      -- 高亮：有 TS parser 就用内置 TS 高亮，否则 fallback 到传统 syntax
      local has_ts = pcall(vim.treesitter.get_parser, ev.buf)
      if not has_ts then
        pcall(vim.cmd, "syntax enable")
      end
    end,
  })
end

return M
