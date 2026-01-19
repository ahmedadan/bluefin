use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Launch Anaconda installer from Live desktop
#
# Required needles:
# - install_icon (Install Bluefin icon on desktop or Welcome dialog with Install button)
# - anaconda_welcome, language_selection, or installer_ready (Anaconda welcome screen)
# - anaconda_initializing, installer_loading (optional, installer loading screen)

sub run {
    my $self = shift;

    # Wait specifically for install_icon to be visible
    # DO NOT accept just 'live_desktop' - we need the install icon/button visible
    assert_screen 'install_icon', 120;
    wait_still_screen 3, 15;  # Wait for screen stable for 3s, timeout 15s

    record_info 'Install', 'Clicking Install Bluefin icon...';
    wait_still_screen 3, 15;  # Wait for screen stable for 3s, timeout 15s
    assert_and_click 'install_icon', timeout => 30, dclick => 1;

    record_info 'Waiting', 'Waiting for Anaconda installer...';

    # May see initializing/loading screen first
    if (check_screen ['anaconda_initializing', 'installer_loading'], 30) {
        record_info 'Loading', 'Anaconda is initializing...';
    }

    wait_still_screen 3, 15;  # Wait for screen stable for 3s, timeout 15s
    assert_screen ['anaconda_welcome', 'language_selection', 'installer_ready'], 240;

    record_info 'Anaconda', 'Installer launched successfully';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
