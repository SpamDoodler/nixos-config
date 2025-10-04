vim.cmd [[colorscheme nightfox]]

vim.api.nvim_create_autocmd({"BufRead", "BufNewFile"}, {
    pattern = "*.sage",
    command = "set filetype=python"
})
