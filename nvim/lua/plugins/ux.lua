-- Editing quality-of-life, ported from dmmulroy/.dotfiles.
--
-- Where one of his plugins overlaps something already here, the existing one
-- wins and the overlapping module is switched off rather than removed:
-- nvim-notify keeps the notifications, indent-blankline keeps the guides, and
-- dressing keeps vim.ui.select/input.
return {
  -- Grab bag of small utilities. Only the modules that do not duplicate
  -- something already in this config are enabled.
  {
    'folke/snacks.nvim',
    priority = 1000,
    lazy = false,
    ---@type snacks.Config
    opts = {
      bigfile = { enabled = true }, -- disables treesitter/lsp on huge files
      bufdelete = { enabled = true }, -- close a buffer without killing the split
      dim = { enabled = true },
      gitbrowse = { enabled = true },
      rename = { enabled = true }, -- tells the LSP about oil/neo-tree renames
      scratch = { enabled = true },
      statuscolumn = { enabled = true },
      toggle = { enabled = true },
      words = { enabled = true }, -- ]] / [[ between LSP references
      indent = { enabled = false }, -- indent-blankline, see ui.lua
      input = { enabled = false }, -- dressing, below
      notifier = { enabled = false }, -- nvim-notify, see ui.lua
    },
    keys = {
      { '<leader>bd', function() Snacks.bufdelete() end, desc = 'Delete buffer' },
      { '<leader>bo', function() Snacks.bufdelete.other() end, desc = 'Delete other buffers' },
      { '<leader>go', function() Snacks.gitbrowse() end, mode = { 'n', 'v' }, desc = 'Open in git host' },
      { '<leader>.', function() Snacks.scratch() end, desc = 'Toggle scratch buffer' },
      { '<leader>s.', function() Snacks.scratch.select() end, desc = 'Find scratch buffer' },
      { '<leader>zm', function() Snacks.toggle.dim():toggle() end, desc = 'Toggle dim mode' },
      { '<leader>zw', function() Snacks.toggle.option('wrap'):toggle() end, desc = 'Toggle line wrap' },
      {
        '<leader>zn',
        function() Snacks.toggle.option('relativenumber', { name = 'Relative Number' }):toggle() end,
        desc = 'Toggle relative numbers',
      },
      { '<leader>xt', function() Snacks.toggle.diagnostics():toggle() end, desc = 'Toggle diagnostics' },
    },
    init = function()
      -- oil renames are file moves as far as a language server is concerned.
      vim.api.nvim_create_autocmd('User', {
        pattern = 'OilActionsPost',
        callback = function(event)
          if event.data.actions.type == 'move' then
            Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
          end
        end,
      })
    end,
  },

  -- vim.ui.select and vim.ui.input rendered as floats instead of a bottom-line
  -- prompt. Code actions and LSP rename go through these.
  {
    'stevearc/dressing.nvim',
    event = 'VeryLazy',
    opts = {},
  },

  -- Diagnostics as a styled float next to the cursor. Neovim's own virtual
  -- text is turned off for it in lsp.lua.
  {
    'rachartier/tiny-inline-diagnostic.nvim',
    event = 'VeryLazy',
    priority = 1000,
    opts = {
      preset = 'powerline',
      options = {
        add_messages = { display_count = true, messages = true },
        multilines = { enabled = true, always_show = true },
      },
    },
  },

  -- LSP- and treesitter-aware folds, with a readable fold line.
  {
    'kevinhwang91/nvim-ufo',
    event = { 'BufReadPost', 'BufNewFile' },
    dependencies = { 'kevinhwang91/promise-async' },
    init = function()
      -- ufo needs folds enabled but nothing folded on open.
      vim.o.foldcolumn = '1'
      vim.o.foldlevel = 99
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    opts = {
      provider_selector = function(_, filetype)
        local lsp_fts = { typescript = true, typescriptreact = true, javascript = true, javascriptreact = true }
        if lsp_fts[filetype] then return { 'lsp', 'treesitter' } end
        return { 'treesitter', 'indent' }
      end,
    },
    keys = {
      { 'zR', function() require('ufo').openAllFolds() end, desc = 'Open all folds' },
      { 'zM', function() require('ufo').closeAllFolds() end, desc = 'Close all folds' },
      { 'zK', function() require('ufo').peekFoldedLinesUnderCursor() end, desc = 'Peek fold' },
    },
  },

  -- Renders markdown in the buffer: headings, code blocks, tables, checkboxes.
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown', 'rmd' },
    dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
    opts = {
      code = { sign = false, width = 'block', right_pad = 1 },
      heading = { sign = false, icons = {} },
    },
  },

  -- Hides secret values in .env and friends so a shared screen does not leak
  -- them. config.toml is in the list for herdr's token.
  {
    'laytan/cloak.nvim',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      patterns = {
        { file_pattern = '**/*.env*', cloak_pattern = '=.+' },
        { file_pattern = '**/*.vars*', cloak_pattern = '=.+' },
        { file_pattern = '**/config.toml', cloak_pattern = '(token =) .+', replace = '%1 ' },
        { file_pattern = '**/*.json', cloak_pattern = '("[aA]pi[kK]ey":) .+', replace = '%1 ' },
      },
    },
  },

  -- Colour literals shown in their own colour. Tailwind classes included.
  {
    'brenoprata10/nvim-highlight-colors',
    event = { 'BufReadPre', 'BufNewFile' },
    opts = {
      render = 'background',
      enable_hex = true,
      enable_short_hex = true,
      enable_rgb = true,
      enable_hsl = true,
      enable_var_usage = true,
      enable_named_colors = true,
      enable_tailwind = true,
    },
  },

  -- Fuzzy popup for : / and ? completion.
  {
    'gelguy/wilder.nvim',
    keys = { ':', '/', '?' },
    dependencies = { 'catppuccin/nvim' },
    config = function()
      local wilder = require 'wilder'
      local c = require('catppuccin.palettes').get_palette 'mocha'
      local text = wilder.make_hl('WilderText', { { a = 1 }, { a = 1 }, { foreground = c.text } })
      local accent = wilder.make_hl('WilderAccent', { { a = 1 }, { a = 1 }, { foreground = c.mauve } })

      wilder.setup { modes = { ':', '/', '?' } }
      wilder.set_option('pipeline', {
        wilder.branch(wilder.cmdline_pipeline { fuzzy = 1 }, wilder.vim_search_pipeline { fuzzy = 1 }),
      })
      wilder.set_option(
        'renderer',
        wilder.popupmenu_renderer(wilder.popupmenu_border_theme {
          highlighter = wilder.basic_highlighter(),
          highlights = { default = text, border = accent, accent = accent },
          pumblend = 5,
          min_width = '100%',
          min_height = '25%',
          max_height = '25%',
          border = 'rounded',
          left = { ' ', wilder.popupmenu_devicons() },
          right = { ' ', wilder.popupmenu_scrollbar() },
        })
      )
    end,
  },
}
