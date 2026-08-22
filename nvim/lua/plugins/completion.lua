-- Completion. blink.cmp rather than nvim-cmp: the fuzzy matcher is a Rust
-- binary downloaded prebuilt for the platform, so there is nothing to compile
-- on Windows and no source-of-truth for keymaps spread across six plugins.
return {
  {
    'saghen/blink.cmp',
    event = { 'InsertEnter', 'CmdlineEnter' },
    version = '1.*', -- a tag, so the prebuilt binary is fetched
    dependencies = { 'rafamadriz/friendly-snippets' },
    opts = {
      -- 'default' is Ctrl-driven: <C-space> opens, <C-n>/<C-p> cycle,
      -- <C-y> accepts. Tab is left alone so it still indents.
      keymap = { preset = 'default' },

      appearance = { nerd_font_variant = 'mono' },

      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 200 },
        ghost_text = { enabled = true },
        menu = { border = 'rounded', draw = { treesitter = { 'lsp' } } },
      },

      signature = { enabled = true, window = { border = 'rounded' } },

      sources = {
        default = { 'lsp', 'path', 'snippets', 'buffer' },
      },

      fuzzy = { implementation = 'prefer_rust_with_warning' },
    },
    opts_extend = { 'sources.default' },
  },
}
