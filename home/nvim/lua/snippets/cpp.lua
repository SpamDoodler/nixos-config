local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

return {
  s({ trig = "inc", name = "Standard header" }, fmt("#include <{}>", { i(1, "iostream") })),
  s({ trig = "main", name = "Main function" }, fmt([[
    int main() {{
        {}
        return 0;
    }}
  ]], { i(0) })),
  s({ trig = "fn", name = "Function" }, fmt([[
    {} {}({}) {{
        {}
    }}
  ]], { i(1, "void"), i(2, "function_name"), i(3), i(0) })),
  s({ trig = "fori", name = "Indexed for loop" }, fmt([[
    for (std::size_t {} = 0; {} < {}; ++{}) {{
        {}
    }}
  ]], { i(1, "idx"), rep(1), i(2, "count"), rep(1), i(0) })),
  s({ trig = "forr", name = "Range-based for loop" }, fmt([[
    for (const auto& {} : {}) {{
        {}
    }}
  ]], { i(1, "item"), i(2, "items"), i(0) })),
  s({ trig = "iff", name = "If statement" }, fmt([[
    if ({}) {{
        {}
    }}
  ]], { i(1, "condition"), i(0) })),
  s({ trig = "cls", name = "Class" }, fmt([[
    class {} {{
    public:
        {}() = default;
        {}
    }};
  ]], { i(1, "ClassName"), rep(1), i(0) })),
  s({ trig = "struct", name = "Struct" }, fmt([[
    struct {} {{
        {}
    }};
  ]], { i(1, "Data"), i(0) })),
  s({ trig = "cout", name = "Print a line" }, fmt("std::cout << {} << '\\n';", { i(1, "value") })),
  s({ trig = "cin", name = "Read a value" }, fmt("std::cin >> {};", { i(1, "value") })),
}
