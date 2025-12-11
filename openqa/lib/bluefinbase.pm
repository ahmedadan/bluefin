package bluefinbase;

use strict;
use warnings;
use base 'basetest';

use testapi;

# Base class for Bluefin OpenQA tests
# Provides common functionality for all Bluefin test modules

sub post_fail_hook {
    my $self = shift;

    # Try to get to a console for log collection
    select_console 'root-console' if (check_screen 'generic_desktop', 0);

    # Upload journal logs
    unless (script_run "journalctl --no-pager > /tmp/journal.txt", 60) {
        upload_logs "/tmp/journal.txt", failok => 1;
    }

    # Upload system info
    script_run "rpm-ostree status > /tmp/ostree-status.txt";
    upload_logs "/tmp/ostree-status.txt", failok => 1;

    # Upload dmesg
    script_run "dmesg > /tmp/dmesg.txt";
    upload_logs "/tmp/dmesg.txt", failok => 1;
}

1;
