local utils = require("plugins.avante.actions.utils")

local M = {}

local translate_prompt =
  'Translate the text in the currently selected range into "{{language}}" with a "{{tone}}" tone.'

local function translate()
  local language = utils.select_language()
  if not language or language == "" then
    return
  end

  local tone = utils.select_tone() or "same as the translation source"

  local prompt = utils.interpolate(translate_prompt, {
    language = language,
    tone = tone,
  })

  utils.prefill_edit_window(prompt)
end

M.execute = utils.build_keymap("<leader>aT", translate, "Translate", "v")

return M
