package bluefinutils;

use strict;
use warnings;
use base 'Exporter';
use testapi;

our @EXPORT = qw(
    boot_to_gdm
    gdm_login
    check_gnome_desktop
);

# Boot through GRUB to GDM login screen
sub boot_to_gdm {
    my %args = @_;
    $args{timeout} //= 300;

    # Handle GRUB if present (may auto-boot)
    if (check_screen 'grub_menu', 30) {
        # Select first entry (default Bluefin)
        send_key 'ret';
    }

    # Wait for GDM to appear
    # We look for the GDM login screen
    assert_screen 'gdm_login_screen', $args{timeout};

    # GDM sometimes has animation, wait for it to settle
    wait_still_screen(stilltime => 5, timeout => 30, similarity_level => 40);
}

# Log in via GDM
sub gdm_login {
    my %args = @_;
    my $user = $args{user} // get_var('USER_LOGIN', 'bluefin');
    my $password = $args{password} // get_var('USER_PASSWORD', 'bluefin');

    # GDM shows user list, click on user or hit enter for first user
    if (check_screen "gdm_user_$user", 5) {
        assert_and_click "gdm_user_$user";
    }
    else {
        # Hit enter to select first/only user
        send_key 'ret';
    }

    # Wait for password prompt
    assert_screen 'gdm_password_prompt', 30;

    # Type password
    type_string $password, max_interval => 50;
    send_key 'ret';

    # Wait for desktop to load
    check_gnome_desktop(timeout => 120);
}

# Verify we're at the GNOME desktop
sub check_gnome_desktop {
    my %args = @_;
    $args{timeout} //= 60;

    # Look for GNOME shell elements
    # Activities button or top panel
    my $count = 5;
    while ($count > 0) {
        $count--;
        assert_screen 'gnome_desktop', $args{timeout};

        # GNOME 40+ opens overview on first login
        # Check if overview is open and close it
        if (match_has_tag 'gnome_overview_open') {
            send_key 'super';
            wait_still_screen 3;
        }
        else {
            last;
        }
    }
}

1;
