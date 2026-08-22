-- Fuzzy finder. live_grep shells out to ripgrep and the file picker uses fd
-- when present; both are installed by winget in the setup steps.
return {
  {
    'nvim-telescope/telescope.nvim',
    cmd = 'Telescope',
    dependencies = {
      'nvim-lua/plenary.nvim',
      -- Native fzf sorter, guarded by cond because building it needs cmake AND
      -- a working MSVC toolchain -- neither of which this machine has, and
      -- zig does not stand in for them here. Without it Telescope silently
      -- uses its Lua sorter: slower on huge repos, identical results.
      {
        'nvim-telescope/telescope-fzf-native.nvim',
        build = 'cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release',
        cond = function() return vim.fn.executable 'cmake' == 1 end,
      },
    },
    keys = {
      { '<leader>ff', '<cmd>Telescope find_files<CR>', desc = 'Find files' },
      { '<leader>fg', '<cmd>Telescope live_grep<CR>', desc = 'Grep in project' },
      { '<leader>fb', '<cmd>Telescope buffers<CR>', desc = 'Find buffer' },
      { '<leader>fh', '<cmd>Telescope help_tags<CR>', desc = 'Help tags' },
      { '<leader>fk', '<cmd>Telescope keymaps<CR>', desc = 'Keymaps' },
      { '<leader>fr', '<cmd>Telescope oldfiles<CR>', desc = 'Recent files' },
      { '<leader>fd', '<cmd>Telescope diagnostics<CR>', desc = 'Diagnostics' },
      { '<leader>fc', '<cmd>Telescope commands<CR>', desc = 'Commands' },
      { '<leader>/', '<cmd>Telescope current_buffer_fuzzy_find<CR>', desc = 'Search buffer' },
    },
    opts = {
      defaults = {
        prompt_prefix = '  ',
        selection_caret = ' ',
        path_display = { 'truncate' },
        sorting_strategy = 'ascending',
        layout_config = { prompt_position = 'top', horizontal = { preview_width = 0.55 } },
        file_ignore_patterns = { '%.git[/\\]', 'node_modules', 'target[/\\]', '%.lock' },
        mappings = {
          i = {
            ['<C-j>'] = 'move_selection_next',
            ['<C-k>'] = 'move_selection_previous',
            ['<Esc>'] = 'close', -- one Esc closes, no normal mode first
          },
        },
      },
      pickers = {
        find_files = { hidden = true }, -- dotfiles are the point of this repo
      },
    },
    config = function(_, opts)
      local telescope = require 'telescope'
      telescope.setup(opts)
      pcall(telescope.load_extension, 'fzf')
    end,
  },
}
