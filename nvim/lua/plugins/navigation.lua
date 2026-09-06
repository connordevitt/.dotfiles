-- Moving around: file editing as a buffer, pinned files, symbols, undo
-- history, search/replace, and git diffs.
--
-- Ported from dmmulroy/.dotfiles. Keys are shifted where his collide with
-- bindings this config already had (<leader>e is line diagnostics here).
return {
  -- Edit the filesystem like a buffer: rename/delete/create with normal
  -- vim edits, then :w. Complements neo-tree rather than replacing it.
  {
    'stevearc/oil.nvim',
    lazy = false, -- so it can hijack a directory argument
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      confirmation = { border = 'rounded' },
      float = { border = 'rounded' },
      view_options = { show_hidden = true },
      keymaps = {
        ['<C-l>'] = false, -- window navigation wins, see config/keymaps.lua
        ['<C-r>'] = 'actions.refresh',
      },
    },
    keys = {
      { '<leader>o', function() require('oil').toggle_float() end, desc = 'Oil file browser' },
      { '-', '<cmd>Oil<CR>', desc = 'Oil: parent directory' },
    },
    init = function()
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'oil',
        callback = function() vim.opt_local.colorcolumn = '' end,
      })
    end,
  },

  -- Four or five files pinned per project, jumped to by number.
  {
    'ThePrimeagen/harpoon',
    keys = {
      { '<leader>ha', function() require('harpoon.mark').add_file() end, desc = 'Harpoon add file' },
      { '<leader>ho', function() require('harpoon.ui').toggle_quick_menu() end, desc = 'Harpoon menu' },
      { '<leader>hr', function() require('harpoon.mark').rm_file() end, desc = 'Harpoon remove file' },
      { '<leader>hc', function() require('harpoon.mark').clear_all() end, desc = 'Harpoon clear all' },
      { '<leader>1', function() require('harpoon.ui').nav_file(1) end, desc = 'Harpoon file 1' },
      { '<leader>2', function() require('harpoon.ui').nav_file(2) end, desc = 'Harpoon file 2' },
      { '<leader>3', function() require('harpoon.ui').nav_file(3) end, desc = 'Harpoon file 3' },
      { '<leader>4', function() require('harpoon.ui').nav_file(4) end, desc = 'Harpoon file 4' },
    },
  },

  -- LSP symbol tree in a side split.
  {
    'hedyhli/outline.nvim',
    cmd = 'Outline',
    opts = {},
    keys = {
      { '<leader>cO', '<cmd>Outline<CR>', desc = 'Symbol outline' },
    },
  },

  -- Undo history as a tree. undofile is already on in config/options.lua,
  -- so this survives restarts.
  {
    'mbbill/undotree',
    cmd = { 'UndotreeToggle', 'UndotreeShow' },
    keys = {
      { '<leader>ut', '<cmd>UndotreeToggle<CR>', desc = 'Undo tree' },
    },
  },

  -- Zoom the current split to fill the tab, and back.
  {
    'szw/vim-maximizer',
    cmd = 'MaximizerToggle',
    keys = {
      { '<leader>m', '<cmd>MaximizerToggle<CR>', desc = 'Maximize split' },
    },
  },

  -- Project-wide find and replace with a preview buffer.
  {
    'nvim-pack/nvim-spectre',
    cmd = 'Spectre',
    dependencies = { 'nvim-lua/plenary.nvim', 'catppuccin/nvim' },
    keys = {
      { '<leader>sr', function() require('spectre').toggle() end, desc = 'Search and replace' },
      {
        '<leader>sw',
        function() require('spectre').open_visual { select_word = true } end,
        desc = 'Replace word under cursor',
      },
    },
    config = function()
      local c = require('catppuccin.palettes').get_palette 'mocha'
      vim.api.nvim_set_hl(0, 'SpectreSearch', { bg = c.red, fg = c.base })
      vim.api.nvim_set_hl(0, 'SpectreReplace', { bg = c.green, fg = c.base })
      require('spectre').setup {
        highlight = { search = 'SpectreSearch', replace = 'SpectreReplace' },
      }
    end,
  },

  -- Full-window git diff and file history. gitsigns covers the gutter and
  -- single hunks; this covers whole commits and ranges.
  {
    'sindrets/diffview.nvim',
    cmd = { 'DiffviewOpen', 'DiffviewFileHistory', 'DiffviewClose' },
    keys = {
      -- <leader>gd is gitsigns diffthis, so the views sit on gv/gh.
      { '<leader>gv', '<cmd>DiffviewOpen<CR>', desc = 'Diff view (working copy)' },
      { '<leader>gc', '<cmd>DiffviewClose<CR>', desc = 'Close diff view' },
      { '<leader>gh', '<cmd>DiffviewFileHistory %<CR>', desc = 'File history (current)' },
      { '<leader>gH', '<cmd>DiffviewFileHistory<CR>', desc = 'File history (repo)' },
    },
    opts = function()
      local actions = require 'diffview.actions'
      return {
        enhanced_diff_hl = true,
        show_help_hints = false,
        view = {
          default = { winbar_info = false },
          merge_tool = { layout = 'diff3_mixed', disable_diagnostics = true, winbar_info = true },
          file_history = { winbar_info = false },
        },
        file_panel = {
          listing_style = 'tree',
          tree_options = { flatten_dirs = true, folder_statuses = 'only_folded' },
          win_config = { position = 'left', width = 35 },
        },
        keymaps = {
          view = {
            { 'n', '<tab>', actions.select_next_entry, { desc = 'Next file' } },
            { 'n', '<s-tab>', actions.select_prev_entry, { desc = 'Prev file' } },
            { 'n', '<leader>gf', actions.toggle_files, { desc = 'Toggle file panel' } },
            { 'n', 'q', actions.close, { desc = 'Close diffview' } },
          },
          file_panel = {
            { 'n', 'j', actions.next_entry, { desc = 'Next entry' } },
            { 'n', 'k', actions.prev_entry, { desc = 'Prev entry' } },
            { 'n', '<cr>', actions.select_entry, { desc = 'Open diff' } },
            { 'n', 's', actions.toggle_stage_entry, { desc = 'Stage/unstage' } },
            { 'n', 'S', actions.stage_all, { desc = 'Stage all' } },
            { 'n', 'U', actions.unstage_all, { desc = 'Unstage all' } },
            { 'n', 'X', actions.restore_entry, { desc = 'Restore entry' } },
            { 'n', 'R', actions.refresh_files, { desc = 'Refresh' } },
            { 'n', 'q', actions.close, { desc = 'Close diffview' } },
          },
          file_history_panel = {
            { 'n', 'j', actions.next_entry, { desc = 'Next entry' } },
            { 'n', 'k', actions.prev_entry, { desc = 'Prev entry' } },
            { 'n', '<cr>', actions.select_entry, { desc = 'Open diff' } },
            { 'n', 'y', actions.copy_hash, { desc = 'Copy commit hash' } },
            { 'n', 'q', actions.close, { desc = 'Close diffview' } },
          },
        },
      }
    end,
  },
}
