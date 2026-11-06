#!/usr/bin/env bash
set -Eeuo pipefail

# Log every run for troubleshooting.
exec >>/var/log/c-auto-static-ip.log 2>&1
echo "===== FIXED IP SETUP: $(date) ====="

FIXED_IP="192.168.1.86"
PREFIX="24"
FIXED_CIDR="${FIXED_IP}/${PREFIX}"

# Keep the Ubuntu Live session untouched. Run only on installed Ubuntu.
if grep -qw 'boot=casper' /proc/cmdline || [[ -d /run/casper ]]; then
    echo "Live session detected; skip."
    exit 0
fi

if [[ -f /var/lib/c-auto-static-ip.done ]]; then
    echo "Already configured; skip."
    systemctl disable c-auto-static-ip.service >/dev/null 2>&1 || true
    exit 0
fi

for command in ip nmcli python3 arping; do
    if ! command -v "$command" >/dev/null 2>&1; then
        echo "ERROR: Missing command: $command. Keeping current network configuration."
        exit 1
    fi
done

IF=""
CIDR=""
GW=""
CON=""

# Wait for NetworkManager to establish an IPv4 connection.
for attempt in $(seq 1 60); do
    IF="$(ip -4 route show default | awk 'NR==1 {for (i=1; i<=NF; i++) if ($i=="dev") {print $(i+1); exit}}')"

    if [[ -n "$IF" ]]; then
        CIDR="$(ip -o -4 addr show dev "$IF" scope global | awk 'NR==1 {print $4}')"
        GW="$(ip -4 route show default dev "$IF" | awk 'NR==1 {for (i=1; i<=NF; i++) if ($i=="via") {print $(i+1); exit}}')"
        CON="$(nmcli -g GENERAL.CONNECTION device show "$IF" 2>/dev/null | head -n1 || true)"
    fi

    if [[ -n "$IF" && -n "$CIDR" && -n "$GW" && -n "$CON" && "$CON" != "--" ]]; then
        break
    fi
    sleep 2
done

if [[ -z "$IF" || -z "$CIDR" || -z "$GW" || -z "$CON" || "$CON" == "--" ]]; then
    echo "ERROR: Could not discover an active IPv4 connection. Keeping current configuration."
    exit 1
fi

# FIX: Use a comma-separated DNS list. The old script joined DNS servers with
# spaces (paste -sd' '), which caused NetworkManager's error:
# "ipv4.dns: 2. DNS server address is invalid".
# Use the detected gateway as primary DNS and 8.8.8.8 as fallback.
DNS="${GW},8.8.8.8"

echo "Interface: $IF"
echo "Current IPv4: $CIDR"
echo "Current gateway: $GW"
echo "Active profile: $CON"
echo "Requested fixed IPv4: $FIXED_CIDR"
echo "DNS to configure: $DNS"

# Safety guard: only use 192.168.1.86/24 on a DHCP-detected 192.168.1.0/24 LAN.
# This intentionally refuses QEMU's default 10.0.2.0/24 NAT and unrelated networks.
if ! python3 - "$CIDR" "$FIXED_CIDR" "$GW" <<'PY'
import ipaddress, sys
try:
    current = ipaddress.ip_interface(sys.argv[1])
    wanted = ipaddress.ip_interface(sys.argv[2])
    gateway = ipaddress.ip_address(sys.argv[3])
    expected = ipaddress.ip_network("192.168.1.0/24")
    ok = (
        current.network == expected
        and wanted.network == expected
        and gateway in expected
        and wanted.ip not in (expected.network_address, expected.broadcast_address)
        and gateway != wanted.ip
    )
    sys.exit(0 if ok else 1)
except ValueError:
    sys.exit(1)
PY
then
    echo "ERROR: Current network is not 192.168.1.0/24 or gateway is outside that subnet. Keeping DHCP/current configuration."
    echo "For another LAN, adjust FIXED_IP/PREFIX and the expected subnet in this script."
    exit 1
fi

STATIC_CON="c-fixed-ip-$IF"
SOURCE_CON="$CON"

# If the active profile has the target name, find a separate DHCP profile to clone.
if [[ "$SOURCE_CON" == "$STATIC_CON" ]]; then
    SOURCE_CON=""
    while IFS= read -r candidate; do
        [[ -z "$candidate" || "$candidate" == "$STATIC_CON" ]] && continue
        method="$(nmcli -g ipv4.method connection show "$candidate" 2>/dev/null || true)"
        iface_name="$(nmcli -g connection.interface-name connection show "$candidate" 2>/dev/null || true)"
        if [[ "$method" == "auto" && ( -z "$iface_name" || "$iface_name" == "$IF" ) ]]; then
            SOURCE_CON="$candidate"
            break
        fi
    done < <(nmcli -t -f NAME connection show)
fi

if [[ -z "$SOURCE_CON" || "$SOURCE_CON" == "$STATIC_CON" ]]; then
    echo "ERROR: Cannot find a separate source profile. Keeping current configuration."
    exit 1
fi

# ARP duplicate check is useful but does NOT guarantee the IP is outside the DHCP pool.
if [[ "${CIDR%/*}" != "$FIXED_IP" ]]; then
    if ! arping -D -I "$IF" -c 3 -w 4 "$FIXED_IP" >/dev/null 2>&1; then
        echo "ERROR: $FIXED_IP may already be in use or the ARP check failed. Keeping current configuration."
        exit 1
    fi
fi

# Clone the source first; only then replace an older target profile.
if nmcli -t -f NAME connection show | grep -Fxq "$STATIC_CON"; then
    nmcli connection delete id "$STATIC_CON"
fi

nmcli connection clone "$SOURCE_CON" "$STATIC_CON"
nmcli connection modify "$STATIC_CON" \
    connection.interface-name "$IF" \
    connection.autoconnect yes \
    connection.autoconnect-priority 100 \
    ipv4.method manual \
    ipv4.addresses "$FIXED_CIDR" \
    ipv4.gateway "$GW" \
    ipv4.dns "$DNS" \
    ipv4.ignore-auto-dns yes

# Prefer the static profile on subsequent boots, but retain the DHCP profile as fallback.
nmcli connection modify "$SOURCE_CON" \
    connection.autoconnect yes \
    connection.autoconnect-priority -100

if ! nmcli connection up id "$STATIC_CON" ifname "$IF"; then
    echo "ERROR: Static profile activation failed; restoring source connection."
    nmcli connection delete id "$STATIC_CON" >/dev/null 2>&1 || true
    nmcli connection up id "$SOURCE_CON" ifname "$IF" || true
    exit 1
fi

sleep 2
if ! ip -o -4 addr show dev "$IF" | grep -Fq "$FIXED_IP/"; then
    echo "ERROR: Fixed address not present after activation; restoring source connection."
    nmcli connection delete id "$STATIC_CON" >/dev/null 2>&1 || true
    nmcli connection up id "$SOURCE_CON" ifname "$IF" || true
    exit 1
fi

mkdir -p /var/lib
touch /var/lib/c-auto-static-ip.done
systemctl disable c-auto-static-ip.service >/dev/null 2>&1 || true

echo "SUCCESS: Fixed IP configured: $FIXED_CIDR"
echo "Gateway detected from DHCP: $GW"
echo "DNS configured: $DNS"
echo "WARNING: Reserve $FIXED_IP outside the router DHCP pool; ARP alone cannot guarantee future uniqueness."
ip -4 -br addr show dev "$IF"
ip -4 route
