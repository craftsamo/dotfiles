---@alias ChatHistoryTag "NewChat"|"Commit"|"Instruction"|"Generate"|"Explain"|"Review"|"Analyze"|"Refactor"|"Fix"|"FixBug"|"Translate"|"Write"|"ReviewCode"|"ReviewSpelling"|"Comment"|"CodeDoc"|"APIDoc"|"DevDoc"|"FixIssues"|"OptimizeCode"|"OptimizeText"

---@class ChatHistoryOpts
---@field used_prompt nil|string
---@field tag ChatHistoryTag

local M = {}

local chat = require("CopilotChat")
local scandir = require("plenary.scandir")
local system_languages = require("plugins.copilotchat.utils.system_languages")
local CHAT_HISTORY_DIR = vim.fn.stdpath("data") .. "/copilotchat_history"

---@param days number|string|nil
M.delete = function(days)
  local files = scandir.scan_dir(CHAT_HISTORY_DIR, {
    search_pattern = "%.json$",
    depth = 1,
  })

  local days_num = tonumber(days)
  if not days_num or days_num < 1 or days_num > 30 then
    days_num = 1
  end

  local current_time = os.time()
  local threshold = current_time - (days_num * 24 * 60 * 60)
  local deleted_count = 0

  for _, file in ipairs(files) do
    local mtime = vim.fn.getftime(file)

    if mtime < threshold then
      local success, err = os.remove(file)
      if success then
        deleted_count = deleted_count + 1
      else
        vim.notify("Failed to delete old chat file: " .. err, vim.log.levels.WARN)
      end
    end
  end

  if deleted_count > 0 then
    vim.notify(
      "Deleted " .. deleted_count .. " old chat files (older than " .. days_num .. " days)",
      vim.log.levels.INFO
    )
  end
end

