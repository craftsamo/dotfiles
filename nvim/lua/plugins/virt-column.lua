-- https://github.com/lukas-reineke/virt-column.nvim
--
-- Filename: ~/.config/nvim/lua/plugins/virt-column.lua
-- ~/.config/nvim/lua/plugins/virt-column.lua
--
-- Plugin that shows the veritcal bar or vertical column
-- It replaces my vim.opt.colorcolumn = "80" configuration

return {
  "lukas-reineke/virt-column.nvim",
  opts = {
    -- char = "|",
    -- char = "",
    -- char = "┇",
    -- char = "∶",
    -- char = "∷",
    -- char = "║",
    -- char = "⋮",
    -- char = "",
    char = "󰮾",
    virtcolumn = "80",
  },
}
