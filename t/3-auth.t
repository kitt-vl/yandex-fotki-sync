use strict;
use warnings;
use utf8;

use Test::More tests => 3;
use lib 'lib';

binmode(STDOUT,':unix');

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt');

$sync->auth;

ok length($sync->token), 'Authorize and get token';


$sync->login('yfsync');
$sync->password('wrong pass');

$sync->auth;

ok length($sync->token) == 0, 'Do not authorize with wrong password';
