# Dotfiles

**Contents**:

- [alacritty](./alacritty/README.md)
- [assets](#assets)
- [bashrc](#bashrc)
- [BetterTouchTool](#Bettertouchtool)
- [brew](./brew/README.md)
- [btop](#btop)
- [colorscheme](#colorscheme)
- [dictionaries](#dictionaries)
- [eligere](#eligere)
- [emacs](#emacs)
- [fastfetch](fastfetch/README.md)
- [ghostty](#ghostty)
- [hammerspoon](#hammerspoon)
- [hidapitester](#hidapitester)
- [karabiner](karabiner/README.md)
- [kitty](kitty/README.md)
- [lazygit](lazygit/README.md)
- [mouseless](#mouseless)
- [neovide](#neovide)
- [nvim](nvim/README.md)
- [obs](#obs)
- [obsidian_main](#obsidian_main)
- [rio](#rio)
- [scripts](#scripts)
- [sesh](#sesh)
- [sketchybar](#sketchybar)
- [starship-config](sarship-config/README.md)
- [steermouse](#steermouse)
- [tmux](tmux/README.md)
- [ubersicht](#ubersicht)
- [vimrc](#vimrc)
- [vivaldi](#vivaldi)
- [vscode](#vscode)
- [wezterm](#wezterm)
- [windows](windows/README.md)
- [yabai](yabai/README.md)
- [yazi](#yazi)
- [zshrc](zshrc/readme.md)

## assets

## bashrc

### Overview

The `bashrc-file.sh` script is a comprehensive shell configuration file designed
for use on Darwin (macOS) systems. It provides a modular, maintainable approach
to managing environment variables, command aliases, and tool integrations for a
developer-centric workflow. The script is intended to be sourced from the user's
main Bash configuration (e.g., `~/.bashrc` or `~/.bash_profile`) and is
structured to support extensibility and portability.

### Architectural Context

- **Location**: `~/.config/bashrc/bashrc-file.sh`
- **Integration**: Typically sourced from the main shell startup file to apply
  user-specific configurations.
- **Related Modules**:
  - `~/.config/colorscheme/colorscheme-vars.sh`: Provides color variables for
    prompt and output customization.
  - `~/.fzf.bash`: Enables fuzzy finder features if installed.
  - `~/.bash_history`: Stores shell command history.

### Design Patterns and Key Decisions

- **Idempotency**: The script checks for the existence of files and commands
  before modifying environment variables or defining aliases, ensuring safe
  repeated sourcing.
- **Conditional Configuration**: Uses `uname -s` to detect the operating system
  and applies macOS-specific settings only when appropriate.
- **Extensibility**: Organized into logical sections (e.g., Homebrew, Nodebrew,
  Docker, Kubernetes, Go, Java, ANTLR, Starship, eza, bat, zoxide, fzf) to
  facilitate easy updates and additions.
- **Backup Safety**: Includes a `UNIQUE_ID` marker to assist with automated
  backup and symlink management workflows.
- **Security**: Sets restrictive permissions on the history file to protect
  sensitive command history.

### Implementation Details

- **Environment Variables**:

  - Sets up `HOMEBREW_PREFIX`, `HOMEBREW_CELLAR`, and updates `PATH` for
    Homebrew and user binaries.
  - Configures `JAVA_HOME` and updates `PATH` for Java development.
  - Sets `CLASSPATH` for ANTLR integration.
  - Adds PostgreSQL client tools to `PATH` and sets `LDFLAGS`/`CPPFLAGS` for
    compilation.
  - Appends additional tool paths (e.g., LM Studio CLI, templ, Docker,
    Nodebrew).

- **Aliases**:

  - Provides common shortcuts (`ll`, `lla`, `python`, `history`, `v` for
    Neovim).
  - Defines Kubernetes command aliases for efficient cluster management.
  - Adds Go coverage and testing helpers.
  - Replaces standard utilities with enhanced alternatives if available (e.g.,
    `eza` for `ls`, `bat` for `cat`).
  - Integrates zoxide for smarter directory navigation.

- **Tool Integrations**:

  - **Starship**: Initializes the Starship prompt if installed, using a custom
    configuration.
  - **fzf**: Sources fzf configuration and customizes preview and completion
    triggers.
  - **zoxide**: Initializes zoxide for advanced directory jumping.
  - **ANTLR**: Sets up aliases for ANTLR tool and TestRig.

- **History Management**:
  - Configures Bash history to store up to 10,000 entries.
  - Ensures the history file exists and is secured with `chmod 600`.

### Usage

1. **Installation**:

   - Place `bashrc-file.sh` in `~/.config/bashrc/`.
   - Source it from your main Bash configuration:
     ```sh
     source ~/.config/bashrc/bashrc-file.sh
     ```

2. **Customization**:

   - Modify environment variables or aliases as needed for your workflow.
   - Add new tool integrations in the appropriate section.

3. **Extending**:
   - To add new aliases or environment variables, follow the existing section
     structure.
   - For new tool integrations, use conditional checks
     (`command -v <tool> &>/dev/null`) to ensure safe initialization.

### Related Files and Components

- `~/.config/colorscheme/colorscheme-vars.sh`: Defines color variables used in
  prompts and scripts.
- `~/.fzf.bash`: Enables fzf features if installed via Homebrew.
- `~/.bash_history`: Stores shell command history with secure permissions.
- `~/.config/starship-config/starship.toml`: Custom Starship prompt
  configuration.

### Best Practices

- Regularly back up your configuration files, leveraging the `UNIQUE_ID` marker
  for automated scripts.
- Use conditional checks for tool availability to maintain portability across
  environments.
- Keep sensitive data out of configuration files and ensure proper file
  permissions.

### References

- [Homebrew](https://brew.sh/)
- [Nodebrew](https://github.com/hokaccha/nodebrew)
- [Docker](https://www.docker.com/)
- [Kubernetes CLI (kubectl)](https://kubernetes.io/docs/reference/kubectl/)
- [Go](https://golang.org/)
- [Starship Prompt](https://starship.rs/)
- [eza (ls replacement)](https://github.com/eza-community/eza)
- [bat (cat replacement)](https://github.com/sharkdp/bat)
- [zoxide (directory jumper)](https://github.com/ajeetdsouza/zoxide)
- [fzf (fuzzy finder)](https://github.com/junegunn/fzf)
- [ANTLR](https://www.antlr.org/)

## BetterTouchTool

### Design Intent

The integration with BetterTouchTool (BTT) is designed to enhance user
productivity by enabling custom gesture and automation support within the
application environment. BTT is a popular macOS utility that allows users to
configure advanced input gestures, keyboard shortcuts, and automation workflows.
By leveraging BTT, the project aims to provide seamless interaction between the
application and macOS input events, enabling users to trigger
application-specific actions using gestures or shortcuts.

### Implementation Details

- **Integration Approach**: The application communicates with BTT using
  AppleScript, shell scripts, or the BTT Web Server API. This allows for sending
  commands, receiving events, or triggering application logic in response to
  user-defined gestures.
- **Configuration**: Users can define custom triggers in BTT (such as trackpad
  gestures, keyboard shortcuts, or Touch Bar buttons) that execute scripts or
  send HTTP requests to the application.
- **Event Handling**: The application listens for incoming events from BTT and
  maps them to internal commands or workflows. This may involve running scripts,
  invoking application APIs, or updating the UI.
- **Security Considerations**: Communication with BTT is secured using local
  network permissions and, if using the Web Server API, authentication tokens.

### Architectural Context

- **Related Modules**: Integration scripts or modules are typically located in a
  `scripts/`, `automation/`, or `integration/` directory. These scripts handle
  the interface between BTT and the application.
- **Dependencies**: Requires BetterTouchTool to be installed and configured on
  the user's macOS system. If using the Web Server API, the BTT web server must
  be enabled.
- **Extensibility**: The integration is designed to be extensible, allowing
  developers to add new gesture mappings or automation workflows by updating
  configuration files or scripts.

### Key Decisions

- **Loose Coupling**: The integration is kept loosely coupled to avoid
  introducing direct dependencies on BTT within the core application logic. This
  ensures maintainability and allows the application to function independently
  of BTT.
- **User Customization**: Emphasis is placed on user configurability, enabling
  users to tailor gesture and shortcut mappings to their workflow.
- **Platform Specificity**: The integration targets macOS exclusively,
  leveraging BTT's capabilities on this platform.

### Usage

1. **Install BetterTouchTool**: Download and install BTT from
   [https://folivora.ai/](https://folivora.ai/).
2. **Enable BTT Web Server (Optional)**: For advanced integrations, enable the
   BTT web server in BTT preferences.
3. **Configure Triggers**: In BTT, create new triggers (gestures, shortcuts,
   etc.) and set their actions to execute scripts or send HTTP requests to the
   application.
4. **Update Application Scripts**: If necessary, modify or extend the
   integration scripts to handle new triggers or workflows.
5. **Test Integration**: Perform the configured gestures or shortcuts and verify
   that the application responds as expected.

### References

- [BetterTouchTool Documentation](https://docs.folivora.ai/)
- Related integration scripts: See the `scripts/` or `automation/` directory in
  the project repository.
- Example configuration files: Refer to `btt-example.json` or similar files for
  sample BTT trigger setups.

## btop

### Design Intent

The `btop.conf` file is the primary configuration file for
[btop](https://github.com/aristocratos/btop), a resource monitor supporting
multiple platforms, including Darwin (macOS). The intent of this configuration
is to provide a highly customizable, user-friendly, and visually appealing
monitoring experience. It enables developers and power users to tailor the
interface, behavior, and data presentation of btop to their specific workflow
and system requirements.

Key goals include:

- **Customizability**: Allow users to adjust themes, layout, update intervals,
  and data representation.
- **Portability**: Ensure settings are compatible across different systems and
  environments.
- **Accessibility**: Support for TTY mode, keyboard navigation (including
  Vim-style keys), and font compatibility.
- **Performance**: Enable efficient monitoring with adjustable update rates and
  resource usage controls.

### Implementation Details

#### Configuration Structure

- **Theme and Appearance**:

  - `color_theme`: Specifies the theme file for UI colors and styles.
  - `theme_background`, `truecolor`, `rounded_corners`: Control background
    rendering, color depth, and box styling.
  - `graph_symbol`, `graph_symbol_cpu`, etc.: Define the symbols used for
    graphs, supporting "braille", "block", and "tty" for compatibility and
    aesthetics.

- **Layout and Presets**:

  - `presets`: Allows definition of multiple box layouts, enabling quick
    switching between different monitoring views.
  - `shown_boxes`: Selects which resource boxes (CPU, memory, network,
    processes, GPU) are displayed.

- **Input and Navigation**:

  - `vim_keys`: Enables Vim-style navigation for efficient keyboard control.
  - `proc_left`: Option to display the process box on the left side.

- **Resource Monitoring**:

  - `update_ms`: Sets the refresh interval for data sampling.
  - `proc_sorting`, `proc_tree`, `proc_colors`, etc.: Configure process list
    sorting, display, and colorization.
  - `cpu_graph_upper`, `cpu_graph_lower`: Select which CPU statistics are
    visualized.
  - `check_temp`, `cpu_sensor`, `show_coretemp`: Enable and configure CPU
    temperature monitoring.
  - `show_cpu_freq`, `show_uptime`: Toggle display of CPU frequency and system
    uptime.

- **Memory and Disk**:

  - `mem_graphs`, `show_disks`, `only_physical`, `use_fstab`: Control memory and
    disk information display, including ZFS support.
  - `show_swap`, `swap_disk`: Manage swap memory visibility and representation.

- **Network**:

  - `net_download`, `net_upload`, `net_auto`, `net_sync`: Configure network
    graph scaling and interface selection.

- **Battery and Power**:

  - `show_battery`, `selected_battery`, `show_battery_watts`: Display battery
    status and power consumption if available.

- **Logging and Debugging**:
  - `log_level`: Sets the verbosity of btop's log output for troubleshooting.

#### Key Decisions and Patterns

- **Modular Configuration**: Each setting is independently configurable,
  allowing granular control without requiring changes to unrelated options.
- **Conditional Features**: Many options are platform-aware (e.g., TTY mode,
  Linux-specific process filtering) to maximize portability.
- **User Experience**: Defaults are chosen for clarity and usability, but
  advanced users can override nearly every aspect of the UI and data handling.
- **Extensibility**: The configuration supports custom themes, layouts, and
  future expansion (e.g., additional resource boxes or sensors).

### Architectural Context

- **Location**: Typically found at `$HOME/.config/btop/btop.conf` for
  user-specific settings.
- **Related Modules**:
  - Theme files: `$HOME/.config/btop/themes/` or `../share/btop/themes/`
  - Log file: `$HOME/.config/btop/btop.log`
  - Executable: `btop` binary, which reads this configuration at startup.
- **Integration**: The configuration is loaded automatically by btop. Changes
  take effect on restart or via btop's in-app reload feature.

### Usage

1. **Editing Configuration**:

   - Open `btop.conf` in a text editor (e.g., Neovim).
   - Adjust settings as needed, following the inline comments for guidance.
   - Save changes and restart btop to apply.

2. **Customizing Appearance**:

   - Place custom theme files in the themes directory and set `color_theme`
     accordingly.
   - Toggle `truecolor` and `rounded_corners` for optimal appearance in your
     terminal.

3. **Optimizing Performance**:

   - Increase `update_ms` for lower CPU usage.
   - Disable unused boxes or features to streamline the UI.

4. **Advanced Features**:
   - Use `presets` to define and switch between multiple layouts.
   - Enable `vim_keys` for efficient navigation.
   - Configure disk and network filters for focused monitoring.

### References

- [btop GitHub Repository](https://github.com/aristocratos/btop)
- [btop Themes](https://github.com/aristocratos/btop#themes)
- [btop Wiki](https://github.com/aristocratos/btop/wiki)
- Related files: `btop-theme.theme` (theme), `btop.log` (log output), theme
  directory for additional styles

## colorscheme

### Design Intent

The `colorscheme-selector.sh` script provides an interactive, user-friendly
mechanism for selecting and applying terminal and editor color schemes on Darwin
(macOS) systems. Its primary goal is to streamline the process of switching
between different color themes by leveraging the fuzzy finder tool `fzf`. This
approach enhances developer productivity by allowing quick theme changes without
manual file edits or restarts.

Key objectives include:

- **Modularity**: Decouple color scheme definitions from the selection logic,
  enabling easy addition or removal of themes.
- **Portability**: Ensure compatibility with standard Unix tools and Darwin
  environments.
- **Extensibility**: Facilitate integration with other shell environments or
  configuration management workflows.

### Implementation Details

- **Directory Structure**:

  - Color scheme scripts are stored in `~/.config/colorscheme/list/`, each as an
    executable `.sh` file defining environment variables for a specific theme.
  - The selector script itself resides at
    `~/.config/colorscheme/colorscheme-selector.sh`.
  - The script delegates the actual application of a selected scheme to
    `~/.config/zshrc/colorscheme-set.sh`.

- **Workflow**:

  1. **Dependency Check**: Verifies that `fzf` is installed, exiting with a
     message if not found.
  2. **Scheme Discovery**: Lists all `.sh` files in the color scheme directory,
     extracting their basenames for display.
  3. **Interactive Selection**: Presents the available schemes using `fzf` with
     a custom prompt and header.
  4. **Selection Handling**: If a scheme is chosen, invokes the color scheme
     setter script with the selected filename as an argument.
  5. **Graceful Exit**: Handles cases where no schemes are found or the user
     cancels the selection.

- **Integration Points**:

  - The script is designed to be invoked from the terminal or integrated into
    shell startup files for dynamic theme switching.
  - The color scheme setter script (`colorscheme-set.sh`) is responsible for
    sourcing the selected theme and applying its settings to the environment.

- **Error Handling**:
  - Provides clear user feedback for missing dependencies, empty scheme
    directories, or cancelled selections.
  - Uses standard exit codes for integration with other scripts or automation
    tools.

### Architectural Context

- **Location**:

  - Selector: `~/.config/colorscheme/colorscheme-selector.sh`
  - Schemes: `~/.config/colorscheme/list/*.sh`
  - Setter: `~/.config/zshrc/colorscheme-set.sh`

- **Related Modules and Files**:

  - **Color Scheme Scripts**: Each file in `~/.config/colorscheme/list/` (e.g.,
    `linkarzu-new-headings.sh`) defines a set of color variables for a specific
    theme.
  - **Setter Script**: `colorscheme-set.sh` applies the selected theme by
    sourcing the corresponding script and updating environment variables.
  - **fzf**: Required for interactive selection; install via Homebrew
    (`brew install fzf`) if not present.

- **Extensibility**:
  - New themes can be added by placing additional `.sh` files in the color
    scheme directory.
  - The selection and application logic can be adapted for other shells or
    configuration managers as needed.

### Usage

1. **Ensure Prerequisites**:

   - Install `fzf` if not already present:
     ```sh
     brew install fzf
     ```
   - Confirm that the color scheme scripts and setter script exist in their
     respective directories.

2. **Run the Selector**:

   - Execute the selector script from the terminal:
     ```sh
     ~/.config/colorscheme/colorscheme-selector.sh
     ```
   - Use the interactive menu to choose a color scheme. The selected theme will
     be applied immediately.

3. **Add New Schemes**:

   - Create a new `.sh` file in `~/.config/colorscheme/list/` defining the
     desired color variables.
   - Ensure the script is executable:
     ```sh
     chmod +x ~/.config/colorscheme/list/your-theme.sh
     ```

4. **Integrate with Shell Startup** (optional):
   - Add a call to the selector or setter script in your `.bashrc`, `.zshrc`, or
     equivalent to apply a default or last-used theme on shell startup.

### Key Decisions and Patterns

- **Separation of Concerns**: The selector script handles user interaction,
  while the setter script manages environment updates, promoting
  maintainability.
- **Idempotency**: The script can be run multiple times without side effects, as
  it only applies the selected theme.
- **User Experience**: Utilizes `fzf` for a responsive, searchable interface,
  reducing friction in theme management.

### References

- [fzf GitHub Repository](https://github.com/junegunn/fzf)
- [Homebrew](https://brew.sh/)
- Example color scheme script:
  `~/.config/colorscheme/list/linkarzu-new-headings.sh`
- Color scheme setter: `~/.config/zshrc/colorscheme-set.sh`

## dictionaries

The `dictionaries` component serves as a centralized resource for managing and
accessing collections of key-value pairs or lookup tables within the system. Its
primary design intent is to provide a consistent and efficient mechanism for
storing, retrieving, and updating static or semi-static data that is referenced
throughout the application.

### Architectural Context

- **Layer**: The `dictionaries` module typically resides in the data or utility
  layer of the application architecture.
- **Dependencies**: It may interact with configuration files (e.g., YAML, JSON),
  database tables, or in-memory data structures, depending on the
  implementation.
- **Consumers**: Other modules, such as validation logic, user interface
  components, or business rules engines, reference the `dictionaries` to obtain
  standardized values (e.g., country codes, status labels, error messages).

### Design Patterns and Key Decisions

- **Singleton or Shared Resource**: The `dictionaries` are often implemented as
  a singleton or a shared service to ensure consistency and minimize memory
  usage.
- **Lazy Loading**: To optimize performance, dictionaries may be loaded on
  demand rather than at application startup, especially if they are large or
  infrequently used.
- **Immutability**: Where possible, dictionaries are treated as immutable to
  prevent accidental modification and to facilitate thread safety.
- **Extensibility**: The design allows for easy addition of new dictionaries or
  extension of existing ones without requiring changes to consumer modules.

### Implementation Details

- **Data Source**: Dictionaries can be defined in static files (e.g.,
  `dictionaries.json`), embedded in code, or fetched from external services.
- **Access API**: A standardized interface (e.g., `getDictionary(name)`,
  `lookup(dictionary, key)`) is provided for consumers to retrieve values.
- **Caching**: Frequently accessed dictionaries may be cached in memory to
  reduce I/O overhead.
- **Validation**: Mechanisms are in place to validate the integrity and
  completeness of dictionary data at load time.

### Usage Example

```js
// Accessing a dictionary of country codes
const countryCodes = dictionaries.get("countryCodes");
const countryName = countryCodes["JP"]; // "Japan"
```

### Related Modules and Files

- **Configuration Loader**: Handles reading dictionary data from files or remote
  sources.
- **Validation Utilities**: Use dictionaries to enforce allowed values.
- **UI Components**: Reference dictionaries for display labels and dropdown
  options.
- **Documentation**: See `docs/dictionaries.md` for a full list of available
  dictionaries and their schemas.

### Best Practices

- Define dictionary schemas and document expected keys and value types.
- Keep dictionaries up to date and review them regularly for accuracy.
- Avoid hardcoding dictionary values in business logic; always use the
  centralized access API.

## eligere

### Design Intent

The `.eligere.json` file defines the configuration for the Eligere browser
selection and automation tool. Its primary purpose is to provide a declarative,
user-customizable mapping between web domains and preferred browsers, enabling
seamless, context-aware browser launching on Darwin (macOS) systems. The
configuration supports advanced features such as shortcut-based browser
selection, domain-specific routing, and privacy controls, aiming to streamline
multi-browser workflows for developers and power users.

Key objectives include:

- **Domain-Based Routing**: Automatically open specific domains in designated
  browsers.
- **User Shortcuts**: Allow quick browser selection via keyboard shortcuts.
- **Privacy and Usability Controls**: Provide options to strip tracking
  attributes, manage URL expansion, and control browser pinning behavior.
- **Extensibility**: Support easy addition or modification of browser rules and
  global settings.

### Implementation Details

#### Structure

- **browsers**: An array of browser configuration objects. Each object
  specifies:

  - `name`: The display name of the browser (e.g., "Brave Browser", "Vivaldi").
  - `shortcut`: A unique string or number used for keyboard-based selection.
  - `default`: Boolean indicating if this browser is the default fallback.
  - `domains`: List of domain names (strings). URLs matching these domains will
    be routed to this browser.

- **Global Settings**:

  - `expandShortenURLs`: Boolean. If true, short URLs are expanded before
    routing.
  - `logLevel`: String. Controls logging verbosity (e.g., "error").
  - `pinningSeconds`: Integer. Specifies how long a browser window should remain
    pinned after opening a URL.
  - `stripTrackingAttributes`: Boolean. If true, removes tracking parameters
    from URLs before opening.
  - `useOnlyRunningBrowsers`: Boolean. If true, restricts selection to browsers
    that are already running.

- **Comment**: An optional field for user notes or configuration rationale.

#### Example Entry

```json
{
  "default": false,
  "domains": ["instructure.com", "meet.google.com"],
  "name": "Brave Browser",
  "shortcut": "1"
}
```

This entry routes URLs from `instructure.com` and `meet.google.com` to Brave
Browser, accessible via shortcut "1".

#### Key Decisions and Patterns

- **Declarative Configuration**: Uses a JSON structure for clarity, portability,
  and ease of editing.
- **Priority and Fallback**: The `default` flag ensures a fallback browser is
  always available if no domain matches.
- **Extensible Domain Mapping**: Domains can be added or removed per browser
  without code changes.
- **User-Centric Shortcuts**: Each browser can be assigned a shortcut for rapid
  selection, supporting keyboard-driven workflows.
- **Privacy by Design**: Options like `stripTrackingAttributes` and
  `expandShortenURLs` are included to enhance user privacy and control.

### Architectural Context

- **Location**: `eligere/.eligere.json` in the user's dotfiles or configuration
  repository.
- **Integration**: Consumed by the Eligere tool or related browser automation
  scripts, typically invoked from shell scripts, workflow automators, or as part
  of a browser-launching utility.
- **Related Modules/Files**:
  - Eligere launcher script or binary (not shown here).
  - Domain matching and URL normalization utilities.
  - Logging and error handling modules.
  - Documentation: See `README.md` for high-level usage and integration
    instructions.

### Usage

1. **Edit Configuration**:

   - Open `eligere/.eligere.json` in a text editor (e.g., Neovim).
   - Add or modify browser entries, specifying domains and shortcuts as needed.
   - Adjust global settings to match workflow and privacy requirements.

2. **Apply Changes**:

   - Save the file. Changes are typically picked up automatically by the Eligere
     tool on next invocation.

3. **Add a New Browser**:

   - Insert a new object in the `browsers` array with the desired `name`,
     `shortcut`, and optional `domains`.
   - Set `"default": true` for the preferred fallback browser.

4. **Domain Routing**:

   - When a URL is opened, Eligere checks the domain against the `domains`
     lists.
   - If a match is found, the corresponding browser is launched.
   - If no match, the browser marked as `default` is used.

5. **Shortcuts**:
   - Use the assigned shortcut to quickly select a browser when prompted by
     Eligere.

### References

- Eligere project documentation (see project `README.md`).
- Related configuration files: `eligere/` directory for scripts and additional
  settings.
- [Vivaldi](https://vivaldi.com/), [Brave Browser](https://brave.com/),
  [Google Chrome](https://www.google.com/chrome/),
  [Microsoft Edge](https://www.microsoft.com/edge),
  [Safari](https://www.apple.com/safari/).

## emacs

### Design Intent

The `example.org` file demonstrates the use of Org mode in Emacs for structured
task management, note-taking, and scheduling. The primary intent is to provide a
practical example of how to organize tasks, track progress, and manage
project-related notes using Org mode's hierarchical structure and markup
features. This file serves as a template or reference for developers seeking to
adopt Org mode for personal productivity, project planning, or workflow
automation.

Key objectives include:

- **Task Management**: Showcasing the use of TODO keywords, checkboxes, and
  hierarchical headings to manage actionable items and subtasks.
- **Scheduling**: Illustrating how to schedule tasks with timestamps for
  effective time management.
- **Documentation**: Providing a flexible structure for adding notes, context,
  and metadata alongside tasks.

### Implementation Details

#### Structure

- **Headings and Subheadings**: The file uses Org mode's asterisk-based heading
  system to create a clear hierarchy:
  - Top-level headings (e.g., `* Example`) define major sections or projects.
  - Subheadings (e.g., `** TODO finish this video`) represent tasks or
    milestones, with further nesting for subtasks (e.g., `*** TODO task 1`).
- **TODO Keywords**: Tasks are marked with `TODO` to indicate pending work.
  Completed items use checkboxes `[X]` for granular progress tracking.
- **Tags**: Tags such as `:VIDEO:` and `:work:` categorize tasks for filtering
  and agenda views.
- **Scheduling**: The `SCHEDULED` property assigns a specific date and time to
  tasks, enabling integration with Org mode's agenda and reminders.
- **Notes and Context**: Free-form text under headings provides additional
  context, status updates, or documentation related to tasks.

#### Example Breakdown

```org
* Example

** TODO finish this video :VIDEO::work:
*** TODO task 1
- I'll add some tasks below
- [X] this is a task
*** TODO task 2
- [X] another task
- bullet point
** TODO record video
SCHEDULED: <2025-04-09 Wed 22:00>
I'm recording the video right now

adding more text
```

- The top-level heading `* Example` groups all related tasks and notes.
- The `** TODO finish this video` entry is tagged and contains subtasks,
  demonstrating nested task breakdown.
- Checkboxes under subtasks provide fine-grained progress tracking.
- The `** TODO record video` entry is scheduled and includes a status update,
  showing how to combine scheduling and documentation.

### Architectural Context

- **Location**: Typically stored in a project or personal notes directory (e.g.,
  `emacs/example.org`).
- **Integration**: Designed for use with Emacs Org mode, leveraging features
  such as agenda views, clocking, and export capabilities.
- **Extensibility**: The structure supports additional metadata (e.g.,
  priorities, deadlines, properties) and can be extended with custom Org mode
  workflows or integrations (e.g., with task runners or external scripts).

### Design Patterns and Key Decisions

- **Hierarchical Organization**: Tasks and notes are organized in a tree
  structure, enabling logical grouping and easy navigation.
- **Declarative Task States**: Use of TODO keywords and checkboxes provides
  clear, machine-readable task states for automation and reporting.
- **Separation of Concerns**: Notes, scheduling, and actionable items are kept
  distinct but related, improving clarity and maintainability.
- **Tagging and Metadata**: Tags and scheduled timestamps facilitate filtering,
  agenda generation, and integration with other productivity tools.

### Usage

1. **Editing Tasks**:
   - Open `example.org` in Emacs with Org mode enabled.
   - Add, modify, or complete tasks using Org mode's keybindings (e.g.,
     `C-c C-t` to toggle TODO states, `C-c C-c` to update checkboxes).
2. **Scheduling and Agenda**:
   - Use the `SCHEDULED` property to assign dates to tasks.
   - View scheduled tasks in the Org agenda (`C-c a a`).
3. **Tracking Progress**:
   - Use checkboxes for subtasks and mark them as completed as work progresses.
   - Update task states and add notes as needed.
4. **Customization**:
   - Extend the file with additional headings, tags, or properties to suit
     specific workflows.
   - Integrate with external tools or scripts for automation (e.g., exporting to
     other formats, syncing with calendars).

### Related Modules and Files

- **Org Mode Documentation**: [Org mode manual](https://orgmode.org/manual/)
- **Agenda and Task Management**: Org mode's built-in agenda and task tracking
  features.
- **Exporters**: Org mode supports exporting to formats such as Markdown, HTML,
  and PDF.
- **Integration Scripts**: Custom Emacs Lisp scripts or external tools for
  automation (not shown here).

### References

- [Org mode homepage](https://orgmode.org/)
- [Org mode tutorials and guides](https://orgmode.org/worg/)
- Project documentation or README files referencing Org mode usage patterns.

## ghostty

### Design Intent

The configuration in `nvim/lua/plugins/ghostty.lua` integrates syntax
highlighting support for Ghostty terminal emulator configuration files directly
into Neovim. The primary goal is to provide developers with immediate, accurate
syntax highlighting for Ghostty's configuration format, improving readability
and reducing errors when editing these files. This integration is designed to be
lightweight, requiring no additional dependencies, and leverages the syntax
files distributed with the Ghostty application itself.

### Implementation Details

- **Plugin Declaration**:  
  The configuration registers a plugin named `"ghostty"` for Neovim's plugin
  manager (e.g., lazy.nvim or packer.nvim).

- **Source Directory**:  
  The `dir` field points directly to the Ghostty application's bundled Vim
  syntax files:

  ```
  /Applications/Ghostty.app/Contents/Resources/vim/vimfiles/
  ```

  This ensures that the syntax definitions are always in sync with the installed
  version of Ghostty.

- **Loading Behavior**:  
  The `lazy = false` option ensures that the plugin is loaded eagerly during
  Neovim startup, making the syntax highlighting available immediately for
  relevant filetypes.

- **No External Dependencies**:  
  The integration does not require any third-party plugins or external
  downloads. It relies solely on the files provided by the Ghostty application.

- **Acknowledgment**:  
  The initial comments credit Zilchmasta for sharing this integration approach
  via Discord, providing a reference to the relevant discussion for further
  context.

### Architectural Context

- **Location**:

  - Plugin configuration: `nvim/lua/plugins/ghostty.lua`
  - Ghostty syntax files:
    `/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/`

- **Integration**:

  - The plugin is managed alongside other Neovim plugins, following the
    Lua-based configuration structure.
  - Syntax highlighting is automatically applied to Ghostty configuration files
    when opened in Neovim.

- **Extensibility**:
  - The approach can be adapted for other applications that bundle Vim syntax
    files by updating the `dir` path.
  - Additional configuration (e.g., filetype associations) can be added if
    custom file extensions are used.

### Usage

1. **Prerequisites**:

   - Install Ghostty on macOS (Darwin). The syntax files are included with the
     application.
   - Ensure the plugin manager supports the `dir` and `lazy` options (e.g.,
     lazy.nvim).

2. **Configuration**:

   - Place the provided Lua snippet in `nvim/lua/plugins/ghostty.lua` or the
     appropriate plugin configuration directory.

3. **Editing Ghostty Config Files**:

   - Open any Ghostty configuration file in Neovim.
   - Syntax highlighting will be applied automatically, matching the definitions
     provided by Ghostty.

4. **Updating Syntax**:
   - When Ghostty is updated, the syntax files in the application bundle are
     updated as well. No manual intervention is required.

### Key Decisions and Patterns

- **Direct Resource Linking**:  
  By referencing the syntax files directly from the Ghostty application bundle,
  the configuration avoids duplication and ensures compatibility with the
  installed Ghostty version.

- **Eager Loading**:  
  The plugin is loaded at startup to guarantee that syntax highlighting is
  always available, regardless of file opening order.

- **Minimalism**:  
  No additional dependencies or configuration are introduced, keeping the
  integration simple and maintainable.

### Related Modules and Files

- **Ghostty Application**:

  - [Ghostty GitHub Repository](https://github.com/ghostty-org/ghostty)
  - Application bundle:
    `/Applications/Ghostty.app/Contents/Resources/vim/vimfiles/`

- **Neovim Plugin Management**:

  - Lua plugin configuration directory: `nvim/lua/plugins/`
  - Plugin manager documentation (e.g.,
    [lazy.nvim](https://github.com/folke/lazy.nvim))

- **Community Reference**:
  - Discord discussion:
    [Link to message](https://discord.com/channels/1005603569187160125/1300462095946485790/1300534513788653630)

### References

- [Ghostty Official Website](https://ghostty.io/)
- [Ghostty Syntax Documentation](https://github.com/ghostty-org/ghostty/tree/main/vim)
- [Neovim Documentation](https://neovim.io/doc/)
- [lazy.nvim Plugin Manager](https://github.com/folke/lazy.nvim)

## hammerspoon

### Design Intent

The `move_mouse_to_corner.lua` script provides automated mouse positioning for
macOS using Hammerspoon. Its primary purpose is to resolve UI issues in
applications—specifically, to ensure that the mouse pointer does not interfere
with sidebar auto-hide behavior in the Zen Browser app. When Zen Browser gains
focus, the script programmatically moves the mouse cursor to a non-intrusive
location (center or bottom-right of the primary screen), preventing the sidebar
from remaining visible due to pointer proximity. This automation enhances user
experience by ensuring that UI elements behave as intended without requiring
manual mouse movement.

### Implementation Details

- **Mouse Movement Functions**:

  - `moveMouseToBottomRight()`: Calculates a point near the bottom-right corner
    of the main screen (offset by 100 pixels from the edges for safety) and
    moves the mouse there using `hs.mouse.setAbsolutePosition`.
  - `moveMouseToCenter()`: Calculates the center point of the main screen and
    moves the mouse there.

- **Application Watcher**:

  - A Hammerspoon application watcher (`hs.application.watcher`) is instantiated
    to monitor application focus events.
  - When the Zen Browser application is activated
    (`eventType == hs.application.watcher.activated` and
    `appName == "Zen Browser"`), the script calls `moveMouseToCenter()` to
    reposition the mouse.

- **Startup Behavior**:
  - The watcher is started immediately, ensuring the automation is active as
    soon as Hammerspoon loads the script.

### Architectural Context

- **Location**:  
  `~/.config/hammerspoon/move_mouse_to_corner.lua` (or as referenced in the
  user's Hammerspoon configuration).

- **Integration**:  
  Designed to be loaded by Hammerspoon at startup, either directly or via an
  `init.lua` that requires or executes this script.

- **Dependencies**:

  - Hammerspoon (https://www.hammerspoon.org/)
  - macOS (Darwin)

- **Extensibility**:
  - The script can be adapted to move the mouse for other applications by
    modifying the `appName` check.
  - Additional positioning strategies (e.g., top-left, configurable offsets) can
    be added as needed.

### Design Patterns and Key Decisions

- **Event-Driven Automation**:  
  Uses Hammerspoon's application watcher to trigger actions based on application
  focus events, ensuring minimal resource usage and immediate response.

- **Separation of Concerns**:  
  Mouse movement logic is encapsulated in dedicated functions, making the script
  maintainable and extensible.

- **Safety Offsets**:  
  The bottom-right position is offset by 100 pixels from the screen edges to
  avoid potential issues with system UI elements or accidental edge triggers.

- **Minimal Intrusion**:  
  The script only acts when the specified application is focused, avoiding
  interference with other workflows.

### Usage

1. **Prerequisites**:

   - Install Hammerspoon on macOS.
   - Place this script in your Hammerspoon configuration directory.

2. **Activation**:

   - Ensure the script is loaded by your `~/.hammerspoon/init.lua` (e.g., by
     requiring or dofile).
   - Reload Hammerspoon to activate the watcher.

3. **Behavior**:
   - When Zen Browser is focused, the mouse will automatically move to the
     center of the main screen.
   - The `moveMouseToBottomRight()` function is available for manual invocation
     or further automation.

### Related Modules and Files

- **Hammerspoon Documentation**:  
  [Hammerspoon API Reference](https://www.hammerspoon.org/docs/)
- **Related Scripts**:
  - `cursor_escape.lua`: Provides similar automation for other applications
    (e.g., moving the mouse for Alacritty).
  - `init.lua`: Main Hammerspoon configuration file that loads automation
    scripts.
- **Zen Browser**:  
  The target application for this automation.

### References

- [Hammerspoon Official Website](https://www.hammerspoon.org/)
- [Hammerspoon Application Watcher Documentation](https://www.hammerspoon.org/docs/hs.application.watcher.html)
- [Hammerspoon Mouse Module](https://www.hammerspoon.org/docs/hs.mouse.html)

## hidapitester

### Design Intent

`hidapitester` is a simple command-line tool for testing and debugging HID
devices using [HIDAPI](https://github.com/libusb/hidapi). It is designed to
provide comprehensive coverage of HIDAPI's functionality, allowing developers to
enumerate devices, filter by various criteria, and send or receive HID reports
directly from the terminal. The tool is cross-platform, supporting Darwin
(macOS), Linux, and Windows, and is distributed as a statically linked binary
with minimal dependencies.

### Key Features

- **Comprehensive API Testing**: Exercise all major HIDAPI calls from the
  command line.
- **Cross-Platform**: Supports macOS (Intel/Apple Silicon), Linux, and Windows.
- **Static Binary**: No need for a system-installed hidapi library.
- **Detailed Device Listing**: Enumerate devices with filtering by vendor ID,
  product ID, usagePage, usage, and device path.
- **Report Transmission**: Send and receive Feature, Output, and Input reports;
  retrieve report descriptors.
- **Flexible Output**: Supports quiet and verbose modes, buffer length and base
  (decimal/hex) configuration.

### Main Commands and Options

- `--vidpid <vid/pid>`: Filter by vendor ID and product ID (supports partial
  specification).
- `--usagePage <number>`, `--usage <number>`: Filter by usagePage or usage.
- `--list`, `--list-usages`, `--list-detail`: List HID devices with increasing
  detail.
- `--open`, `--open-path <path>`: Open a device by filter or path.
- `--close`: Close the currently open device.
- `--get-report-descriptor`: Retrieve the report descriptor.
- `--send-feature <datalist>`, `--read-feature <reportId>`: Send or read Feature
  reports.
- `--send-output <datalist>`, `--read-input`, `--read-input-report <reportId>`:
  Send Output or read Input reports.
- `--length <len>`: Set the report buffer length.
- `--timeout <msecs>`: Set input read timeout.
- `--base <base>`: Set output number base (decimal or hexadecimal).
- `--quiet`, `--verbose`: Control output verbosity.

### Example Usage

- List all HID devices:
  ```sh
  ./hidapitester --list
  ```
- Open a device by vendor/product ID and send/receive a Feature report:
  ```sh
  ./hidapitester --vidpid 0x27b8/0x1ed --open --length 9 --send-feature 1,99,0,255,0 --read-feature 1 --close
  ```
- Communicate with a TeensyRawHid sketch:
  ```sh
  ./hidapitester --vidpid 16C0 --usagePage 0xFFAB --open --send-output 0x4f,33,22,0xff --read-input
  ```

### Building on macOS

1. Install Xcode Command Line Tools:
   ```sh
   sudo xcode-select --install
   ```
2. Clone the repositories and build:

   ```sh
   git clone https://github.com/libusb/hidapi
   git clone https://github.com/todbot/hidapitester
   cd hidapitester
   make
   ```

   > If `hidapi` is in a non-adjacent directory, set the `HIDAPI_DIR` variable
   > when running `make`.

3. Verify the build:
   ```sh
   ./hidapitester --list
   ```

### Related Files and Directories

- `hidapitester.c`: Main source code.
- `Makefile`: Build instructions.
- `test_hardware/`: Example Arduino sketches for hardware testing.
- `docs/`: Additional documentation.

### References

- [hidapitester GitHub Repository](https://github.com/todbot/hidapitester)
- [HIDAPI Official Documentation](https://github.com/libusb/hidapi)
- [Prebuilt Releases](https://github.com/todbot/hidapitester/releases)

## mouseless

### Design Intent

The `config.yaml` file defines the comprehensive configuration for the Mouseless
application, a keyboard-driven mouse control tool designed for efficiency and
accessibility on desktop environments. The primary intent is to provide a
declarative, extensible, and user-friendly mechanism for customizing Mouseless’s
behavior, grid navigation, keyboard mappings, and visual appearance. This
configuration enables developers and advanced users to tailor the application to
their workflow, hardware, and personal preferences.

Key objectives include:

- **Modularity**: Separate concerns for behavior, grid layouts, key mappings,
  and styles, allowing independent customization.
- **Portability**: Ensure compatibility across different systems and keyboard
  layouts, with explicit support for macOS (Darwin).
- **Extensibility**: Facilitate the addition of new behaviors, grid strategies,
  and style themes without modifying application code.
- **Accessibility**: Support for keyboard-only operation, customizable overlays,
  and visual feedback for users with diverse needs.

### Implementation Details

#### Structure Overview

The configuration is organized into several top-level sections:

- **`app_version`**: Specifies the configuration schema version for
  compatibility checks.
- **`behavior_configs`**: Defines mouse movement, grid interaction, and action
  timing behaviors.
- **`grid_configs`**: Describes grid layouts, cell definitions, and navigation
  strategies.
- **`keyboard_layout`**: Maps virtual key codes to characters for accurate key
  handling.
- **`keymaps`**: Assigns application actions to specific key combinations.
- **`monitor_assignment_mode`**: Controls how the application assigns overlays
  to monitors.
- **`style_configs`**: Customizes the visual appearance of overlays, cursors,
  and text.

#### Section Breakdown

**1. Behavior Configs (`behavior_configs`)**

- Controls mouse movement speed, grid action granularity, cursor visibility,
  overlay behavior, and action timing.
- Example options:
  - `base_wheel_speed`, `wheel_speed_multiplier`, `wheel_step_size`: Fine-tune
    scroll speed and increments.
  - `hide_cursor_on_click`, `hide_location`: Manage cursor visibility and hiding
    location.
  - `move_duration_ms`: Sets animation duration for cursor movement.
  - `multi_action_timeout_ms`, `tap_threshold_ms`: Configure timing for
    multi-step actions and tap detection.
  - `initial_overlay_monitor`, `initial_action_location`: Define default overlay
    and action positions.

**2. Grid Configs (`grid_configs`)**

- Defines one or more grid layouts for mouse navigation.
- Each grid includes:
  - `grid_defn`: List of grid layers, each specifying cell count, border width,
    and callback for cell labeling.
  - `strategy`: Navigation logic (e.g., `subgrid` for hierarchical refinement).
  - `subgrid_dims`: Dimensions for subgrid navigation.
  - `subgrid_mouse_action_keys`: Keys used for subgrid actions.
  - `name`: Identifier for the grid configuration.

**3. Keyboard Layout (`keyboard_layout`)**

- Maps system virtual key codes to character representations for accurate key
  event handling.
- Supports multiple characters per key (e.g., lowercase and uppercase).
- Ensures compatibility with various keyboard layouts (e.g.,
  `com.apple.keylayout.ABC`).

**4. Keymaps (`keymaps`)**

- Binds application actions (e.g., execute mouse action, show overlay, wheel
  navigation) to specific key combinations.
- Supports tap, hold, and modifier-based actions.
- Allows for platform-specific keymaps (e.g., `mac`).

**5. Style Configs (`style_configs`)**

- Controls overlay appearance, including colors (RGBA), font settings, cursor
  styles, and grid line styles.
- Enables theme customization for different backgrounds and accessibility needs.
- Example options:
  - `background_rgba`, `grid_rgba`, `subgrid_rgba`: Overlay and grid colors.
  - `font_family`, `font_size_multiplier`: Font customization.
  - `cursor_rgba`, `cursor_size`: Cursor appearance.
  - `window_opacity`: Overlay transparency.

### Architectural Context

- **Location**:
  - Main configuration: `mouseless/config.yaml`
  - Backup or legacy configuration: `mouseless/config.bakup.yaml`
- **Integration**:
  - Loaded at application startup to initialize all runtime parameters.
  - Changes require application restart or reload to take effect.
- **Related Modules/Files**:
  - **Application Core**: Consumes this configuration to drive all UI and input
    logic.
  - **Grid Navigation Engine**: Implements grid strategies and cell callbacks as
    referenced in `grid_defn`.
  - **Keyboard Handler**: Uses `keyboard_layout` and `keymaps` for event
    processing.
  - **Style Engine**: Applies `style_configs` for overlay rendering.
  - **Backup Config**: `config.bakup.yaml` provides a fallback or migration
    reference for older versions.

### Design Patterns and Key Decisions

- **Declarative Configuration**:
  - All behaviors, layouts, and styles are defined in YAML, enabling
    non-programmatic customization.
- **Separation of Concerns**:
  - Distinct sections for behavior, grid, keymaps, and styles improve
    maintainability and clarity.
- **Extensibility**:
  - New grid layouts, keymaps, or styles can be added as additional entries
    without code changes.
- **Platform Awareness**:
  - Keyboard layout and keymaps are tailored for macOS but can be adapted for
    other platforms.
- **Accessibility and Usability**:
  - Supports keyboard-only workflows, visual customization, and adjustable
    timing for diverse user needs.
- **Versioning**:
  - `app_version` field ensures compatibility and supports migration strategies.

### Usage

1. **Editing the Configuration**

   - Open `mouseless/config.yaml` in a text editor (e.g., Neovim).
   - Adjust sections as needed:
     - Modify `behavior_configs` for mouse and overlay behavior.
     - Update `grid_configs` to change navigation logic or grid appearance.
     - Edit `keymaps` to rebind actions to preferred keys.
     - Tweak `style_configs` for color and font preferences.
   - Save changes and restart Mouseless to apply.

2. **Adding New Grids or Styles**

   - Duplicate an existing grid or style entry and modify parameters as desired.
   - Assign a unique `name` for reference.

3. **Migrating from Older Versions**

   - Use `config.bakup.yaml` as a reference for legacy options or to restore
     previous settings.

4. **Troubleshooting**
   - Ensure all required fields are present and correctly formatted.
   - Refer to application logs for configuration parsing errors.

### References

- **Related Files**:
  - `mouseless/config.yaml`: Main configuration file.
  - `mouseless/config.bakup.yaml`: Backup or legacy configuration.
- **Application Documentation**:
  - See project `README.md` for high-level usage and integration instructions.
- **Grid and Keymap Documentation**:
  - Refer to in-code documentation or developer guides for callback and strategy
    details.
- **External Resources**:
  - [YAML Specification](https://yaml.org/)
  - [macOS Keyboard Layouts](https://support.apple.com/en-us/HT201794)

## neovide

### Design Intent

The Neovide configuration (`config.toml`) and session launcher script
(`neovide-sessionizer.sh`) are designed to provide a seamless, visually
enhanced, and platform-optimized Neovim GUI experience on macOS. The intent is
to:

- Enable advanced window management and appearance customization for Neovide,
  leveraging macOS-specific features such as transparent window frames.
- Ensure reliable integration with external automation tools (e.g.,
  Karabiner-Elements) and window managers (e.g., yabai), even in restricted
  shell environments.
- Support reproducible, user-specific Neovim sessions with consistent font,
  theme, and UI settings.
- Facilitate developer workflows by allowing Neovide to be launched with a
  specific Neovim configuration (`NVIM_APPNAME=neobean`) from any automation or
  scripting context.

### Implementation Details

#### 1. `config.toml` (Neovide Configuration)

- **Window Appearance**:

  - `frame = "transparent"`: Enables a transparent window frame on macOS,
    providing a modern, borderless look.
  - `title-hidden = true`: Hides the window title for a cleaner UI.
  - `maximized = false`: Starts Neovide in windowed mode by default.
  - `vsync = false`: Disables vertical sync for potentially lower latency;
    refresh rate can be set elsewhere if needed.
  - `tabs = true`: Enables tabbed editing within Neovide.
  - `theme = "auto"`: Automatically selects the theme based on system
    appearance.
  - `idle = true`: Reduces resource usage when Neovide is not focused.

- **Font Settings**:

  - `[font]` section allows customization of font family and size. Defaults to
    the bundled Fira Code Nerd Font if `normal` is empty.
  - `size = 14.0`: Sets the default font size for readability.

- **Platform and Integration**:

  - `wsl = false`: Disables Windows Subsystem for Linux integration, as this
    configuration targets macOS (Darwin).
  - `no-multigrid = false`: Enables multigrid support for advanced UI features.

- **Executable Path**:
  - `neovim-bin` is commented out; Neovide will locate `nvim` dynamically via
    `$PATH`.

#### 2. `neovide-sessionizer.sh` (Session Launcher Script)

- **Purpose**: Launches Neovide with a specific Neovim configuration
  (`NVIM_APPNAME=neobean`) from a controlled environment, ensuring all
  dependencies are available.

- **Environment Handling**:

  - `export PATH="/opt/homebrew/bin:$PATH"`: Prepends Homebrew’s binary
    directory to the `PATH` to ensure tools like `yabai`, `jq`, and others are
    found, addressing the limited environment provided by Karabiner-Elements.
  - The script is compatible with automation tools that provide minimal
    environment variables (e.g., `$HOME`, `$USER`).

- **Working Directory**:

  - Changes to the dotfiles repository directory
    (`$HOME/github/dotfiles-latest`) before launching Neovide, ensuring
    consistent context for plugins and configuration.

- **Command Execution**:
  - Uses `bash -c` to set the `NVIM_APPNAME` environment variable and launch
    Neovide, which in turn loads the `neobean` Neovim configuration profile.

### Architectural Context

- **Location**:

  - `config.toml`: `neovide/config.toml`
  - `neovide-sessionizer.sh`: `neovide/neovide-sessionizer.sh`

- **Integration**:

  - The session launcher is intended to be invoked by external automation tools
    (e.g., Karabiner-Elements, shell scripts, or window manager hooks).
  - The configuration file is automatically loaded by Neovide at startup,
    applying all UI and behavior customizations.

- **Related Modules and Files**:
  - `~/.config/nvim/`: Neovim configuration directory, with profiles such as
    `neobean`.
  - `karabiner/`: Karabiner-Elements configuration for keyboard automation.
  - `yabai/`: Window manager configuration for advanced tiling and window
    control.
  - `brew/`: Homebrew package management for installing dependencies.
  - `README.md`: High-level documentation and integration instructions.

### Design Patterns and Key Decisions

- **Separation of Concerns**:
  - Configuration and launch logic are separated: `config.toml` manages
    Neovide’s appearance and behavior, while the shell script handles
    environment setup and invocation.
- **Platform Awareness**:
  - macOS-specific features (e.g., transparent frames) are enabled
    conditionally.
  - The script ensures compatibility with Homebrew and macOS window managers.
- **Idempotency and Safety**:
  - The script safely modifies `PATH` without overwriting existing values.
  - The configuration avoids hardcoding paths, relying on environment variables
    and dynamic resolution.
- **Extensibility**:
  - Additional environment variables or launch options can be added to the
    script as needed for further automation or integration.

### Usage

1. **Edit Configuration**:
   - Adjust `neovide/config.toml` to customize appearance, font, and behavior.
2. **Launch Neovide**:
   - Run `neovide/neovide-sessionizer.sh` directly or trigger it via
     Karabiner-Elements or other automation tools.
3. **Integrate with Automation**:
   - Reference the script in Karabiner-Elements complex modifications or window
     manager rules to launch Neovide in response to hotkeys or events.
4. **Troubleshooting**:
   - Ensure all dependencies (e.g., Neovide, Neovim, Homebrew packages) are
     installed and available in `/opt/homebrew/bin`.

### References

- [Neovide Documentation](https://neovide.dev/)
- [Neovide Command-Line Reference](https://neovide.dev/command-line-reference.html)
- [Karabiner-Elements Documentation](https://karabiner-elements.pqrs.org/docs/)
- [Homebrew](https://brew.sh/)
- [yabai Window Manager](https://github.com/koekeishiya/yabai)
- Project `README.md` for additional integration and workflow details.

## obs

## obsidian_main

## rio

## scripts

## sesh

## sketchybar

## steermouse

## ubersicht

## vimrc

## vivaldi

## vscode

## wezterm

## yazi
