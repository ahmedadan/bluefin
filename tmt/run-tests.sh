#!/bin/bash
set -euo pipefail

# TMT test runner for Bluefin
# Usage: ./run-tests.sh [plan] [image]
#   plan:  boot, services, container, or all (default: all)
#   image: container image to test (default: ghcr.io/ublue-os/bluefin:stable)

PLAN="${1:-all}"
IMAGE="${2:-ghcr.io/ublue-os/bluefin:stable}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check tmt is installed
if ! command -v tmt &> /dev/null; then
    echo "tmt not found. Install with:"
    echo "  pipx install 'tmt[provision-bootc,provision-container]'"
    exit 1
fi

cd "$SCRIPT_DIR"

case "$PLAN" in
    boot)
        echo "Running boot tests with image: $IMAGE"
        tmt run --all \
            plan --name boot \
            provision --how bootc --container-image "$IMAGE"
        ;;
    services)
        echo "Running services tests with image: $IMAGE"
        tmt run --all \
            plan --name services \
            provision --how bootc --container-image "$IMAGE"
        ;;
    container)
        echo "Running container tests with image: $IMAGE"
        tmt run --all \
            plan --name container \
            provision --how container --image "$IMAGE"
        ;;
    all)
        echo "Running all tests with image: $IMAGE"
        tmt run --all \
            provision --how bootc --container-image "$IMAGE"
        ;;
    *)
        echo "Unknown plan: $PLAN"
        echo "Usage: $0 [boot|services|container|all] [image]"
        exit 1
        ;;
esac
