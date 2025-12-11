use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Reboot into installed system
#
# Required needles:
# - anaconda_complete
# - anaconda_reboot (Reboot button)
# - gdm_login_screen (after reboot)

sub run {
    my $self = shift;

    my $boot_timeout = get_var('BOOT_TIMEOUT', 300);

    # Should be at installation complete screen
    assert_screen 'anaconda_complete', 30;

    # Click Reboot
    record_info 'Reboot', 'Rebooting into installed system...';
    assert_and_click 'anaconda_reboot';

    # Wait for system to reboot and reach GDM
    # First the live system shuts down, then GRUB, then boot

    # Optionally handle GRUB
    if (check_screen 'grub_menu', 60) {
        send_key 'ret';
    }

    # Wait for GDM login screen
    assert_screen 'gdm_login_screen', $boot_timeout;

    wait_still_screen(stilltime => 5, timeout => 30, similarity_level => 40);

    record_info 'Success', 'Booted into installed system';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
