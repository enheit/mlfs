-- File finder with custom UI

local ui = require('mlfs.ui')
local fuzzy = require('mlfs.fuzzy')

local M = {}

-- Plugin configuration (will be set from init.lua)
M.config = {}

-- Cached file list
local file_cache = {
  files = {},
  root = nil,
}

-- Check if a command exists
local function command_exists(cmd)
  local handle = io.popen('command -v ' .. cmd .. ' 2>/dev/null')
  if not handle then
    return false
  end
  local result = handle:read('*a')
  handle:close()
  return result ~= ''
end

-- Get the project root (where nvim was opened)
local function get_project_root()
  return vim.fn.getcwd()
end

-- Build file listing command
local function build_file_list_command()
  local root = get_project_root()
  local exclude_patterns = M.config.exclude_patterns or {}

  -- Prefer fd over find (fd is faster and more user-friendly)
  if command_exists('fd') then
    -- Build fd command
    local cmd = 'fd --type f --color never'

    -- Show hidden files (files starting with .)
    if M.config.show_hidden then
      cmd = cmd .. ' --hidden'
    end

    -- Add exclude patterns
    for _, pattern in ipairs(exclude_patterns) do
      cmd = cmd .. ' --exclude "' .. pattern .. '"'
    end

    -- Add root directory
    cmd = cmd .. ' . "' .. root .. '"'

    return cmd
  else
    -- Fallback to find command
    local cmd = 'find "' .. root .. '" -type f'

    -- Exclude patterns using -path and -prune
    for _, pattern in ipairs(exclude_patterns) do
      cmd = cmd .. ' -path "*/' .. pattern .. '/*" -prune -o'
    end

    -- Final print command
    cmd = cmd .. ' -type f -print'

    return cmd
  end
end

-- Get list of files in project
local function get_files()
  local root = get_project_root()

  -- Return cached files if root hasn't changed
  if file_cache.root == root and #file_cache.files > 0 then
    return file_cache.files
  end

  -- Get new file list
  local cmd = build_file_list_command()
  local handle = io.popen(cmd)
  if not handle then
    return {}
  end

  local files = {}
  for line in handle:lines() do
    -- Make path relative to root
    local filepath = line
    if filepath:sub(1, #root) == root then
      filepath = filepath:sub(#root + 2)  -- +2 to skip the trailing /
    end
    table.insert(files, filepath)
  end
  handle:close()

  -- Update cache
  file_cache.files = files
  file_cache.root = root

  return files
end

-- Update results based on current query
local function update_results()
  if not ui.is_open() then
    return
  end

  local query = ui.get_query()
  local all_files = get_files()

  -- Filter files using fuzzy matching
  local results = fuzzy.filter(query, all_files)

  -- Render results
  ui.render_results(results, query)
end

-- Handle file selection
local function select_file()
  local selected = ui.get_selected()
  if not selected then
    ui.close()
    return
  end

  -- Close UI first
  ui.close()

  -- Open the selected file
  vim.cmd('edit ' .. vim.fn.fnameescape(selected))
end

-- Setup keymaps for the picker
local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }

  -- Close picker
  vim.keymap.set('n', 'q', function() ui.close() end, opts)
  vim.keymap.set('n', '<Esc>', function() ui.close() end, opts)
  vim.keymap.set('i', '<Esc>', function()
    ui.close()
    vim.cmd('stopinsert')
  end, opts)

  -- Select file
  vim.keymap.set('i', '<CR>', function()
    vim.cmd('stopinsert')
    select_file()
  end, opts)
  vim.keymap.set('n', '<CR>', select_file, opts)

  -- Navigation
  vim.keymap.set('i', '<C-n>', function()
    ui.select_next()
  end, opts)
  vim.keymap.set('i', '<C-p>', function()
    ui.select_prev()
  end, opts)
  vim.keymap.set('i', '<Down>', function()
    ui.select_next()
  end, opts)
  vim.keymap.set('i', '<Up>', function()
    ui.select_prev()
  end, opts)
  vim.keymap.set('n', 'j', function()
    ui.select_next()
  end, opts)
  vim.keymap.set('n', 'k', function()
    ui.select_prev()
  end, opts)
end

-- Setup autocmds for real-time updates
local function setup_autocmds(buf)
  local augroup = vim.api.nvim_create_augroup('MLFSPicker', { clear = true })

  -- Update results on text change and prevent multi-line
  vim.api.nvim_create_autocmd({ 'TextChangedI', 'TextChanged' }, {
    group = augroup,
    buffer = buf,
    callback = function()
      -- Prevent multiple lines
      local line_count = vim.api.nvim_buf_line_count(buf)
      if line_count > 1 then
        local prompt_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, { prompt_line })
      end

      -- Only update if we're on the first line (prompt line)
      local cursor = vim.api.nvim_win_get_cursor(0)
      if cursor[1] == 1 then
        update_results()
      end
    end,
  })

  -- Keep cursor on first line in normal mode
  vim.api.nvim_create_autocmd('CursorMoved', {
    group = augroup,
    buffer = buf,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      if cursor[1] ~= 1 then
        vim.api.nvim_win_set_cursor(0, { 1, cursor[2] })
      end
    end,
  })

  -- Keep cursor on first line in insert mode
  vim.api.nvim_create_autocmd('CursorMovedI', {
    group = augroup,
    buffer = buf,
    callback = function()
      local cursor = vim.api.nvim_win_get_cursor(0)
      if cursor[1] ~= 1 then
        vim.api.nvim_win_set_cursor(0, { 1, cursor[2] })
      end
    end,
  })

  -- Clean up on buffer close
  vim.api.nvim_create_autocmd('BufWipeout', {
    group = augroup,
    buffer = buf,
    callback = function()
      ui.close()
    end,
  })
end

-- Open file finder
function M.open()
  -- Get file list
  local files = get_files()

  if #files == 0 then
    vim.notify('No files found in current directory', vim.log.levels.WARN)
    return
  end

  -- Open UI
  local height = M.config.window_height or 15
  local buf, win = ui.open(height)

  if not buf or not win then
    vim.notify('Failed to open picker', vim.log.levels.ERROR)
    return
  end

  -- Setup keymaps and autocmds
  setup_keymaps(buf)
  setup_autocmds(buf)

  -- Initial render with all files
  ui.render_results(files, '')

  -- Make buffer modifiable only on first line
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)

  -- Enter insert mode at end of prompt
  vim.cmd('startinsert!')
end

-- Clear file cache (useful if files change)
function M.refresh_cache()
  file_cache.files = {}
  file_cache.root = nil
end

return M
