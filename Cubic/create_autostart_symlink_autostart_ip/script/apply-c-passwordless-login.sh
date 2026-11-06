#!/usr/bin/env bash
set -Eeuo pipefail

# Install first-boot automatic-login + passwordless sudo configuration into a Cubic custom-root.
# Usage: sudo -E bash apply-c-passwordless-login.sh "$ROOT"

ROOT="${1:-}"
if [[ -z "$ROOT" ]]; then
    echo "Usage: sudo -E bash $0 \"\$ROOT\"" >&2
    echo "Khai báo biến ROOT trước: ROOT=\"/path/to/custom-root\"" >&2
    exit 2
fi

ROOT="$(realpath -m "$ROOT")"
if [[ ! -f "$ROOT/etc/os-release" || ! -d "$ROOT/etc" || ! -d "$ROOT/usr" ]]; then
    echo "ERROR: '$ROOT' does not look like a valid custom-root." >&2
    exit 1
fi
if [[ $EUID -ne 0 ]]; then
    echo "ERROR: Run with sudo/root so files can be written." >&2
    exit 1
fi

TARGET_SCRIPT="$ROOT/usr/local/sbin/c-configure-autologin-nopasswd.sh"
TARGET_UNIT="$ROOT/etc/systemd/system/c-configure-autologin-nopasswd.service"
TARGET_WANTS="$ROOT/etc/systemd/system/multi-user.target.wants/c-configure-autologin-nopasswd.service"

install -d -o root -g root -m 0755 "$ROOT/usr/local/sbin"
install -d -o root -g root -m 0755 "$ROOT/etc/systemd/system/multi-user.target.wants"

cat > "$TARGET_SCRIPT" <<'TARGET'
#!/usr/bin/env bash
set -Eeuo pipefail

LOG=/var/log/c-configure-autologin-nopasswd.log
exec >>"$LOG" 2>&1

echo "===== configure login/sudo: $(date -Is) ====="

# Do not change the live session. On an installed system, / will not be casper/overlay.
if grep -qw 'boot=casper' /proc/cmdline 2>/dev/null || [[ -d /run/casper ]]; then
    echo "Live session detected; skip."
    exit 0
fi
ROOT_FS="$(findmnt -n -o FSTYPE / 2>/dev/null || true)"
if [[ "$ROOT_FS" == overlay || "$ROOT_FS" == squashfs || "$ROOT_FS" == aufs ]]; then
    echo "Live/immutable root detected ($ROOT_FS); skip."
    exit 0
fi

# Run only once after installation.
if [[ -f /var/lib/c-configure-autologin-nopasswd.done ]]; then
    echo "Already configured; skip."
    systemctl disable c-configure-autologin-nopasswd.service >/dev/null 2>&1 || true
    exit 0
fi

# Pick the first ordinary user with a conventional /home/<name> directory.
USERNAME="$(awk -F: '$3 >= 1000 && $3 < 60000 && $6 ~ /^\/home\/[^/]+$/ && $7 !~ /(nologin|false)$/ {print $1; exit}' /etc/passwd)"
if [[ -z "$USERNAME" || ! -d "/home/$USERNAME" ]]; then
    echo "ERROR: No normal user found in /etc/passwd with a /home/<user> directory."
    exit 1
fi
if [[ ! "$USERNAME" =~ ^[a-z_][a-z0-9_-]*\$?$ ]]; then
    echo "ERROR: Username '$USERNAME' is not safe for a sudoers entry."
    exit 1
fi

echo "Target user: $USERNAME"

# Configure GDM automatic login. Ubuntu Desktop 24.04 normally uses /etc/gdm3/custom.conf.
if [[ -d /etc/gdm3 ]]; then
    GDM_CONF=/etc/gdm3/custom.conf
elif [[ -d /etc/gdm ]]; then
    GDM_CONF=/etc/gdm/custom.conf
else
    echo "ERROR: GDM configuration directory not found; is this Ubuntu Desktop?"
    exit 1
fi

install -d -o root -g root -m 0755 "$(dirname "$GDM_CONF")"
if [[ ! -f "$GDM_CONF" ]]; then
    printf '[daemon]\n' > "$GDM_CONF"
    chown root:root "$GDM_CONF"
    chmod 0644 "$GDM_CONF"
fi
if [[ ! -f "${GDM_CONF}.pre-c" ]]; then
    cp -a "$GDM_CONF" "${GDM_CONF}.pre-c"
