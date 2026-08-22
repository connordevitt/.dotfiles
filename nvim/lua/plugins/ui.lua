-- Statusline, buffer tabs, indent guides, notifications.
return {
  -- Statusline. laststatus=3 means one bar spanning all splits.
  {
    'nvim-lualine/lualine.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        theme = 'catppuccin',
        globalstatus = true,
        component_separators = { left = '', right = '' },
        section_separators = { left = '', right = '' },
        disabled_filetypes = { statusline = { 'neo-tree', 'lazy', 'mason' } },
      },
      sections = {
        lualine_a = { { 'mode', fmt = function(s) return s:sub(1, 1) end } },
        lualine_b = { 'branch', 'diff', 'diagnostics' },
        lualine_c = { { 'filename', path = 1 } }, -- path relative to cwd
        lualine_x = { 'filetype' },
        lualine_y = { 'progress' },
        lualine_z = { 'location' },
      },
    },
  },

  -- Buffers rendered as tabs along the top. WezTerm's own tab bar is a level
  -- above this: those are shells, these are files inside one Neovim.
  {
    'akinsho/bufferline.nvim',
    event = 'VeryLazy',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    opts = {
      options = {
        diagnostics = 'nvim_lsp',
        separator_style = 'thin',
        show_buffer_close_icons = false,
        offsets = {
          { filetype = 'neo-tree', text = 'Explorer', highlight = 'Directory' },
        },
      },
    },
  },

  -- Indent guides, with the current scope highlighted.
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    opts = {
      indent = { char = '│' },
      scope = { enabled = true, show_start = false, show_end = false },
      exclude = { filetypes = { 'help', 'lazy', 'mason', 'neo-tree', 'checkhealth' } },
    },
  },

  -- Replaces the one-line messages at the bottom with stacked floats.
  {
    'rcarriga/nvim-notify',
    event = 'VeryLazy',
    opts = { render = 'compact', stages = 'static', timeout = 2500 },
    config = function(_, opts)
      require('notify').setup(opts)
      vim.notify = require 'notify'
    end,
  },
}
