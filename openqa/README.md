# OpenQA Tests for Bluefin

Automated OS testing for Bluefin using [openQA](https://open.qa/).

## Overview

This directory contains openQA tests that validate Bluefin boots correctly and the GNOME desktop is functional. Tests use virtual machines to simulate real user scenarios.

## Directory Structure

```
openqa/
├── README.md           # This file
├── docker-compose.yml  # Container deployment
├── main.pm             # Test distribution entry point
├── templates.fif.json  # Job templates, machines, products
├── lib/
│   ├── bluefinbase.pm  # Base test class
│   └── bluefinutils.pm # Utility functions
├── tests/
│   └── boot/
│       ├── boot_to_gdm.pm    # Boot to GDM login
│       ├── gdm_login.pm      # Log in via GDM
│       └── check_desktop.pm  # Verify desktop
├── needles/
│   └── boot/           # Reference screenshots (JSON + PNG)
└── assets/             # ISOs go here
```

## Prerequisites

- Podman or Docker
- KVM support (`/dev/kvm`)
- Bluefin ISO image

## Quick Start

### 1. Start OpenQA

```bash
cd openqa/

# Create assets directory and add ISO
mkdir -p assets
cp /path/to/bluefin-latest.iso assets/

# Start containers
podman-compose up -d
# or
docker compose up -d
```

### 2. Access Web UI

Open http://localhost:9526 in your browser.

Default credentials: Admin / opensesame (change immediately)

### 3. Load Job Templates

```bash
# Using openQA client (install with: pip install openqa_client)
openqa-client --host http://localhost:9526 templates.fif.json
```

Or via Web UI: Operator Menu → Job Templates → Upload

### 4. Create Test Job

Via API:
```bash
openqa-client \
  --host http://localhost:9526 \
  isos post \
  ISO=bluefin-latest.iso \
  DISTRI=bluefin \
  VERSION=latest \
  FLAVOR=default \
  ARCH=x86_64 \
  TEST=boot_to_gdm
```

Via Web UI: Operator Menu → Create Job

## Test Suites

| Suite | Description |
|-------|-------------|
| `boot_to_gdm` | Boot to GDM login screen (quick smoke test) |
| `boot_to_desktop` | Boot and log in to GNOME desktop |
| `boot_full` | Full boot test with desktop verification |

## Creating Needles

Needles are reference screenshots used for visual matching. Each needle consists of:
- A PNG screenshot
- A JSON file describing match areas

### Steps to Create a Needle

1. Run a test job
2. When test fails or reaches desired screen, go to job details
3. Click "Create needle" button
4. Draw rectangles around elements to match
5. Add tags (must match tags in test code)
6. Save

### Needle Best Practices

- Use small, distinctive match areas
- Set match percentage 80-95% (lower = more tolerant)
- Tag needles with descriptive names
- Create variant needles for theme differences

## Writing Tests

Test modules inherit from `bluefinbase` and implement `run()`:

```perl
use strict;
use warnings;
use base 'bluefinbase';
use testapi;
use bluefinutils;

sub run {
    my $self = shift;

    # Wait for screen matching needle
    assert_screen 'gdm_login_screen', 300;

    # Type text
    type_string 'password', max_interval => 50;

    # Press key
    send_key 'ret';

    # Log info
    record_info 'Success', 'Test passed';
}

sub test_flags {
    return { fatal => 1 };
}

1;
```

### Key testapi Functions

| Function | Description |
|----------|-------------|
| `assert_screen $tag, $timeout` | Wait for needle match, fail if not found |
| `check_screen $tag, $timeout` | Wait for needle match, return true/false |
| `send_key $key` | Send keyboard key (e.g., 'ret', 'alt-f4') |
| `type_string $text` | Type text |
| `assert_and_click $tag` | Match needle and click matched area |
| `record_info $title, $text` | Log information |
| `upload_logs $path` | Upload file as test artifact |

## Variables

Set these in job templates or when creating jobs:

| Variable | Default | Description |
|----------|---------|-------------|
| `BOOT_TIMEOUT` | 300 | Seconds to wait for boot |
| `DESKTOP_TIMEOUT` | 120 | Seconds to wait for desktop |
| `USER_LOGIN` | bluefin | Username for login |
| `USER_PASSWORD` | bluefin | User password |
| `BLUEFIN_VARIANT` | bluefin | Variant: bluefin, bluefin-dx |

## Troubleshooting

### Tests fail immediately

1. Check ISO path is correct
2. Verify KVM is available: `ls -la /dev/kvm`
3. Check container logs: `podman-compose logs -f worker`

### Needle not matching

1. Check tags in test code match needle tags
2. Adjust match percentage in needle JSON
3. Screen resolution may differ - recreate needle

### VM not starting

1. Ensure nested virtualization is enabled
2. Check SELinux/AppArmor isn't blocking KVM
3. Verify sufficient RAM/CPU for VM

## CI/CD Integration

See `.github/workflows/openqa-tests.yml` (to be created) for GitHub Actions integration.

## References

- [openQA Documentation](https://open.qa/docs)
- [Fedora openQA Tests](https://pagure.io/fedora-qa/os-autoinst-distri-fedora)
- [openSUSE openQA Tests](https://github.com/os-autoinst/os-autoinst-distri-opensuse)
