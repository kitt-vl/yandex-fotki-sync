use strict;
use warnings;
use feature qw/say/;
use utf8;
use Data::Dumper;

use Test::More tests => 14;
use lib 'lib';

binmode(STDOUT,':unix');

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt');

$sync->auth;

ok length($sync->token), 'Authorize and get token';

ok length($sync->albums_url), 'App has url for all albums';

$sync->load_albums;

my $files = $sync->scan;

for my $file (@{$files})
{
  $file->upload();
  ok $file->link_self, 'Uploaded file has link_self';
}
