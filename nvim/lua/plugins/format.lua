-- Formatting, kept out of the LSP layer so the formatter and the language
-- server can be chosen independently (lua_ls formats badly; stylua does not).
return {
  {
    'stevearc/conform.nvim',
    event = { 'BufWritePre' },
    cmd = 'ConformInfo',
    dependencies = {
      -- Formatters are not language servers, so mason-lspconfig does not
      -- install them. This does, from the same Mason registry, keeping a
      -- fresh machine one `nvim` away from working instead of one
      -- `:MasonInstall` away.
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim',
        opts = {
          ensure_installed = { 'stylua', 'prettierd', 'ruff', 'shfmt' },
          run_on_start = true,
          auto_update = false,
        },
      },
    },
    keys = {
      {
        '<leader>cf',
        function() require('conform').format { async = true, lsp_format = 'fallback' } end,
        mode = { 'n', 'v' },
        desc = 'Format buffer',
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettierd', 'prettier', stop_after_first = true },
        typescript = { 'prettierd', 'prettier', stop_after_first = true },
        javascriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        typescriptreact = { 'prettierd', 'prettier', stop_after_first = true },
        json = { 'prettierd', 'prettier', stop_after_first = true },
        jsonc = { 'prettierd', 'prettier', stop_after_first = true },
        yaml = { 'prettierd', 'prettier', stop_after_first = true },
        markdown = { 'prettierd', 'prettier', stop_after_first = true },
        css = { 'prettierd', 'prettier', stop_after_first = true },
        html = { 'prettierd', 'prettier', stop_after_first = true },
        python = { 'ruff_format' },
        sh = { 'shfmt' },
        toml = { 'taplo' },
      },

      -- Format on save, unless :FormatDisable was used. The escape hatch
      -- matters on shared repos where a reformat would bury a real diff.
      format_on_save = function(buf)
        if vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
        return { timeout_ms = 800, lsp_format = 'fallback' }
      end,
    },
    init = function()
      -- Make gq use conform.
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      vim.api.nvim_create_user_command('FormatDisable', function(args)
        if args.bang then
          vim.b.disable_autoformat = true -- :FormatDisable! -> this buffer
        else
          vim.g.disable_autoformat = true
        end
      end, { desc = 'Disable format on save', bang = true })

      vim.api.nvim_create_user_command('FormatEnable', function()
        vim.b.disable_autoformat = false
        vim.g.disable_autoformat = false
      end, { desc = 'Re-enable format on save' })
    end,
  },
}
