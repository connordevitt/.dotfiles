-- File tree, git signs, keymap discovery, and small editing conveniences.
return {
  -- Sidebar file explorer. netrw is disabled in config/lazy.lua so this is
  -- the only thing that opens on a directory argument.
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    cmd = 'Neotree',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    keys = {
      { '<leader>t', '<cmd>Neotree toggle<CR>', desc = 'Toggle file tree' },
      { '<leader>T', '<cmd>Neotree reveal<CR>', desc = 'Reveal file in tree' },
    },
    init = function()
      -- `nvim .` has to work. netrw is disabled and neo-tree only loads on
      -- its own command, so a directory argument would otherwise open an
      -- empty buffer. Load it eagerly in that one case so it can hijack.
      if vim.fn.argc(-1) == 1 then
        local stat = (vim.uv or vim.loop).fs_stat(vim.fn.argv(0))
        if stat and stat.type == 'directory' then require 'neo-tree' end
      end
    end,
    opts = {
      close_if_last_window = true,
      popup_border_style = 'rounded',
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true, -- reflect changes made outside nvim
        filtered_items = {
          hide_dotfiles = false, -- this is a dotfiles repo, after all
          hide_gitignored = true,
        },
      },
      window = { width = 32 },
      default_component_configs = {
        indent = { with_expanders = true },
        git_status = { symbols = { added = '+', modified = '~', deleted = '-' } },
      },
    },
  },

  -- Git gutter signs, hunk staging, and inline blame.
  {
    'lewis6991/gitsigns.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      signs = {
        add = { text = '│' },
        change = { text = '│' },
        delete = { text = '_' },
        topdelete = { text = '‾' },
        changedelete = { text = '~' },
      },
      on_attach = function(buf)
        local gs = require 'gitsigns'
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
        end
        map('n', ']h', function() gs.nav_hunk 'next' end, 'Next hunk')
        map('n', '[h', function() gs.nav_hunk 'prev' end, 'Previous hunk')
        map('n', '<leader>gs', gs.stage_hunk, 'Stage hunk')
        map('n', '<leader>gr', gs.reset_hunk, 'Reset hunk')
        map('n', '<leader>gp', gs.preview_hunk, 'Preview hunk')
        map('n', '<leader>gb', function() gs.blame_line { full = true } end, 'Blame line')
        map('n', '<leader>gd', gs.diffthis, 'Diff against index')
      end,
    },
  },

  -- Pending-keymap popup. Also the fastest way to remember what <leader>
  -- does without opening the README.
  {
    'folke/which-key.nvim',
    event = 'VeryLazy',
    opts = {
      preset = 'helix',
      spec = {
        { '<leader>b', group = 'buffer' },
        { '<leader>f', group = 'find' },
        { '<leader>g', group = 'git' },
        { '<leader>c', group = 'code' },
        { '<leader>x', group = 'diagnostics' },
        { '<leader>h', group = 'harpoon' },
        { '<leader>s', group = 'search/replace' },
        { '<leader>u', group = 'undo' },
        { '<leader>z', group = 'toggle' },
      },
    },
    keys = {
      {
        '<leader>?',
        function() require('which-key').show { global = false } end,
        desc = 'Buffer keymaps',
      },
    },
  },

  -- Treesitter-aware, so it does not fire inside strings.
  {
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    opts = { check_ts = true },
  },

  -- ys/cs/ds to add, change, delete surrounding quotes and brackets.
  {
    'kylechui/nvim-surround',
    event = 'VeryLazy',
    opts = {},
  },

  -- Highlights TODO / FIXME / HACK and makes them searchable.
  {
    'folke/todo-comments.nvim',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
    keys = {
      { '<leader>ft', '<cmd>TodoTelescope<CR>', desc = 'Find TODOs' },
    },
  },
}
