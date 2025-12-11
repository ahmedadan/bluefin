use strict;
use warnings;
use base 'bluefinbase';
use testapi;
use bluefinutils;

# Test: Log in via GDM to GNOME desktop
#
# This test validates that:
# 1. User can be selected at GDM
# 2. Password entry works
# 3. GNOME desktop session starts
#
# Required needles:
# - gdm_login_screen (from previous test)
# - gdm_password_prompt
# - gnome_desktop

sub run {
    my $self = shift;

    my $user = get_var('USER_LOGIN', 'bluefin');
    my $password = get_var('USER_PASSWORD', 'bluefin');
    my $desktop_timeout = get_var('DESKTOP_TIMEOUT', 120);

    # We should already be at GDM from the previous test
    # But verify just in case
    assert_screen 'gdm_login_screen', 30;

    record_info 'GDM Login', "Logging in as user: $user";

    # GDM user selection
    # For single-user systems, just hit enter
    # For multi-user, look for specific user
    if (check_screen "gdm_user_$user", 5) {
        assert_and_click "gdm_user_$user";
    }
    else {
        # Hit enter to select the displayed user
        # GDM on Bluefin typically shows single user
        send_key 'ret';
    }

    # Wait for password prompt
    assert_screen 'gdm_password_prompt', 30;

    # Small delay before typing (GDM can be sensitive)
    sleep 1;

    # Type password
    type_string $password, max_interval => 50;

    # Submit
    send_key 'ret';

    # Wait for GNOME desktop to load
    # GNOME 40+ may show overview on first login
    record_info 'Desktop', 'Waiting for GNOME desktop...';

    my $count = 5;
    while ($count > 0) {
        $count--;
        assert_screen ['gnome_desktop', 'gnome_overview_open'], $desktop_timeout;

        # If overview is open, close it
        if (match_has_tag 'gnome_overview_open') {
            record_info 'Overview', 'GNOME overview detected, closing...';
            send_key 'super';
            wait_still_screen 3;
        }
        else {
            last;
        }
    }

    # Final verification - we should see the desktop
    assert_screen 'gnome_desktop', 30;

    # Move mouse to avoid interfering with UI elements
    mouse_set(512, 384);

    record_info 'Success', 'Successfully logged in to GNOME desktop';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
