#!/bin/bash

# Get the number of lines in the client list.
# The header is always 1 line, so if the count is > 1, clients are still connected.
client_count=$(wayvncctl client-list | wc -l)

# If the line count is 1 or less, it means only the header is left (or it's empty),
# so no clients are connected.
if [ "$client_count" -le 1 ]; then
    # Restore the default wallpaper
    hyprctl hyprpaper wallpaper ",/home/jonah/projects/dotfiles/wallpapers/airplane.jpg"
fi
