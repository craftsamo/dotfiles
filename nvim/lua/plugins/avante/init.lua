return {
  {
    "yetone/avante.nvim",
    event = "VeryLazy",
    version = false,

    opts = {
      provider = "copilot",
      behaviour = {
        auto_suggestions = false,
        auto_set_highlight_group = true,
        auto_set_keymaps = true,
        auto_apply_diff_after_generation = false,
        support_paste_from_clipboard = false,
        enable_cursor_planning_mode = true,
      },

      providers = {
        copilot = {
          model = "claude-sonnet-4", -- Model to use for Copilot
          timeout = 30000,
          extra_request_body = {
            options = {
              temperature = 0,
              max_completion_tokens = 8192,
              reasoning_effort = "medium",
            },
          },
        },
        ollama = {
          endpoint = "http://localhost:11434",
          model = "starcoder2:instruct",
          timeout = 30000, -- Timeout in milliseconds
          extra_request_body = {
            options = {
              temperature = 0.75,
              num_ctx = 20480,
              keep_alive = "5m",
            },
          },
        },
      },

      rag_service = {
        enabled = true, -- Enables the RAG service
        host_mount = os.getenv("HOME"), -- Host mount path for the rag service (Docker will mount this path)
        runner = "docker", -- Runner for the RAG service (can use docker or nix)
        llm = { -- Language Model (LLM) configuration for RAG service
          provider = "ollama", -- The LLM provider ("ollama")
          endpoint = "http://localhost:11434", -- The LLM API endpoint for Ollama
          api_key = "", -- Ollama typically does not require an API key
          model = "starcoder2:instruct", -- The LLM model name (e.g., "llama2", "mistral")
          extra = nil, -- Extra configuration options for the LLM (optional) Kristin", -- Extra configuration options for the LLM (optional)
        },
        embed = { -- Embedding model configuration for RAG service
          provider = "ollama", -- The Embedding provider ("ollama")
          endpoint = "http://localhost:11434", -- The Embedding API endpoint for Ollama
          api_key = "", -- Ollama typically does not require an API key
          model = "nomic-embed-text", -- The Embedding model name (e.g., "nomic-embed-text")
          extra = { -- Extra configuration options for the Embedding model (optional)
            embed_batch_size = 10,
          },
        },
        docker_extra_args = "", -- Extra arguments to pass to the docker command
      },

      windows = {
        position = "right",
        width = 40,
        sidebar_header = {
          align = "center",
          rounded = false,
        },
        ask = {
          floating = true,
          start_insert = true,
          border = "rounded",
        },
      },
    },
    build = "make",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "stevearc/dressing.nvim",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      --- The below dependencies are optional,
      "echasnovski/mini.pick", -- for file_selector provider mini.pick
      "nvim-telescope/telescope.nvim", -- for file_selector provider telescope
      "hrsh7th/nvim-cmp", -- autocompletion for avante commands and mentions
      "ibhagwan/fzf-lua", -- for file_selector provider fzf
      "nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
      "zbirenbaum/copilot.lua", -- for providers='copilot'
    },
  },
}
