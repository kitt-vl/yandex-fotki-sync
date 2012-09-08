use strict;
use warnings;

package Yandex::Fotki::Album;
use Mojo::Base -base;
use Mojo::DOM;

has id => '';
has author => '';
has title => '';
has summary => '';
has edited => '';
has updated => '';
has published => '';
has link_self => '';
has link_edit => '';
has link_photos => '';
has link_cover => '';
has link_ymapsml => '';
has link_alternate => '';
has img => '';
has protected => '';
has image_count => '';

sub new{
	my ($class, $xml) = (shift, shift);
	my $self = bless {}, ref $class || $class;
	
	$self->parse($xml) if $xml;
	
	return $self;
}

sub parse{
	my ($self, $xml) = (shift, shift);
	
	my $dom = Mojo::DOM->new($xml);
	$self->id($dom->entry->id->text);
	$self->author($dom->entry->author->name->text);
	$self->title($dom->entry->title->text);
	
	my $link = $dom->at('link[rel="self"]');
	$self->link_self($link->{href}) if $link;
}

1;
