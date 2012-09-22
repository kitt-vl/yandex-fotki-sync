use strict;
use warnings;

package Yandex::Fotki::Album;

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
  return unless $xml;
    
  $self->SUPER::parse($xml);
  	
  my $dom = Mojo::DOM->new($xml);
      
  my $parent = $dom->at('link[rel="album"]');
	$self->link_parent($parent->{href}) if $parent;
}

sub delete{
	my $self = shift;
	
	my $ua = $self->sync->ua;
	my $tx = $ua->delete($self->link_self, {'Authorization' => 'OAuth ' . $self->sync->token});
	
	if($tx->res->code == 204)
	{
    $self->link_self('');
    
		$self->sync->albums->each(sub {
		  my ($e, $count) = @_;
		  splice @{$self->sync->albums}, $count-1 if $e->id eq $self->id;
		});	
	}
	
	return $tx->res->code;  
}

sub create{
	my $self = shift;
	die 'Empty login!' unless $self->sync->login;
	
	my $ua = $self->sync->ua;

	my $atom_album =<<"ALBUM"
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:f="yandex:fotki">
  <title>@{[ $self->title ]}</title>
  <summary>@{[ $self->title ]}</summary>
</entry>
ALBUM
;
	my $tx = $ua->post( $self->sync->albums_url => 
                  { 
                    'Content-Type' => 'application/atom+xml; charset=utf-8; type=entry',
										'Authorization' => 'OAuth ' . $self->sync->token
									}
								 => $atom_album
					);
  $self->parse($tx->res->body);
  return $self;
}

sub hierarhy{
    my $self = shift;
    		
    my $parent = $self->sync->albums->first(sub{ $_->link_self eq $self->link_parent });
		
		warn 'No parent album with link ' . $self->link_parent and next unless $parent;
		
		$self->parent($parent);
		push @{$parent->childs}, $self;
}
1;
