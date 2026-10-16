# NVIDIA first-boot service for a Cubic Ubuntu 24.04.4 ISO

## What it does
- Adds a systemd oneshot service to the Cubic custom-root.
- At the first boot of the INSTALLED Ubuntu system, scans PCI sysfs for an NVIDIA display-class device (vendor 0x10de).
- If no NVIDIA display GPU is present, records that result and exits without installing packages.
- If an NVIDIA GPU is present, runs apt-get update and `ubuntu-drivers install` to let Ubuntu choose the recommended driver.
- Marks successful/no-NVIDIA runs as complete so it only runs once. If APT/driver installation fails, it leaves no completion marker; the next boot can retry.
- It skips the live ISO session (`boot=casper`).

## Install into the active Cubic project's custom-root from the HOST Ubuntu terminal:
```bash
cd ~/Downloads
chmod +x deploy-nvidia-firstboot-iso.sh
sudo ./deploy-nvidia-firstboot-iso.sh "$HOME/ubuntu-iso-build/cubic-project/custom-root"
```
Without an argument the script uses `~/ubuntu-iso-build/cubic-project/custom-root` of the user who ran `sudo` (the same project path as `prepare-cubic-env-host.sh` and `iso.md`). If Cubic's active custom-root is elsewhere, pass that directory instead.

Then rebuild the ISO in Cubic. This script only adds the service; it does not build the ISO. See `iso.md` for the optional unit override that runs the driver installation in the background.

### After installing Ubuntu from that ISO:
- Internet access is required for APT/driver download.
- Check log: /var/log/nvidia-firstboot.log
- Check state: /var/lib/nvidia-firstboot/result and /var/lib/nvidia-firstboot/done
- Reboot after successful driver installation.
- Official Ubuntu driver selection guide: https://ubuntu.com/desktop/docs/en/latest/how-to/graphics/install-nvidia-drivers/

## <span style="color: red">Caution</span>:
Test the generated ISO in a VM and then on target hardware. The service runs only after Ubuntu is installed; it cannot fix a black screen that occurs before the installer starts. Secure Boot and driver-module compatibility still need validation on the target computer.
