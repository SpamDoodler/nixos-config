-- Run without language servers: nvim --headless -u NONE
--   -c 'luafile home/nvim/lua/core/diagnostics.lua' -c 'luafile tests/neovim-hover.lua'
local original_mouse = vim.fn.getmousepos
local ok, err = pcall(function()
  vim.o.number = true
  vim.o.mouse = "a"
  local buffer = vim.api.nvim_get_current_buf()
  local window = vim.api.nvim_get_current_win()
  vim.api.nvim_buf_set_lines(buffer, 0, -1, false, { "editing cursor", "A speling mistake.", "clean line" })
  vim.api.nvim_win_set_cursor(window, { 1, 0 })
  local ns = vim.api.nvim_create_namespace("nixsama-hover-test")
  vim.diagnostic.set(ns, buffer, { {
    lnum = 1, col = 2, end_col = 9, message = "Spelling hover fixture", severity = vim.diagnostic.severity.WARN,
  } })
  local mouse
  vim.fn.getmousepos = function() return mouse end
  local function popup()
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      if vim.api.nvim_win_get_config(win).relative ~= "" then
        local lines = vim.api.nvim_buf_get_lines(vim.api.nvim_win_get_buf(win), 0, -1, false)
        if table.concat(lines, "\n"):find("Spelling hover fixture", 1, true) then return win end
      end
    end
  end
  local function move(position, mode)
    mouse = position
    local callback = assert(vim.fn.maparg("<MouseMove>", mode or "n", false, true).callback)
    callback()
  end
  move({ winid = window, line = 2, wincol = 1, column = 1 })
  assert(vim.wait(2000, popup, 20), "No gutter hover popup")
  local win = popup()
  move({ winid = win, line = 1, wincol = 1, column = 1 })
  assert(vim.api.nvim_win_is_valid(win), "Entering popup closed it")
  move({ winid = window, line = 2, wincol = 20, column = 4 })
  assert(vim.wait(2000, popup, 20), "No hover on flagged text")
  assert(vim.deep_equal(vim.api.nvim_win_get_cursor(window), { 1, 0 }), "Hover moved the editing cursor")
  move({ winid = window, line = 3, wincol = 20, column = 4 })
  assert(not popup(), "Leaving diagnostic did not close popup")
  move({ winid = window, line = 2, wincol = 20, column = 4 }, "i")
  assert(vim.wait(2000, popup, 20), "Insert-mode mapping did not open hover")
  move({ winid = window, line = 2, wincol = 20, column = 15 })
  assert(not popup(), "Text outside diagnostic left popup open")
  -- Hover another split, without moving the editing cursor or focus.
  vim.cmd("vsplit")
  local other = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(window)
  move({ winid = other, line = 2, wincol = 1, column = 1 })
  assert(vim.wait(2000, popup, 20), "Other-split hover failed")
  assert(vim.api.nvim_get_current_win() == window, "Hover stole focus")
end)
vim.fn.getmousepos = original_mouse
if not ok then io.stderr:write(tostring(err) .. "\n"); vim.cmd("cquit 1") end
print("PASS: gutter/text hover, insert mapping, popup stability, split focus and cursor preservation")
vim.cmd("qa!")
