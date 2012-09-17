use strict;
use warnings;

package Yandex::Fotki::Base;
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

has local_path => '';
has io => undef;
has sync => undef;

sub new{
	my ($class, %args) = @_;
	
	my $self = $class->SUPER::new(%args);
	
	$self->parse($args{xml}) if exists $args{xml};
	
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
