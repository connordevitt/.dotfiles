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
-- outer layers: WezTerm uses Alt+arrows and Herdr's prefix is Ctrl+; so
-- nothing intercepts these.
--
-- At the edge of the last split the move is handed to Herdr, so focus crosses
-- out of Neovim and into the neighbouring Herdr pane instead of stopping dead.
-- HERDR_PANE_ID is only set inside a Herdr pane, so outside one this is a
-- plain <C-w> move. Ported from dmmulroy/.dotfiles.
local function navigate(wincmd, direction)
  local from = vim.api.nvim_get_current_win()
  vim.cmd('wincmd ' .. wincmd)
  if vim.api.nvim_get_current_win() ~= from then return end -- moved, done

  local pane = vim.env.HERDR_PANE_ID
  if pane and pane ~= '' then
    local herdr = vim.env.HERDR_BIN_PATH
    if herdr == nil or herdr == '' then herdr = 'herdr' end
    vim.fn.system { herdr, 'pane', 'focus', '--direction', direction, '--current' }
  end
end

for lhs, move in pairs {
  ['<C-h>'] = { 'h', 'left' },
  ['<C-j>'] = { 'j', 'down' },
  ['<C-k>'] = { 'k', 'up' },
  ['<C-l>'] = { 'l', 'right' },
} do
  map('n', lhs, function() navigate(move[1], move[2]) end, 'Window ' .. move[2] .. ' (Neovim/Herdr)')
end
map('n', '<leader>=', '<C-w>=', 'Equalize splits')

map('n', '<C-Up>', '<cmd>resize +2<CR>', 'Taller')
map('n', '<C-Down>', '<cmd>resize -2<CR>', 'Shorter')
map('n', '<C-Left>', '<cmd>vertical resize -2<CR>', 'Narrower')
map('n', '<C-Right>', '<cmd>vertical resize +2<CR>', 'Wider')
map('n', [[<leader>\]], '<cmd>vsplit<CR>', 'Split vertically') -- matches WezTerm
map('n', '<leader>-', '<cmd>split<CR>', 'Split horizontally') -- matches WezTerm

map('n', '<S-h>', '<cmd>bprevious<CR>', 'Previous buffer')
map('n', '<S-l>', '<cmd>bnext<CR>', 'Next buffer')
-- <leader>bd / <leader>bo are Snacks.bufdelete, see plugins/ux.lua: it closes
-- the buffer without closing the window it was displayed in.

-- Keep the cursor put while joining and centred while jumping around.
map('n', 'J', 'mzJ`z', 'Join lines, keep cursor')
map('n', '<C-d>', '<C-d>zz', 'Half page down, centred')
map('n', '<C-u>', '<C-u>zz', 'Half page up, centred')
map('n', 'n', 'nzzzv', 'Next match, centred')
map('n', 'N', 'Nzzzv', 'Previous match, centred')

-- Same idea for every other jump that can land near a window edge: the target
-- ends up in the middle of the screen with its context around it.
map('n', '{', '{zz', 'Previous paragraph, centred')
map('n', '}', '}zz', 'Next paragraph, centred')
map('n', 'G', 'Gzz', 'End of file, centred')
map('n', 'gg', 'ggzz', 'Start of file, centred')
map('n', '%', '%zz', 'Matching bracket, centred')
map('n', '*', '*zz', 'Search word forward, centred')
map('n', '#', '#zz', 'Search word backward, centred')
map('n', '<C-o>', '<C-o>zz', 'Jump list back, centred')
map('n', '<C-i>', '<C-i>zz', 'Jump list forward, centred')

-- Move the selection up and down, re-indenting as it goes.
map('v', 'J', ":m '>+1<CR>gv=gv", 'Move selection down')
map('v', 'K', ":m '<-2<CR>gv=gv", 'Move selection up')

-- Stay in visual mode when shifting indentation.
map('v', '<', '<gv', 'Outdent')
map('v', '>', '>gv', 'Indent')

-- Paste over a selection without clobbering the unnamed register.
map('x', '<leader>p', [["_dP]], 'Paste without yanking')

map('n', '<leader>e', vim.diagnostic.open_float, 'Line diagnostics')

-- ]d / [d walk every diagnostic; ]e / [e and ]w / [w walk only errors and only
-- warnings, which is the difference between skimming hints and chasing a real
-- failure. The jump is centred and does not open a float -- tiny-inline
-- diagnostics already renders the message at the cursor.
local function jump_diagnostic(count, severity)
  return function()
    if pcall(vim.diagnostic.jump, { count = count, severity = severity, float = false }) then
      vim.cmd 'normal! zz'
    end
  end
end

map('n', '[d', jump_diagnostic(-1), 'Previous diagnostic')
map('n', ']d', jump_diagnostic(1), 'Next diagnostic')
map('n', '[e', jump_diagnostic(-1, vim.diagnostic.severity.ERROR), 'Previous error')
map('n', ']e', jump_diagnostic(1, vim.diagnostic.severity.ERROR), 'Next error')
map('n', '[w', jump_diagnostic(-1, vim.diagnostic.severity.WARN), 'Previous warning')
map('n', ']w', jump_diagnostic(1, vim.diagnostic.severity.WARN), 'Next warning')
map('n', '<leader>xl', vim.diagnostic.setloclist, 'Diagnostics to loclist')
map('n', '<leader>xq', vim.diagnostic.setqflist, 'Diagnostics to quickfix')

-- Terminal: Esc drops back to normal mode instead of being sent to the shell.
map('t', '<Esc><Esc>', [[<C-\><C-n>]], 'Terminal: normal mode')
