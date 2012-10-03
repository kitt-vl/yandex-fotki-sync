use strict;
use warnings;

package Yandex::Fotki::Photo;

use Mojo::Base 'Yandex::Fotki::Base';
use Mojo::DOM;
use Data::Dumper;

has access           => 'private';
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
        
        $self->build_local_path;
        
        push @{$album->photos}, $self unless $album->photos->first(sub{ $_->link_self eq $self->link_self });
    }
}

sub upload {
    my ($self) = ( shift);

    #$self->sync->load_albums;
    
    my $album ;
    if($self->parent_path)
    {
        $album =
          $self->sync->albums->first( sub { $_->local_path eq $self->parent_path } )
          // Yandex::Fotki::Album->new(
            sync       => $self->sync,
            local_path => $self->parent_path
          );
          
              $album->create unless $album->link_self;
           }
    
    my $ua = $self->sync->ua;

    #say 'URL:' . $self->sync->photos_url;
    #say 'PATH:' . $self->io->abs_path;
    #say 'TOKEN:' . $self->sync->token;
    my $params = { image => { file => '' . $self->io->abs_path } };

    $params->{album} = $album->id if $album && $album->id;
    $params->{'access'} = $self->sync->default_access;

    #say '=====================================================================';
    #say 'Uploading photo :';
    #say '   abs_path: ' . $self->io->abs_path;
    #say '   title: ' . $self->title;
    #say '   local_path: ' . $self->local_path;
    #say '   link_album: ' . $album->link_self ;
    
    
    my $tx = $ua->post_form(
        $self->sync->photos_url => $params => {
            'Authorization' => 'OAuth ' . $self->sync->token,
            'Content-Type'  => 'multipart/form-data'
        }
    );

    #say '   result: ' . $tx->res->code;
    #say '   link_self: ' . $self->link_self;
    
    warn "Error upload photo '" . $self->io->abs_path . "': " . $tx->error . "\nBody: " . $tx->res->body
      and return $tx->res->code
      if $tx->error;

    return unless $tx->res->code == 201;
    
    say 'Photo "' . $self->io->abs_path . '" uploaded.';
    $self->parse( $tx->res->body );
    return $self;
}

sub delete {
    my $self = shift;

    my $ua = $self->sync->ua;
    my $tx =
      $ua->delete( $self->link_self,
        { 'Authorization' => 'OAuth ' . $self->sync->token } );

    if ($tx->res->code == 204)
    {

        if($self->link_self && $self->link_album)
        {
            if(my $album = $self->sync->albums->first(sub{ $_->link_self eq $self->link_album }))
            {
                $album->photos->each(sub{
                    my ($photo, $cnt) = @_;
                    if($photo->link_self eq $self->link_self)
                    {
                        splice @{$album->photos}, $cnt-1;
                    }
                });
            }
        }
        $self->link_self('');
    }

    return $tx->res->code;
}

1;
