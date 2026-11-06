#!/usr/bin/env bash
set -Eeuo pipefail
umask 022

# Deploy first-boot NVIDIA driver setup into an Ubuntu Cubic custom-root.
# Run on the HOST Ubuntu, preferably with Cubic closed.
# Usage: sudo -E bash deploy-nvidia.sh "$ROOT"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo -E bash $0 \"\$ROOT\"" >&2
  exit 1
fi

CALLER="${SUDO_USER:-}"
CALLER_HOME=""
if [[ -n "$CALLER" && "$CALLER" != root ]]; then
  CALLER_HOME="$(getent passwd "$CALLER" | cut -d: -f6)"
fi

ROOT_INPUT="${1:-}"
if [[ -z "$ROOT_INPUT" ]]; then
  if [[ -z "$CALLER_HOME" || ! -d "$CALLER_HOME" ]]; then
    echo "ERROR: Cannot determine your normal user's home directory." >&2
    echo "Pass the Cubic custom-root explicitly as the first argument." >&2
    exit 1
  fi

  # Prefer the project's known conventional path. Otherwise auto-discover a
  # unique custom-root under the calling user's home directory.
  PREFERRED="$CALLER_HOME/ubuntu-iso-build/custom-root"
  if [[ -f "$PREFERRED/etc/os-release" ]]; then
    ROOT_INPUT="$PREFERRED"
  else
    mapfile -t FOUND_ROOTS < <(
      find "$CALLER_HOME" -maxdepth 7 -type f -path '*/custom-root/etc/os-release' -print 2>/dev/null \
        | while IFS= read -r release_file; do dirname "$(dirname "$release_file")"; done \
        | sort -u
    )
    if ((${#FOUND_ROOTS[@]} == 1)); then
      ROOT_INPUT="${FOUND_ROOTS[0]}"
    elif ((${#FOUND_ROOTS[@]} == 0)); then
      echo "ERROR: No Cubic custom-root found under: $CALLER_HOME" >&2
      echo "Usage: sudo bash $0 /full/path/to/custom-root" >&2
      exit 1
    else
      echo "ERROR: Multiple custom-root directories found; refusing to edit an ambiguous project:" >&2
      printf '  %s\n' "${FOUND_ROOTS[@]}" >&2
      echo "Run again with the desired custom-root as the first argument." >&2
      exit 1
    fi
  fi
fi

ROOT="$(readlink -f -- "$ROOT_INPUT")"
HOST_ROOT="$(readlink -f /)"
if [[ -z "$ROOT" || "$ROOT" == "$HOST_ROOT" ]]; then
  echo "ERROR: Refusing to modify the running host root filesystem." >&2
  exit 1
fi
if [[ ! -d "$ROOT/etc" || ! -d "$ROOT/usr" || ! -f "$ROOT/etc/os-release" ]]; then
  echo "ERROR: '$ROOT' does not look like a Linux root filesystem." >&2
  exit 1
fi
if ! grep -Eq '^ID="?ubuntu"?$' "$ROOT/etc/os-release"; then
  echo "ERROR: '$ROOT' does not look like an Ubuntu root filesystem." >&2
  exit 1
fi

# Show which image will be changed and its Ubuntu release.
ROOT_ID="$(grep -E '^(ID|VERSION_ID|VERSION_CODENAME)=' "$ROOT/etc/os-release" || true)"
printf 'Target root: %s\n%s\n' "$ROOT" "$ROOT_ID"

install -d -m 0755 "$ROOT/usr/local/sbin" \
  "$ROOT/etc/systemd/system/multi-user.target.wants"

cat > "$ROOT/usr/local/sbin/nvidia-firstboot-install" <<'INSTALLER'
#!/usr/bin/env bash
set -Eeuo pipefail

STATE_DIR=/var/lib/nvidia-firstboot
LOG_FILE=/var/log/nvidia-firstboot.log
install -d -m 0755 "$STATE_DIR" /var/log
exec >>"$LOG_FILE" 2>&1

log() { printf '[%s] %s\n' "$(date --iso-8601=seconds)" "$*"; }

# Safety guard: never install drivers in the ISO's live environment.
if grep -qwE '(^|[[:space:]])boot=casper([[:space:]]|$)' /proc/cmdline 2>/dev/null; then
  log 'Live ISO environment detected; skipping this run.'
  exit 0
fi

if [[ -e "$STATE_DIR/done" ]]; then
  log 'Already completed; nothing to do.'
  exit 0
fi

# Detect NVIDIA PCI display-class devices; ignore NVIDIA audio devices.
has_nvidia_gpu=0
for dev in /sys/bus/pci/devices/*; do
  [[ -r "$dev/vendor" && -r "$dev/class" ]] || continue
  vendor="$(<"$dev/vendor")"
  class="$(<"$dev/class")"
  if [[ "$vendor" == '0x10de' && "$class" == 0x03* ]]; then
    log "NVIDIA display-class PCI device found: $(basename "$dev") (class=$class)."
    has_nvidia_gpu=1
    break
  fi
done

if (( has_nvidia_gpu == 0 )); then
  log 'No NVIDIA display GPU detected. No packages will be installed.'
  printf 'no-nvidia\n' > "$STATE_DIR/result"
  touch "$STATE_DIR/done"
  exit 0
fi

log 'NVIDIA GPU detected. Updating APT metadata...'
apt-get update

if ! command -v ubuntu-drivers >/dev/null 2>&1; then
  log 'ubuntu-drivers is missing; installing ubuntu-drivers-common.'
  DEBIAN_FRONTEND=noninteractive apt-get install -y ubuntu-drivers-common
fi

log 'Asking Ubuntu to select and install the recommended NVIDIA driver for this machine.'
DEBIAN_FRONTEND=noninteractive ubuntu-drivers install

printf 'nvidia-driver-install-command-succeeded\n' > "$STATE_DIR/result"
touch "$STATE_DIR/done"
touch /var/run/reboot-required 2>/dev/null || true
log 'Driver installation command completed. Reboot to load the kernel module.'
INSTALLER
chmod 0755 "$ROOT/usr/local/sbin/nvidia-firstboot-install"

# The dispatcher schedules actual APT/driver work in a transient background
# unit, so the driver installation does not hold up the desktop startup.
cat > "$ROOT/etc/systemd/system/nvidia-firstboot.service" <<'UNIT'
[Unit]
Description=Schedule NVIDIA first-boot driver detection and installation
Documentation=https://ubuntu.com/server/docs/nvidia-drivers-installation/
Wants=network-online.target
After=network-online.target
ConditionKernelCommandLine=!boot=casper
ConditionPathExists=!/var/lib/nvidia-firstboot/done

[Service]
Type=oneshot
ExecStart=/usr/bin/systemd-run --no-block --collect --unit=nvidia-firstboot-worker.service --property=Type=oneshot --property=Wants=network-online.target --property=After=network-online.target --property=TimeoutStartSec=45min /usr/local/sbin/nvidia-firstboot-install
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
UNIT
chmod 0644 "$ROOT/etc/systemd/system/nvidia-firstboot.service"
ln -sfn ../nvidia-firstboot.service \
  "$ROOT/etc/systemd/system/multi-user.target.wants/nvidia-firstboot.service"

# It is enabled in the target image by the symlink; it is not run while building.
echo
echo "Installed NVIDIA first-boot service in: $ROOT"
echo "Service: $ROOT/etc/systemd/system/nvidia-firstboot.service"
echo "Script:  $ROOT/usr/local/sbin/nvidia-firstboot-install"
echo "GPU detection and driver selection occur on the installed target machine."
echo "The actual driver installation runs as a background systemd worker."
echo "On the installed system: /var/log/nvidia-firstboot.log"
echo "Result/state: /var/lib/nvidia-firstboot/"
