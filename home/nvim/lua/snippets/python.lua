local ls = require("luasnip")
local s, i = ls.snippet, ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

return {
  s({ trig = "def", name = "Function" }, fmt([[
    def {}({}):
        {}
  ]], { i(1, "function_name"), i(2), i(0, "pass") })),
  s({ trig = "cls", name = "Class with initializer" }, fmt([[
    class {}:
        def __init__(self, {}):
            {}
  ]], { i(1, "ClassName"), i(2, "value"), i(0, "self.value = value") })),
  s({ trig = "main", name = "Main entry point" }, fmt([[
    def main():
        {}


    if __name__ == "__main__":
        main()
  ]], { i(0, "pass") })),
  s({ trig = "for", name = "For loop" }, fmt([[
    for {} in {}:
        {}
  ]], { i(1, "item"), i(2, "items"), i(0, "pass") })),
  s({ trig = "enum", name = "Enumerate items" }, fmt([[
    for {}, {} in enumerate({}):
        {}
  ]], { i(1, "idx"), i(2, "item"), i(3, "items"), i(0, "pass") })),
  s({ trig = "with", name = "Open a text file" }, fmt([[
    with open({}, encoding="utf-8") as {}:
        {}
  ]], { i(1, '"input.txt"'), i(2, "file"), i(0, "pass") })),
  s({ trig = "try", name = "Handle a specific exception" }, fmt([[
    try:
        {}
    except {} as {}:
        {}
  ]], { i(1, "pass"), i(2, "ValueError"), i(3, "exc"), i(0, "raise") })),
  s({ trig = "test", name = "Test function" }, fmt([[
    def test_{}():
        assert {}
  ]], { i(1, "behavior"), i(0, "actual == expected") })),
  s({ trig = "dclass", name = "Dataclass (import at module level)" }, fmt([[
    from dataclasses import dataclass


    @dataclass
    class {}:
        {}: {}
  ]], { i(1, "Data"), i(2, "value"), i(0, "int") })),
  s({ trig = "prop", name = "Read-only property" }, fmt([[
    @property
    def {}(self):
        return self._{}
  ]], { i(1, "value"), rep(1) })),
}
