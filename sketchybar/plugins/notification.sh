#!/bin/bash

# Filename: ~/.config/sketchybar/felixkratz-linkarzu/plugins/notification.sh
# ~/.config/sketchybar/felixkratz-linkarzu/plugins/notification.sh

source "$HOME/.config/sketchybar/felixkratz-linkarzu/colors.sh"

custom_notification="$HOME/.config/custom-notification.txt"

if [ -f "$custom_notification" ]; then
  sketchybar -m --set notification label=" " icon="" icon.color=$GREEN label.color=$GREEN icon.drawing=on
else
  sketchybar -m --set notification label="" icon.drawing=off
fi
