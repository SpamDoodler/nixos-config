vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  underline = true,
  virtual_text = false,
  signs = { text = {
    [vim.diagnostic.severity.ERROR] = "E",
    [vim.diagnostic.severity.WARN] = "W",
    [vim.diagnostic.severity.INFO] = "I",
    [vim.diagnostic.severity.HINT] = "H",
  } },
  float = { border = "rounded", source = "if_many" },
})
vim.opt.signcolumn = "yes"
vim.opt.mousemoveevent = true

local float, key
local generation = 0
local function close_hover()
  if float and vim.api.nvim_win_is_valid(float) then
    vim.api.nvim_win_close(float, true)
  end
  float, key = nil, nil
end

vim.keymap.set({ "n", "i", "x" }, "<MouseMove>", function()
  generation = generation + 1
  local ticket = generation
  local mouse = vim.fn.getmousepos()
  -- Keep the message readable while the pointer moves onto its popup.
  if mouse.winid == float and float and vim.api.nvim_win_is_valid(float) then return end
  local info = vim.fn.getwininfo(mouse.winid)[1]
  if not info or mouse.line < 1 or vim.api.nvim_win_get_config(mouse.winid).relative ~= "" then
    close_hover()
    return
  end
  local buffer = vim.api.nvim_win_get_buf(mouse.winid)
  local line = mouse.line - 1
  local gutter = mouse.wincol <= info.textoff
  local column = math.max(0, (mouse.column or 1) - 1) -- getmousepos uses byte columns.
  local scope = gutter and "line" or "cursor"
  local target = mouse.winid .. ":" .. line .. ":" .. (gutter and "gutter" or column)
  if key == target and float and vim.api.nvim_win_is_valid(float) then return end
  close_hover()
  local matches = vim.tbl_filter(function(diagnostic)
    local last = diagnostic.end_lnum or diagnostic.lnum
    local end_column = diagnostic.end_col or (diagnostic.col + 1)
    if line < diagnostic.lnum or line > last then return false end
    if last > diagnostic.lnum and line == last and end_column == 0 then return false end
    if gutter then return true end
    return (line > diagnostic.lnum or column >= diagnostic.col)
      and (line < last or column < end_column
        or (diagnostic.lnum == last and diagnostic.col == end_column and column == diagnostic.col))
  end, vim.diagnostic.get(buffer))
  if #matches == 0 then return end
  local changedtick = vim.api.nvim_buf_get_changedtick(buffer)
  vim.defer_fn(function()
    if ticket ~= generation or not vim.api.nvim_win_is_valid(mouse.winid) then return end
    if vim.api.nvim_win_get_buf(mouse.winid) ~= buffer
      or vim.api.nvim_buf_get_changedtick(buffer) ~= changedtick then return end
    vim.api.nvim_win_call(mouse.winid, function()
      local _, win = vim.diagnostic.open_float({
        bufnr = buffer, pos = { line, column }, scope = scope, focus = false,
        relative = "mouse",
        focusable = false, border = "rounded", source = "if_many",
        close_events = { "BufHidden", "InsertEnter", "CursorMoved", "CursorMovedI", "TextChanged", "TextChangedI" },
      })
      float, key = win, target
    end)
  end, 180)
end, { silent = true, desc = "Hover gutter or flagged text (requires terminal mouse-move reporting)" })
