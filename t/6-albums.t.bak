use strict;
use warnings;
use utf8;
use Data::Dumper;

use Test::More tests => 22;
use lib 'lib';

binmode( STDOUT, ':unix' );

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt');

$sync->auth;

ok length( $sync->token ), 'Authorize and get token';

ok length( $sync->albums_url ), 'App has url for all albums';

my $test_name = 'test album ' . rand;

my $album = Yandex::Fotki::Album->new( title => $test_name, sync => $sync );

ok $album->isa('Yandex::Fotki::Album'),
  'Create_album method return right class "Yandex::Fotki::Album"';

$album->create;

ok length( $album->id ),        'New album has id';
ok length( $album->link_self ), 'New album has link';

is $album->author, 'yfsync', 'New album has right author';
is $album->title, $test_name, 'New album has right title';

my $album2 =
  Yandex::Fotki::Album->new( title => 'test album 2', sync => $sync );

ok $album2->isa('Yandex::Fotki::Album'),
  'Method return right class "Yandex::Fotki::Album"';

$album2->create;


ok length( $album2->id ), 'New album has id';
ok length( $album2->link_photos ), 'New album has link to photo collection';

$sync->load_albums;
if(my $test = $sync->albums->first(sub{ $_->local_path eq 't'}))
{
    $test->delete;
}

is scalar @{ $sync->albums }, 6, 'Right number of albums';

ok $sync->albums->first( sub { $_->title eq 'Неразобранное' } ),
  'Right album title in collection';
ok $sync->albums->first( sub { $_->title eq 'test album 2' } ),
  'Right album title in collection';
ok $sync->albums->first( sub { $_->title eq $test_name } ),
  'Right album title in collection';

my $del_code = $album->delete;
is $del_code, 204, 'Right delete code';

my $del_code2 = $album2->delete;
is $del_code2, 204, 'Right delete code';

my $album3 =
  Yandex::Fotki::Album->new( 
            title => 'test album with parent', 
            sync => $sync, 
            link_album => 'http://api-fotki.yandex.ru/api/users/yfsync/album/255407/' 
    );

$album3->create;

ok length( $album3->id ), 'New album has id';
ok length( $album3->link_photos ), 'New album has link to photo collection';

is $album3->link_album,
  'http://api-fotki.yandex.ru/api/users/yfsync/album/255407/',
  'Right album parent';

my $del_code3 = $album3->delete;
is $del_code3, 204, 'Right delete code';

#######################################
$sync->load_albums;
is scalar @{ $sync->albums }, 4, 'Right number of albums after delete';
