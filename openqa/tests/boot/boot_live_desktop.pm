use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Boot Bluefin Live CD to desktop
#
# Live CD auto-logs into a GNOME session (no GDM login required)
#
# Required needles:
# - grub_menu (optional, may auto-boot)
# - welcome_dialog (Bluefin welcome dialog - preferred)
# - live_desktop or live_desktop_ready (GNOME desktop as fallback)
#
# NOTE: This test is for booting to the live desktop, not for installation.
# It accepts live_desktop as valid since we just want to verify boot completed.
# For installation tests, use install_bluefin.pm which waits for welcome_dialog.

sub run {
    my $self = shift;

    my $boot_timeout = get_var('BOOT_TIMEOUT', 300);

    # Handle GRUB bootloader if present
    if (check_screen 'grub_menu', 30) {
        record_info 'GRUB', 'GRUB bootloader detected';
        wait_still_screen 2;
        # Select "Start Bluefin" or first entry
        send_key 'ret';
    }

    # Wait for Live desktop
    # Live CD auto-logs in - we should see GNOME desktop directly
    # Accept welcome_dialog (preferred) or just desktop (boot verification)
    record_info 'Booting', 'Waiting for Live desktop...';

    assert_screen ['welcome_dialog', 'live_desktop', 'live_desktop_ready'], $boot_timeout;

    # Handle Bluefin welcome dialog if it appears
    if (match_has_tag 'welcome_dialog') {
        record_info 'Welcome', 'Welcome dialog detected, closing...';
        send_key 'esc';  # Close the dialog
        sleep 2;
    }

    # GNOME might open overview on first boot
    if (check_screen 'gnome_overview_open', 5) {
        record_info 'Overview', 'GNOME overview detected, closing...';
        send_key 'super';
        sleep 2;
    }

    # Verify we're at a usable desktop state
    wait_still_screen 3;

    record_info 'Success', 'Live desktop reached';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
