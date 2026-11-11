local lint = require("lint")
local defaults = vim.fn.stdpath("config") .. "/diagnostic-defaults"

local function project_file(name)
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  return vim.fs.find(name, { path = dir or vim.fn.getcwd(), upward = true, type = "file" })[1]
end

lint.linters_by_ft = { nix = { "statix", "deadnix" }, lua = { "selene" } }
local deadnix = lint.linters.deadnix
local parse_deadnix = deadnix.parser
deadnix.parser = function(output, buffer)
  local diagnostics = parse_deadnix(output, buffer)
  for _, diagnostic in ipairs(diagnostics) do diagnostic.source = "deadnix" end
  return diagnostics
end
lint.linters.deadnix = deadnix
local selene = lint.linters.selene
selene.args = {
  "--display-style", "json", "--no-summary", "--config",
  function() return project_file("selene.toml") or (defaults .. "/selene.toml") end,
  "-",
}
lint.linters.selene = selene

local statix = lint.linters.statix
statix.args = {
  "check", "-o", "errfmt", "--stdin", "--config",
  function()
    return project_file("statix.toml") or vim.fs.dirname(vim.api.nvim_buf_get_name(0)) or vim.fn.getcwd()
  end,
}
lint.linters.statix = statix

local function run(event)
  if vim.bo.buftype ~= "" or vim.api.nvim_buf_get_name(0) == "" then return end
  local dir = vim.fs.dirname(vim.api.nvim_buf_get_name(0))
  if not dir or vim.fn.isdirectory(dir) ~= 1 then return end
  if vim.bo.filetype == "lua" then
    lint.try_lint("selene", { cwd = dir })
  elseif vim.bo.filetype == "nix" then
    lint.try_lint("statix", { cwd = dir })
    -- deadnix 1.3.2 cannot read stdin. Never lint an unsaved disk snapshot.
    if not vim.bo.modified and (event ~= "InsertLeave") then
      lint.try_lint("deadnix", { cwd = dir })
    end
  end
end

vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost", "InsertLeave" }, {
  group = vim.api.nvim_create_augroup("NixSamaLint", { clear = true }),
  callback = function(event) run(event.event) end,
})
vim.api.nvim_create_user_command("Lint", function() run("manual") end, {
  desc = "Run buffer linters (deadnix requires a saved buffer)",
})
