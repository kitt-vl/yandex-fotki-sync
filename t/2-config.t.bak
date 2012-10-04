use strict;
use warnings;
use utf8;

use Test::More tests => 11;
use lib 'lib';
use File::Spec::Functions;
use IO::Easy;

binmode( STDOUT, ':unix' );

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

my $config_dir = catfile( 't', 'testconfig' );

my $io = IO::Easy::Dir->new('.');
$sync->home_path( $io->append($config_dir)->abs_path );

$io->append($config_dir)->as_dir->rm_tree
  if -d $io->append($config_dir)->abs_path;
is -d $io->append($config_dir)->abs_path, undef, 'Config path clear';

$io->append($config_dir)->as_dir->create;
is -d $io->append($config_dir)->abs_path, 1, 'Config path exists';

is -f $sync->config_path, undef, 'Config file not exists before save';

$sync->login('dump_test_login');
$sync->password('secret');
$sync->token('65122f876746541237865c837ba9852');
$sync->save_config;

is -f $sync->config_path, 1, 'Config file exists after save';

$sync->login('dump_test_login');
$sync->password('');
$sync->token('');

$sync->load_config;
is $sync->login, 'dump_test_login', 'Config file contains login value';
is $sync->token, '65122f876746541237865c837ba9852',
  'Config file contains token value';

$sync->login('another_login');
$sync->password('another_secret');
$sync->token('8978937345645bc4a44b46bb98712654de');

$sync->save_config;

$sync->login('dump_test_login');
$sync->password('');
$sync->token('');

$sync->load_config;
is $sync->login, 'dump_test_login', 'Config file support multilogin';
is $sync->token, '65122f876746541237865c837ba9852',
  'Config file right multilogin token';

$sync->login('another_login');
$sync->load_config;
is $sync->login, 'another_login', 'Config file support multilogin2';
is $sync->token, '8978937345645bc4a44b46bb98712654de',
  'Config file right multilogin token2';
