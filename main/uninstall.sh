#!/bin/bash

# NVIDIA Suspend Fix Uninstaller for Ubuntu 25.04

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

echo "Uninstalling NVIDIA suspend fix..."

# Disable and stop services
echo "Disabling services..."
systemctl disable gnome-shell-suspend.service 2>/dev/null || true
systemctl disable gnome-shell-resume.service 2>/dev/null || true
systemctl stop gnome-shell-suspend.service 2>/dev/null || true
systemctl stop gnome-shell-resume.service 2>/dev/null || true

# Remove files
echo "Removing files..."
rm -f /usr/local/bin/suspend-gnome-shell.sh
rm -f /etc/systemd/system/gnome-shell-suspend.service
rm -f /etc/systemd/system/gnome-shell-resume.service

# Reload systemd
echo "Reloading systemd..."
systemctl daemon-reload

echo ""
echo "✓ Uninstall complete!"
echo ""
echo "The NVIDIA suspend fix has been removed."
echo "Your system will now use default suspend behavior."
