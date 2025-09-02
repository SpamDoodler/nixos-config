local ls = require"luasnip"

ls.config.setup({
  history = false,
  region_check_events = "InsertEnter",
  delete_check_events = "TextChanged,InsertLeave",
})

local t = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
end

_G.tab_complete = function()
    if ls and ls.jumpable(1) then
        return t "<Plug>luasnip-jump-next"
    else
        return t "<Tab>"
    end
end

_G.s_tab_complete = function()
    if ls and ls.jumpable(-1) then
        return t "<Plug>luasnip-jump-prev"
    else
        return t "<S-Tab>"
    end
end

vim.api.nvim_set_keymap("i", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<Tab>", "v:lua.tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("s", "<S-Tab>", "v:lua.s_tab_complete()", {expr = true})
vim.api.nvim_set_keymap("i", "<C-S>", "<Plug>luasnip-next-choice", {})
vim.api.nvim_set_keymap("s", "<C-S>", "<Plug>luasnip-next-choice", {})

local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local events = require("luasnip.util.events")

local function readints(args)
    return table.concat(vim.split(args[1][1], ', '), ' >> ')
end

local function copy(args)
	return args[1]
end

ls.snippets.cpp = {
  s("ustd", t("using namespace std;")),

  s("rints", {
    t("int "), i(1), t({";","cin >> "}),
    f(readints, 1),
    t({";", ""}),
    i(0),
  }),

  s("coutm", {
    t("int "),
    i(1),
    t({";", "cin >> "}),
    f(readints, 1),
    t({";", ""}),
    i(0),
  }),

  s("fori", {
    t("for (int "),
    i(1),
    t(" = "),
    i(2, "0"),
    t("; "),
    f(copy, 1),
    i(3),
    t("; "),
    i(4),
    f(copy, 1),
    t({") {", "\t"}),
    i(0),
    t({"", "}"}),
  }),
}

ls.snippets.go = {
  s("ife", {
    t({"if err != nil {", "\t"}),
    c(1, {
      t(""),
      t("return "),
    }),
    i(0),
    t({"", "}"}),
  })
}
