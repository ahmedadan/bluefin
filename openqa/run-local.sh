#!/bin/bash
# Quick helper script to run OpenQA tests locally

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  start     - Start OpenQA containers"
    echo "  stop      - Stop OpenQA containers"
    echo "  logs      - View container logs"
    echo "  setup     - Load job templates (run once after start)"
    echo "  test      - Create a test job (requires ISO in assets/)"
    echo "  testdirect [suite] - Create job (suites: boot_live, install_bluefin, boot_to_gdm)"
    echo "  status    - Check container status"
    echo ""
    echo "Prerequisites:"
    echo "  - Place Bluefin ISO in assets/ directory"
    echo "  - Ensure /dev/kvm is available"
}

check_iso() {
    if ! ls assets/*.iso 1>/dev/null 2>&1; then
        echo "Error: No ISO found in assets/ directory"
        echo "Download a Bluefin ISO and place it in: $SCRIPT_DIR/assets/"
        exit 1
    fi
}

start() {
    echo "Starting OpenQA containers..."
    check_iso

    if command -v podman-compose &>/dev/null; then
        podman-compose up -d
    elif command -v docker &>/dev/null; then
        docker compose up -d
    else
        echo "Error: Neither podman-compose nor docker found"
        exit 1
    fi

    echo ""
    echo "OpenQA is starting..."
    echo "Web UI will be available at: http://localhost:9526"
    echo ""
    echo "Run '$0 test' to create a test job once containers are ready"
}

stop() {
    echo "Stopping OpenQA containers..."
    if command -v podman-compose &>/dev/null; then
        podman-compose down
    elif command -v docker &>/dev/null; then
        docker compose down
    fi
}

logs() {
    if command -v podman-compose &>/dev/null; then
        podman-compose logs -f
    elif command -v docker &>/dev/null; then
        docker compose logs -f
    fi
}

status() {
    if command -v podman &>/dev/null; then
        podman ps -a --filter name=openqa
    elif command -v docker &>/dev/null; then
        docker ps -a --filter name=openqa
    fi
}

get_api_keys() {
    # Get API keys from running container
    if podman exec openqa cat /etc/openqa/client.conf 2>/dev/null | grep -q "key"; then
        API_KEY=$(podman exec openqa grep "^key" /etc/openqa/client.conf | cut -d= -f2 | tr -d ' ')
        API_SECRET=$(podman exec openqa grep "^secret" /etc/openqa/client.conf | cut -d= -f2 | tr -d ' ')
    else
        echo "Error: Cannot get API keys from container. Is openqa running?"
        exit 1
    fi
}

create_test() {
    check_iso
    get_api_keys

    ISO_FILE=$(ls assets/*.iso | head -1 | xargs basename)

    echo "Creating test job with ISO: $ISO_FILE"

    # Use openqa-cli from inside the container
    podman exec openqa openqa-cli api \
        -X POST isos \
        ISO="$ISO_FILE" \
        DISTRI=bluefin \
        VERSION=latest \
        FLAVOR=default \
        ARCH=x86_64 \
        TEST=boot_to_gdm

    echo ""
    echo "Job created! View at: http://localhost:9526"
}

setup_templates() {
    echo "Loading job templates..."

    # Copy templates file into container and load it
    podman cp "$SCRIPT_DIR/templates.fif.json" openqa:/tmp/templates.fif.json

    podman exec openqa openqa-cli api \
        -X POST job_templates_scheduling \
        --param-file /tmp/templates.fif.json

    echo "Templates loaded!"
}

create_test_direct() {
    check_iso

    ISO_FILE=$(ls assets/*.iso | head -1 | xargs basename)
    TEST_SUITE="${2:-install_bluefin}"

    echo "Creating test job with ISO: $ISO_FILE, suite: $TEST_SUITE"

    # Create job directly without templates
    podman exec openqa openqa-cli api \
        -X POST jobs \
        ISO="$ISO_FILE" \
        DISTRI=bluefin \
        VERSION=latest \
        FLAVOR=default \
        ARCH=x86_64 \
        BACKEND=qemu \
        QEMUCPUS=2 \
        QEMURAM=4096 \
        HDDSIZEGB=40 \
        UEFI=1 \
        TEST="$TEST_SUITE" \
        TEST_SUITE="$TEST_SUITE" \
        CASEDIR=/var/lib/openqa/tests/bluefin \
        PRODUCTDIR=/var/lib/openqa/tests/bluefin \
        NEEDLES_DIR=/var/lib/openqa/tests/bluefin/needles \
        DESKTOP=gnome \
        USER_LOGIN=bluefin \
        USER_PASSWORD=bluefin

    echo ""
    echo "Job created! View at: http://localhost:9526"
}

case "${1:-}" in
    start)  start ;;
    stop)   stop ;;
    logs)   logs ;;
    setup)  setup_templates ;;
    test)   create_test ;;
    testdirect) create_test_direct "$@" ;;
    status) status ;;
    *)      usage ;;
esac
