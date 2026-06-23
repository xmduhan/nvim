-- netrw 文件类型配置
--
-- 目标：显式禁用 netrw 原生 q 行为，统一使用全局自定义关闭逻辑。
-- 这样在 netrw buffer 中按 q 时，不再触发 netrw 自带动作，而是关闭当前 netrw 窗口/buffer。

vim.keymap.set("n", "q", function()
  require("config.functions").close_buffer_alternative()
end, {
  buffer = true,
  silent = true,
  desc = "Close netrw buffer (disable native q)",
})
