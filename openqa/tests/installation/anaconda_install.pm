use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Complete Anaconda installation
#
# This handles the Fedora/Bluefin Anaconda installation flow
#
# Required needles:
# - anaconda_welcome
# - anaconda_destination (Installation Destination)
# - anaconda_destination_done
# - anaconda_begin_install
# - anaconda_installing
# - anaconda_complete

sub run {
    my $self = shift;

    my $install_timeout = get_var('INSTALL_TIMEOUT', 1800);  # 30 min default

    # Should be at Anaconda welcome
    assert_screen 'anaconda_welcome', 30;

    # Click Continue (language selection)
    assert_and_click 'anaconda_continue';
    wait_still_screen 5;

    # Installation Summary hub
    assert_screen 'anaconda_hub', 60;

    # Click on Installation Destination
    assert_and_click 'anaconda_destination';
    wait_still_screen 3;

    # Select disk (usually auto-selected for single disk)
    assert_screen 'anaconda_destination_disk', 30;

    # If disk not selected, click it
    if (check_screen 'anaconda_disk_unselected', 5) {
        assert_and_click 'anaconda_disk';
    }

    # Click Done
    assert_and_click 'anaconda_done';
    wait_still_screen 5;

    # Back at hub - may need to wait for storage config
    assert_screen 'anaconda_hub_ready', 120;

    # Begin Installation
    assert_and_click 'anaconda_begin_install';

    # Wait for installation to complete
    record_info 'Installing', 'Installation in progress...';
    assert_screen 'anaconda_complete', $install_timeout;

    record_info 'Complete', 'Installation finished';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
