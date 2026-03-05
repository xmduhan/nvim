-- Neovim主配置文件
-- 设置leader键
vim.g.mapleader = " "
vim.g.maplocalleader = ","

-- 导入配置模块
require("config.options")
require("config.keymaps")
require("config.autocmds")

-- 延迟加载插件
require("plugins.init")
