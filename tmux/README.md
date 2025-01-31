# tmux Configuration

This repository contains a custom tmux configuration with updated key bindings, color scheme, and additional features for enhanced productivity.

## Features

- **Custom Key Bindings**:
  - Prefix key changed from `C-b` to `C-t`
  - Key bindings for pane resizing and window movement
- **Enhanced Color Scheme**:
  - Updated status bar and pane borders with a new color scheme
- **Vi Mode**:
  - Enabled vi mode for copy mode and pane navigation
- **macOS Specific Configuration**:
  - Included settings and utility scripts tailored for macOS

## Setup

1. Create and populate the `~/tmux.conf` file:

   ```sh
   echo "source-file ~/.config/tmux/tmux.conf" > ~/tmux.conf
   ```

## Key Bindings

- **Prefix Key**: `C-t` (Control + t)
- **Pane Resizing**:
  - `Prefix + h` : Resize pane left
  - `Prefix + j` : Resize pane down
  - `Prefix + k` : Resize pane up
  - `Prefix + l` : Resize pane right
- **Window Movement**:
  - `Prefix + H` : Move window left
  - `Prefix + L` : Move window right

## Custom Scripts

- **lazygit Popup**:
  - Open lazygit in a popup window with `Prefix + g`

## License

This project is licensed under the MIT License.

Feel free to customize it further based on your specific needs and preferences!
