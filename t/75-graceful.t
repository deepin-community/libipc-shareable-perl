use warnings;
use strict;

use IPC::Shareable;
use Test::More;

# non-graceful
{
    tie my $sv, 'IPC::Shareable', {
        key     => 'lock',
        create  => 1,
        exclusive => 1,
        destroy => 1
    };

    my $catch = eval {
        tie my $sv2, 'IPC::Shareable', {
            key     => 'lock',
            create  => 1,
            exclusive => 1,
            destroy => 1
        };
        1;
    };

    is
        $catch,
        undef,
        "without 'graceful', we croak if two attemps made on same exclusive seg";

    like
        $@,
        qr/using exclusive/,
        "...and error message is sane";
}

# graceful
my $catch;

{
    tie my $sv, 'IPC::Shareable', {
        key     => 'DONE',
        create  => 1,
        exclusive => 1,
        graceful  => 1,
        destroy => 1
    };

    tie my $sv2, 'IPC::Shareable', {
        key     => 'DONE',
        create  => 1,
        exclusive => 1,
        graceful  => 1,
        destroy => 1
    };
}

END {
    is
        $@,
        '',
        "with 'graceful', we silently exit if two attemps made on same exclusive seg";

    done_testing;
};
