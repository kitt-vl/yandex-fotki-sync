use strict;
use warnings;
use utf8;

use Test::More tests => 2;
use lib 'lib';

binmode(STDOUT,':unix');

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt1');

$sync->auth;

ok length($sync->token), 'Authorize and get token';

