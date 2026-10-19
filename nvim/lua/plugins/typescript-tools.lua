-- TypeScript: mirrors dmmulroy's typescript-tools.lua, which talks to tsserver
-- directly instead of going through ts_ls (removed from lsp.lua's list).
-- Diverges: separate_diagnostic_server and tsserver_max_memory = 12288 are
-- dropped -- a second tsserver with a 12GB heap is more than this machine needs.
return {
  {
    'pmizio/typescript-tools.nvim',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'neovim/nvim-lspconfig',
      'marilari88/twoslash-queries.nvim',
    },
    ft = { 'typescript', 'typescriptreact', 'javascript', 'javascriptreact' },
    config = function()
      require('typescript-tools').setup {
        -- Not covered by vim.lsp.config('*') in lsp.lua, so blink's
        -- completion capabilities are passed here directly.
        capabilities = require('blink.cmp').get_lsp_capabilities(),
        on_attach = function(client, buffer_number) require('twoslash-queries').attach(client, buffer_number) end,
        settings = {
          publish_diagnostic_on = 'insert_leave',
          jsx_close_tag = {
            enable = true,
            filetypes = { 'javascriptreact', 'typescriptreact' },
          },
          tsserver_file_preferences = {
            includeInlayParameterNameHints = 'all',
            includeInlayParameterNameHintsWhenArgumentMatchesName = true,
            includeInlayVariableTypeHints = true,
            includeInlayVariableTypeHintsWhenTypeMatchesName = true,
            includeInlayPropertyDeclarationTypeHints = true,
            includeInlayFunctionParameterTypeHints = true,
            includeInlayEnumMemberValueHints = true,
            includeInlayFunctionLikeReturnTypeHints = true,
            includeCompletionsForModuleExports = true,
            includeCompletionsForImportStatements = true,
          },
          tsserver_format_options = {
            insertSpaceAfterOpeningAndBeforeClosingEmptyBraces = true,
            semicolons = 'insert',
          },
          complete_function_calls = true,
          include_completions_with_insert_text = true,
          code_lens = 'off',
          disable_member_code_lens = true,
        },
      }
    end,
  },
}
