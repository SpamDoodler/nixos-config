-- LTeX+ uses client-side commands for dictionary/rule actions, unlike ordinary
-- replacement quick fixes. Keep those choices writable and outside the store.
local fields = {
  ["_ltex.addToDictionary"] = { "dictionary", "words" },
  ["_ltex.disableRules"] = { "disabledRules", "ruleIds" },
  ["_ltex.hideFalsePositives"] = { "hiddenFalsePositives", "falsePositives" },
}

local function state_path(client)
  local root = client.config.root_dir or vim.fn.getcwd()
  return vim.fn.stdpath("data") .. "/nixsama/ltex/" .. vim.fn.sha256(root) .. ".json"
end

local function read_state(path)
  if vim.fn.filereadable(path) == 0 then return {} end
  local state = vim.json.decode(table.concat(vim.fn.readfile(path), "\n"))
  assert(type(state) == "table", "Expected an LTeX settings object")
  for _, pair in pairs(fields) do
    local values = state[pair[1]]
    if values then
      assert(type(values) == "table", "Invalid LTeX setting: " .. pair[1])
      for language, entries in pairs(values) do
        assert(type(language) == "string" and type(entries) == "table" and vim.islist(entries), "Invalid LTeX language list")
        for _, entry in ipairs(entries) do assert(type(entry) == "string", "Invalid LTeX entry") end
      end
    end
  end
  return state
end

local function load(client)
  local ok, state = pcall(read_state, state_path(client))
  if not ok then
    vim.notify("Cannot load LTeX choices: " .. tostring(state), vim.log.levels.ERROR)
    return
  end
  client.settings.ltex = vim.tbl_deep_extend("force", client.settings.ltex or {}, state)
end

local commands = {}
for command_name, pair in pairs(fields) do
  commands[command_name] = function(command, context)
    local client = vim.lsp.get_client_by_id(context.client_id)
    if not client or client.name ~= "ltex_plus" then return end
    local ok, err = pcall(function()
      local path = state_path(client)
      local state = read_state(path) -- Never overwrite an unreadable/corrupt file.
      local argument = assert(command.arguments and command.arguments[1], "Missing LTeX arguments")
      local additions = assert(argument[pair[2]], "Missing LTeX entries")
      local target = state[pair[1]] or {}
      for language, entries in pairs(additions) do
        local list = target[language] or {}
        for _, entry in ipairs(entries) do
          if not vim.tbl_contains(list, entry) then list[#list + 1] = entry end
        end
        target[language] = list
      end
      state[pair[1]] = target
      vim.fn.mkdir(vim.fs.dirname(path), "p", 448) -- 0700; may contain prose.
      local temporary = path .. "." .. vim.fn.getpid() .. ".tmp"
      assert(vim.fn.writefile({ vim.json.encode(state) }, temporary) == 0, "Cannot write LTeX choices")
      vim.uv.fs_chmod(temporary, 384) -- 0600
      assert(vim.uv.fs_rename(temporary, path))
      load(client)
      client:notify("workspace/didChangeConfiguration", { settings = client.settings })
      vim.notify("LTeX choice saved for this project", vim.log.levels.INFO)
    end)
    if not ok then vim.notify("Cannot save LTeX choice: " .. tostring(err), vim.log.levels.ERROR) end
  end
end

-- These are explicit single-purpose actions, not automatic spelling changes.
local function word_action(command_name)
  vim.lsp.buf.code_action({
    filter = function(action)
      return type(action.command) == "table" and action.command.command == command_name
    end,
    apply = true,
  })
end

vim.api.nvim_create_user_command("LtexAddWord", function()
  word_action("_ltex.addToDictionary")
end, { desc = "Add the LTeX-flagged word under the cursor to this project's dictionary" })
vim.api.nvim_create_user_command("LtexIgnore", function()
  word_action("_ltex.hideFalsePositives")
end, { desc = "Ignore the LTeX false positive under the cursor in this sentence/project" })

return {
  -- Do not start a prose checker on source code, commits, or every text buffer.
  filetypes = { "tex", "plaintex", "markdown" },
  settings = { ltex = {
    enabled = { "latex", "tex", "markdown" },
    language = "en-US",
    checkFrequency = "edit",
    diagnosticSeverity = "warning",
    completionEnabled = false, -- Keep prose dictionaries out of cmp suggestions.
    languageToolHttpServerUri = "", -- Bundled local LanguageTool; no text upload.
    additionalRules = { enablePickyRules = false },
  } },
  on_init = load,
  on_attach = function(_, buffer)
    -- 'spell' is window-local, not buffer-local.
    for _, window in ipairs(vim.fn.win_findbuf(buffer)) do vim.wo[window].spell = false end
    vim.keymap.set("n", "zg", function() word_action("_ltex.addToDictionary") end, {
      buffer = buffer, desc = "LTeX: add word to project dictionary",
    })
  end,
  commands = commands,
}
