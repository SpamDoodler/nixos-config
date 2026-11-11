local ls = require("luasnip")

ls.config.setup({ enable_autosnippets = false })

-- Neovim calls LaTeX buffers "tex"; keep the definitions in latex.lua.
ls.filetype_extend("tex", { "latex" })

local paths = vim.api.nvim_get_runtime_file("lua/nixsama/snippets", false)
assert(paths[1], "NixSama snippet directory is missing from the runtime path")
require("luasnip.loaders.from_lua").lazy_load({ paths = paths })

-- Completion, expansion and jump mappings belong to completion.lua.
