local utils = require("plugins.avante.actions.utils")

local M = {}

local docstring_prompt = "Add docstring to the following codes."

local function docstring()
  utils.prefill_edit_window(docstring_prompt)
end

M.add = utils.build_keymap("<leader>aD", docstring, "Docstring", "v")

return M
