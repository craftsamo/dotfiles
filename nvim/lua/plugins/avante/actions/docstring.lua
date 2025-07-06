local utils = require("plugins.avante.actions.utils")

local M = {}

--############################################################################
--                              Add Docstring
--############################################################################

local docstring_prompt = "Add docstring to the following codes."

local function add_docstring()
  utils.prefill_edit_window(docstring_prompt)
end

M.group = utils.build_keymap("<leader>aD", nil, "Docstring", "v")
M.add = utils.build_keymap("<leader>aDa", add_docstring, "Add", "v")

return M
