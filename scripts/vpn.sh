#!/usr/bin/env bash
set -euo pipefail

VPN_NAME="Shannon Office"

echo "Deleting old inactive FortiClient VPN interfaces..."

nmcli -t -f NAME,TYPE,DEVICE connection show \
  | awk -F: '$2=="tun" && $1 ~ /^fctvpn/ && $3=="" {print $1}' \
  | while read -r conn; do
        echo "Deleting stale VPN profile: $conn"
        nmcli connection delete "$conn" || true
    done

echo "Connecting FortiClient VPN: $VPN_NAME"

forticlient vpn connect "$VPN_NAME"

echo "Disabling autoconnect on FortiClient VPN interfaces..."

nmcli -t -f NAME,TYPE connection show \
  | awk -F: '$2=="tun" && $1 ~ /^fctvpn/ {print $1}' \
  | while read -r conn; do
        echo "Disabling autoconnect: $conn"
        nmcli connection modify "$conn" connection.autoconnect no
    done

echo "Done."
