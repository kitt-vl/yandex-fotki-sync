use strict;
use warnings;

package Yandex::Fotki::Photo;

use Mojo::Base 'Yandex::Fotki::Base';
use Mojo::DOM;
use Data::Dumper;

has access           => 'public';
has xxx              => 'false';
has hide_original    => 'false';
has disable_comments => 'false';

has link_original => '';

sub parse {
    my ( $self, $xml ) = ( shift, shift );
    return unless $xml;

    $self->SUPER::parse($xml);

    my $dom = Mojo::DOM->new($xml);

    my $parent = $dom->at('link[rel="album"]');
    if ($parent) {
        $self->link_album( $parent->{href} );
        
        my $album =
          $self->sync->albums->first( sub { $_->link_self eq $self->link_album }
          );
          
        unless ( $album && $album->id ) {
            $album = Yandex::Fotki::Album->new(
                link_self => $self->link_album,
                sync      => $self->sync
            );
            $album->load_info;
        }
    }
}

sub upload {
    my ($self) = ( shift, shift );

    $self->sync->load_albums;
    
    my $album =
      $self->sync->albums->first( sub { $_->local_path eq $self->parent_path } )
      // Yandex::Fotki::Album->new(
        sync       => $self->sync,
        local_path => $self->parent_path
      );

    $album->create unless $album->link_self;

    my $ua = $self->sync->ua;

    #say 'URL:' . $self->sync->photos_url;
    #say 'PATH:' . $self->io->abs_path;
    #say 'TOKEN:' . $self->sync->token;
    my $params = { image => { file => '' . $self->io->abs_path } };

    $params->{album} = $album->id if $album->id;


    say '=====================================================================';
    say 'Uploading photo :';
    say '   abs_path: ' . $self->io->abs_path;
    say '   title: ' . $self->title;
    say '   local_path: ' . $self->local_path;
    say '   link_album: ' . $self->link_album;
    
    
    my $tx = $ua->post_form(
        $self->sync->photos_url => $params => {
            'Authorization' => 'OAuth ' . $self->sync->token,
            'Content-Type'  => 'multipart/form-data'
        }
    );

    say '   result: ' . $tx->res->code;
    say '   link_self: ' . $self->link_self;
    
    warn "Upload photo error: " . $tx->error . "\nBody: " . $tx->res->body
      and return $tx->res->code
      if $tx->error;

    return unless $tx->res->code == 201;

    $self->parse( $tx->res->body );
    return $self;
}

sub delete {
    my $self = shift;

    my $ua = $self->sync->ua;
    my $tx =
      $ua->delete( $self->link_self,
        { 'Authorization' => 'OAuth ' . $self->sync->token } );

    $self->link_self('') if $tx->res->code == 204;

    return $tx->res->code;
}


sub parent_path{
    my $self = shift;
    my $parent_path = $self->SUPER::parent_path;
    
}
1;
