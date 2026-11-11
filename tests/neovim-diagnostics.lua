-- Run with the candidate config and its tools: nvim --headless -c 'luafile tests/neovim-diagnostics.lua'
-- Uses only disposable local fixtures. No OpenCode/model request is made.
local ok, err = pcall(function()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  vim.o.autowrite = false
  vim.o.autowriteall = false
  local root = assert(vim.env.TMPDIR) .. "/nvim-diagnostics-" .. vim.fn.getpid()
  vim.fn.mkdir(root, "p")
  local function write(path, lines)
    vim.fn.mkdir(vim.fs.dirname(path), "p")
    vim.fn.writefile(lines, path)
  end
  local function source(diagnostic)
    return (diagnostic.source or ""):lower()
  end
  local function open_fixture(folder, filename, lines)
    local dir = root .. "/" .. folder
    vim.fn.mkdir(dir .. "/.git", "p")
    local path = dir .. "/" .. filename
    write(path, lines)
    vim.cmd("edit! " .. vim.fn.fnameescape(path))
    return vim.api.nvim_get_current_buf(), path, dir
  end
  local function require_diagnostics(buffer, predicate, label)
    local success = vim.wait(25000, function()
      return predicate(vim.diagnostic.get(buffer))
    end, 100)
    assert(success, label .. ":\n" .. vim.inspect(vim.diagnostic.get(buffer)))
    print("PASS: " .. label)
  end
  local function has(diagnostics, name)
    for _, diagnostic in ipairs(diagnostics) do
      if source(diagnostic):find(name, 1, true) then return true end
    end
    return false
  end

  local python = open_fixture("python", "bad.py", {
    "import os", "", "", "def typed(value: int) -> int:", "    return value", "",
    'result: str = typed(1)', 'danger: int = eval("1")',
  })
  assert(vim.wait(10000, function()
    return #vim.lsp.get_clients({ bufnr = python }) == 2
  end, 100))
  vim.wait(1000)
  vim.api.nvim_buf_set_lines(python, -1, -1, false, { "" })
  require_diagnostics(python, function(d)
    for _, diagnostic in ipairs(d) do
      if diagnostic.code == "S307" and has(d, "pyright") then return true end
    end
    return false
  end,
    "Pyright type errors and Ruff lint diagnostics")
  local ruff = vim.lsp.get_clients({ bufnr = python, name = "ruff" })[1]
  assert(ruff and not ruff.server_capabilities.hoverProvider)
  assert(not ruff.server_capabilities.documentFormattingProvider)

  local cpp, cppfile, cppdir = open_fixture("cpp", "bad.cpp", {
    "int * pointer() { return 0; }",
    'int broken() { return "wrong"; }',
  })
  write(cppdir .. "/compile_commands.json", { vim.json.encode({ {
    directory = cppdir, file = cppfile,
    arguments = { "clang++", "-std=c++20", "-Wall", "-Wextra", "-Wpedantic", "-Wconversion", "-Wshadow", "-c", cppfile },
  } }) })
  require_diagnostics(cpp, function(d)
    local compiler, tidy = false, false
    for _, diagnostic in ipairs(d) do
      if tostring(diagnostic.code):find("modernize-use-nullptr", 1, true) then tidy = true end
      if diagnostic.severity == vim.diagnostic.severity.ERROR then compiler = true end
    end
    return compiler and tidy
  end, "clangd compiler diagnostics plus strict clang-tidy checks")

  local tex = open_fixture("latex", "bad.tex", {
    "\\documentclass{article}", "\\begin{document}", "See \\ref{missing}.", "\\end{document}",
  })
  assert(vim.wait(10000, function()
    local clients = vim.lsp.get_clients({ bufnr = tex, name = "texlab" })
    return clients[1] and clients[1].initialized
  end, 100), "texlab did not initialize")
  -- Configuration is delivered asynchronously after didOpen; exercise save too.
  vim.wait(500)
  vim.cmd("write")
  require_diagnostics(tex, function(d)
    for _, diagnostic in ipairs(d) do
      if diagnostic.message:find("Non-breaking space", 1, true) then return true end
    end
    return false
  end, "texlab runs ChkTeX without automatic compilation")

  local nix = open_fixture("nix", "bad.nix", {
    "x: let unused = 1; in { x = x; missing = unknown; }",
  })
  vim.cmd("Lint")
  require_diagnostics(nix, function(d)
    for _, diagnostic in ipairs(d) do
      if diagnostic.code == "sema-undefined-variable" and has(d, "statix") and has(d, "deadnix") then return true end
    end
    return false
  end, "nixd, Statix and deadnix diagnostics")
  for _, diagnostic in ipairs(vim.diagnostic.get(nix)) do
    assert(diagnostic.code ~= "sema-unused-def-let", "Duplicate unused-binding report from nixd")
  end

  local lua = open_fixture("lua", "bad.lua", {
    "local unused = 1", "vim.notify(missing)", "---@type integer", 'local typed = "wrong"', "print(typed)",
  })
  vim.cmd("Lint")
  require_diagnostics(lua, function(d)
    for _, diagnostic in ipairs(d) do
      if tostring(diagnostic.code) == "assign-type-mismatch" and has(d, "selene") then return true end
    end
    return false
  end, "Lua language-server type errors and Neovim-aware Selene lint")

  local sources = require("cmp").get_config().sources
  assert(vim.iter(sources):any(function(item) return item.name == "path" end))
  assert(vim.fn.maparg(",rn", "n") ~= "" and vim.fn.maparg(",af", "n") ~= "")
  local diagnostic_config = vim.diagnostic.config()
  assert(diagnostic_config.signs.text[vim.diagnostic.severity.WARN] == "W")
  assert(not diagnostic_config.virtual_text and vim.o.mousemoveevent)

  -- Hover the gutter without moving the editing cursor or making a model call.
  local namespace = vim.api.nvim_create_namespace("diagnostic-ui-test")
  vim.diagnostic.set(namespace, lua, { {
    lnum = 1, col = 0, message = "hover fixture", source = "test", severity = vim.diagnostic.severity.WARN,
  } })
  local mouse = vim.fn.getmousepos
  vim.fn.getmousepos = function()
    return { winid = vim.api.nvim_get_current_win(), line = 2, wincol = 1 }
  end
  local hover = vim.fn.maparg("<MouseMove>", "n", false, true).callback
  hover()
  assert(vim.wait(3000, function()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then return true end
    end
    return false
  end), "Gutter hover did not open a diagnostic float")
  vim.fn.getmousepos = mouse

  -- Ensure the OpenCode payload uses unsaved text and exactly +/-2 lines.
  vim.diagnostic.reset()
  local buffer = open_fixture("bridge", "sample.py", { "one", "two", "three", "four", "five", "six", "seven" })
  vim.api.nvim_buf_set_lines(buffer, 3, 4, false, { "unsaved line" })
  vim.diagnostic.set(namespace, buffer, { { lnum = 3, col = 0, message = "example error", source = "test" } })
  local bridge = require("nixsama.core.opencode")
  local prompt = assert(bridge.diagnostic_prompt(buffer, 3))
  assert(prompt:find("2: two", 1, true) and prompt:find("6: six", 1, true))
  assert(prompt:find("4: unsaved line", 1, true))
  assert(not prompt:find("1: one", 1, true) and not prompt:find("7: seven", 1, true))
  vim.api.nvim_win_set_cursor(0, { 4, 0 })
  bridge.suggest()
  assert(vim.bo.buftype == "nofile", "Expected a review preview, not an automatic request")
  local sent
  local jobstart = vim.fn.jobstart
  vim.fn.jobstart = function(argv, options) sent = { argv = argv, options = options }; return 1 end
  vim.fn.maparg("s", "n", false, true).callback()
  vim.fn.jobstart = jobstart
  assert(sent.argv[1] == "opencode" and sent.argv[3] == "review" and sent.argv[5] == prompt)
  assert(sent.options.term and sent.options.cwd:find("bridge", 1, true))
  print("PASS: gutter signs/hover and confirmed OpenCode payload (job mocked, no inference)")

  -- Real CLI checks: clean inputs, strict baseline, and narrow project overrides.
  local defaults = vim.fn.stdpath("config") .. "/diagnostic-defaults"
  local function cli(argv, stdin, cwd)
    return vim.system(argv, { text = true, stdin = stdin, cwd = cwd }):wait(15000)
  end
  local ruff_clean = cli({ "ruff", "check", "--config", defaults .. "/ruff.toml", "-" }, "value: int = 1\n")
  assert(ruff_clean.code == 0, ruff_clean.stderr)
  local ruff_bad = cli({ "ruff", "check", "--config", defaults .. "/ruff.toml", "-" }, "import os\n")
  assert(ruff_bad.code == 1 and ruff_bad.stdout:find("F401", 1, true))
  local selene_clean = cli({ "selene", "--config", defaults .. "/selene.toml", "-" }, 'vim.notify("hello")\n')
  assert(selene_clean.code == 0, selene_clean.stderr)
  local nix_clean = "{ value = 1; }\n"
  assert(cli({ "statix", "check", "--stdin" }, nix_clean, root).code == 0)
  local cleanfile = root .. "/clean.nix"
  write(cleanfile, { "{ value = 1; }" })
  assert(cli({ "deadnix", "--fail", cleanfile }).code == 0)
  assert(cli({ "chktex", "-q" }, "\\documentclass{article}\n\\begin{document}\nHello.\n\\end{document}\n", root).code == 0)

  local override = root .. "/overrides"
  vim.fn.mkdir(override, "p")
  write(override .. "/ruff.toml", { '[lint]', 'select = ["F"]', 'ignore = ["F401"]' })
  local override_file = override .. "/example.py"
  write(override_file, { "import os" })
  local result = cli({ "ruff", "check", override_file }, nil, override)
  assert(result.code == 0, result.stdout .. result.stderr)
  write(override .. "/statix.toml", { 'disabled = ["manual_inherit"]' })
  result = cli({ "statix", "check", "--stdin", "--config", override .. "/statix.toml" }, "x: { x = x; }\n", override)
  assert(result.code == 0, result.stdout .. result.stderr)
  write(override .. "/selene.toml", { 'std = "lua51"', '[lints]', 'unused_variable = "allow"' })
  result = cli({ "selene", "--config", override .. "/selene.toml", "-" }, "local unused = 1\n", override)
  assert(result.code == 0, result.stdout .. result.stderr)
  -- User clangd config has high priority, but Remove wins over Add across fragments.
  local override_cpp = override .. "/example.cpp"
  write(override_cpp, { "int * pointer() { return 0; }" })
  write(override .. "/.clangd", {
    "Diagnostics:", "  ClangTidy:", "    Remove: [modernize-use-nullptr]",
  })
  result = cli({ "clangd", "--clang-tidy", "--enable-config", "--check=" .. override_cpp }, nil, override)
  assert(result.code == 0, result.stderr)
  assert(not result.stderr:find("[modernize-use-nullptr]", 1, true), result.stderr)
  print("PASS: clean CLI fixtures, strict baseline and project rule overrides")

  for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
end)
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
  vim.cmd("cquit 1")
end
print("PASS: strict diagnostic integration")
vim.cmd("qa!")
