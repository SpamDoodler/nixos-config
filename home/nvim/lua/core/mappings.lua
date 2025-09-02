local opts = { noremap = true, silent = true }

-- Normal keymaps
vim.keymap.set('n', '<C-J>', ':bprev<CR>', opts)
vim.keymap.set('n', '<C-K>', ':bnext<CR>', opts)
vim.keymap.set('n', '<C-H>', '<C-W>h', opts)
vim.keymap.set('n', '<C-L>', '<C-W>l', opts)
vim.keymap.set('t', '<ESC>', '<C-\\><C-n>', opts)
vim.keymap.set('n', 'j', 'gj', opts)
vim.keymap.set('n', 'k', 'gk', opts)
vim.keymap.set('v', 'j', 'gj', opts)
vim.keymap.set('v', 'k', 'gk', opts)

-- Plugin shortcuts
vim.keymap.set('n', '<F3>', ':NvimTreeToggle<CR>', opts)
