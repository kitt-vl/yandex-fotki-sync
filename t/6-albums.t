use strict;
use warnings;
use utf8;
use Data::Dumper;

use Test::More tests => 2;
use lib 'lib';

binmode(STDOUT,':unix');

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt');

$sync->auth;

ok length($sync->token), 'Authorize and get token';

my $album = $sync->create_album('test album');

print Dumper($album);
