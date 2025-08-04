# NVIDIA Suspend Fix for Ubuntu 25.04

A simple solution to fix NVIDIA graphics card suspend/resume crashes on Ubuntu 25.04 with GNOME and Wayland.

## Problem

NVIDIA graphics cards (especially RTX 2080 Ti and similar) crash the system when suspending on Ubuntu 25.04. The system appears to suspend but never resumes, requiring a hard reboot.

**Root Cause:** GNOME Shell and Chrome try to access the NVIDIA driver after it has already been suspended, causing a kernel deadlock.

## Solution

This script implements the proven fix from the Arch Linux community that:

- Pauses GNOME Shell and Chrome before system suspend
- Resumes GNOME Shell and Chrome after system resume
- Prevents suspend crashes with minimal complexity

## Compatibility

- **Tested on:** Ubuntu 25.04 with GNOME + Wayland
- **Graphics:** NVIDIA RTX series (RTX 2080 Ti confirmed working)
- **Desktop:** GNOME Shell with GDM login manager
- **Driver:** NVIDIA open drivers (nvidia-driver-575-open recommended)

## Quick Install

```bash
# Download and run the fix
curl -fsSL https://raw.githubusercontent.com/joncorv/gnome-nvidia-suspend-script/main/install.sh | sudo bash
```

Or manually:

```bash
# Download the script
wget https://raw.githubusercontent.com/joncorv/gnome-nvidia-suspend-script/main/install.sh

# Make executable and run
chmod +x install.sh
sudo ./install.sh
```

## What It Does

### Simple Process Management

- **Before suspend:** Pauses `gnome-shell` and `chrome` processes with `SIGSTOP`
- **After resume:** Resumes `gnome-shell` and `chrome` processes with `SIGCONT`
- **Result:** No more suspend crashes during user sessions

## Files Created

The script creates these files:

```
/usr/local/bin/suspend-gnome-shell.sh          # Process suspend/resume handler
/etc/systemd/system/gnome-shell-suspend.service # Suspend service
/etc/systemd/system/gnome-shell-resume.service  # Resume service
```

## Testing

After installation, test suspend/resume:

```bash
# Test suspend (should work without crashing)
sudo systemctl suspend

# Check service status
systemctl status gnome-shell-suspend.service
systemctl status gnome-shell-resume.service
```

## Uninstall

```bash
# Download and run uninstaller
wget https://raw.githubusercontent.com/[YOUR-USERNAME]/nvidia-suspend-fix/main/uninstall.sh
sudo bash uninstall.sh
```

Or manually:

```bash
sudo systemctl disable gnome-shell-suspend gnome-shell-resume
sudo rm /usr/local/bin/suspend-gnome-shell.sh
sudo rm /etc/systemd/system/gnome-shell-*.service
sudo systemctl daemon-reload
```

## Prerequisites

Before using this fix, ensure you have:

1. **NVIDIA drivers properly installed:**

   ```bash
   sudo ubuntu-drivers autoinstall
   ```

2. **Video memory preservation enabled** in `/etc/modprobe.d/nvidia-drm.conf`:

   ```
   options nvidia-drm modeset=1
   options nvidia NVreg_PreserveVideoMemoryAllocations=1
   options nvidia NVreg_TemporaryFilePath=/var/tmp
   ```

3. **GRUB kernel parameters** in `/etc/default/grub`:

   ```
   GRUB_CMDLINE_LINUX_DEFAULT="quiet splash nouveau.modeset=0 nvidia-drm.modeset=1 mem_sleep_default=deep"
   ```

4. **NVIDIA systemd services enabled:**
   ```bash
   sudo systemctl enable nvidia-suspend nvidia-resume nvidia-hibernate
   ```

## Troubleshooting

### Still Crashing?

- Check logs: `journalctl -b -1 | grep -i nvidia`
- Verify services are running: `systemctl status gnome-shell-suspend`
- Ensure GNOME Shell is running: `pgrep gnome-shell`

### Chrome Not Detected?

- The script targets the `chrome` process name
- For Chromium: `killall -STOP chromium` (modify script if needed)
- For other browsers: Add them to the suspend script

### Login Screen Suspend?

This fix only works when logged in. To prevent login screen suspend:

- Avoid leaving the system at login screen for extended periods
- Or manually disable GDM suspend in system settings

## How It Works

The fix works by preventing the race condition that causes NVIDIA suspend crashes:

1. **Normal suspend flow:** System → NVIDIA driver → GNOME Shell → Suspend
2. **Problem:** GNOME Shell/Chrome try to access suspended NVIDIA driver
3. **Our fix:** System → Pause GNOME Shell & Chrome → NVIDIA driver → Suspend
4. **Resume:** Resume → NVIDIA driver → Resume GNOME Shell & Chrome → System

## Credits

- **Original solution:** [Arch Linux Forums](https://bbs.archlinux.org/viewtopic.php?id=277713)
- **NVIDIA developer insights:** [NVIDIA Developer Forums](https://forums.developer.nvidia.com/t/trouble-suspending-with-510-39-01-linux-5-16-0-freezing-of-tasks-failed-after-20-009-seconds/200933/12)
- **Contributors:** devyn.cairns, gabekings, and the Arch Linux community

## License

MIT License - Feel free to use, modify, and distribute.

## Contributing

Found a bug or improvement? Please open an issue or submit a pull request!

---

**⚠️ Disclaimer:** This fix modifies system suspend behavior. While thoroughly tested, use at your own risk. Always backup your system before making changes.
