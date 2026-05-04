return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      modes = {
        -- 仅启用 search 模式的 flash（/ 和 ? 之后的高亮/跳转更好用）
        search = {
          enabled = true,
        },
        -- 其余模式保持默认行为（不接管按键）
        char = { enabled = false },
        treesitter = { enabled = false },
      },
    },
    -- 去掉所有自定义 keys，让 s/S/r/R/<leader>f/<leader>j 等保持 nvim 默认行为
    keys = {},
  },
}
