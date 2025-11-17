# MLFS - My Lovely File Selector

A fast, fuzzy file finder for Neovim with smart filtering and beautiful highlighting.

[![asciicast](https://asciinema.org/a/fcLCb3bhb3iXWmIB2tfXvDNmU.svg)](https://asciinema.org/a/fcLCb3bhb3iXWmIB2tfXvDNmU)

## Features

- **Fast fuzzy matching** powered by fzf
- **Smart filtering**: Excludes `node_modules` and other build directories by default
- **Shows hidden files**: Includes `.env`, `.gitignore`, and other dotfiles
- **Bottom split interface**: Clean, non-intrusive UI
- **Filename-first matching**: Better results for partial filename searches
- **Colorscheme integration**: Automatically adapts to your current theme
- **Lightweight**: No preview window, focuses on speed

## Dependencies

**Required:**
- `fzf` - Fuzzy finder

**Optional:**
- `fd` - Faster file listing (falls back to `find` if not available)

### Installing dependencies

```bash
# Ubuntu/Debian
sudo apt install fzf fd-find

# Arch Linux
sudo pacman -S fzf fd

# macOS
brew install fzf fd
```

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  'enheit/mlfs',
  dependencies = {
    -- Optional: only if you want to ensure fzf is installed via vim plugin
    'junegunn/fzf',
  },
  config = function()
    require('mlfs').setup({
      -- Optional: customize configuration
      exclude_patterns = {
        'node_modules',
        '.git',
        'dist',
        'build',
      },
      show_hidden = true,
      window_height = 15,
    })

    -- Set keybinding
    vim.keymap.set('n', '<leader><leader>', ':MLFSFind<CR>', { desc = 'Find Files' })
  end,
}
```

### Using [packer.nvim](https://github.com/wbthomason/packer.nvim)

```lua
use {
  'enheit/mlfs',
  config = function()
    require('mlfs').setup()
  end,
}
```

### Using [vim-plug](https://github.com/junegunn/vim-plug)

```vim
Plug 'enheit/mlfs'

" In your init.vim or after plug#end()
lua require('mlfs').setup()
```

## Usage

### Default keybinding

Press `<leader><leader>` to open the file selector.

### Commands

```vim
:MLFSFind    " Open file selector
```

### In the fzf window

- Type to search files
- `Enter` - Open selected file
- `Tab` - Select multiple files
- `Esc` or `Ctrl-c` - Close without selecting

## Configuration

### Default configuration

```lua
require('mlfs').setup({
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
})

-- Set keybinding
vim.keymap.set('n', '<leader><leader>', ':MLFSFind<CR>', { desc = 'Find Files' })
```

### Custom keybinding example

```lua
require('mlfs').setup({
  -- your config here
})

-- Use any keybinding you prefer
vim.keymap.set('n', '<C-p>', ':MLFSFind<CR>', { desc = 'Find files' })
```

### Exclude additional patterns

```lua
require('mlfs').setup({
  exclude_patterns = {
    'node_modules',
    '.git',
    'vendor',        -- Add vendor directory
    '*.pyc',         -- Add Python bytecode
    '__pycache__',   -- Add Python cache
  },
})
```

## How it works

1. **File listing**: Uses `fd` (or `find` as fallback) to list all files in your project
2. **Smart filtering**: Automatically excludes common build/dependency directories
3. **Includes hidden files**: Shows `.env`, `.gitignore`, etc. (configurable)
4. **Fuzzy search**: Uses fzf for fast, fuzzy matching with highlighting
5. **Path display**: Shows relative paths from project root

## Integration with other plugins

MLFS is designed to work alongside:
- [MLTS](https://github.com/enheit/mlts) - My Lovely Theme Selector
- [MLTB](https://github.com/enheit/mltb) - My Lovely Theme Builder

All plugins follow the same naming convention and code style.

## License

MIT

## Credits

- Built with [fzf](https://github.com/junegunn/fzf) for fuzzy finding
- Inspired by telescope.nvim and fzf.vim
