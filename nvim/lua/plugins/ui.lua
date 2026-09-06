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

  -- Indent guides, one colour per depth. The scope hook colours the bar next
  -- to the function/block the cursor is in with that depth's colour, so the
  -- body you are inside is identifiable at a glance.
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'catppuccin/nvim' },
    config = function()
      local hooks = require 'ibl.hooks'
      local levels = {
        'IblIndent1',
        'IblIndent2',
        'IblIndent3',
        'IblIndent4',
        'IblIndent5',
        'IblIndent6',
      }

      -- Registered as a hook rather than set once: a :colorscheme reload
      -- clears user highlight groups, and this re-applies them.
      hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
        local c = require('catppuccin.palettes').get_palette 'mocha'
        local colors = { c.red, c.peach, c.yellow, c.green, c.sapphire, c.mauve }
        for i, name in ipairs(levels) do
          vim.api.nvim_set_hl(0, name, { fg = colors[i] })
        end
      end)

      -- Without this the scope bar uses its own single colour instead of the
      -- one belonging to its depth.
      hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

      require('ibl').setup {
        indent = { char = '│', highlight = levels },
        scope = { enabled = true, show_start = false, show_end = false, highlight = levels },
        exclude = { filetypes = { 'help', 'lazy', 'mason', 'neo-tree', 'checkhealth' } },
      }
    end,
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
