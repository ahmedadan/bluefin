use strict;
use warnings;
use base 'bluefinbase';
use testapi;

# Test: Complete Anaconda installation
#
# This handles the Fedora/Bluefin Anaconda installation flow
#
# Required needles:
# - anaconda_welcome, language_selection, installer_ready
# - anaconda_installation_method, disk_selection, use_entire_disk
# - anaconda_storage_config, encryption_option
# - anaconda_review, review_and_install, ready_to_install
# - anaconda_installing, installation_progress, software_installation
# - anaconda_complete, installation_complete, successfully_installed, reboot_ready

sub run {
    my $self = shift;

    my $install_timeout = get_var('INSTALL_TIMEOUT', 1800);  # 30 min default

    # Should be at Anaconda welcome (language selection)
    assert_screen ['anaconda_welcome', 'language_selection', 'installer_ready'], 30;

    # Click Continue (language selection)
    assert_and_click 'anaconda_welcome';
    wait_still_screen 5;

    # Date and time configuration (if shown)
    if (check_screen ['anaconda_date_time', 'date_and_time'], 10) {
        record_info 'Date/Time', 'Date and time screen detected';
        send_key 'ret';  # Accept defaults and continue
        wait_still_screen 3;
    }

    # Installation method - disk selection
    assert_screen ['anaconda_installation_method', 'disk_selection', 'use_entire_disk'], 60;
    record_info 'Disk', 'Selecting installation destination...';

    # Click to select disk/use entire disk
    assert_and_click 'anaconda_installation_method';
    wait_still_screen 3;

    # Storage configuration / encryption option
    if (check_screen ['anaconda_storage_config', 'encryption_option'], 30) {
        record_info 'Storage', 'Storage configuration screen';
        # Skip encryption, continue with defaults
        send_key 'ret';
        wait_still_screen 3;
    }

    # Review and install screen
    assert_screen ['anaconda_review', 'review_and_install', 'ready_to_install'], 120;
    record_info 'Review', 'At review screen, beginning installation...';

    # Begin Installation
    assert_and_click 'anaconda_review';

    # Wait for installation progress
    record_info 'Installing', 'Installation in progress...';
    assert_screen ['anaconda_installing', 'installation_progress', 'software_installation'], 60;

    # Wait for installation to complete
    assert_screen ['anaconda_complete', 'installation_complete', 'successfully_installed', 'reboot_ready'], $install_timeout;

    record_info 'Complete', 'Installation finished';
}

sub test_flags {
    return { fatal => 1, milestone => 1 };
}

1;
