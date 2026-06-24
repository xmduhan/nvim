-- 本地配置，用于项目特定的设置
local function load_local_config()
  local local_config = vim.fn.getcwd() .. "/.nvim.lua"
  if vim.fn.filereadable(local_config) == 1 and vim.fn.getcwd() ~= vim.fn.expand("~") then
    vim.cmd("source " .. local_config)
  end
end

-- 自动加载本地配置
vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  callback = load_local_config,
})

return {
  load_local_config = load_local_config,
}
