use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Complete Bluefin installation from Live CD
#
# This is a single test that handles the entire installation flow:
# 1. Boot Live CD to desktop
# 2. Click Install Bluefin icon
# 3. Complete Anaconda installation
# 4. Reboot into installed system
#
# Required needles:
# - welcome_dialog OR install_icon - Must show the Welcome dialog, not just desktop
# - install_icon (with click_point)
# - anaconda_welcome, language_selection, installer_ready
# - anaconda_initializing, installer_loading (optional)
# - anaconda_date_time, date_and_time (optional)
# - anaconda_installation_method, disk_selection, use_entire_disk
# - anaconda_storage_config, encryption_option
# - anaconda_review, review_and_install, ready_to_install
# - anaconda_installing, installation_progress, software_installation
# - anaconda_complete, installation_complete, successfully_installed, reboot_ready
# - gnome_initial_setup, firstboot_welcome, firstboot_keyboard, firstboot_privacy
# - firstboot_timezone, firstboot_about_you (GNOME Initial Setup)
# - gdm_login_screen

sub run {
    my $self = shift;

    # Shorter timeouts for needle creation - increase once needles are ready
    my $boot_timeout = get_var('BOOT_TIMEOUT', 180);
    my $install_timeout = get_var('INSTALL_TIMEOUT', 1800);

    # === PHASE 1: Boot Live CD ===
    record_info 'Phase 1', 'Booting Live CD...';

    # Wait specifically for the Welcome dialog with "Install Bluefin..." button
    # DO NOT accept just 'live_desktop' - we must see the Welcome dialog before proceeding
    # The Welcome dialog appears after the desktop loads, may take a few seconds
    assert_screen ['install_icon', 'welcome_dialog'], $boot_timeout;
    record_info 'Live', 'Welcome dialog visible';

    # === PHASE 2: Launch Installer ===
    record_info 'Phase 2', 'Launching Anaconda installer...';

    # Click the "Install Bluefin..." button in the Welcome dialog
    # The needle has click_point set to the button coordinates
    assert_and_click ['install_icon', 'welcome_dialog'], timeout => 30;
    sleep 2;

    # Keyboard fallback: Try Enter first (Install button is default/focused)
    # DO NOT use Tab - it moves focus to "Not Now" button
    send_key 'ret';
    sleep 5;  # Wait for Anaconda to start

    # May see initializing/loading screen first
    if (check_screen ['anaconda_initializing', 'installer_loading'], 30) {
        record_info 'Loading', 'Anaconda is initializing...';
        # Wait for it to finish loading
        assert_screen ['anaconda_welcome', 'language_selection', 'installer_ready'], 120;
    }

    # === PHASE 3: Configure Installation ===
    record_info 'Phase 3', 'Configuring installation...';

    # Anaconda Welcome - language selection
    # Click the Next button using the needle click_point
    assert_screen ['anaconda_welcome', 'language_selection', 'installer_ready'], 60;
    assert_and_click 'anaconda_welcome', timeout => 30;
    sleep 1;
    send_key 'ret';  # Fallback for GTK click issues
    sleep 3;

    # Date and time screen (may appear)
    if (check_screen ['anaconda_date_time', 'date_and_time'], 15) {
        record_info 'Date/Time', 'Date and time screen detected';
        assert_and_click 'anaconda_date_time', timeout => 30;
        sleep 1;
        send_key 'ret';
        sleep 2;
    }

    # Installation method - disk selection
    assert_screen ['anaconda_installation_method', 'disk_selection', 'use_entire_disk'], 60;
    record_info 'Disk', 'Selecting installation destination...';
    assert_and_click 'anaconda_installation_method', timeout => 30;
    sleep 1;
    send_key 'ret';
    sleep 2;

    # Storage configuration / encryption option
    if (check_screen ['anaconda_storage_config', 'encryption_option'], 30) {
        record_info 'Storage', 'Storage configuration screen';
        assert_and_click 'anaconda_storage_config', timeout => 30;
        sleep 1;
        send_key 'ret';
        sleep 2;
    }

    # Review and install screen
    assert_screen ['anaconda_review', 'review_and_install', 'ready_to_install'], 120;
    record_info 'Review', 'At review screen';

    # === PHASE 4: Install ===
    record_info 'Phase 4', 'Starting installation...';

    # Click Begin Installation button
    assert_and_click 'anaconda_review', timeout => 30;
    sleep 1;
    send_key 'ret';  # Fallback for GTK click issues

    # Wait for installation progress
    assert_screen ['anaconda_installing', 'installation_progress', 'software_installation'], 60;
    record_info 'Installing', 'Installation in progress...';

    # Wait for installation to complete (this takes a while)
    # Include negative tags to detect failures quickly
    assert_screen ['anaconda_complete', 'installation_complete', 'successfully_installed', 'reboot_ready', 'installation_failed', 'anaconda_error'], $install_timeout;

    # Check if we matched an error screen - fail fast
    if (match_has_tag('installation_failed') || match_has_tag('anaconda_error')) {
        die "Installation failed - error screen detected. Check screenshots for details.";
    }
    record_info 'Done', 'Installation complete';

    # === PHASE 5: Reboot ===
    record_info 'Phase 5', 'Rebooting into installed system...';

    # Click "Exit to live desktop" button
    assert_and_click 'reboot_ready', timeout => 60;
    sleep 1;
    send_key 'ret';  # Fallback for GTK click issues
    sleep 3;

    # The button exits to live desktop, so we need to reboot via terminal
    # Open terminal with Super+T or via app menu
    send_key 'super';
    sleep 2;
    type_string "terminal\n";
    sleep 3;

    # Reboot the system
    type_string "sudo reboot\n";
    sleep 10;

    # Eject live ISO so we boot from disk
    eject_cd;

    # Handle MOK (Machine Owner Key) management screen if Secure Boot is enabled
    # This blue screen appears with "Continue boot" selected
    if (check_screen ['mok_management', 'continue_boot', 'secure_boot'], 60) {
        record_info 'MOK', 'MOK management screen detected, continuing boot';
        send_key 'ret';
        sleep 5;
    }

    # Handle GRUB on reboot
    if (check_screen 'grub_menu', 90) {
        send_key 'ret';
    }

    # After reboot, we may see GNOME Initial Setup or GDM
    assert_screen ['gnome_initial_setup', 'firstboot_welcome', 'gdm_login_screen'], $boot_timeout;

    # Handle GNOME Initial Setup if present
    # IMPORTANT: GNOME Initial Setup requires Alt+N to advance screens (Enter doesn't work)
    if (match_has_tag('gnome_initial_setup') || match_has_tag('firstboot_welcome')) {
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
        # Try clicking Skip button at known coordinates (center-left of dialog)
        record_info 'Tour', 'Dismissing Welcome to Bluefin tour dialog';
        mouse_set(500, 420);
        mouse_click;
        sleep 2;

        # Alternative: press Escape to close the dialog
        send_key 'esc';
        sleep 2;

        # Wait for desktop to be fully visible
        wait_still_screen(stilltime => 3, timeout => 30, similarity_level => 40);
    }

    record_info 'Success', 'Installed system booted to desktop';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
