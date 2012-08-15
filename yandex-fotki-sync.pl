use strict;
use warnings;

use 5.016;
use utf8;
use lib 'lib';
use Yandex::Fotki::Sync;

my $sync = Yandex::Fotki::Sync->new;
$sync->start;
