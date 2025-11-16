-- UI management for custom picker

local M = {}

-- UI state
local state = {
  buf = nil,
  win = nil,
  prompt = 'Files> ',
  selected_index = 1,
  results = {},
  on_select = nil,
}

-- Get color from highlight group
-- @param group string: highlight group name
-- @param attr string: attribute to get (fg, bg, etc.)
-- @return string: color hex code or nil
local function get_hl_color(group, attr)
  local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
  if hl[attr] then
    return string.format('#%06x', hl[attr])
  end
  return nil
end

-- Setup highlight groups based on current theme
local function setup_highlights()
  -- Prompt line
  vim.api.nvim_set_hl(0, 'MLFSPrompt', {
    fg = get_hl_color('Question', 'fg') or get_hl_color('Title', 'fg'),
    bold = true,
  })

  -- Selected item
  vim.api.nvim_set_hl(0, 'MLFSSelection', {
    link = 'CursorLine',
  })

  -- Matched characters
  vim.api.nvim_set_hl(0, 'MLFSMatch', {
    fg = get_hl_color('Search', 'fg') or get_hl_color('IncSearch', 'fg'),
    bold = true,
  })

  -- Normal text
  vim.api.nvim_set_hl(0, 'MLFSNormal', {
    link = 'Normal',
  })
end

-- Create and open the picker window
-- @param height number: window height in lines
function M.open(height)
  height = height or 15

  -- Setup highlights
  setup_highlights()

  -- Create scratch buffer
  state.buf = vim.api.nvim_create_buf(false, true)

  -- Set buffer options
  vim.api.nvim_buf_set_option(state.buf, 'buftype', 'nofile')
  vim.api.nvim_buf_set_option(state.buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(state.buf, 'swapfile', false)
  vim.api.nvim_buf_set_option(state.buf, 'filetype', 'mlfs')

  -- Create bottom split
  vim.cmd('botright ' .. height .. 'split')
  state.win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(state.win, state.buf)

  -- Set window options
  vim.api.nvim_win_set_option(state.win, 'number', false)
  vim.api.nvim_win_set_option(state.win, 'relativenumber', false)
  vim.api.nvim_win_set_option(state.win, 'cursorline', false)
  vim.api.nvim_win_set_option(state.win, 'wrap', false)
  vim.api.nvim_win_set_option(state.win, 'spell', false)

  -- Initial prompt
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, { state.prompt })

  -- Move cursor to end of prompt
  vim.api.nvim_win_set_cursor(state.win, { 1, #state.prompt })

  return state.buf, state.win
end

-- Render results in the buffer
-- @param results table: list of result strings
-- @param query string: search query for highlighting
function M.render_results(results, query)
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  state.results = results

  -- Get current prompt line content
  local prompt_line = vim.api.nvim_buf_get_lines(state.buf, 0, 1, false)[1] or state.prompt

  -- Limit results to prevent performance issues
  local max_results = 100

  -- Build lines: prompt + separator + results
  local lines = { prompt_line }

  if #results == 0 then
    table.insert(lines, '─────────────────────')
    table.insert(lines, '  No matches found')
  else
    table.insert(lines, '─────────────────────')
    for i = 1, math.min(#results, max_results) do
      table.insert(lines, '  ' .. results[i])
    end

    if #results > max_results then
      table.insert(lines, string.format('  ... and %d more', #results - max_results))
    end
  end

  -- Update buffer
  vim.api.nvim_buf_set_option(state.buf, 'modifiable', true)
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  -- Keep buffer modifiable so user can type in prompt line

  -- Clear previous highlights
  vim.api.nvim_buf_clear_namespace(state.buf, -1, 0, -1)

  -- Highlight prompt
  vim.api.nvim_buf_add_highlight(state.buf, -1, 'MLFSPrompt', 0, 0, #state.prompt)

  -- Highlight selected item
  if #results > 0 and state.selected_index <= #results then
    local line_idx = state.selected_index + 1  -- +1 for separator line
    vim.api.nvim_buf_add_highlight(state.buf, -1, 'MLFSSelection', line_idx, 0, -1)
  end

  -- Highlight matched characters in results
  if query and query ~= '' then
    local fuzzy = require('mlfs.fuzzy')
    for i, result in ipairs(results) do
      if i > max_results then
        break
      end
      local line_idx = i + 1  -- +1 for separator
      local positions = fuzzy.get_match_positions(result, query)
      for _, pos in ipairs(positions) do
        -- +2 to account for "  " prefix
        vim.api.nvim_buf_add_highlight(state.buf, -1, 'MLFSMatch', line_idx, pos + 2, pos + 3)
      end
    end
  end
end

-- Get current query from prompt line
-- @return string: current query text
function M.get_query()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return ''
  end

  local prompt_line = vim.api.nvim_buf_get_lines(state.buf, 0, 1, false)[1] or state.prompt
  return prompt_line:sub(#state.prompt + 1)
end

-- Get currently selected result
-- @return string|nil: selected result or nil
function M.get_selected()
  if state.selected_index > 0 and state.selected_index <= #state.results then
    return state.results[state.selected_index]
  end
  return nil
end

-- Move selection up
function M.select_prev()
  if #state.results == 0 then
    return
  end

  state.selected_index = state.selected_index - 1
  if state.selected_index < 1 then
    state.selected_index = 1
  end

  -- Re-render to update highlight
  M.render_results(state.results, M.get_query())
end

-- Move selection down
function M.select_next()
  if #state.results == 0 then
    return
  end

  state.selected_index = state.selected_index + 1
  if state.selected_index > #state.results then
    state.selected_index = #state.results
  end

  -- Re-render to update highlight
  M.render_results(state.results, M.get_query())
end

-- Close the picker
function M.close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  -- Reset state
  state.buf = nil
  state.win = nil
  state.results = {}
  state.selected_index = 1
end

-- Check if picker is open
function M.is_open()
  return state.win ~= nil and vim.api.nvim_win_is_valid(state.win)
end

-- Get current state
function M.get_state()
  return state
end

return M
