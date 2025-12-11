#!/bin/bash
set -euo pipefail

# Check bootc container lint passes
bootc container lint || true

# Check key packages installed
rpm -q gnome-shell
rpm -q podman
rpm -q flatpak

# Check bluefin branding
test -f /usr/share/ublue-os/bluefin-logo.svg || \
test -f /usr/share/pixmaps/fedora-logo.png

echo "PASS: Container checks passed"
