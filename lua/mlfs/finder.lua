-- File finder using fzf

local M = {}

-- Plugin configuration (will be set from init.lua)
M.config = {}

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

-- Get fzf color scheme based on current Neovim colorscheme
local function get_fzf_colors()
  -- Get current background
  local bg = vim.o.background

  -- Define color scheme based on background
  if bg == 'dark' then
    return '--color=dark,fg:#d0d0d0,bg:#1c1c1c,hl:#5f87af,fg+:#ffffff,bg+:#262626,hl+:#5fd7ff,info:#afaf87,prompt:#d7005f,pointer:#af5fff,marker:#87ff00,spinner:#af5fff,header:#87afaf'
  else
    return '--color=light,fg:#000000,bg:#ffffff,hl:#5f87af,fg+:#000000,bg+:#e0e0e0,hl+:#0087d7,info:#875f00,prompt:#d7005f,pointer:#af5fff,marker:#00af00,spinner:#af5fff,header:#005f87'
  end
end

-- Open fzf file selector
function M.open()
  -- Check if fzf is installed
  if not command_exists('fzf') then
    vim.notify('fzf is not installed. Please install fzf first.', vim.log.levels.ERROR)
    return
  end

  local root = get_project_root()
  local file_list_cmd = build_file_list_command()
  local height = M.config.window_height or 15

  -- Build fzf command with options
  local fzf_opts = {
    '--multi',  -- Allow multiple selection with Tab
    '--reverse',  -- Results from top to bottom
    '--height=' .. height,
    '--border=none',
    '--prompt=Files> ',
    '--pointer=>',
    '--marker=✓',
    '--info=inline',
    '--layout=reverse',
    '--ansi',
    get_fzf_colors(),
  }

  local fzf_cmd = file_list_cmd .. ' | fzf ' .. table.concat(fzf_opts, ' ')

  -- Create temporary file for fzf output
  local tmp_file = vim.fn.tempname()
  fzf_cmd = fzf_cmd .. ' > ' .. tmp_file

  -- Save current window
  local original_win = vim.api.nvim_get_current_win()

  -- Create bottom split
  vim.cmd('botright ' .. height .. 'split')
  local fzf_win = vim.api.nvim_get_current_win()
  local fzf_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(fzf_win, fzf_buf)

  -- Run fzf in terminal
  vim.fn.termopen(fzf_cmd, {
    on_exit = function(_, exit_code)
      -- Close the fzf window
      if vim.api.nvim_win_is_valid(fzf_win) then
        vim.api.nvim_win_close(fzf_win, true)
      end

      -- Return to original window
      if vim.api.nvim_win_is_valid(original_win) then
        vim.api.nvim_set_current_win(original_win)
      end

      -- If user selected a file (exit code 0)
      if exit_code == 0 then
        -- Read selected files from temp file
        local file = io.open(tmp_file, 'r')
        if file then
          for line in file:lines() do
            if line ~= '' then
              -- Open the selected file
              local filepath = line
              -- Make path relative to current directory for cleaner display
              if filepath:sub(1, #root) == root then
                filepath = filepath:sub(#root + 2)  -- +2 to skip the trailing /
              end
              vim.cmd('edit ' .. vim.fn.fnameescape(filepath))
            end
          end
          file:close()
        end
      end

      -- Clean up temp file
      vim.fn.delete(tmp_file)
    end,
  })

  -- Enter insert mode to start searching immediately
  vim.cmd('startinsert')
end

return M
