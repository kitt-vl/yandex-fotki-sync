use strict;
use warnings;
use feature qw/say/;
use utf8;
use Data::Dumper;
use Cwd;
use Test::More tests => 45;
use lib 'lib';

binmode( STDOUT, ':unix' );

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt');
$sync->work_path(Cwd::cwd);
$sync->auth;

ok length( $sync->token ), 'Authorize and get token';

ok length( $sync->albums_url ), 'App has url for all albums';

$sync->load_albums;

my $photos = $sync->scan;

while ( my $photo = shift @{$photos} ) {
    $photo->upload;

    ok $photo->link_self,   'Uploaded file has link_self';
    like $photo->link_self, qr/https?\:\/\/.*yfsync.*photo.*/,
      'Link_self look like right URL';

    my $code = $photo->delete;

    is $code, 204, 'Right delete response code';
}

################################################################################
if( my $test = $sync->albums_by_path->{'t'})
{
    $test->delete;
}
################################################################################
$photos = $sync->scan;
my $local_photo = 't/суб дир 2/test sub dir3/image 8 в субдиректории .jpg';
utf8::encode($local_photo);

my $photo = $photos->first(sub{ $_->local_path eq $local_photo });

ok $photo, 'Find local photo in collection';

$photo->upload;
ok $photo->link_self,   'Uploaded file has link_self';

my $album = $sync->albums_by_path->{$photo->parent_path};
ok $album, 'Uploaded photo has album';

$album->load_photos; 
is scalar keys %{$album->photos}, 2, 'Right size of album photos collection';

################################################################################
$local_photo = 't/суб дир 2/test sub dir3/image in subfolder 7.bmp';
utf8::encode($local_photo);

$photo = $photos->first(sub{ $_->local_path eq $local_photo });
ok $photo, 'Find local photo in collection';

$photo->upload;
ok $photo->link_self,   'Uploaded file has link_self';

$album->load_photos;
is scalar keys %{$album->photos}, 4, 'Right size of album photos collection';

my $code = $photo->delete;
is $code, 204, 'Right delete response code';
is scalar keys %{$album->photos}, 2, 'Right size of album photos collection after photo delete';

if( my $test = $sync->albums_by_path->{'t'})
{
    $test->delete;
}
