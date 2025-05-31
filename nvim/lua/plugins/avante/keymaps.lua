local avante = require("avante")
local avante_api = require("avante.api")

local M = {}

M.set_avante_keymaps = function()
  -- Toggle
  vim.keymap.set("n", "<leader>at", "", { desc = "Avante - Toggle" })

  ---- Window
  vim.keymap.set("n", "<leader>atw", function()
    avante.toggle()
  end, { desc = "Avante - Window" })

  ---- Debug
  vim.keymap.set("n", "<leader>atd", function()
    avante.toggle.debug()
  end, { desc = "Avante - Debug" })

  ----  Hint
  vim.keymap.set("n", "<leader>ath", function()
    avante.toggle.hint()
  end, { desc = "Avante - Hint" })

  ---- Suggestion
  vim.keymap.set("n", "<leader>ats", function()
    avante.toggle.suggestion()
  end, { desc = "Avante - Suggestion" })

  -- Chat
  vim.keymap.set("n", "<leader>ac", "", { desc = "Avante - Chat" })
  vim.keymap.set({ "n", "v" }, "<leader>acc", avante_api.ask, { desc = "Avante - Chat" })
  vim.keymap.set({ "n", "v" }, "<leader>acn", function()
    avante_api.ask({ new_chat = true })
  end, { desc = "Avante - New Chat" })

  -- Edit
  vim.keymap.set("v", "<leader>ae", avante_api.edit, { desc = "Avante - Edit" })

  -- Stop
  vim.keymap.set("n", "<leader>as", avante_api.stop, { desc = "Avante - Stop" })

  -- Refresh
  vim.keymap.set("n", "<leader>ar", function()
    avante_api.refresh()
  end, { desc = "Avante - Refresh" })

  -- Focus
  vim.keymap.set("n", "<leader>af", avante_api.focus, { desc = "Avante - Focus Window" })

  -- Display repo map
  vim.keymap.set("n", "<leader>aR", require("avante.repo_map").show, { desc = "Avante - Display Repo Map" })

  -- Chat History
  vim.keymap.set("n", "<leader>ah", avante_api.select_history, { desc = "Avante - Chat History" })

  -- Add all buffers
  vim.keymap.set("n", "<leader>ab", avante_api.add_buffer_files, { desc = "Avante - All Buffers" })

  -- Switch to CopilotChat
  vim.keymap.set("n", "<leader>aS", function()
    M.remove_avante_keymaps()
    require("plugins.copilotchat.keymaps").set_copilotchat_keymaps()
  end, { desc = "Switch CopilotChat" })
end

M.remove_avante_keymaps = function()
  pcall(vim.keymap.del, "n", "<leader>at")
  pcall(vim.keymap.del, "n", "<leader>atw")
  pcall(vim.keymap.del, "n", "<leader>atd")
  pcall(vim.keymap.del, "n", "<leader>ath")
  pcall(vim.keymap.del, "n", "<leader>ats")
  pcall(vim.keymap.del, "n", "<leader>ac")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>acc")
  pcall(vim.keymap.del, { "n", "v" }, "<leader>acn")
  pcall(vim.keymap.del, "v", "<leader>ae")
  pcall(vim.keymap.del, "n", "<leader>as")
  pcall(vim.keymap.del, "n", "<leader>ar")
  pcall(vim.keymap.del, "n", "<leader>af")
  pcall(vim.keymap.del, "n", "<leader>aR")
  pcall(vim.keymap.del, "n", "<leader>ah")
  pcall(vim.keymap.del, "n", "<leader>ab")
end

M.keymaps = {
  vim.api.nvim_create_user_command("SetAvanteKeymaps", M.set_avante_keymaps, {}),
  vim.api.nvim_create_user_command("RemoveAvanteKeymaps", M.remove_avante_keymaps, {}),
}

return M
