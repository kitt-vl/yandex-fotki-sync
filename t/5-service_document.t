use strict;
use warnings;
use utf8;

use Test::More tests => 4;
use lib 'lib';
use Mojo::DOM;

binmode(STDOUT,':unix');

use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;
$sync->login('alekna');
$sync->load_service_document;

ok length($sync->service_document) > 0, 'Service document non zero length';

my $dom = Mojo::DOM->new($sync->service_document);

my $title = $dom->at('title');
ok defined($title), 'Title node exist';
is $title->text, 'alekna на Яндекс.Фотках', 'Right title';
