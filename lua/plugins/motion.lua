return {
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    ---@type Flash.Config
    opts = {
      modes = {
        -- 让 search 模式也使用 flash（/ 和 ? 之后的高亮/跳转更好用）
        search = {
          enabled = true,
        },
      },
    },
    keys = {
      -- 常用：类似 "s" 快速跳到屏幕内任意位置
      {
        "s",
        function()
          require("flash").jump()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash: jump",
      },
      -- 选中 Treesitter 节点/语法单元
      {
        "S",
        function()
          require("flash").treesitter()
        end,
        mode = { "n", "x", "o" },
        desc = "Flash: treesitter",
      },
      -- 远程操作（类似 easymotion 的远程编辑/选择能力）
      {
        "r",
        function()
          require("flash").remote()
        end,
        mode = "o",
        desc = "Flash: remote",
      },
      {
        "R",
        function()
          require("flash").treesitter_search()
        end,
        mode = { "o", "x" },
        desc = "Flash: treesitter search",
      },

      -- 保持你原先的 leader 习惯：
      -- <leader>f：跨窗口 jump（接近 easymotion-overwin-w）
      {
        "<leader>f",
        function()
          require("flash").jump({
            search = {
              multi_window = true,
            },
          })
        end,
        mode = { "n", "x", "o" },
        desc = "Flash: jump (multi-window)",
      },
      -- <leader>j：向下跳（这里做成 "向下" 的字符落点）
      {
        "<leader>j",
        function()
          require("flash").jump({
            search = {
              forward = true,
              wrap = false,
              multi_window = true,
            },
          })
        end,
        mode = { "n", "x", "o" },
        desc = "Flash: jump forward",
      },
    },
  },
}
