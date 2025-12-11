use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Launch Anaconda installer from Live desktop
#
# Required needles:
# - live_desktop
# - install_icon (Install Bluefin icon on desktop)
# - anaconda_welcome (Anaconda welcome screen)

sub run {
    my $self = shift;

    assert_screen 'live_desktop', 60;
    wait_still_screen 3, 15;  # Wait for screen stable for 3s, timeout 15s

    record_info 'Install', 'Clicking Install Bluefin icon...';
    wait_still_screen 3, 15;  # Wait for screen stable for 3s, timeout 15s
    assert_and_click 'install_icon', timeout => 120, dclick => 1;

    record_info 'Waiting', 'Waiting for Anaconda installer...';
    wait_still_screen 3, 15;  # Wait for screen stable for 3s, timeout 15s
    assert_screen 'anaconda_welcome', 240;

    record_info 'Anaconda', 'Installer launched successfully';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
