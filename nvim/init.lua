-- init.lua  --  Neovim configuration
-- Source of truth lives in C:\Repositorys\dotfiles\nvim and is junctioned to
-- %LOCALAPPDATA%\nvim, which is where Neovim actually looks.
--
-- Load order matters: options (and the leader key) must be set before lazy.nvim
-- pulls in plugins, or plugin keymaps register against the wrong leader.

require 'config.options'
require 'config.lazy' -- bootstraps lazy.nvim, then loads lua/plugins/*
require 'config.keymaps' -- last, so these win over any plugin default
