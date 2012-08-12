#!perl

use strict;
use warnings;

use lib 'lib';
use Yandex::Fotki::Sync;

my $sync = Yandex::Fotki::Sync->new;
$sync->start;
