return {
  {
    "pwntester/octo.nvim",
    opts = function(_, opts)
      opts.enable_builtin = true
      opts.default_to_projects_v2 = true
      opts.default_merge_method = "squash"
      opts.picker = "fzf-lua"

      if LazyVim.has("fzf-lua") then
        opts.picker = "fzf-lua"
      elseif LazyVim.has("telescope.nvim") then
        opts.picker = "telescope"
      else
        LazyVim.error("`octo.nvim` requires `telescope.nvim` or `fzf-lua`")
      end

      -- Keep some empty windows in sessions
      vim.api.nvim_create_autocmd("ExitPre", {
        group = vim.api.nvim_create_augroup("octo_exit_pre", { clear = true }),
        callback = function(ev)
          local keep = { "octo" }
          for _, win in ipairs(vim.api.nvim_list_wins()) do
            local buf = vim.api.nvim_win_get_buf(win)
            if vim.tbl_contains(keep, vim.bo[buf].filetype) then
              vim.bo[buf].buftype = "" -- set buftype to empty to keep the window
            end
          end
        end,
      })
    end,
  },
}
