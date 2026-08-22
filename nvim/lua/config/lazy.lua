-- LAZY.NVIM  --  plugin manager bootstrap
-- lazy.nvim is not vendored into this repo. It clones itself on first launch
-- into the Neovim data dir, and every plugin under lua/plugins/ follows.
-- The only prerequisite is git being on PATH.

local lazypath = vim.fn.stdpath 'data' .. '/lazy/lazy.nvim'

if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system {
    'git',
    'clone',
    '--filter=blob:none',
    '--branch=stable',
    'https://github.com/folke/lazy.nvim.git',
    lazypath,
  }
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { 'Failed to clone lazy.nvim:\n', 'ErrorMsg' },
      { out, 'WarningMsg' },
      { '\nIs git on PATH? Press any key to exit.' },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

require('lazy').setup {
  -- Every file in lua/plugins/ returning a spec table is picked up here.
  spec = { { import = 'plugins' } },

  -- Versions are pinned in lazy-lock.json, which IS tracked in this repo.
  -- :Lazy update rewrites it; commit the result so another machine resolves
  -- to the same plugin commits rather than whatever is on HEAD that day.
  lockfile = vim.fn.stdpath 'config' .. '/lazy-lock.json',

  install = { colorscheme = { 'catppuccin' } },
  checker = { enabled = true, notify = false }, -- check for updates quietly
  change_detection = { notify = false },
  ui = { border = 'rounded' },

  performance = {
    rtp = {
      -- Built-in plugins that are pure overhead here.
      disabled_plugins = {
        'gzip',
        'tarPlugin',
        'zipPlugin',
        'tohtml',
        'tutor',
        'netrwPlugin',
      },
    },
  },
}
