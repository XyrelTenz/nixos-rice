#!/usr/bin/env bash
# close-window.sh — Super+Q handler.
# If the focused window is a terminal running tmux, kill the tmux session
# before closing the window so no orphaned session is left behind.

focused_class=$(hyprctl activewindow -j | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('class',''))" 2>/dev/null)

if [[ "$focused_class" == "com.mitchellh.ghostty" || "$focused_class" == "Ghostty" || "$focused_class" == "ghostty" ]]; then
    # Kill every tmux session — all windows in the terminal are inside tmux.
    tmux kill-server 2>/dev/null || true
fi

hyprctl dispatch closewindow ""
