-- MLFS - My Lovely File Selector
-- Main plugin entry point

local finder = require('mlfs.finder')

local M = {}

-- Plugin configuration
M.config = {
  -- Directories/patterns to exclude from search
  exclude_patterns = {
    'node_modules',
    '.git',
    'dist',
    'build',
    'target',
    '.next',
    'coverage',
  },
  -- Whether to show hidden files (files starting with .)
  show_hidden = true,
  -- Height of the fzf window (in lines)
  window_height = 15,
  -- Keybinding for opening the file selector
  keymap = '<leader><leader>',
}

-- Setup function
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_extend('force', M.config, opts)

  -- Update finder config
  finder.config = M.config

  -- Setup keymap if provided
  if M.config.keymap then
    vim.keymap.set('n', M.config.keymap, function()
      M.find()
    end, {
      noremap = true,
      silent = true,
      desc = 'Open MLFS file selector',
    })
  end
end

-- Open file finder
function M.find()
  finder.open()
end

-- Create user commands
vim.api.nvim_create_user_command('MLFSFind', function()
  M.find()
end, {
  desc = 'Open MLFS file selector',
})

return M
