#!/bin/bash
set -euo pipefail

# Check flatpak is available
flatpak --version

# Check flatpak remotes configured
flatpak remotes | grep -E "(flathub|fedora)"

# Check terminal is installed
rpm -q gnome-terminal || flatpak info org.gnome.Terminal

echo "PASS: Key applications verified"
