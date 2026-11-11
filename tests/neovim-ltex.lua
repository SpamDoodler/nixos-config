-- Candidate editor/config/plugins required. All sources and dictionaries are
-- disposable under TMPDIR / isolated XDG_DATA_HOME. No inference or web checker.
local ok, err = pcall(function()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  vim.o.autowrite = false
  vim.o.autowriteall = false
  local root = assert(vim.env.TMPDIR) .. "/nvim-ltex-" .. vim.fn.getpid()
  vim.fn.mkdir(root .. "/.git", "p")
  local function open(name, lines)
    local path = root .. "/" .. name
    vim.fn.writefile(lines, path)
    vim.cmd("edit! " .. vim.fn.fnameescape(path))
    return vim.api.nvim_get_current_buf(), path
  end
  local function diagnostics(buffer)
    return vim.tbl_filter(function(d) return d.source == "LTeX" end, vim.diagnostic.get(buffer))
  end
  local function wait_for(predicate, message)
    assert(vim.wait(60000, predicate, 100), message)
  end
  local markdown, path = open("sample.md", {
    "This is a speling mistake.", "", "```python", "speling = blorfzzzz", "```", "",
    "Use `blorfzzzz` here.", "", "This are incorrect.", "",
    "$\\mathsf{blorfzzzz} = xyzzzz$", "", "$$", "blorfzzzz = xyzzzz", "$$",
  })
  wait_for(function() return #diagnostics(markdown) > 0 end, "No Markdown prose diagnostics")
  local client = assert(vim.lsp.get_clients({ name = "ltex_plus", bufnr = markdown })[1])
  assert(not vim.wo.spell)
  assert(client.settings.ltex.languageToolHttpServerUri == "")
  local spelling
  local grammar
  for _, d in ipairs(diagnostics(markdown)) do
    assert(d.lnum ~= 3 and d.lnum ~= 6, "LTeX checked Markdown code: " .. vim.inspect(d))
    assert(d.lnum ~= 10 and d.lnum ~= 13, "LTeX checked Markdown math: " .. vim.inspect(d))
    assert(d.severity == vim.diagnostic.severity.WARN)
    if d.lnum == 0 then spelling = d end
    if d.lnum == 8 then grammar = d end
  end
  assert(spelling and grammar, "Expected spelling and grammar diagnostics: " .. vim.inspect(diagnostics(markdown)))
  local response = assert(client:request_sync("textDocument/codeAction", {
    textDocument = { uri = vim.uri_from_bufnr(markdown) },
    range = spelling.user_data.lsp.range,
    context = { diagnostics = { spelling.user_data.lsp } },
  }, 10000, markdown))
  assert(not response.err, vim.inspect(response.err))
  local replacement, dictionary, disable, hide
  for _, action in ipairs(response.result or {}) do
    if action.edit and action.title:find("spelling", 1, true) then replacement = action end
    local command = action.command and action.command.command
    if command == "_ltex.addToDictionary" then dictionary = action end
    if command == "_ltex.disableRules" then disable = action end
    if command == "_ltex.hideFalsePositives" then hide = action end
  end
  assert(replacement and dictionary and disable and hide, "Missing expected LTeX code actions")
  -- Test the actual user binding from column zero, outside the misspelled word.
  local select = vim.ui.select
  local menu
  vim.ui.select = function(items, _, callback) menu = items; callback(nil) end
  vim.api.nvim_win_set_cursor(0, { 1, 0 })
  vim.fn.maparg("<F4>", "n", false, true).callback()
  wait_for(function() return menu ~= nil end, "The F4 binding offered no actions at line start")
  vim.ui.select = select
  assert(#menu > 0, "Empty line-level code-action menu")
  vim.lsp.util.apply_workspace_edit(replacement.edit, client.offset_encoding)
  assert(vim.api.nvim_buf_get_lines(markdown, 0, 1, false)[1] == "This is a spelling mistake.")
  assert(vim.fn.readfile(path)[1] == "This is a speling mistake.", "Quick fix saved unexpectedly")
  vim.cmd("undo")

  vim.api.nvim_win_set_cursor(0, { 1, spelling.col })
  vim.fn.maparg("zg", "n", false, true).callback()
  wait_for(function()
    for _, d in ipairs(diagnostics(markdown)) do if d.lnum == 0 then return false end end
    return true
  end, "Dictionary action did not remove spelling diagnostic")
  local state_path = vim.fn.stdpath("data") .. "/nixsama/ltex/" .. vim.fn.sha256(root) .. ".json"
  local state = vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
  assert(vim.tbl_contains(state.dictionary["en-US"], "speling"))
  -- Exercise the direct ignore command, then reload persistence independently.
  vim.api.nvim_win_set_cursor(0, { 9, grammar.col })
  vim.cmd("LtexIgnore")
  wait_for(function()
    local saved = vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
    return saved.hiddenFalsePositives and #(saved.hiddenFalsePositives["en-US"] or {}) > 0
  end, "Direct ignore command did not persist a sentence exception")
  client:exec_cmd(disable.command, { bufnr = markdown })
  state = vim.json.decode(table.concat(vim.fn.readfile(state_path), "\n"))
  assert(#state.hiddenFalsePositives["en-US"] > 0 and #state.disabledRules["en-US"] > 0)
  local fresh = { config = { root_dir = root }, settings = { ltex = {} } }
  local config = require("nixsama.plugins.ltex")
  config.on_init(fresh)
  assert(vim.deep_equal(fresh.settings.ltex.dictionary, state.dictionary))
  local other = { config = { root_dir = root .. "/other" }, settings = { ltex = {} } }
  config.on_init(other)
  assert(not other.settings.ltex.dictionary, "Dictionary leaked across projects")
  print("PASS: Markdown spelling/grammar, code exclusion, safe corrections and persistent project choices")

  -- Separate root: the previous test deliberately disabled the spelling rule.
  local texroot = root .. "/tex"
  vim.fn.mkdir(texroot .. "/.git", "p")
  local tex = open("tex/sample.tex", {
    "\\documentclass{article}", "\\begin{document}", "This is a speling mistake.", "",
    "$\\mathsf{blorfzzzz} = xyzzzz$", "",
    "\\begin{verbatim}", "speling blorfzzzz", "\\end{verbatim}", "\\end{document}",
  })
  wait_for(function() return #diagnostics(tex) > 0 end, "No LaTeX prose diagnostics")
  local prose = false
  for _, d in ipairs(diagnostics(tex)) do
    if d.lnum == 2 then prose = true end
    assert(d.lnum ~= 4 and d.lnum ~= 7, "LTeX checked math/verbatim: " .. vim.inspect(d))
  end
  assert(prose)
  vim.api.nvim_buf_set_lines(tex, 2, 3, false, { "This is a spelling mistake." })
  wait_for(function() return #diagnostics(tex) == 0 end, "Clean LaTeX fixture still has prose diagnostics")
  wait_for(function() return #vim.lsp.get_clients({ name = "texlab", bufnr = tex }) == 1 end, "texlab no longer attaches")
  assert(vim.lsp.config.texlab.settings.texlab.build.onSave == false)
  assert(not vim.tbl_contains(config.filetypes, "python"))
  print("PASS: LaTeX prose checking excludes math/verbatim and coexists with texlab")
end)
for _, client in ipairs(vim.lsp.get_clients()) do client:stop(true) end
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
print("PASS: LTeX+ integration (local checker)")
vim.cmd("qa!")
