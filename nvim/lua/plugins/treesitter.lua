-- Syntax highlighting, indentation, and text objects driven by real parsers.
--
-- Both plugins are on their `main` branch. The old `master` branch is frozen
-- and its README states Neovim 0.12 is not supported: its query directives
-- (e.g. `#set-lang-from-info-string!` in queries/markdown/injections.scm) still
-- read `match[id]` as a single TSNode, which became a node *list* in 0.11.
-- On 0.12 that surfaced as a redraw-loop error on every markdown buffer --
-- "attempt to call method 'range' (a nil value)" out of the treesitter
-- highlighter -- because 0.12's runtime ftplugin auto-starts treesitter for
-- markdown, and master's queries shadow the runtime's.
--
-- `main` is a parser/query installer and nothing more: highlighting, folds and
-- injections now come from Neovim itself, so they are wired up below by hand.
--
-- Windows note: `main` shells out to the tree-sitter CLI (winget:
-- tree-sitter.tree-sitter-cli) to build parsers. The CLI compiles via the Rust
-- `cc` crate, which on an msvc target emits MSVC-style flags -- `zig cc` swallows
-- those and exits 0 without writing parser.so, so zig alone is NOT enough here
-- even though it was for master. A cl.exe-compatible compiler (LLVM's clang-cl,
-- or MSVC build tools) has to be on PATH for `:TSUpdate` to build anything.
--
-- Neovim 0.12 bundles parsers for c, lua, markdown, markdown_inline, query, vim
-- and vimdoc, so those keep highlighting with no compiler present at all.

-- Parser installation is NOT automatic, on purpose. `install()` is documented
-- as a no-op once a parser is present, but a parser that fails to *compile*
-- never becomes present, so any automatic call retries forever:
--   * from `config` it re-downloads all 26 parsers on every launch;
--   * from `build` it is worse -- lazy.nvim sets `_.build = not installed[name]`,
--     so a failed build stays flagged and re-runs at every startup, blocking
--     the editor while it downloads and fails again.
-- Either way `nvim <file>` becomes unusable. Run `:TSInstallConfigured` once a
-- working C compiler is on PATH; `:TSInstall <lang>` covers one-offs.
local languages = {
  'bash',
  'c',
  'css',
  'diff',
  'dockerfile',
  'git_config',
  'gitcommit',
  'gitignore',
  'html',
  'javascript',
  'json', -- also used for jsonc; main has no separate jsonc parser
  'lua',
  'luadoc',
  'markdown',
  'markdown_inline',
  'powershell',
  'python',
  'query',
  'regex',
  'rust',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- main does not support lazy-loading, and parsers must be rebuilt whenever
    -- the plugin updates or they fall out of sync with parser.lua.
    lazy = false,
    branch = 'main',
    config = function()
      vim.api.nvim_create_user_command(
        'TSInstallConfigured',
        function() require('nvim-treesitter').install(languages) end,
        { desc = 'Install every parser this config expects' }
      )

      -- main dropped the separate jsonc parser; the json one handles it, but
      -- only once the filetype is mapped to that language explicitly.
      vim.treesitter.language.register('json', 'jsonc')

      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('treesitter_start', { clear = true }),
        callback = function(args)
          -- No parser for this filetype is the normal case, not an error --
          -- plain text, log files, and anything not in the list above.
          if not pcall(vim.treesitter.start, args.buf) then return end

          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          -- Indent queries are optional and missing for plenty of languages.
          -- Setting indentexpr without one indents worse than the default.
          if lang and vim.treesitter.query.get(lang, 'indents') then
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },

  {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = 'main',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {
      select = { lookahead = true },
      move = { set_jumps = true },
    },
    keys = {
      -- main drops the keymap table master had; these are the same bindings.
      {
        'af',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
        end,
        mode = { 'x', 'o' },
        desc = 'a function',
      },
      {
        'if',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
        end,
        mode = { 'x', 'o' },
        desc = 'inner function',
      },
      {
        'ac',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
        end,
        mode = { 'x', 'o' },
        desc = 'a class',
      },
      {
        'ic',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
        end,
        mode = { 'x', 'o' },
        desc = 'inner class',
      },
      {
        'aa',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@parameter.outer', 'textobjects')
        end,
        mode = { 'x', 'o' },
        desc = 'an argument',
      },
      {
        'ia',
        function()
          require('nvim-treesitter-textobjects.select').select_textobject('@parameter.inner', 'textobjects')
        end,
        mode = { 'x', 'o' },
        desc = 'inner argument',
      },
      {
        ']f',
        function()
          require('nvim-treesitter-textobjects.move').goto_next_start('@function.outer', 'textobjects')
        end,
        mode = { 'n', 'x', 'o' },
        desc = 'Next function',
      },
      {
        ']c',
        function() require('nvim-treesitter-textobjects.move').goto_next_start('@class.outer', 'textobjects') end,
        mode = { 'n', 'x', 'o' },
        desc = 'Next class',
      },
      {
        '[f',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_start('@function.outer', 'textobjects')
        end,
        mode = { 'n', 'x', 'o' },
        desc = 'Previous function',
      },
      {
        '[c',
        function()
          require('nvim-treesitter-textobjects.move').goto_previous_start('@class.outer', 'textobjects')
        end,
        mode = { 'n', 'x', 'o' },
        desc = 'Previous class',
      },
    },
  },
}
