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
has link_parent => '';

has parent => undef;
has childs => sub { Mojo::Collection->new };
has local_path => '';

sub new{
	my ($class, $xml) = (shift, shift);
	my $self = bless {}, ref $class || $class;
	
	$self->parse($xml) if $xml;
	
	return $self;
}

sub parse{
	my ($self, $xml) = (shift, shift);
	
	utf8::decode($xml); 
	
	my $dom = Mojo::DOM->new($xml);
	
	$self->id($dom->entry->id->text);
	$self->author($dom->entry->author->name->text);
	$self->title($dom->entry->title->text);
	
	my $link = $dom->at('link[rel="self"]');
	$self->link_self($link->{href}) if $link;
	
	my $parent = $dom->at('link[rel="album"]');
	$self->link_parent($parent->{href}) if $parent;
}

sub build_local_path{
	my $self = shift;
	my $path = $self->title;
	my $parent = $self->parent;
	while($parent)
	{
		$path = $parent->title . '\\' . $path  ;
		$parent = $parent->parent;
	}
	
	$self->local_path($path);
	
}

1;
