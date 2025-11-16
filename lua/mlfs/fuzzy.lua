-- Fuzzy matching using fzf backend

local M = {}

-- Check if fzf is installed
local function is_fzf_available()
  local handle = io.popen('command -v fzf 2>/dev/null')
  if not handle then
    return false
  end
  local result = handle:read('*a')
  handle:close()
  return result ~= ''
end

M.fzf_available = is_fzf_available()

-- Use fzf --filter to get fuzzy matched and ranked results
-- @param query string: search query
-- @param items table: list of items to filter
-- @return table: filtered and ranked items
function M.filter(query, items)
  if not M.fzf_available then
    -- Fallback to simple substring matching
    return M.simple_filter(query, items)
  end

  if not query or query == '' then
    return items
  end

  -- Create temporary file with items
  local tmp_input = vim.fn.tempname()
  local tmp_output = vim.fn.tempname()

  local input_file = io.open(tmp_input, 'w')
  if not input_file then
    return {}
  end

  for _, item in ipairs(items) do
    input_file:write(item .. '\n')
  end
  input_file:close()

  -- Run fzf --filter
  local cmd = string.format('fzf --filter %s < %s > %s 2>/dev/null',
    vim.fn.shellescape(query),
    vim.fn.shellescape(tmp_input),
    vim.fn.shellescape(tmp_output)
  )

  os.execute(cmd)

  -- Read results
  local results = {}
  local output_file = io.open(tmp_output, 'r')
  if output_file then
    for line in output_file:lines() do
      table.insert(results, line)
    end
    output_file:close()
  end

  -- Clean up
  vim.fn.delete(tmp_input)
  vim.fn.delete(tmp_output)

  return results
end

-- Simple substring fallback matcher
-- @param query string: search query
-- @param items table: list of items to filter
-- @return table: filtered items
function M.simple_filter(query, items)
  if not query or query == '' then
    return items
  end

  local results = {}
  local lower_query = query:lower()

  for _, item in ipairs(items) do
    if item:lower():find(lower_query, 1, true) then
      table.insert(results, item)
    end
  end

  return results
end

-- Get positions of matched characters for highlighting
-- This is a simple implementation that finds character positions
-- @param text string: the text to search in
-- @param query string: the search query
-- @return table: list of character positions that matched
function M.get_match_positions(text, query)
  if not query or query == '' then
    return {}
  end

  local positions = {}
  local text_lower = text:lower()
  local query_lower = query:lower()
  local text_idx = 1

  for i = 1, #query_lower do
    local char = query_lower:sub(i, i)
    local pos = text_lower:find(char, text_idx, true)
    if pos then
      table.insert(positions, pos - 1) -- 0-indexed for nvim_buf_add_highlight
      text_idx = pos + 1
    end
  end

  return positions
end

return M
