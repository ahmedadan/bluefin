use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Reboot into installed system
#
# Required needles:
# - anaconda_complete, installation_complete, successfully_installed, reboot_ready
# - gnome_initial_setup, firstboot_welcome (GNOME Initial Setup screens)
# - firstboot_keyboard, firstboot_privacy, firstboot_timezone, firstboot_about_you
# - gdm_login_screen (after setup complete)

sub run {
    my $self = shift;

    my $boot_timeout = get_var('BOOT_TIMEOUT', 300);

    # Should be at installation complete screen
    assert_screen ['anaconda_complete', 'installation_complete', 'successfully_installed', 'reboot_ready'], 30;

    # Click Reboot
    record_info 'Reboot', 'Rebooting into installed system...';
    assert_and_click 'reboot_ready';

    # Wait for system to reboot and reach GDM or GNOME Initial Setup
    # First the live system shuts down, then GRUB, then boot

    # Optionally handle GRUB
    if (check_screen 'grub_menu', 60) {
        send_key 'ret';
    }

    # After reboot, we may see GNOME Initial Setup or GDM
    assert_screen ['gnome_initial_setup', 'firstboot_welcome', 'gdm_login_screen'], $boot_timeout;

    # Handle GNOME Initial Setup if present
    # IMPORTANT: GNOME Initial Setup requires Alt+N to advance screens (Enter doesn't work)
    if (match_has_tag('gnome_initial_setup') || match_has_tag('firstboot_welcome')) {
        record_info 'Initial Setup', 'GNOME Initial Setup detected';

        # Welcome/Language selection - use Alt+N to advance
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

        # About You / User creation - Full Name only (password is separate screen)
        if (check_screen ['firstboot_about_you', 'user_creation'], 30) {
            record_info 'User', 'About You screen - Full Name';
            my $fullname = get_var('USER_FULLNAME', 'Test User');
            type_string $fullname;
            sleep 2;  # Wait for username to auto-generate
            send_key 'alt-n';
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
            sleep 3;
        }

        # Setup complete screen
        if (check_screen ['setup_complete', 'firstboot_done', 'all_done'], 30) {
            record_info 'Complete', 'Setup complete screen';
            send_key 'alt-n';  # Start using GNOME
            sleep 5;
        }

        # Complete setup and reach desktop or GDM
        assert_screen ['gdm_login_screen', 'gnome_desktop', 'bluefin_desktop'], 120;
    }

    wait_still_screen(stilltime => 5, timeout => 30, similarity_level => 40);

    record_info 'Success', 'Booted into installed system';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
