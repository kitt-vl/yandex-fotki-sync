use strict;
use warnings;
use feature qw/say/;
use utf8;
use Data::Dumper;
use Cwd;

use lib 'lib';
use Yandex::Fotki::Sync;

binmode( STDOUT, ':unix' );

my $sync = Yandex::Fotki::Sync->new;

$sync->login('yfsync');
$sync->password('yfsyncTESTaccaunt');
$sync->work_path(Cwd::cwd);
$sync->auth;

$sync->load_albums;

#say Dumper(keys $sync->albums_by_link);
for my $link (keys $sync->albums_by_link)
{
	#say 'Title "' . $sync->albums_by_link->{$link}->title . '"; Link "' . $sync->albums_by_link->{$link}->link_self;
	$sync->albums_by_link->{$link}->delete if $sync->albums_by_link->{$link}->title eq 't';
}


