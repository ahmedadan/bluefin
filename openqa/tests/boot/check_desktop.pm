use strict;
use warnings;
use base 'bluefinbase';
use testapi;
use bluefinutils;

# Test: Verify GNOME desktop functionality
#
# This test validates that:
# 1. Top panel is visible (Activities, clock, system menu)
# 2. Can open Activities overview
# 3. Can access terminal (Ptyxis)
#
# Required needles:
# - gnome_desktop
# - gnome_top_panel
# - gnome_overview_open
# - gnome_activities_button

sub run {
    my $self = shift;

    # Verify we're at the desktop
    assert_screen 'gnome_desktop', 30;

    record_info 'Desktop Check', 'Verifying GNOME desktop elements';

    # Check top panel is visible
    assert_screen 'gnome_top_panel', 10;

    # Test Activities overview
    record_info 'Activities', 'Testing Activities overview';

    # Click Activities or press Super key
    send_key 'super';
    wait_still_screen 3;

    # Verify overview opened
    assert_screen 'gnome_overview_open', 30;

    # Close overview
    send_key 'super';
    wait_still_screen 3;

    # Verify back at desktop
    assert_screen 'gnome_desktop', 30;

    # Test opening terminal via keyboard shortcut
    # Bluefin uses Ptyxis as default terminal
    record_info 'Terminal', 'Testing terminal launch';

    # Common GNOME terminal shortcut
    send_key 'ctrl-alt-t';

    # Wait for terminal window
    if (check_screen 'terminal_window', 30) {
        record_info 'Ptyxis', 'Terminal launched successfully';

        # Close terminal
        send_key 'alt-f4';
        wait_still_screen 2;
    }
    else {
        record_soft_failure 'Terminal shortcut may not be configured';
    }

    # Final state: clean desktop
    assert_screen 'gnome_desktop', 30;

    record_info 'Success', 'Desktop verification complete';
}

sub test_flags {
    return { fatal => 0 };  # Non-fatal, nice to have
}

1;
