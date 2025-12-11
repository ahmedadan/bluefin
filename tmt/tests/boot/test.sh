#!/bin/bash
set -euo pipefail

# Check system booted
systemctl is-system-running --wait || systemctl is-system-running | grep -E "(running|degraded)"

# Check bootc status
bootc status

# Check ostree deployment
rpm-ostree status

echo "PASS: System booted successfully"
