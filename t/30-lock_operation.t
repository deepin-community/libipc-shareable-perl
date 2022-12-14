use warnings;
use strict;

use Carp;
use IPC::Shareable;
use Test::More;
use Test::SharedFork;

my $sv;

my $awake = 0;
local $SIG{ALRM} = sub { $awake = 1 };

# locking

my $pid = fork;
defined $pid or die "Cannot fork: $!\n";

if ($pid == 0) {
    # child

    sleep unless $awake;
    tie($sv, 'IPC::Shareable', 'TEST', { destroy => 0 });

    for (0 .. 99) {
        (tied $sv)->lock;
        ++$sv;
        (tied $sv)->unlock;
    }
    is $sv, 100, "in child: locked and set SV to 100";
    exit;

} else {
    # parent

    tie($sv, 'IPC::Shareable', 'TEST', { create => 1, destroy => 1 })
        or die "parent process can't tie \$sv";
    $sv = 0;
    kill ALRM => $pid;
    waitpid($pid, 0);
    for (0 .. 99) {
        (tied $sv)->lock;
        ++$sv;
        (tied $sv)->unlock;
    }
    is $sv, 200, "in parent: locked and updated SV to 200";
}

done_testing();
