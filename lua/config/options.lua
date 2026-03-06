-- Neovim选项配置
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

-- 界面设置
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.showmode = false
vim.opt.signcolumn = "yes"

-- 光标形状设置
-- 在insert模式下使用块状光标，normal模式下使用竖线光标
vim.opt.guicursor = "n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- 缩进设置
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2

-- 搜索设置
vim.opt.incsearch = true
vim.opt.hlsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- 窗口设置
vim.opt.splitbelow = true
vim.opt.splitright = true

-- 其他设置
vim.opt.backspace = "indent,eol,start"
vim.opt.clipboard = "unnamedplus"
vim.opt.mouse = ""
vim.opt.timeoutlen = 300
vim.opt.updatetime = 300

-- 折叠设置
vim.opt.foldmethod = "indent"
vim.opt.foldlevel = 99

-- 换行设置
vim.opt.wrap = false
vim.opt.linebreak = true

-- 备份设置
vim.opt.swapfile = false
vim.opt.backup = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"

-- 补全设置
vim.opt.completeopt = "menuone,noselect"

