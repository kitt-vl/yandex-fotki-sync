use strict;
use warnings;

package Yandex::Fotki::Album;

#use lib 'lib';
#use Yandex::Fotki::Base;

use Mojo::Base 'Yandex::Fotki::Base';
use Mojo::DOM;

has link_photos => '';
has link_cover => '';
has link_ymapsml => '';
has link_alternate => '';
has protected => '';
has image_count => '';
has link_parent => '';

has parent => undef;
has childs => sub { Mojo::Collection->new };

sub parse{
  my ($self, $xml) = (shift, shift);  
    
  $self->SUPER::parse($xml);
  	
  my $dom = Mojo::DOM->new($xml);
      
  my $parent = $dom->at('link[rel="album"]');
	$self->link_parent($parent->{href}) if $parent;
}


1;
