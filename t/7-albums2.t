use strict;
use warnings;
use feature qw/say/;
use utf8;
use Data::Dumper;

use Test::More tests => 7;
use lib 'lib';

binmode( STDOUT, ':unix' );

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt');

$sync->auth;

ok length( $sync->token ), 'Authorize and get token';

ok length( $sync->albums_url ), 'App has url for all albums';

$sync->load_albums;

is scalar keys %{$sync->albums_by_path}, 4, 'Right number of albums by path';
is scalar keys %{$sync->albums_by_link}, 4, 'Right number of albums by link';

my $path = 'Неразобранное/level 2/level 3-1';
utf8::encode($path);

my $find_album =
  $sync->albums_by_path->{$path};

#say Dumper(map{ $_->local_path} @{$sync->albums});

ok $find_album, 'Album with path  finded'; 

is $find_album->id, 'urn:yandex:fotki:yfsync:album:255984',
  'Album with id "urn:yandex:fotki:yfsync:album:255984" finded';
