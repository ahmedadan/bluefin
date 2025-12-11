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
    # Boot Live CD to desktop only (quick smoke test)
    'boot_live' => [
        'boot/boot_live_desktop',
    ],

    # Full installation - single consolidated test
    'install_bluefin' => [
        'installation/install_bluefin',
    ],

    # Boot already-installed system to GDM
    'boot_to_gdm' => [
        'boot/boot_to_gdm',
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
