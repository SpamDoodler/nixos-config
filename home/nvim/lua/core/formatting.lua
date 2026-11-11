-- Format stdin without shell filters: failed commands must never replace code
-- with their diagnostics. Commands format the whole buffer and never save it.
local function format_buffer(name, command, filetypes)
  local function notify(message, level)
    vim.notify(message, level or vim.log.levels.ERROR, { title = name })
  end

  if vim.bo.buftype ~= "" or not vim.bo.modifiable then
    notify("Formatting requires a normal, modifiable buffer")
    return
  end
  if not vim.tbl_contains(filetypes, vim.bo.filetype) then
    notify("Wrong filetype: " .. vim.bo.filetype)
    return
  end
  if vim.fn.executable(command[1]) ~= 1 then
    notify("Executable not found: " .. command[1])
    return
  end

  local buffer = vim.api.nvim_get_current_buf()
  local changedtick = vim.api.nvim_buf_get_changedtick(buffer)
  local filename = vim.api.nvim_buf_get_name(buffer)
  local cwd = filename ~= "" and vim.fn.fnamemodify(filename, ":h") or vim.fn.getcwd()
  local input = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  if vim.bo.endofline then
    input = input .. "\n"
  end

  -- Keep project-local formatter settings discoverable for named files.
  local argv = vim.list_extend({}, command)
  if name == "Black" and filename ~= "" then
    vim.list_extend(argv, { "--stdin-filename", filename })
  end
  local ok, result = pcall(function()
    return vim.system(argv, { stdin = input, text = true, cwd = cwd, timeout = 15000 }):wait()
  end)
  if not ok then
    notify(tostring(result))
    return
  end
  if result.code ~= 0 then
    local detail = vim.trim(result.stderr or "")
    if detail == "" then
      detail = vim.trim(result.stdout or "")
    end
    notify("Formatter failed (exit " .. result.code .. "); buffer unchanged.\n" .. detail)
    return
  end
  if not vim.api.nvim_buf_is_valid(buffer)
    or vim.api.nvim_get_current_buf() ~= buffer
    or vim.api.nvim_buf_get_changedtick(buffer) ~= changedtick then
    notify("Buffer changed while formatting; result discarded")
    return
  end

  local output = result.stdout or ""
  if output == input then
    notify("Already formatted", vim.log.levels.INFO)
    return
  end
  local endofline = output:sub(-1) == "\n"
  local lines = vim.split(output, "\n", { plain = true })
  if endofline then
    table.remove(lines)
  end
  if #lines == 0 then
    lines = { "" }
  end
  local view = vim.fn.winsaveview()
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  vim.bo.endofline = endofline
  vim.fn.winrestview(view)
  notify("Formatted; use :write to save", vim.log.levels.INFO)
end

local formatters = {
  Black = { command = { "black", "--quiet", "-" }, filetypes = { "python" } },
  Alejandra = { command = { "alejandra", "--quiet" }, filetypes = { "nix" } },
  Latexindent = {
    command = { "latexindent", "-g", "/dev/null", "-" },
    filetypes = { "tex", "plaintex", "latex" },
  },
}

for name, formatter in pairs(formatters) do
  vim.api.nvim_create_user_command(name, function()
    format_buffer(name, formatter.command, formatter.filetypes)
  end, { desc = "Format the whole buffer with " .. name .. " (without saving)" })
end
