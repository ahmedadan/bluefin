#!/bin/bash
set -euo pipefail

# Check podman works
podman --version
podman info

# Check key systemd units
systemctl is-enabled NetworkManager
systemctl is-enabled gdm

# Check no failed units (warning only)
failed=$(systemctl --failed --no-legend | wc -l)
if [ "$failed" -gt 0 ]; then
    echo "WARNING: $failed failed systemd units"
    systemctl --failed
fi

echo "PASS: System services verified"
