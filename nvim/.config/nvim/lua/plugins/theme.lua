-- Conditional theme loader: uses omarchy theme if available, falls back to catppuccin
local omarchy_theme = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

if vim.fn.filereadable(omarchy_theme) == 1 then
  -- Load omarchy theme
  return dofile(omarchy_theme)
else
  -- Fallback to catppuccin
  return {
    {
      "catppuccin/nvim",
      name = "catppuccin",
      lazy = false,
      priority = 1000,
      opts = {
        flavour = "mocha",
      },
    },
    {
      "LazyVim/LazyVim",
      opts = {
        colorscheme = "catppuccin",
      },
    },
  }
end
