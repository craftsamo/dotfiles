local M = {}

--- Prefill the edit window with a given request and submit it immediately.
-- Opens the edit window, populates it with the request text, sets the cursor position,
-- and simulates a submission via a keypress.
--- @param request string: The text to prefill in the edit window.
M.prefill_edit_window = function(request)
  require("avante.api").edit()
  local code_bufnr = vim.api.nvim_get_current_buf()
  local code_winid = vim.api.nvim_get_current_win()
  if code_bufnr == nil or code_winid == nil then
    return
  end
  vim.api.nvim_buf_set_lines(code_bufnr, 0, -1, false, { request })
  -- Optionally set the cursor position to the end of the input
  vim.api.nvim_win_set_cursor(code_winid, { 1, #request + 1 })
  -- Simulate Ctrl+S keypress to submit
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-s>", true, true, true), "v", true)
end

--Build a keymap configuration for a given key and callback.
--Constructs a keymap entry with a specific key, callback function, description, and mode.
--- @param key string: The key to bind.
--- @param callback function|nil: The function to execute when the key is pressed.
--- @param desc string: The description of the keymap.
--- @param mode string|table: The mode in which the keymap is active (e.g., "n" for normal mode).
--- @return table: A table representing the keymap configuration.
M.build_keymap = function(key, callback, desc, mode)
  return {
    key,
    callback or "",
    desc = desc,
    mode = mode,
  }
end

return M
