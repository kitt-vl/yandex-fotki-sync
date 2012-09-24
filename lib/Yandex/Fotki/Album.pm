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

has parent => undef;
has childs => sub { Mojo::Collection->new };

sub parse{
  my ($self, $xml) = (shift, shift);  
  return unless $xml;
    
  $self->SUPER::parse($xml);
  	
  my $dom = Mojo::DOM->new($xml);
      
  my $parent = $dom->at('link[rel="album"]');
	$self->link_album($parent->{href}) if $parent;
  
  push @{$self->sync->albums}, $self unless $self->sync->albums->first(sub{ $_->link_self eq $self->link_self });
  
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
	
  my $album;
  
  if(my $parent_path = $self->parent_path)
  {
    $album = $self->sync->albums->first(sub{ $_->local_path eq $parent_path }) 
                      // Yandex::Fotki::Album->new(sync => $self->sync, local_path => $parent_path);
                      
    $album->create unless $album->link_self;
   
  } 
  
	my $ua = $self->sync->ua;
  #say 'ALBUM CREATE: localpath ' . $self->local_path;
	my $atom_album =<<"ALBUM"
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:f="yandex:fotki">
  <title>@{[ $self->title ]}</title>
  <summary>@{[ $self->title ]}</summary>
ALBUM
;

  $atom_album .= "\n<link href='" . $album->link_self . "' rel='album' />\n"  if $album && $album->link_self;
  $atom_album .= '</entry>';
  
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
    
    return unless $self->link_album;
    		
    my $parent = $self->sync->albums->first(sub{ $_->link_self eq $self->link_album });
		
		warn 'No parent album with link ' . $self->link_album and next unless $parent;
		
		$self->parent($parent);
		push @{$parent->childs}, $self;
}
1;
