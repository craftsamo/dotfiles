#!/bin/bash

LAYOUT=$(cat ~/.config/tmux/layouts/7030/layout.txt)
tmux select-layout "$LAYOUT"
