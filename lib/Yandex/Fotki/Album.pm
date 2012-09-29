use strict;
use warnings;

package Yandex::Fotki::Album;

use Mojo::Base 'Yandex::Fotki::Base';
use Mojo::DOM;

has link_photos    => '';
has link_cover     => '';
has link_ymapsml   => '';
has link_alternate => '';
has protected      => '';
has image_count    => '';

sub parse {
    my ( $self, $xml ) = ( shift, shift );
    return unless $xml;

    $self->SUPER::parse($xml);

    my $dom = Mojo::DOM->new($xml);

    my $parent = $dom->at('link[rel="album"]');
    $self->link_album( $parent->{href} ) if $parent;

    push @{ $self->sync->albums }, $self
      unless $self->link_self && $self->sync->albums->first(
        sub { $_->link_self eq $self->link_self } );

}

sub delete {
    my $self = shift;

    my $ua = $self->sync->ua;
    my $tx =
      $ua->delete( $self->link_self,
        { 'Authorization' => 'OAuth ' . $self->sync->token } );

    if ( $tx->res->code == 204 ) {
        $self->delete_from_cache;
    }

    return $tx->res->code;
}

sub delete_from_cache{
    my $self = shift;
    
    $self->link_self('');

    $self->sync->albums->each(
        sub {
            my ( $elem, $count ) = @_;
            splice @{ $self->sync->albums }, $count - 1
              if $elem->id eq $self->id;
              
            $elem->delete_from_cache if $elem->link_album && $elem->link_album eq $self->link_self;
        }
    );
    
}

sub create {
    my $self = shift;
    die 'Empty login!' unless $self->sync->login;

    my $album;

    if ( my $parent_path = $self->parent_path ) {
        $album =
          $self->sync->albums->first( sub { $_->local_path eq $parent_path } )
          // Yandex::Fotki::Album->new(
            sync       => $self->sync,
            local_path => $parent_path
          );

        $album->create unless $album->link_self;
    }

    my $ua = $self->sync->ua;

    my $atom_album = <<"ALBUM"
<entry xmlns="http://www.w3.org/2005/Atom" xmlns:f="yandex:fotki">
  <title>@{[ $self->title ]}</title>
  <summary>@{[ $self->title ]}</summary>
ALBUM
      ;

    $atom_album .= "<link href='" . $album->link_self . "' rel='album' />\n"
      if $album && $album->link_self;
      
    $atom_album .= '</entry>';

    say '=====================================================================';
    say 'Creating album :';
    say '   title: ' . $self->title;
    say '   local_path: ' . $self->local_path;
    say '   link_album: ' . ($album && $album->link_self?$album->link_self : '');
    
    my $tx = $ua->post(
        $self->sync->albums_url => {
            'Content-Type' => 'application/atom+xml; charset=utf-8; type=entry',
            'Authorization' => 'OAuth ' . $self->sync->token
        } => $atom_album
    );
    $self->parse( $tx->res->body );
    
    say '   result: ' . $tx->res->code;
    say '   link_self: ' . $self->link_self;
    return $self;
}

1;
