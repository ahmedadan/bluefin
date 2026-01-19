#!/usr/bin/perl
# OpenQA test distribution entry point for Bluefin

use strict;
use warnings;
use testapi;
use autotest;
use needle;

# Initialize needle directory
my $needles_dir = get_var('NEEDLES_DIR', '/var/lib/openqa/tests/bluefin/needles');
needle::init($needles_dir);

# Add library path
unshift @INC, '/var/lib/openqa/tests/bluefin/lib';

# Get test configuration
my $test_suite = get_var('TEST_SUITE', 'install_bluefin');

# Define test suites
my %test_suites = (
    # Quick smoke tests
    'boot_live' => [
        'boot/boot_live_desktop',
    ],
    'boot_to_gdm' => [
        'boot/boot_to_gdm',
    ],

    # Full installation flow
    'install_bluefin' => [
        'installation/install_bluefin',
    ],

    # Modular installation (for debugging/development)
    'install_step_by_step' => [
        'boot/boot_live_desktop',
        'installation/start_install',
        'installation/anaconda_install',
        'installation/reboot_installed',
        'firstboot/gnome_initial_setup',
        'boot/boot_to_gdm',
        'boot/gdm_login',
    ],

    # Desktop verification
    'verify_desktop' => [
        'boot/boot_to_gdm',
        'boot/gdm_login',
        'boot/check_desktop',
    ],

    # Start installation from Live desktop
    'start_install' => [
        'installation/start_install',
    ],
);

# Load tests
my $tests = $test_suites{$test_suite};
if (!$tests) {
    die "Unknown test suite: $test_suite. Available: " . join(', ', keys %test_suites);
}

for my $test (@$tests) {
    autotest::loadtest("tests/$test.pm");
}

1;
