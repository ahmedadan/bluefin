#!/bin/bash
set -euo pipefail

# Check GNOME Shell is available
rpm -q gnome-shell

# Check GDM is enabled
systemctl is-enabled gdm

# Check GNOME session files exist
test -f /usr/share/gnome-session/sessions/gnome.session

echo "PASS: GNOME desktop components verified"
