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
# - live_desktop (GNOME desktop with install icon)

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
    record_info 'Booting', 'Waiting for Live desktop...';

    assert_screen 'live_desktop', $boot_timeout;

    # GNOME might open overview on first boot
    if (match_has_tag 'gnome_overview_open') {
        send_key 'super';
        wait_still_screen 3;
    }

    # Verify we're at the desktop
    assert_screen 'live_desktop', 30;

    record_info 'Success', 'Live desktop reached';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