fi
TMP_CONF="$(mktemp)"
awk -v user="$USERNAME" '
function add_auto_login() {
    print "AutomaticLoginEnable = True"
    print "AutomaticLogin = " user
    inserted = 1
}
BEGIN { in_daemon = 0; found_daemon = 0; inserted = 0 }
/^\[[^]]+\][[:space:]]*$/ {
    if (in_daemon && !inserted) add_auto_login()
    in_daemon = ($0 ~ /^\[daemon\][[:space:]]*$/)
    if (in_daemon) found_daemon = 1
    print
    next
}
in_daemon && /^[[:space:]]*#?[[:space:]]*AutomaticLoginEnable[[:space:]]*=/ { next }
in_daemon && /^[[:space:]]*#?[[:space:]]*AutomaticLogin[[:space:]]*=/ { next }
{ print }
END {
    if (!found_daemon) {
        print ""
        print "[daemon]"
        add_auto_login()
    } else if (in_daemon && !inserted) {
        add_auto_login()
    }
}
' "$GDM_CONF" > "$TMP_CONF"
install -o root -g root -m 0644 "$TMP_CONF" "$GDM_CONF"
rm -f "$TMP_CONF"

echo "Automatic login configured in $GDM_CONF"

# Passwordless sudo for the selected account only. The account password itself remains set.
if ! command -v visudo >/dev/null 2>&1; then
    echo "ERROR: visudo is missing; install the sudo package in the target image."
    exit 1
fi
SUDOERS_FILE="/etc/sudoers.d/90-c-nopasswd-${USERNAME}"
TMP_SUDOERS="$(mktemp)"
printf '%s ALL=(ALL:ALL) NOPASSWD:ALL\n' "$USERNAME" > "$TMP_SUDOERS"
chown root:root "$TMP_SUDOERS"
chmod 0440 "$TMP_SUDOERS"
if ! visudo -cf "$TMP_SUDOERS" >/dev/null; then
    rm -f "$TMP_SUDOERS"
    echo "ERROR: Generated sudoers rule did not pass visudo validation."
    exit 1
fi
install -o root -g root -m 0440 "$TMP_SUDOERS" "$SUDOERS_FILE"
rm -f "$TMP_SUDOERS"
if ! visudo -c >/dev/null 2>&1; then
    rm -f "$SUDOERS_FILE"
    echo "ERROR: Full sudoers configuration failed validation; custom rule removed."
    exit 1
fi

echo "Passwordless sudo configured for $USERNAME (NOPASSWD:ALL)."
mkdir -p /var/lib
touch /var/lib/c-configure-autologin-nopasswd.done
systemctl disable c-configure-autologin-nopasswd.service >/dev/null 2>&1 || true
echo "SUCCESS: automatic login and passwordless sudo configured for $USERNAME."
TARGET

chmod 0755 "$TARGET_SCRIPT"
chown root:root "$TARGET_SCRIPT"

cat > "$TARGET_UNIT" <<'UNIT'
[Unit]
Description=Configure GDM automatic login and passwordless sudo on first installed boot
After=local-fs.target
Before=display-manager.service

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/c-configure-autologin-nopasswd.sh
TimeoutStartSec=90

[Install]
WantedBy=multi-user.target
UNIT
chmod 0644 "$TARGET_UNIT"
chown root:root "$TARGET_UNIT"

ln -sfn ../c-configure-autologin-nopasswd.service "$TARGET_WANTS"

# Avoid racing with the earlier auto-login-only service suggested in the conversation.
rm -f \
  "$ROOT/etc/systemd/system/multi-user.target.wants/configure-gdm-autologin.service" \
  "$ROOT/etc/systemd/system/configure-gdm-autologin.service"

# Validate the generated in-target script syntax and unit presence.
bash -n "$TARGET_SCRIPT"

echo
 echo "Prepared passwordless desktop login + sudo for Cubic root: $ROOT"
echo "Files installed:"
printf '  %s\n  %s\n  %s\n' "$TARGET_SCRIPT" "$TARGET_UNIT" "$TARGET_WANTS"
echo
 echo "Next: rebuild ISO in Cubic, install it to a test VM, then check:"
echo "  cat /var/log/c-configure-autologin-nopasswd.log"
echo "  sudo -n true && echo 'sudo passwordless OK'"
echo "  grep -E 'AutomaticLogin(Enable)?[[:space:]]*=' /etc/gdm3/custom.conf"
echo
 echo "Security: this config skips the graphical login prompt and allows the selected user to run any sudo command without a password. The user's account password is not deleted."
