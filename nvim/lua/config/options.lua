-- OPTIONS  --  vim.opt settings, no plugins involved
-- Everything here works on a bare Neovim install with no network access.

-- Leader must be set before lazy.nvim loads. Space is deliberate: WezTerm's
-- leader is Ctrl+a and Herdr's prefix is Ctrl+; so none of the three collide.
vim.g.mapleader = ' '
vim.g.maplocalleader = [[\]]

local opt = vim.opt

opt.number = true
opt.relativenumber = true -- jump N lines with 5j / 12k
opt.cursorline = true
opt.scrolloff = 8 -- keep 8 lines of context above/below
opt.sidescrolloff = 8
opt.wrap = false

-- Overridden per-filetype by editorconfig.
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.expandtab = true
opt.smartindent = true
opt.breakindent = true

opt.ignorecase = true
opt.smartcase = true -- ...unless the pattern has a capital in it
opt.hlsearch = true
opt.incsearch = true

-- Splits open where the eye expects them
opt.splitright = true
opt.splitbelow = true

opt.termguicolors = true -- 24-bit colour; WezTerm supports it
opt.signcolumn = 'yes' -- always on, so text does not jitter
opt.showmode = false -- lualine already shows the mode
opt.cmdheight = 1
opt.pumheight = 10
opt.laststatus = 3 -- one global statusline, not one per split
opt.fillchars = { eob = ' ' } -- hide the ~ on empty lines
opt.list = true
opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

opt.undofile = true -- persistent undo across restarts
opt.swapfile = false
opt.backup = false
opt.updatetime = 250 -- faster CursorHold -> gitsigns, diagnostics
opt.timeoutlen = 400 -- which-key popup delay

-- Windows-style selection: a shifted cursor key starts and extends a highlight,
-- an unshifted one drops it. Covers Shift+Arrow (by character/line) and
-- Ctrl+Shift+Arrow (by word), which is the muscle memory this borrows from.
-- This is Visual mode, not Select mode -- the highlight is the same, but the
-- selection survives typing instead of being replaced. Add 'key' to
-- 'selectmode' if you want the replace-on-type behaviour too.
opt.keymodel = { 'startsel', 'stopsel' }

opt.mouse = 'a'
opt.clipboard = 'unnamedplus' -- yank straight to the Windows clipboard
opt.completeopt = { 'menu', 'menuone', 'noselect' }
opt.confirm = true -- prompt instead of failing on unsaved quit
opt.splitkeep = 'screen'

-- Windows: PowerShell as :! and :terminal shell, in place of cmd.exe.
-- pwsh (7+) is preferred and falls back to the bundled Windows PowerShell.
if vim.fn.has 'win32' == 1 then
  local pwsh = vim.fn.executable 'pwsh' == 1 and 'pwsh' or 'powershell'
  vim.opt.shell = pwsh
  vim.opt.shellcmdflag =
    '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
  vim.opt.shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.opt.shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  vim.opt.shellquote = ''
  vim.opt.shellxquote = ''
end

-- Flash the yanked region so it is obvious what went to the clipboard.
vim.api.nvim_create_autocmd('TextYankPost', {
  group = vim.api.nvim_create_augroup('highlight_yank', { clear = true }),
  -- vim.hl replaced vim.highlight in 0.11; keep working on older builds too.
  callback = function() (vim.hl or vim.highlight).on_yank { timeout = 150 } end,
})

-- Reopen a file on the line it was left on.
vim.api.nvim_create_autocmd('BufReadPost', {
  group = vim.api.nvim_create_augroup('last_position', { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(args.buf) then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})
