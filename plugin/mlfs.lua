-- MLFS plugin initialization
-- This file is automatically loaded by Neovim

-- Prevent loading twice
if vim.g.loaded_mlfs then
  return
end
vim.g.loaded_mlfs = 1

-- Setup default highlight groups
-- These integrate with the current colorscheme
local function setup_highlights()
  -- Only set if not already defined by colorscheme
  vim.api.nvim_set_hl(0, 'MLFSBorder', { link = 'FloatBorder' })
  vim.api.nvim_set_hl(0, 'MLFSTitle', { link = 'Title' })
  vim.api.nvim_set_hl(0, 'MLFSMatch', { link = 'Search' })
end

-- Setup highlights on colorscheme change
setup_highlights()
vim.api.nvim_create_autocmd('ColorScheme', {
  pattern = '*',
  callback = setup_highlights,
  desc = 'Update MLFS highlight groups on colorscheme change',
})
