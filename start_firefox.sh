#!/bin/bash
# Launch Firefox and ensure it tiles in Awesome WM

# Launch Firefox in background
firefox &

# Wait for window to appear
for i in {1..10}; do
    WIN_ID=$(xdotool search --onlyvisible --class "Firefox" | head -n 1)
    if [ ! -z "$WIN_ID" ]; then
        break
    fi
    sleep 0.2
done

if [ -z "$WIN_ID" ]; then
    notify-send "Error" "Firefox window not found"
    exit 1
fi

# Move window to current tag and activate it
# Requires awesome-client installed (`sudo pacman -S awesome-client` or `apt install awesome-extra`)
echo "client = client.focus
if client then
    client:move_to_tag(client.screen.selected_tag)
    client.floating = false
    client:raise()
end" | awesome-client

# Map and activate window
xdotool windowmap $WIN_ID
xdotool windowactivate $WIN_ID