---@param encoded_title string
---@return string|nil
local function decode_title(encoded_title)
  -- Extract the timestamp part (before first underscore)
  local timestamp, encoded = encoded_title:match("^(%d%d%d%d%d%d%d%d_%d%d%d%d%d%d)_(.+)$")

  -- Restore base64 padding characters
  local padding_len = 4 - (#encoded % 4)
  if padding_len < 4 then
    encoded = encoded .. string.rep("=", padding_len)
  end

  -- Restore original base64 characters
  encoded = encoded:gsub("_", "/"):gsub("-", "+")

  -- Decode and return with timestamp if successful
  local success, decoded = pcall(vim.base64.decode, encoded)
  if success and timestamp then
    local ts_num
    if timestamp then
      local y, m, d, H, M, S = timestamp:match("^(%d%d%d%d)(%d%d)(%d%d)_(%d%d)(%d%d)(%d%d)$")
      if y and m and d and H and M and S then
        ts_num = os.time({
          year = tonumber(y),
          month = tonumber(m),
          day = tonumber(d),
          hour = tonumber(H),
          min = tonumber(M),
          sec = tonumber(S),
        })
      end
    end
    if ts_num then
      local columns = vim.o.columns
      local weekday = os.date("%a", ts_num)
      local day = os.date("%d", ts_num)
      local time = os.date("%H:%M", ts_num)
      if columns <= 150 then
        return string.format("%s", decoded:gsub("-", " "))
      else
        return string.format("%s %s %s  %s", weekday, day, time, decoded:gsub("-", " "))
      end
    end
  else
    return encoded_title -- Fallback to encoded if decoding fails
  end
  return nil
end

---@param timestamp number
---@return string|osdate
local function fmt_relative_time(timestamp)
  -- Get current timestamp for relative time calculations
  local now = os.time()
  local diff = now - timestamp

  if diff < 60 then
    return "Now"
  elseif diff < 3600 then
    local mins = math.floor(diff / 60)
    return string.format("%02d min%s", mins, mins == 1 and "" or "s")
  elseif diff < 86400 then
    local hours = math.floor(diff / 3600)
    return string.format("%02d hour%s", hours, hours == 1 and "" or "s")
  elseif diff < 2592000 then
    local days = math.floor(diff / 86400)
    return string.format("%02d day%s", days, days == 1 and "" or "s")
  elseif diff < 31536000 then
    local months = math.floor(diff / 2592000)
    return string.format("%02d month%s", months, months == 1 and "" or "s")
  else
    return os.date("%Y-%m-%d", timestamp)
  end
end

M.list = function()
  local snacks = require("snacks")

  -- Delete old chat files first
  M.delete()

  local files = scandir.scan_dir(CHAT_HISTORY_DIR, {
    search_pattern = "%.json$",
    depth = 1,
  })

  if #files == 0 then
    vim.notify("No chat history found", vim.log.levels.INFO)
    return
  end

  local items = {}
  for i, item in ipairs(files) do
    -- Extract basename from file's full path without extension
    local filename = item:match("^.+[/\\](.+)$") or item
    local basename = filename:match("^(.+)%.[^%.]*$") or filename

    table.insert(items, {
      idx = i,
      file = item,
      basename = basename,
      text = decode_title(basename),
    })
  end

  table.sort(items, function(a, b)
    return a.file > b.file
  end)

  -- Check if we have any valid items
  if #items == 0 then
    vim.notify("No valid chat history files found", vim.log.levels.INFO)
    return
  end

  snacks.picker({
    actions = {
      delete_history_file = function(picker, item)
        if not item or not item.file then
          vim.notify("No file selected", vim.log.levels.WARN)
          return
        end

        -- Confirm deletion
        vim.ui.select(
          { "Yes", "No" },
          { prompt = "Delete " .. vim.fn.fnamemodify(item.file, ":t") .. "?" },
          function(choice)
            if choice == "Yes" then
              -- Delete the file
              local success, err = os.remove(item.file)
              if success then
                vim.notify("Deleted: " .. item.file, vim.log.levels.INFO)
                -- Refresh the picker to show updated list
                picker:close()
                vim.schedule(function()
                  M.list()
                end)
              else
                vim.notify("Failed to delete: " .. (err or "unknown error"), vim.log.levels.ERROR)
              end
            end
          end
        )
      end,
    },
    confirm = function(picker, item)
      picker:close()

      -- Verify file exists before loading
      if not vim.fn.filereadable(item.file) then
        vim.notify("Chat history file not found: " .. item.file, vim.log.levels.ERROR)
        return
      end

      vim.g.copilot_chat_title = item.basename
      vim.cmd("only")

      chat.open()
      vim.schedule(function()
        vim.g.copilot_chat_title = item.basename
        chat.load(item.basename)
      end)
    end,
    items = items,
    format = function(item)
      local formatted_title = decode_title(item.basename)
      local display = " " .. formatted_title

      local mtime = vim.fn.getftime(item.file)
      local date = fmt_relative_time(mtime)

      return {
        { string.format("%-8s", date), "SnacksPickerLabel" },
        { display },
      }
    end,
    preview = function(ctx)
      local file = io.open(ctx.item.file, "r")
      if not file then
        ctx.preview:set_lines({ "Unable to read file" })
        return
      end

      local content = file:read("*a")
      file:close()

      local ok, messages = pcall(vim.json.decode, content, {
        luanil = {
          object = true,
          array = true,
        },
      })

      if not ok then
        ctx.preview:set_lines({ "vim.fn.json_decode error" })
        return
      end

      local config = chat.config
      local preview = {}
      for _, message in ipairs(messages or {}) do
        local header = message.role == "user" and config.question_header or config.answer_header
        table.insert(preview, header .. config.separator .. "\n")
        table.insert(preview, message.content .. "\n")
      end

      ctx.preview:highlight({ ft = "copilot-chat" })
      ctx.preview:set_lines(preview)
    end,
    sort = {
      fields = { "text:desc" },
    },
    title = "Copilot Chat History",
    win = {
      input = {
        keys = {
          ["dd"] = "delete_history_file", -- Use our custom action
        },
      },
    },
  })
end

local title_prompt = [[
Generate a concise title in %s that accurately describes what the AI is doing with the given prompt or request.

Requirements:
- Focus on the relationship between the prompt and response (what was the AI asked to do?)
- If the prompt describes code or functionality, focus on that functionality rather than the conversation itself
- Keep the entire title within 10 words including the verb
- Use natural, descriptive language instead of keyword lists
- Use hyphens to join words in the title
- Do not include special characters other than hyphens
- Output only the title without any explanations or formatting

Prompt (what the user asked):
```
%s
```

Response (what the AI provided):
```
%s
```
]]

---@param response string
---@param opts ChatHistoryOpts|nil
M.save = function(response, opts)
  if response == nil or response == "" then
    vim.notify("Could not save because of no response.", vim.log.levels.WARN)
    return
  end

  if vim.g.copilot_chat_title then
    vim.schedule(function()
      chat.save(vim.g.copilot_chat_title)
    end)
  else
    if opts == nil then
      opts = { used_prompt = "", tag = "NewChat" }
    end

    -- Use AI to generate prompt title based on first AI response to user question
    chat.ask(vim.trim(title_prompt:format(system_languages.default, opts.used_prompt, response)), {
      model = "gpt-4.1",
      callback = function(gen_response)
        -- Generate timestamp in format YYYYMMDD_HHMMSS
        local timestamp = os.date("%Y%m%d_%H%M%S")
        -- Encode the generated title to make it safe as a filename
        local title = opts.tag .. ": " .. gen_response
        local safe_title = vim.base64.encode(title):gsub("/", "_"):gsub("+", "-"):gsub("=", "")
        vim.g.copilot_chat_title = timestamp .. "_" .. vim.trim(safe_title)
        chat.save(vim.g.copilot_chat_title)
        return gen_response
      end,
      headless = true, -- Disable updating chat buffer and history with this question
    })
  end
end

return M
