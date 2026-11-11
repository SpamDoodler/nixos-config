-- Run with the candidate configuration loaded:
-- nvim --headless -c 'luafile tests/neovim-formatting.lua'
-- All files are temporary; real formatters run, but no user file is saved.
local original_notify = vim.notify
local messages = {}
vim.notify = function(message, level)
  table.insert(messages, { message = message, level = level })
end

local ok, err = pcall(function()
  assert(vim.v.errmsg == "", vim.v.errmsg)
  vim.o.autowrite = false
  vim.o.autowriteall = false
  for _, server in ipairs({ "pyright", "ruff", "clangd", "rust_analyzer", "texlab", "ltex_plus", "nixd", "lua_ls" }) do
    vim.lsp.enable(server, false)
  end
  local root = assert(vim.env.TMPDIR, "Set TMPDIR for test artifacts")
    .. "/nvim format test " .. vim.fn.getpid()
  vim.fn.mkdir(root, "p")

  local function contents()
    return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  end

  local function open_sample(name, ft, lines)
    local path = root .. "/" .. name
    vim.fn.writefile(lines, path)
    vim.cmd("edit! " .. vim.fn.fnameescape(path))
    vim.bo.filetype = ft
    messages = {}
    return path
  end

  local samples = {
    { name = "sample.py", ft = "python", command = "Black", lines = { "value=  [1,2,3]" } },
    { name = "sample.nix", ft = "nix", command = "Alejandra", lines = { "{a=1;b=[1 2];}" } },
    {
      name = "sample.tex", ft = "tex", command = "Latexindent",
      lines = { "\\begin{itemize}", "\\item Example", "\\end{itemize}" },
    },
  }
  for _, sample in ipairs(samples) do
    local path = open_sample(sample.name, sample.ft, sample.lines)
    local before = contents()
    vim.cmd(sample.command)
    local formatted = contents()
    assert(formatted ~= before, sample.command .. " did not format the sample")
    assert(messages[#messages].level == vim.log.levels.INFO, vim.inspect(messages))
    assert(vim.bo.modified, "Formatted buffer should remain unsaved")
    assert(vim.deep_equal(vim.fn.readfile(path), sample.lines), "Formatter saved the file")
    local tick = vim.api.nvim_buf_get_changedtick(0)
    vim.cmd(sample.command)
    assert(contents() == formatted, sample.command .. " was not idempotent")
    assert(vim.api.nvim_buf_get_changedtick(0) == tick, "Second run created another edit")
    vim.cmd("undo")
    assert(contents() == before, sample.command .. " did not undo in one step")
  end
  assert(vim.fn.filereadable(root .. "/indent.log") == 0, "latexindent left a log in the project")

  -- Real parser failures must not insert error messages into the buffer.
  for _, sample in ipairs({
    { name = "invalid.py", ft = "python", command = "Black", lines = { "def broken(:" } },
    { name = "invalid.nix", ft = "nix", command = "Alejandra", lines = { "{ broken = ; }" } },
  }) do
    open_sample(sample.name, sample.ft, sample.lines)
    local before = contents()
    vim.cmd(sample.command)
    assert(contents() == before and not vim.bo.modified, "Failed formatter changed the buffer")
    assert(messages[#messages].level == vim.log.levels.ERROR, "Failure was not reported")
  end

  open_sample("wrong-type.py", "python", { "value = 1" })
  vim.cmd("Alejandra")
  assert(messages[#messages].message:find("Wrong filetype", 1, true))
  assert(not vim.bo.modified)

  local original_system = vim.system
  vim.system = function()
    return { wait = function() return { code = 124, stdout = "garbage", stderr = "Timed out" } end }
  end
  vim.cmd("Black")
  assert(contents() == "value = 1" and not vim.bo.modified, "Timeout replaced buffer")
  vim.system = function()
    return { wait = function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, { "newer edit" })
      return { code = 0, stdout = "outdated output\n", stderr = "" }
    end }
  end
  vim.cmd("Black")
  assert(contents() == "newer edit", "Formatter overwrote a newer edit")
  vim.system = original_system

  local path = vim.env.PATH
  vim.env.PATH = ""
  vim.cmd("Black")
  vim.env.PATH = path
  assert(messages[#messages].message:find("Executable not found", 1, true))
  assert(contents() == "newer edit")
end)

vim.notify = original_notify
if not ok then
  io.stderr:write(tostring(err) .. "\n")
  vim.cmd("cquit 1")
end
print("PASS: formatter commands, repeat runs, undo, no saves/logs, and failure preservation")
vim.cmd("qa!")
