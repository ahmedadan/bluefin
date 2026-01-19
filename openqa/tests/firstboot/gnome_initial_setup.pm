use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: GNOME Initial Setup (First Boot Wizard)
#
# Handles the GNOME Initial Setup wizard that appears on first boot after installation.
# This is a reusable module that can be called from various test flows.
#
# Required needles:
# - firstboot_welcome, gnome_initial_setup - Welcome/Language selection
# - firstboot_keyboard, keyboard_layout - Keyboard layout
# - firstboot_privacy, location_services - Privacy settings
# - firstboot_timezone, timezone_selection - Timezone selection
# - firstboot_about_you, user_creation - User creation
# - firstboot_password, password_screen - Password entry
# - firstboot_done, setup_complete, all_done - Setup complete

sub run {
    my $self = shift;

    my $timeout = get_var('FIRSTBOOT_TIMEOUT', 180);

    # Check if we're at GNOME Initial Setup
    assert_screen ['gnome_initial_setup', 'firstboot_welcome'], $timeout;
    record_info 'Initial Setup', 'GNOME Initial Setup detected';

    # Welcome/Language selection - use Alt+N to advance
    record_info 'Welcome', 'Language selection screen';
    send_key 'alt-n';
    sleep 2;

    # Keyboard layout
    if (check_screen ['firstboot_keyboard', 'keyboard_layout'], 30) {
        record_info 'Keyboard', 'Keyboard layout screen';
        send_key 'alt-n';
        sleep 2;
    }

    # Privacy/Location services
    if (check_screen ['firstboot_privacy', 'location_services'], 30) {
        record_info 'Privacy', 'Privacy settings screen';
        send_key 'alt-n';
        sleep 2;
    }

    # Timezone - requires selecting a city before Next works
    if (check_screen ['firstboot_timezone', 'timezone_selection'], 30) {
        record_info 'Timezone', 'Timezone selection screen';
        # Click on the search field (needle has click_point on search input)
        assert_and_click 'firstboot_timezone', timeout => 10;
        sleep 1;
        type_string 'New York';
        sleep 2;
        send_key 'down';  # Select first search result
        sleep 1;
        send_key 'ret';  # Confirm selection
        sleep 1;
        send_key 'alt-n';
        sleep 2;
    }

    # About You - Full Name and Username only (Password is separate screen)
    if (check_screen ['firstboot_about_you', 'user_creation'], 30) {
        record_info 'User', 'About You screen - Full Name';
        my $fullname = get_var('USER_FULLNAME', 'Test User');
        type_string $fullname;
        sleep 2;  # Wait for username to auto-generate
        # Try Alt+N first, then Tab+Enter as fallback
        send_key 'alt-n';
        sleep 1;
        # If still on About You, try Tab to Next button and Enter
        if (check_screen ['firstboot_about_you', 'user_creation'], 3) {
            record_info 'Fallback', 'Alt+N did not work, trying Tab+Enter';
            send_key 'tab';
            send_key 'tab';
            send_key 'tab';  # Tab to Next button
            sleep 1;
            send_key 'ret';
        }
        sleep 2;
    }

    # Password screen - separate from About You
    if (check_screen ['firstboot_password', 'password_screen'], 30) {
        record_info 'Password', 'Password screen';
        my $password = get_var('USER_PASSWORD', 'bluefin123');
        # Type first password
        type_string $password;
        sleep 1;
        # Tab to Confirm Password field
        # Tab order: Password field -> eye icon -> Confirm Password field
        send_key 'tab';  # Skip eye icon on first field
        send_key 'tab';  # Land on Confirm Password field
        sleep 1;
        # Type confirmation password
        type_string $password;
        sleep 1;
        send_key 'alt-n';
        sleep 1;
        # Fallback: Tab to Next and Enter
        if (check_screen ['firstboot_password', 'password_screen'], 3) {
            send_key 'tab';
            send_key 'tab';
            send_key 'ret';
        }
        sleep 3;
    }

    # Setup complete screen
    if (check_screen ['setup_complete', 'firstboot_done', 'all_done'], 30) {
        record_info 'Complete', 'Setup complete screen';
        send_key 'alt-n';  # Start using GNOME
        sleep 5;
    }

    # Wait for desktop to stabilize after setup
    sleep 10;

    # The Welcome to Bluefin tour dialog may appear - dismiss it
    if (check_screen ['desktop_welcome_tour', 'bluefin_tour'], 15) {
        record_info 'Tour', 'Dismissing Welcome to Bluefin tour dialog';
        # Try clicking Skip button at known coordinates (center-left of dialog)
        mouse_set(500, 420);
        mouse_click;
        sleep 2;
    }

    # Alternative: press Escape to close any remaining dialog
    send_key 'esc';
    sleep 2;

    # Wait for desktop to be fully visible
    wait_still_screen(stilltime => 3, timeout => 30, similarity_level => 40);

    record_info 'Success', 'GNOME Initial Setup completed';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
