use strict;
use warnings;
use utf8;

use Test::More tests => 5;
use lib 'lib';
use File::Spec::Functions;

use_ok 'Yandex::Fotki::Sync';
binmode(STDOUT,':unix');
my $sync = Yandex::Fotki::Sync->new;
is $sync->scan('t')->isa('Mojo::Collection'), 1, 'Right class of scan result';

#11 pics
is $sync->scan()->size, 11, 'Right number of total pictures current dir';
is $sync->scan('t')->size, 11, 'Right number of total pictures in "t" directory';
#is $sync->scan(catfile('t', 'суб дир 2'))->size, 6, 'Right number of total pictures in subdir'; 
is $sync->scan(catfile('t', 'testdir 1'))->size, 3, 'Right number of total pictures "testdir 1" dir';

