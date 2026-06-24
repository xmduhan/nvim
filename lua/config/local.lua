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

-- netrw 配置
local ok, netrw = pcall(require, "netrw")
if ok then
  netrw.setup({
    -- File icons to use when `use_devicons` is false or if
    -- no icon is found for the given file type.
    icons = {
      symlink = "",
      directory = "",
      file = "",
    },
    -- Uses mini.icon or nvim-web-devicons if true, otherwise use the file icon specified above
    use_devicons = true,
    mappings = {
      -- Function mappings receive an object describing the node under the cursor
      ["p"] = function(payload)
        print(vim.inspect(payload))
      end,
      -- String mappings are executed as vim commands
      ["<Leader>p"] = ":echo 'hello world'<CR>",
    },
  })
end

return {
  load_local_config = load_local_config,
}
