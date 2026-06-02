#!@runtimeShell@
set -e -o pipefail
export PATH=@path@

BOOTED_KERNEL=$(readlink -f /run/booted-system/kernel || true)
CURRENT_KERNEL=$(readlink -f /run/current-system/kernel || true)

BOOTED_INITRD=$(readlink -f /run/booted-system/initrd || true)
CURRENT_INITRD=$(readlink -f /run/current-system/initrd || true)

BOOTED_SYSTEMD=$(readlink -f /run/booted-system/systemd || true)
CURRENT_SYSTEMD=$(readlink -f /run/current-system/systemd || true)

REBOOT_NEEDED=false

if [ "$BOOTED_KERNEL" != "$CURRENT_KERNEL" ]; then
  echo "STATUS: Kernel changed (booted: $BOOTED_KERNEL, current: $CURRENT_KERNEL)."
  REBOOT_NEEDED=true
fi

if [ "$BOOTED_INITRD" != "$CURRENT_INITRD" ] && [ -n "$BOOTED_INITRD" ]; then
  echo "STATUS: Initrd changed (booted: $BOOTED_INITRD, current: $CURRENT_INITRD)."
  REBOOT_NEEDED=true
fi

if [ "$BOOTED_SYSTEMD" != "$CURRENT_SYSTEMD" ] && [ -n "$BOOTED_SYSTEMD" ]; then
  echo "STATUS: Systemd changed (booted: $BOOTED_SYSTEMD, current: $CURRENT_SYSTEMD)."
  REBOOT_NEEDED=true
fi

if [ "$REBOOT_NEEDED" = "true" ]; then
  if [ "@autoReboot@" = "true" ]; then
    echo "STATUS: Reboot needed! Triggering reboot..."
    systemctl reboot
  else
    echo "STATUS: Reboot needed but autoReboot is disabled."
  fi
else
  echo "STATUS: No reboot needed."
fi
