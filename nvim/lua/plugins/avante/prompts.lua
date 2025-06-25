-- Environment detection and system prompt creation module
local M = {}

-- Get user's language from locale information
function M.get_user_language()
  -- Language mapping table
  local language_map = {
    -- Primary language codes
    en = "english",
    ja = "japanese",
    zh = "chinese",
    ko = "korean",
    fr = "french",
    de = "german",
    es = "spanish",
    it = "italian",
    pt = "portuguese",
    ru = "russian",
    ar = "arabic",
    hi = "hindi",
    th = "thai",
    vi = "vietnamese",
    tr = "turkish",
    pl = "polish",
    nl = "dutch",
    sv = "swedish",
    da = "danish",
    no = "norwegian",
    fi = "finnish",
    el = "greek",
    he = "hebrew",
    cs = "czech",
    sk = "slovak",
    hu = "hungarian",
    ro = "romanian",
    bg = "bulgarian",
    hr = "croatian",
    sr = "serbian",
    sl = "slovenian",
    et = "estonian",
    lv = "latvian",
    lt = "lithuanian",
    uk = "ukrainian",
    be = "belarusian",
    ka = "georgian",
    hy = "armenian",
    az = "azerbaijani",
    kk = "kazakh",
    ky = "kyrgyz",
    uz = "uzbek",
    tg = "tajik",
    mn = "mongolian",
    my = "burmese",
    km = "khmer",
    lo = "lao",
    si = "sinhala",
    ta = "tamil",
    te = "telugu",
    ml = "malayalam",
    kn = "kannada",
    gu = "gujarati",
    pa = "punjabi",
    bn = "bengali",
    ["or"] = "oriya",
    ["as"] = "assamese",
    ne = "nepali",
    mr = "marathi",
    ur = "urdu",
    fa = "persian",
    ps = "pashto",
    ku = "kurdish",
    am = "amharic",
    ti = "tigrinya",
    om = "oromo",
    so = "somali",
    sw = "swahili",
    zu = "zulu",
    xh = "xhosa",
    af = "afrikaans",
    -- Extended variations
    jp = "japanese", -- Alternative Japanese code
    kr = "korean", -- Alternative Korean code
    cn = "chinese", -- Alternative Chinese code
  }

  -- Function to extract language code from locale string
  local function extract_language_code(locale_str)
    if not locale_str or locale_str == "" then
      return nil
    end

    -- Extract language code (before underscore or dot)
    local lang_code = string.match(locale_str:lower(), "^([a-z]+)")
    return lang_code
  end

  -- For macOS: Check Apple system settings first (higher priority for user experience)
  if M.get_user_os() == "macos" then
    -- Check Apple Locale setting (most accurate for user preference)
    local apple_locale = vim.fn.system("defaults read -g AppleLocale 2>/dev/null")
    if vim.v.shell_error == 0 and apple_locale and apple_locale ~= "" then
      local lang_code = extract_language_code(apple_locale:gsub("\n", ""))
      if lang_code and language_map[lang_code] then
        return language_map[lang_code]
      end
    end

    -- Check Apple Languages setting (user's preferred language order)
    local apple_languages =
      vim.fn.system("defaults read -g AppleLanguages 2>/dev/null | head -n 2 | tail -n 1 | sed 's/[^a-zA-Z_-]//g'")
    if vim.v.shell_error == 0 and apple_languages and apple_languages ~= "" then
      local lang_code = extract_language_code(apple_languages:gsub("\n", ""))
      if lang_code and language_map[lang_code] then
        return language_map[lang_code]
      end
    end
  end

  -- Check environment variables for language (fallback for all systems)
  local env_vars = {
    vim.env.LANGUAGE,
    vim.env.LC_ALL,
    vim.env.LC_MESSAGES,
    vim.env.LANG,
  }

  for _, env_var in ipairs(env_vars) do
    if env_var and env_var ~= "" then
      local lang_code = extract_language_code(env_var)
      if lang_code and language_map[lang_code] then
        return language_map[lang_code]
      end
    end
  end

  -- Check for specific country codes in full locale (e.g., en_US, ja_JP)
  for _, env_var in ipairs(env_vars) do
    if env_var and env_var ~= "" then
      local country_code = string.match(env_var:lower(), "_([a-z]+)")
      if country_code then
        -- Map some common country codes to languages
        local country_to_lang = {
          us = "english",
          gb = "english",
          au = "english",
          ca = "english",
          jp = "japanese",
          cn = "chinese",
          tw = "chinese",
          hk = "chinese",
          kr = "korean",
          fr = "french",
          de = "german",
          at = "german",
          ch = "german",
          es = "spanish",
          mx = "spanish",
          ar = "spanish",
          it = "italian",
          pt = "portuguese",
          br = "portuguese",
          ru = "russian",
          ["in"] = "hindi",
          th = "thai",
          vn = "vietnamese",
          tr = "turkish",
        }
        if country_to_lang[country_code] then
          return country_to_lang[country_code]
        end
      end
    end
  end

  -- Additional check for Japanese environment using date command
  local time_output = vim.fn.system("date")
  if vim.v.shell_error == 0 and string.match(time_output, "[\227-\239]") then
    return "japanese"
  end

  -- Check if system has specific language tools installed
  local function check_command_language(cmd, pattern, language)
    local output = vim.fn.system(cmd)
    if vim.v.shell_error == 0 and string.match(output, pattern) then
      return language
    end
    return nil
  end

  -- Try some system-specific commands
  local lang_checks = {
    { "locale", "ja_", "japanese" },
    { "locale", "zh_", "chinese" },
    { "locale", "ko_", "korean" },
    { "locale", "fr_", "french" },
    { "locale", "de_", "german" },
    { "locale", "es_", "spanish" },
  }

  for _, check in ipairs(lang_checks) do
    local detected = check_command_language(check[1], check[2], check[3])
    if detected then
      return detected
    end
  end

  -- Default to English if no language indicators found
  return "english"
end

-- Get user's operating system (MacOS or Windows)
function M.get_user_os()
  -- Use vim.uv for newer Neovim versions, fallback to vim.loop for older versions
  local uv = vim.uv or vim.loop
  local os_name = uv.os_uname().sysname

  if os_name == "Darwin" then
    return "macos"
  elseif os_name == "Windows_NT" or string.match(os_name, "MINGW") or string.match(os_name, "CYGWIN") then
    return "windows"
  elseif os_name == "Linux" then
    return "linux"
  else
    return "unknown"
  end
end

-- Get IDE environment information (Neovim version, etc.)
function M.get_ide_info()
  local nvim_version = vim.version()
  local version_string = string.format("%d.%d.%d", nvim_version.major, nvim_version.minor, nvim_version.patch)

  -- Get additional Neovim build information
  local has_info, build_info = pcall(vim.fn.execute, "version")
  local build_type = "release"
  local build_date = "unknown"

  if has_info and build_info then
    -- Extract build information if available
    local build_line = string.match(build_info, "Compiled by.*")
    if build_line then
      if string.match(build_line, "dev") or string.match(build_line, "nightly") then
        build_type = "development"
      end
    end

    local date_line = string.match(build_info, "Compiled on (%S+ %S+ %S+ %S+)")
    if date_line then
      build_date = date_line
    end
  end

  return {
    name = "neovim",
    version = version_string,
    build_type = build_type,
    build_date = build_date,
    lua_version = _VERSION or "unknown",
    has_gui = vim.fn.has("gui_running") == 1,
    terminal = vim.env.TERM or "unknown",
  }
end

-- Get comprehensive environment information
function M.get_environment_info()
  return {
    language = M.get_user_language(),
    os = M.get_user_os(),
    ide = M.get_ide_info(),
  }
end

-- Create environment context extension for system prompt
-- ----------------------------------------------------------
--
-- =====
-- SYSTEM INFORMATION
-- - Platform: macOS
-- - Language: English
-- - Editor: Neovim v0.11.0
-- =====
-- Respond in English when appropriate. Use macOS-specific paths and commands when relevant.
--
-- ----------------------------------------------------------

function M.create_system_prompt(custom_prompt)
  local env_info = M.get_environment_info()

  -- Format language name with proper capitalization
  local function format_language_name(lang)
    local language_names = {
      japanese = "Japanese",
      chinese = "Chinese",
      korean = "Korean",
      french = "French",
      german = "German",
      spanish = "Spanish",
      italian = "Italian",
      portuguese = "Portuguese",
      russian = "Russian",
      english = "English",
      arabic = "Arabic",
      hindi = "Hindi",
      thai = "Thai",
      vietnamese = "Vietnamese",
      turkish = "Turkish",
      polish = "Polish",
      dutch = "Dutch",
      swedish = "Swedish",
      danish = "Danish",
      norwegian = "Norwegian",
      finnish = "Finnish",
      greek = "Greek",
      hebrew = "Hebrew",
    }
    return language_names[lang] or lang:gsub("^%l", string.upper)
  end

  -- Format OS name with proper capitalization
  local function format_os_name(os)
    local os_names = {
      macos = "macOS",
      windows = "Windows",
      linux = "Linux",
      unknown = "Unknown OS",
    }
    return os_names[os] or os:gsub("^%l", string.upper)
  end

  -- Create language preference
  local language_preference = ""
  if env_info.language ~= "english" then
    language_preference = string.format(" Respond in %s when appropriate.", format_language_name(env_info.language))
  end

  -- Create OS context
  local os_context = ""
  if env_info.os == "macos" then
    os_context = " Use macOS-specific paths and commands when relevant."
  elseif env_info.os == "windows" then
    os_context = " Use Windows-specific paths and commands when relevant."
  elseif env_info.os == "linux" then
    os_context = " Use Linux-specific paths and commands when relevant."
  end

  -- Create environment context extension
  local environment_context = string.format(
    "\n\n====\n\nSYSTEM INFORMATION\n\n- Platform: %s\n- Language: %s\n- Editor: Neovim v%s\n\n====\n\n%s%s",
    format_os_name(env_info.os),
    format_language_name(env_info.language),
    env_info.ide.version,
    language_preference,
    os_context
  )

  -- If custom_prompt is provided, append environment context to it
  if custom_prompt and custom_prompt ~= "" then
    return custom_prompt .. environment_context
  else
    -- Return only environment context if no custom prompt provided
    return environment_context:sub(3) -- Remove leading newlines
  end
end

-- Print environment information for debugging
function M.print_environment_info()
  local env_info = M.get_environment_info()

  print("=== Environment Information ===")
  print("Language: " .. env_info.language)
  print("Operating System: " .. env_info.os)
  print("IDE: " .. env_info.ide.name .. " v" .. env_info.ide.version)
  print("Build Type: " .. env_info.ide.build_type)
  print("Build Date: " .. env_info.ide.build_date)
  print("Lua Version: " .. env_info.ide.lua_version)
  print("Has GUI: " .. tostring(env_info.ide.has_gui))
  print("Terminal: " .. env_info.ide.terminal)
  print("===============================")
end

return M
