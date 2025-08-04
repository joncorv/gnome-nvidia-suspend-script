#!/bin/bash

# Complete NVIDIA Suspend Fix for Ubuntu 25.04
# Handles both logged-in users and login screen

if [[ $EUID -ne 0 ]]; then
    echo "Please run as root: sudo $0"
    exit 1
fi

echo "Installing complete NVIDIA suspend fix..."

# 1. Create gnome-shell suspend/resume script
echo "Creating /usr/local/bin/suspend-gnome-shell.sh"
cat >/usr/local/bin/suspend-gnome-shell.sh <<'EOF'
#!/bin/bash
case "$1" in
suspend)
    killall -STOP gnome-shell 2>/dev/null || true
    ;;
resume)
    killall -CONT gnome-shell 2>/dev/null || true
    ;;
esac
EOF
chmod +x /usr/local/bin/suspend-gnome-shell.sh

# 2. Create gnome-shell suspend service
echo "Creating /etc/systemd/system/gnome-shell-suspend.service"
cat >/etc/systemd/system/gnome-shell-suspend.service <<'EOF'
[Unit]
Description=Suspend gnome-shell
Before=systemd-suspend.service
Before=systemd-hibernate.service
Before=nvidia-suspend.service
Before=nvidia-hibernate.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/suspend-gnome-shell.sh suspend

[Install]
WantedBy=systemd-suspend.service
WantedBy=systemd-hibernate.service
EOF

# 3. Create gnome-shell resume service
echo "Creating /etc/systemd/system/gnome-shell-resume.service"
cat >/etc/systemd/system/gnome-shell-resume.service <<'EOF'
[Unit]
Description=Resume gnome-shell
After=systemd-suspend.service
After=systemd-hibernate.service
After=nvidia-resume.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/suspend-gnome-shell.sh resume

[Install]
WantedBy=systemd-suspend.service
WantedBy=systemd-hibernate.service
EOF

# 4. Create login screen auto-shutdown script
echo "Creating /usr/local/bin/gdm-auto-shutdown.sh"
cat >/usr/local/bin/gdm-auto-shutdown.sh <<'EOF'
#!/bin/bash
while true; do
    if who | grep -q .; then
        # Someone is logged in, wait 1 minute
        sleep 60
    else
        # No one logged in, wait 20 minutes then shutdown
        sleep 1200
        if ! who | grep -q .; then
            shutdown -h now
        fi
    fi
done
EOF
chmod +x /usr/local/bin/gdm-auto-shutdown.sh

# 5. Create auto-shutdown service
echo "Creating /etc/systemd/system/gdm-auto-shutdown.service"
cat >/etc/systemd/system/gdm-auto-shutdown.service <<'EOF'
[Unit]
Description=Auto shutdown at GDM login screen after 20 minutes
After=gdm3.service

[Service]
Type=simple
ExecStart=/usr/local/bin/gdm-auto-shutdown.sh
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 6. Disable GDM suspend (prevent login screen suspend)
echo "Configuring GDM to disable suspend..."
mkdir -p /etc/dconf/db/gdm.d
cat >/etc/dconf/db/gdm.d/01-disable-suspend <<'EOF'
[org/gnome/settings-daemon/plugins/power]
sleep-inactive-ac-timeout=0
sleep-inactive-battery-timeout=0

[org/gnome/desktop/session]
idle-delay=uint32 1200
EOF

# Update dconf database
dconf update

# 7. Enable all services
echo "Enabling services..."
systemctl daemon-reload
systemctl enable gnome-shell-suspend.service
systemctl enable gnome-shell-resume.service
systemctl enable gdm-auto-shutdown.service

echo ""
echo "✓ Installation complete!"
echo ""
echo "What this fix does:"
echo "  • Pauses gnome-shell before suspend (prevents NVIDIA crash)"
echo "  • Resumes gnome-shell after resume"
echo "  • Disables suspend at login screen"
echo "  • Powers off after 20 minutes at login screen with no activity"
echo ""
echo "Test with: sudo systemctl suspend"
echo ""
echo "To uninstall:"
echo "  sudo systemctl disable gnome-shell-suspend gnome-shell-resume gdm-auto-shutdown"
echo "  sudo rm /usr/local/bin/suspend-gnome-shell.sh"
echo "  sudo rm /usr/local/bin/gdm-auto-shutdown.sh"
echo "  sudo rm /etc/systemd/system/gnome-shell-*.service"
echo "  sudo rm /etc/systemd/system/gdm-auto-shutdown.service"
echo "  sudo rm /etc/dconf/db/gdm.d/01-disable-suspend"
