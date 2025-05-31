local window_utils = require("plugins.copilotchat.utils.window")
local chat_history = require("plugins.copilotchat.utils.chat_history")
local actions = {
  explain = require("plugins.copilotchat.actions.explain"),
  refactoring = require("plugins.copilotchat.actions.refactoring"),
  review = require("plugins.copilotchat.actions.review"),
  fix = require("plugins.copilotchat.actions.fix"),
  document = require("plugins.copilotchat.actions.document"),
  analyze = require("plugins.copilotchat.actions.analyze"),
  optimize = require("plugins.copilotchat.actions.optimize"),
  generate = require("plugins.copilotchat.actions.generate"),
  chat = require("plugins.copilotchat.actions.chat"),
  commit = require("plugins.copilotchat.actions.commit"),
  translate = require("plugins.copilotchat.actions.translate"),
  output_template = require("plugins.copilotchat.actions.utils.output_template"),
}

local M = {}

M.set_copilotchat_keymaps = function()
  vim.keymap.set({ "n", "v" }, "<leader>at", "", { desc = "CopilotChat - Toggle window" })
  vim.keymap.set({ "n", "v" }, "<leader>atv", window_utils.toggle_vertical, { desc = "CopilotChat - Vertical" })
  vim.keymap.set({ "n", "v" }, "<leader>atf", window_utils.toggle_float, { desc = "CopilotChat - Float" })
  vim.keymap.set({ "n", "v" }, "<leader>ax", window_utils.clear, { desc = "CopilotChat - Clear" })
  vim.keymap.set({ "n", "v" }, "<leader>ah", chat_history.list, { desc = "CopilotChat - List chat history" })
  vim.keymap.set({ "n", "v" }, "<leader>ae", actions.explain.execute, { desc = "CopilotChat - Explain" })
  vim.keymap.set({ "n", "v" }, "<leader>ar", actions.refactoring.execute, { desc = "CopilotChat - Refactoring" })
  vim.keymap.set({ "n", "v" }, "<leader>aR", actions.review.execute, { desc = "CopilotChat - Review" })
  vim.keymap.set({ "n", "v" }, "<leader>af", actions.fix.execute, { desc = "CopilotChat - Fix" })
  vim.keymap.set({ "n", "v" }, "<leader>ad", actions.document.execute, { desc = "CopilotChat - Document" })
  vim.keymap.set({ "n", "v" }, "<leader>aa", actions.analyze.execute, { desc = "CopilotChat - Analyze" })
  vim.keymap.set({ "n", "v" }, "<leader>ao", actions.optimize.execute, { desc = "CopilotChat - Optimize" })
  vim.keymap.set({ "n", "v" }, "<leader>ag", actions.generate.execute, { desc = "CopilotChat - Generate" })
  vim.keymap.set({ "n", "v" }, "<leader>aC", actions.chat.open, { desc = "CopilotChat - Open chat" })
  vim.keymap.set({ "n", "v" }, "<leader>ac", actions.commit.execute, { desc = "CopilotChat - Commit" })
  vim.keymap.set({ "n", "v" }, "<leader>au", "", { desc = "CopilotChat - Utils" })
  vim.keymap.set({ "n", "v" }, "<leader>aT", actions.translate.execute, { desc = "CopilotChat - Translate" })
  vim.keymap.set({ "n", "v" }, "<leader>auo", actions.output_template, { desc = "CopilotChat - Output template" })

  vim.keymap.set({ "n", "v" }, "<leader>aS", function()
    M.remove_copilotchat_keymaps()
    require("plugins.avante.keymaps").set_avante_keymaps()
  end, { desc = "Switch Avante" })
end

M.remove_copilotchat_keymaps = function()
  pcall(vim.keymap.del, { "n", "v" }, "<leader>at")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>atv")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>atf")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ax")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ah")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ae")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ar")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>aR")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>af")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ad")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>aa")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ao")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ag")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>aC")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ac")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>au")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>aT")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>auo")

  -- default
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ap")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>aq")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>ax")
end

M.keymaps = {
  vim.api.nvim_create_user_command("SetCopilotChatKeymaps", M.set_copilotchat_keymaps, {}),
  vim.api.nvim_create_user_command("RemoveCopilotChatKeymaps", M.remove_copilotchat_keymaps, {}),
}

M.set_copilotchat_keymaps()

return M
