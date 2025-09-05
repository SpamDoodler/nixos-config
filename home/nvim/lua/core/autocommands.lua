local function set_filetype_opts(patterns, opts_table)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = patterns,
    callback = function()
      for k,v in pairs(opts_table) do
        vim.opt_local[k] = v
      end
    end
  })
end

-- Language-specific indentation
set_filetype_opts({"asm", "go"}, { tabstop = 4, shiftwidth = 4, expandtab = false })
set_filetype_opts({"norg", "nix", "lua", "haskell"}, { tabstop = 2, shiftwidth = 2, wrap = false })
set_filetype_opts({"python", "cpp", "c"}, { tabstop = 4, shiftwidth = 4 })

