use strict;
use warnings;

package Yandex::Fotki::Photo;

use Mojo::Base 'Yandex::Fotki::Base';
use Mojo::DOM;
use File::Spec;
use Data::Dumper;

has access           => 'private';
has xxx              => 'false';
has hide_original    => 'false';
has disable_comments => 'false';

has link_original => '';

sub parse {
  my ($self, $xml) = (shift, shift);
  return unless $xml;
  
  my $dom = $self->SUPER::parse($xml);

  if (my $parent = $dom->at('link[rel="album"]')) {
    $self->link_album($parent->{href});

    my $album =
      $self->sync->albums_by_link->{$self->link_album};

    die 'Album "' . $self->link_album . '" not found by in albums_by_link!' unless $album;
    # $self->title($self->io->name) if $self->io;
    $self->build_local_path;

    $album->photos->{$self->local_path} = $self;
    $album->photos->{$self->unsorted_path} = $self;
  }
}

sub upload {
  my ($self) = (shift);

  #$self->sync->load_albums;

  my $album;
  if ($self->parent_path) {
    $album =
      $self->sync->albums_by_path->{$self->parent_path || 'NOT_EXISTS_PATH'}
      // Yandex::Fotki::Album->new(
      sync       => $self->sync,
      local_path => $self->parent_path
      );

    $album->create unless $album->link_self;
  }

  #check photo already exists
  if(exists $album->photos->{$self->local_path} )
  {
    say 'Photo "' . $self->io->abs_path . '" already exists, skipping.';
    $self =  $album->photos->{$self->local_path};
    return $self;
  }
  elsif(exists $album->photos->{$self->unsorted_path} )
  {
    say 'Photo "' . $self->io->abs_path . '" already exists, skipping.';
    $self =  $album->photos->{$self->unsorted_path};
    return $self;
  }
  ###########################
  my $ua = $self->sync->ua;

  #say 'URL:' . $self->sync->photos_url;
  #say 'PATH:' . $self->io->abs_path;
  #say 'TOKEN:' . $self->sync->token;
  my $params = {image => {file => '' . $self->io->abs_path}};

  $params->{album} = $album->id if $album && $album->id;
  $params->{title} = $self->io->name;
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
      #'Content-Type'  => 'multipart/form-data',

    }
  );

  #say '   result: ' . $tx->res->code;
  #say '   link_self: ' . $self->link_self;

  warn "Error upload photo '"
    . $self->io->abs_path . "': "
    . $tx->error
    . "\nBody: "
    . $tx->res->body
    and return $tx->res->code
    if $tx->error;

  return unless $tx->res->code == 201;

  say 'Photo "' . $self->io->abs_path . '" uploaded.';
  $self->parse($tx->res->body);
  return $self;
}

sub delete {
  my $self = shift;

  my $ua = $self->sync->ua;
  my $tx =
    $ua->delete($self->link_self,
    {'Authorization' => 'OAuth ' . $self->sync->token});

  if ($tx->res->code == 204) {

    if(my $parent = $self->sync->albums_by_link->{$self->link_album})
    {
        delete $parent->photos->{$self->local_path};
        delete $parent->photos->{$self->unsorted_path};
    }
    $self->link_self('');
  }

  return $tx->res->code;
}

sub unsorted_path{
  my $self= shift;
  die 'unsorted_path: local_path is empty!' unless $self->local_path;

  my @dir = File::Spec->splitdir($self->local_path);
  my $file_name = pop @dir;
  
  push @dir, 'Неразобранное в ' . $dir[-1], $file_name;
  return join('/', @dir);
}

sub remote_exists{
  my $self = shift;

  return 1 if $self->link_self;


}
1;
