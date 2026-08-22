-- LSP: servers, diagnostics, and the keymaps that only make sense once a
-- language server is attached.
--
-- Neovim 0.11+ has native LSP configuration (vim.lsp.config / vim.lsp.enable).
-- nvim-lspconfig is still used, but only as the shipped catalogue of server
-- definitions -- cmd, filetypes, root markers -- rather than as a setup layer.
-- Mason downloads the server binaries into the Neovim data dir so nothing has
-- to be installed system-wide.
return {
  {
    'neovim/nvim-lspconfig',
    event = { 'BufReadPre', 'BufNewFile' },
    dependencies = {
      { 'mason-org/mason.nvim', opts = { ui = { border = 'rounded' } } },
      {
        'mason-org/mason-lspconfig.nvim',
        -- automatic_enable would call vim.lsp.enable() for every server-ish
        -- package Mason has installed. That quietly attaches `stylua --lsp`
        -- as a formatting server on top of conform, which then formats Lua
        -- twice. The explicit list at the bottom of this file is the only
        -- thing that should decide what runs.
        opts = { automatic_enable = false },
      },
      { 'j-hui/fidget.nvim', opts = { notification = { window = { winblend = 0 } } } },
    },
    config = function()
      ----------------------------------------------------------------
      -- Diagnostics
      ----------------------------------------------------------------
      vim.diagnostic.config {
        severity_sort = true,
        underline = { severity = vim.diagnostic.severity.WARN },
        virtual_text = { spacing = 2, prefix = '●', source = 'if_many' },
        float = { border = 'rounded', source = 'if_many' },
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = ' ',
            [vim.diagnostic.severity.WARN] = ' ',
            [vim.diagnostic.severity.INFO] = ' ',
            [vim.diagnostic.severity.HINT] = ' ',
          },
        },
      }

      ----------------------------------------------------------------
      -- Keymaps, bound per-buffer the moment a server attaches
      ----------------------------------------------------------------
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp_attach', { clear = true }),
        callback = function(args)
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = args.buf, desc = 'LSP: ' .. desc })
          end

          -- Telescope pickers where there is usually more than one result.
          map('n', 'gd', '<cmd>Telescope lsp_definitions<CR>', 'Go to definition')
          map('n', 'gr', '<cmd>Telescope lsp_references<CR>', 'References')
          map('n', 'gI', '<cmd>Telescope lsp_implementations<CR>', 'Implementations')
          map('n', '<leader>cs', '<cmd>Telescope lsp_document_symbols<CR>', 'Document symbols')
          map('n', '<leader>cS', '<cmd>Telescope lsp_dynamic_workspace_symbols<CR>', 'Workspace symbols')

          map('n', 'gD', vim.lsp.buf.declaration, 'Go to declaration')
          map('n', 'K', vim.lsp.buf.hover, 'Hover docs')
          map({ 'n', 'i' }, '<C-s>', vim.lsp.buf.signature_help, 'Signature help')
          map('n', '<leader>cr', vim.lsp.buf.rename, 'Rename symbol')
          map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, 'Code action')

          -- Highlight other uses of the symbol under the cursor, if supported.
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client and client:supports_method 'textDocument/documentHighlight' then
            local hl = vim.api.nvim_create_augroup('lsp_highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = args.buf,
              group = hl,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = args.buf,
              group = hl,
              callback = vim.lsp.buf.clear_references,
            })
          end

          -- Inlay hints off by default -- useful, but noisy while writing.
          if client and client:supports_method 'textDocument/inlayHint' then
            map(
              'n',
              '<leader>ch',
              function()
                vim.lsp.inlay_hint.enable(
                  not vim.lsp.inlay_hint.is_enabled { bufnr = args.buf },
                  { bufnr = args.buf }
                )
              end,
              'Toggle inlay hints'
            )
          end
        end,
      })

      ----------------------------------------------------------------
      -- Servers
      ----------------------------------------------------------------
      -- Applies to every server, on top of whatever lspconfig ships.
      vim.lsp.config('*', {
        capabilities = require('blink.cmp').get_lsp_capabilities(),
      })

      -- lua_ls needs to be told it is editing Neovim config, or every `vim.`
      -- reference in this repo is reported as an undefined global.
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            workspace = { checkThirdParty = false },
            diagnostics = { globals = { 'vim' } },
            hint = { enable = true },
            format = { enable = false }, -- stylua handles this, see format.lua
          },
        },
      })

      -- taplo is here for herdr/config.toml, which is otherwise unvalidated.
      local servers = {
        'lua_ls', -- this repo
        'taplo', -- toml: herdr/config.toml, pyproject, Cargo
        'jsonls',
        'yamlls',
        'ts_ls', -- javascript / typescript
        'bashls',
        'marksman', -- markdown, including README.md
      }

      require('mason-lspconfig').setup { ensure_installed = servers }
      vim.lsp.enable(servers)
    end,
  },
}
