#!/bin/bash

# Complete NVIDIA Suspend Fix for Ubuntu 25.04
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
            killall -STOP gnome-shell
            killall -STOP chrome
            killall -STOP firefox
            ;;
            resume)
            killall -CONT gnome-shell
            killall -CONT chrome
            killall -CONT firefox
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

# 4. Enable services
echo "Enabling services..."
systemctl daemon-reload
systemctl enable gnome-shell-suspend.service
systemctl enable gnome-shell-resume.service

echo ""
echo "✓ Installation complete!"
echo ""
echo "What this fix does:"
echo "  • Pauses gnome-shell and chrome before suspend"
echo "  • Resumes gnome-shell and chrome after resume"
echo "  • Prevents NVIDIA suspend crashes"
echo ""
echo "Test with: sudo systemctl suspend"
echo ""
echo "To uninstall, run: sudo ./uninstall.sh"
echo "Or manually:"
echo "  sudo systemctl disable gnome-shell-suspend gnome-shell-resume"
echo "  sudo rm /usr/local/bin/suspend-gnome-shell.sh"
echo "  sudo rm /etc/systemd/system/gnome-shell-*.service"
