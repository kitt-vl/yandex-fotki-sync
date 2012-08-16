use strict;
use warnings;
use utf8;

use Test::More tests => 10;
use lib 'lib';

binmode(STDOUT,':unix');

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->options( ['--login', 'yfsync', '--dir', '/some/path/to/imgs', '--password', 'secret word'] );
$sync->parse_options;

is $sync->login, 'yfsync', 'Rigth parse login from options';
is $sync->password, 'secret word', 'Rigth parse password from options';
is $sync->work_path, '/some/path/to/imgs', 'Rigth parse work dir from options';

$sync->login('');
$sync->password('');
$sync->work_path('');

$sync->options( ['-l', 'yfsync', '-d', '/some/path/to/imgs', '-p', 'secret word'] );
$sync->parse_options;

is $sync->login, 'yfsync', 'Rigth parse login from options short';
is $sync->password, 'secret word', 'Rigth parse password from options short';
is $sync->work_path, '/some/path/to/imgs', 'Rigth parse work dir from options short';

########################################################################

$sync->login('');
$sync->password('');
$sync->work_path('');

$sync->options( ['-l', 'yfsync@yandex.ru', '-d', '/some/path with backspace/to/imgs', '-p', 'secret word"sdf'] );
$sync->parse_options;

is $sync->login, 'yfsync@yandex.ru', 'Rigth parse login from options short2';
is $sync->password, 'secret word"sdf', 'Rigth parse password from options short2';
is $sync->work_path, '/some/path with backspace/to/imgs', 'Rigth parse work dir from options short2';
