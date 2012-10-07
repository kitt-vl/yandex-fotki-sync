use strict;
use warnings;
use feature qw/say/;
use utf8;
use Data::Dumper;
use Cwd;
use Test::More tests => 36;
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
my %uploaded;
while ( my $photo = shift @{$photos} ) {
    $photo->upload;

    ok $photo->link_self,   'Uploaded file has link_self';
    like $photo->link_self, qr/https?\:\/\/.*yfsync.*photo.*/,
      'Link_self look like right URL';

    $uploaded{$photo->local_path} = $photo->link_self;
}

while ( my $photo = shift @{$photos} ) {
    $photo->upload;

    ok $photo->link_self,   'Uploaded file has link_self';
    like $photo->link_self, qr/https?\:\/\/.*yfsync.*photo.*/,
      'Link_self look like right URL';

    is $uploaded{$photo->local_path}, $photo->link_self, 'Photo skip second upload';
    #my $code = $photo->delete;

    #is $code, 204, 'Right delete response code';
}

if( my $test = $sync->albums_by_path->{'t'})
{
    $test->delete;
}