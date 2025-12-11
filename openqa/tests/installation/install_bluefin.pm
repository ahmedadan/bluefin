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
# - live_desktop
# - install_icon (with click_point)
# - anaconda_continue (with click_point)
# - anaconda_hub
# - anaconda_destination (with click_point)
# - anaconda_select_disk (with click_point) - click on disk icon
# - anaconda_done (with click_point)
# - anaconda_hub_ready
# - anaconda_begin_install (with click_point)
# - anaconda_complete
# - anaconda_reboot (with click_point)
# - gdm_login_screen

sub run {
    my $self = shift;

    # Shorter timeouts for needle creation - increase once needles are ready
    my $boot_timeout = get_var('BOOT_TIMEOUT', 180);
    my $install_timeout = get_var('INSTALL_TIMEOUT', 1800);

    # === PHASE 1: Boot Live CD ===
    record_info 'Phase 1', 'Booting Live CD...';

    # Wait for Live desktop
    assert_screen 'live_desktop', $boot_timeout;
    record_info 'Live', 'Live desktop reached';

    # === PHASE 2: Configure Installation ===
    record_info 'Phase 2', 'Configuring installation...';

    # Click Install Bluefin icon on desktop
    assert_and_click 'install_icon', timeout => 60;
    sleep 5;  # Wait for Anaconda to start

    # Click Continue (language selection on Anaconda Welcome screen)
    assert_and_click 'anaconda_continue', timeout => 60;
    sleep 5;  # Wait for hub to load

    # Wait for Installation Summary hub
    assert_screen 'anaconda_hub', 60;
    sleep 2;  # Cooldown before clicking

    # Click Installation Destination
    assert_and_click 'anaconda_destination', timeout => 60;
    sleep 3;  # Wait for destination screen to load

    # Select the disk
    assert_and_click 'anaconda_select_disk', timeout => 60;
    sleep 2;  # Wait for selection

    # Click Done to confirm disk selection
    assert_and_click 'anaconda_done', timeout => 60;
    sleep 5;  # Wait for hub to reload

    # Wait for hub to be ready (storage configured)
    assert_screen 'anaconda_hub_ready', 60;

    # === PHASE 3: Install ===
    record_info 'Phase 3', 'Starting installation...';

    assert_and_click 'anaconda_begin_install', timeout => 60;

    # Wait for installation to complete (this takes a while)
    assert_screen 'anaconda_complete', $install_timeout;
    record_info 'Done', 'Installation complete';

    # === PHASE 4: Reboot ===
    record_info 'Phase 4', 'Rebooting into installed system...';

    assert_and_click 'anaconda_reboot', timeout => 60;

    # Handle GRUB on reboot
    if (check_screen 'grub_menu', 60) {
        send_key 'ret';
    }

    # Wait for GDM login screen
    assert_screen 'gdm_login_screen', $boot_timeout;
    record_info 'Success', 'Installed system booted to GDM';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
