-- Catppuccin Mocha, the same palette as wezterm.lua and herdr/config.toml.
-- transparent_background is on so WezTerm's acrylic blur shows through the
-- editor instead of being painted over by a flat #1e1e2e.
return {
  {
    'catppuccin/nvim',
    name = 'catppuccin',
    lazy = false,
    priority = 1000, -- must load before anything that sets highlights
    opts = {
      flavour = 'mocha',
      transparent_background = true,
      show_end_of_buffer = false,
      term_colors = true,
      styles = {
        comments = { 'italic' },
        conditionals = { 'italic' },
      },
      integrations = {
        blink_cmp = true,
        gitsigns = true,
        indent_blankline = { enabled = true, scope_color = 'surface2' },
        lsp_trouble = false,
        mason = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { 'undercurl' },
            warnings = { 'undercurl' },
          },
        },
        neotree = true,
        notify = true,
        telescope = { enabled = true },
        treesitter = true,
        which_key = true,
      },
      custom_highlights = function(c)
        return {
          -- Green accent on the cursor line number, matching the active tab
          -- colour in wezterm.lua (#a6e3a1).
          CursorLineNr = { fg = c.green, style = { 'bold' } },
          -- Keep floats readable against the transparent background.
          NormalFloat = { bg = c.mantle },
          FloatBorder = { fg = c.surface2, bg = c.mantle },
        }
      end,
    },
    config = function(_, opts)
      require('catppuccin').setup(opts)
      vim.cmd.colorscheme 'catppuccin'
    end,
  },
}
