local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  -- 插件管理器自身
  { "folke/lazy.nvim", version = "*" },

  -- 颜色主题
  -- require("plugins.colorscheme"),

  -- 文件浏览器
  -- require("plugins.explorer"),

  -- Markdown支持
  -- require("plugins.markdown"),

  -- Git集成
  -- require("plugins.git"),

  -- 对齐工具
  -- require("plugins.align"),

  -- 运动插件
  -- require("plugins.motion"),

  -- Flycode插件
  require("plugins.flycode"),

  -- Org模式
  require("plugins.orgmode"),
}, {
  install = {
    colorscheme = { "molokai" },
  },
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    notify = false,
  },
})
