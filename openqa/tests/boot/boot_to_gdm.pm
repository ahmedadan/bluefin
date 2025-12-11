use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Boot Bluefin from ISO/image to GDM login screen
#
# This test validates that:
# 1. GRUB bootloader appears (or auto-boots)
# 2. System boots successfully
# 3. GDM login screen is reached
#
# Required needles:
# - grub_menu (optional, may auto-boot)
# - gdm_login_screen

sub run {
    my $self = shift;

    my $boot_timeout = get_var('BOOT_TIMEOUT', 300);

    # Handle GRUB bootloader if present
    # Some setups auto-boot, so this is optional
    if (check_screen 'grub_menu', 30) {
        # GRUB menu visible - select first entry (default Bluefin)
        record_info 'GRUB', 'GRUB bootloader detected';

        # Wait a moment for menu to be responsive
        wait_still_screen 2;

        # Press enter to boot default entry
        send_key 'ret';
    }
    else {
        record_info 'Auto-boot', 'No GRUB menu detected, assuming auto-boot';
    }

    # Wait for GDM login screen
    # This is the main assertion - system must reach GDM
    record_info 'Waiting', 'Waiting for GDM login screen...';

    assert_screen 'gdm_login_screen', $boot_timeout;

    # GDM has animations, wait for screen to settle
    wait_still_screen(stilltime => 5, timeout => 30, similarity_level => 40);

    # Verify we're really at GDM (not a transient splash)
    assert_screen 'gdm_login_screen', 10;

    record_info 'Success', 'Bluefin booted successfully to GDM';
}

sub test_flags {
    # fatal: if this fails, subsequent tests should not run
    # milestone: save VM state after this test for restart
    return { fatal => 1, milestone => 1 };
}

1;
