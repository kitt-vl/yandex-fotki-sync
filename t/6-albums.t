use strict;
use warnings;
use utf8;
use Data::Dumper;

use Test::More tests => 24;
use lib 'lib';

binmode(STDOUT,':unix');

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt');

$sync->auth;

ok length($sync->token), 'Authorize and get token';

ok length($sync->albums_url), 'App has url for all albums';

my $test_name = 'test album ' . rand;

my $album = $sync->create_album($test_name);
ok $album->isa('Yandex::Fotki::Album') , 'Create_album method return right class "Yandex::Fotki::Album"';

ok length($album->id), 'New album has id';
ok length($album->link_self), 'New album has link';

is $album->author, 'yfsync', 'New album has right author';
is $album->title, $test_name, 'New album has right title';

my $album2 = $sync->create_album('test album 2');
ok $album2->isa('Yandex::Fotki::Album') , 'Method return right class "Yandex::Fotki::Album"';
ok length($album2->id), 'New album has id';

$sync->load_albums;

is scalar @{$sync->albums}, 6, 'Right number of albums';


ok $sync->albums->grep(sub { $_->title eq 'Неразобраннное' } ), 'Right album title in collection';
ok $sync->albums->grep(sub{ $_->title eq 'test album 2' }), 'Right album title in collection';
ok $sync->albums->grep(sub{ $_->title eq $test_name }), 'Right album title in collection';

my $del_code = $sync->delete_album($album);
is $del_code, 204, 'Right delete code';

my $del_code2 = $sync->delete_album($album2);
is $del_code2, 204, 'Right delete code';

$sync->load_albums;
is scalar @{$sync->albums}, 4, 'Right number of albums after delete';

$sync->hierarhy_albums;

is scalar @{$sync->albums}, 1, 'Right 1st level hierarhy numbers of albums';
is $sync->albums->first->title, 'Неразобраннное', 'Right 1st level hierarhy album title';

is $sync->albums->first->childs->size, 1, 'Right 1st level hierarhy album childs collection';
is $sync->albums->first->childs->first->title, 'level 2', 'Right 2nd level hierarhy album title';
is $sync->albums->first->childs->first->childs->size, 2, 'Right 2st level hierarhy album childs collection';

is $sync->albums->first->childs->first->childs->[0]->title, 'уровень 3-2', 'Right 3rd level hierarhy album title';
is $sync->albums->first->childs->first->childs->[1]->title, 'level 3-1', 'Right 3rd level hierarhy album title';

#print Dumper($sync->albums);
