#!/bin/bash

# --- Configuration ---
CONNECT_SCRIPT="/home/jonah/.config/hypr/scripts/vnc_connect.sh"
DISCONNECT_SCRIPT="/home/jonah/.config/hypr/scripts/vnc_disconnect.sh"
LOG_FILE="/home/jonah/.config/hypr/scripts/manager.log"
CONNECT_SOUND="/usr/share/sounds/freedesktop/stereo/service-login.oga"
DISCONNECT_SOUND="/usr/share/sounds/freedesktop/stereo/service-logout.oga"

# --- Setup ---
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE") 2>&1

# --- Global Variables ---
WAYVNC_PID=

# --- Functions ---
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

notify() {
    notify-send "WayVNC" "$1" -u "${2:-normal}"
}

play_sound() {
    if [[ -f "$1" ]] && command -v paplay >/dev/null; then
        paplay "$1" &
    else
        log "Warning: Cannot play sound. File missing or paplay not found."
    fi
}

cleanup() {
    log "Cleanup initiated. Terminating WayVNC server..."
    # This trap is a final failsafe for when you manually stop the script.
    if [[ -n $WAYVNC_PID && -e /proc/$WAYVNC_PID ]]; then
        kill "$WAYVNC_PID"
        log "WayVNC server (PID: $WAYVNC_PID) terminated by cleanup trap."
    fi
    log "Manager script is shutting down."
    exit 0
}

# Trap the script exit (Ctrl+C, etc.) to run the final cleanup.
trap cleanup INT TERM

# --- Main Logic ---
# NEW: Add a main loop that will run forever, allowing restarts.
while true; do
    log "Starting WayVNC server..."
    # Remove any stale socket file that might prevent starting
    rm -f /run/user/1000/wayvncctl

    wayvnc 0.0.0.0 5901 --output HDMI-A-1 --disable-input &
    WAYVNC_PID=$!

    sleep 1

    if ! kill -0 "$WAYVNC_PID" 2>/dev/null; then
        log "CRITICAL: WayVNC server failed to start immediately!"
        notify "WayVNC server failed to start!" "critical"
        log "Waiting 10 seconds before retrying..."
        sleep 10
        continue # NEW: Instead of exiting, we loop back to try again.
    fi

    log "WayVNC server started successfully with PID: $WAYVNC_PID"
    notify "WayVNC server is running." "low"

    log "Starting VNC connection monitor..."
    last_client_count=0

    # This inner loop monitors the running process
    while true; do
        if ! kill -0 "$WAYVNC_PID" 2>/dev/null; then
            log "CRITICAL: WayVNC server process (PID: $WAYVNC_PID) has crashed or stopped."
            notify "WayVNC server has crashed! Attempting to restart..." "critical"
            break # NEW: Break out of the *inner* monitoring loop to let the outer loop restart it.
        fi

        if ! client_list=$(wayvncctl client-list); then
            log "Warning: 'wayvncctl client-list' command failed. Server might be unresponsive."
            sleep 5
            continue
        fi

        current_client_count=$(echo "$client_list" | grep -c .)

        if [[ $current_client_count -gt 0 && $last_client_count -eq 0 ]]; then
            log "VNC client connected. Executing connect script."
            notify "VNC Client Connected." "normal"
            play_sound "$CONNECT_SOUND"
            bash "$CONNECT_SCRIPT"
        fi

        if [[ $current_client_count -eq 0 && $last_client_count -gt 0 ]]; then
            log "Last VNC client disconnected. Executing disconnect script."
            notify "VNC Client Disconnected." "normal"
            play_sound "$DISCONNECT_SOUND"
            bash "$DISCONNECT_SCRIPT"
        fi

        last_client_count=$current_client_count
        sleep 3
    done

    # If the inner loop was broken due to a crash, we land here.
    log "Restarting in 5 seconds..."
    sleep 5
done
