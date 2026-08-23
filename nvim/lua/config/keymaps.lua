-- KEYMAPS  --  non-plugin bindings
-- Plugin-specific keys live next to their plugin in lua/plugins/ so that
-- lazy.nvim can use them as load triggers. Only editor-level keys are here.
--
-- Leader is <Space>. See the table in the README for the full list.

local map = function(mode, lhs, rhs, desc, opts)
  opts = vim.tbl_extend('force', { silent = true, desc = desc }, opts or {})
  vim.keymap.set(mode, lhs, rhs, opts)
end

-- Clear search highlight without losing the pattern.
map('n', '<Esc>', '<cmd>nohlsearch<CR>', 'Clear search highlight')

map('n', '<leader>w', '<cmd>write<CR>', 'Write file')
map('n', '<leader>q', '<cmd>quit<CR>', 'Quit window')
map('n', '<leader>Q', '<cmd>qa!<CR>', 'Quit all, discard changes')

-- Window navigation. Ctrl+h/j/k/l is the vim convention and is free at both
-- outer layers: WezTerm uses Alt+arrows and Herdr's vim-nav plugin is not
-- installed, so nothing intercepts these.
map('n', '<C-h>', '<C-w>h', 'Window left')
map('n', '<C-j>', '<C-w>j', 'Window down')
map('n', '<C-k>', '<C-w>k', 'Window up')
map('n', '<C-l>', '<C-w>l', 'Window right')

map('n', '<C-Up>', '<cmd>resize +2<CR>', 'Taller')
map('n', '<C-Down>', '<cmd>resize -2<CR>', 'Shorter')
map('n', '<C-Left>', '<cmd>vertical resize -2<CR>', 'Narrower')
map('n', '<C-Right>', '<cmd>vertical resize +2<CR>', 'Wider')
map('n', [[<leader>\]], '<cmd>vsplit<CR>', 'Split vertically') -- matches WezTerm
map('n', '<leader>-', '<cmd>split<CR>', 'Split horizontally') -- matches WezTerm

map('n', '<S-h>', '<cmd>bprevious<CR>', 'Previous buffer')
map('n', '<S-l>', '<cmd>bnext<CR>', 'Next buffer')
map('n', '<leader>bd', '<cmd>bdelete<CR>', 'Delete buffer')
map('n', '<leader>bo', '<cmd>%bd|e#|bd#<CR>', 'Delete other buffers')

-- Keep the cursor put while joining and centred while jumping around.
map('n', 'J', 'mzJ`z', 'Join lines, keep cursor')
map('n', '<C-d>', '<C-d>zz', 'Half page down, centred')
map('n', '<C-u>', '<C-u>zz', 'Half page up, centred')
map('n', 'n', 'nzzzv', 'Next match, centred')
map('n', 'N', 'Nzzzv', 'Previous match, centred')

-- Move the selection up and down, re-indenting as it goes.
map('v', 'J', ":m '>+1<CR>gv=gv", 'Move selection down')
map('v', 'K', ":m '<-2<CR>gv=gv", 'Move selection up')

-- Stay in visual mode when shifting indentation.
map('v', '<', '<gv', 'Outdent')
map('v', '>', '>gv', 'Indent')

-- Paste over a selection without clobbering the unnamed register.
map('x', '<leader>p', [["_dP]], 'Paste without yanking')

map('n', '<leader>e', vim.diagnostic.open_float, 'Line diagnostics')
map('n', '[d', function() vim.diagnostic.jump { count = -1, float = true } end, 'Previous diagnostic')
map('n', ']d', function() vim.diagnostic.jump { count = 1, float = true } end, 'Next diagnostic')
map('n', '<leader>xl', vim.diagnostic.setloclist, 'Diagnostics to loclist')

-- Terminal: Esc drops back to normal mode instead of being sent to the shell.
map('t', '<Esc><Esc>', [[<C-\><C-n>]], 'Terminal: normal mode')
