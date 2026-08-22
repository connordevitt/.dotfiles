-- Syntax highlighting, indentation, and text objects driven by real parsers.
--
-- Windows note: parsers are compiled from C on install. There is no MSVC or
-- gcc on this machine, so zig is installed by winget and nvim-treesitter picks
-- it up off PATH automatically. If :TSInstall ever fails with "no C compiler
-- found", that is zig having gone missing from PATH.
return {
  {
    'nvim-treesitter/nvim-treesitter',
    -- Pinned to master deliberately. The `main` branch is the rewrite with a
    -- different setup API (`require('nvim-treesitter').install{}` plus a manual
    -- `vim.treesitter.start()` autocmd); the opts table below is master's shape.
    -- Moving to main means rewriting this file, not flipping the branch.
    branch = 'master',
    build = ':TSUpdate',
    event = { 'BufReadPost', 'BufNewFile' },
    cmd = { 'TSInstall', 'TSUpdate', 'TSInstallInfo' },
    dependencies = {
      { 'nvim-treesitter/nvim-treesitter-textobjects', branch = 'master' },
    },
    main = 'nvim-treesitter.configs',
    opts = {
      ensure_installed = {
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
        'json',
        'jsonc',
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
      },
      auto_install = true, -- pull a parser on first open of a filetype
      highlight = { enable = true },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = '<C-space>',
          node_incremental = '<C-space>',
          node_decremental = '<BS>',
        },
      },
      textobjects = {
        select = {
          enable = true,
          lookahead = true,
          keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = '@class.inner',
            ['aa'] = '@parameter.outer',
            ['ia'] = '@parameter.inner',
          },
        },
        move = {
          enable = true,
          set_jumps = true,
          goto_next_start = { [']f'] = '@function.outer', [']c'] = '@class.outer' },
          goto_previous_start = { ['[f'] = '@function.outer', ['[c'] = '@class.outer' },
        },
      },
    },
  },
}
