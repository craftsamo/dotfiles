#!/bin/bash

LAYOUT=$(cat ~/.config/tmux/layouts/2x3/layout.txt)
tmux select-layout "$LAYOUT"
