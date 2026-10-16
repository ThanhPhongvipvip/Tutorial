#!/usr/bin/env bash
set -Eeuo pipefail

# Deploy a first-boot NVIDIA driver installer into a Cubic custom-root.
# Run this on the host Ubuntu system, NOT inside the ISO's live session.

CALLER_HOME="$(getent passwd "${SUDO_USER:-$USER}" | cut -d: -f6)"
ROOT="${1:-$CALLER_HOME/ubuntu-iso-build/cubic-project/custom-root}"

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo: sudo $0 [PATH_TO_CUBIC_CUSTOM_ROOT]" >&2
  exit 1
fi

if [[ ! -f "$ROOT/etc/os-release" ]]; then
  echo "ERROR: Cannot find $ROOT/etc/os-release" >&2
  echo "Pass the actual Cubic custom-root directory as the first argument." >&2
  exit 1
fi

# Refuse to deploy into the running host by accident.
if [[ "$(readlink -f "$ROOT")" == "/" ]]; then
  echo "ERROR: Refusing to modify the host root filesystem." >&2
  exit 1
fi

if ! grep -q '^ID=ubuntu$' "$ROOT/etc/os-release"; then
  echo "ERROR: $ROOT does not look like an Ubuntu root filesystem." >&2
  exit 1
fi

install -d -m 0755 "$ROOT/usr/local/sbin" \
  "$ROOT/etc/systemd/system/multi-user.target.wants"

cat > "$ROOT/usr/local/sbin/nvidia-firstboot-install" <<'INSTALLER'
#!/usr/bin/env bash
set -Eeuo pipefail

STATE_DIR=/var/lib/nvidia-firstboot
LOG_FILE=/var/log/nvidia-firstboot.log
mkdir -p "$STATE_DIR" /var/log
exec >>"$LOG_FILE" 2>&1

log() { printf '[%s] %s\n' "$(date --iso-8601=seconds)" "$*"; }

# Safety guard: never install drivers in the ISO's live environment.
if grep -qwE '(^|[[:space:]])boot=casper([[:space:]]|$)' /proc/cmdline 2>/dev/null; then
  log 'Live ISO environment detected; skipping. The installed system may run this later.'
  exit 0
fi

if [[ -e "$STATE_DIR/done" ]]; then
  log 'Already completed; nothing to do.'
  exit 0
fi

# Detect only NVIDIA PCI display-class devices (class 0x03xxxx), not NVIDIA audio devices.
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
# If networking or a repository is unavailable, exit without the done marker;
# the systemd oneshot can then retry on a later boot.
apt-get update

if ! command -v ubuntu-drivers >/dev/null 2>&1; then
  log 'ubuntu-drivers is missing; installing ubuntu-drivers-common.'
  DEBIAN_FRONTEND=noninteractive apt-get install -y ubuntu-drivers-common
fi

log 'Asking Ubuntu to select and install the recommended NVIDIA driver.'
DEBIAN_FRONTEND=noninteractive ubuntu-drivers install

printf 'nvidia-driver-install-command-succeeded\n' > "$STATE_DIR/result"
touch "$STATE_DIR/done"
# Signal that a reboot is needed for the kernel module to take effect.
touch /var/run/reboot-required 2>/dev/null || true
log 'Driver installation command completed successfully. Reboot the computer to load the driver.'
INSTALLER
chmod 0755 "$ROOT/usr/local/sbin/nvidia-firstboot-install"

cat > "$ROOT/etc/systemd/system/nvidia-firstboot.service" <<'UNIT'
[Unit]
Description=Detect NVIDIA GPU and install the recommended Ubuntu driver once
Documentation=https://ubuntu.com/desktop/docs/en/latest/how-to/graphics/install-nvidia-drivers/
Wants=network-online.target
After=network-online.target
ConditionKernelCommandLine=!boot=casper
ConditionPathExists=!/var/lib/nvidia-firstboot/done

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/nvidia-firstboot-install
RemainAfterExit=yes
TimeoutStartSec=45min

[Install]
WantedBy=multi-user.target
UNIT
chmod 0644 "$ROOT/etc/systemd/system/nvidia-firstboot.service"
ln -sfn ../nvidia-firstboot.service \
  "$ROOT/etc/systemd/system/multi-user.target.wants/nvidia-firstboot.service"

# Ensure the service is enabled in the target image; do not execute it during build.
echo "Installed NVIDIA first-boot service in: $ROOT"
echo "Service: $ROOT/etc/systemd/system/nvidia-firstboot.service"
echo "Script:  $ROOT/usr/local/sbin/nvidia-firstboot-install"
echo
echo "Next: rebuild the ISO from this Cubic project and test it in a VM/target machine."
echo "On an installed system, log: /var/log/nvidia-firstboot.log"
echo "State: /var/lib/nvidia-firstboot/"

