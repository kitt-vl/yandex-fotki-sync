use strict;
use warnings;

package Yandex::Fotki::Photo;
#use Yandex::Fotki::Base;
#use lib 'lib';
use Mojo::Base 'Yandex::Fotki::Base';
use Mojo::DOM;

has link_album => '';
has access => 'public';
has xxx => 'false';
has hide_original => 'false';
has disable_comments => 'false';

has link_orig => '';


1;
