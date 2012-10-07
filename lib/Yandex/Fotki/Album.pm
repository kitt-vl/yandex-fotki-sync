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

has photos => sub { return {} };

sub parse {
  my ($self, $xml) = (shift, shift);
  return unless $xml;

  if (my $dom = $self->SUPER::parse($xml)) {
    my $parent = $dom->at('link[rel="album"]');
    $self->link_album($parent->{href}) if $parent;

    my $photos = $dom->at('link[rel="photos"]');
    $self->link_photos($photos->{href}) if $photos;
  }

  $self->sync->albums_by_link->{$self->link_self} = $self;

}

sub delete {
  my $self = shift;

  my $ua = $self->sync->ua;
  my $tx =
    $ua->delete($self->link_self,
    {'Authorization' => 'OAuth ' . $self->sync->token});

  if ($tx->res->code == 204) {

    my $child_str = '^' . quotemeta(''.$self->title .'/');
    my $child_re = qr($child_str);
    #quick and dirty remove child albums from cache
    for my $child (grep {$_ =~ $child_re } keys $self->sync->albums_by_path)
    {
      my $child_link = $self->sync->albums_by_path->{$child}->link_self;
      delete $self->sync->albums_by_link->{$child_link};  
      delete $self->sync->albums_by_path->{$child};  
    }

    delete $self->sync->albums_by_path->{$self->local_path};
    delete $self->sync->albums_by_link->{$self->link_self};
  }

  return $tx->res->code;
}

sub create {
  my $self = shift;
  die 'Empty login!' unless $self->sync->login;

  my $album;

  if (my $parent_path = $self->parent_path) {
    $album =
      $self->sync->albums_by_path->{$parent_path}
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

#say '=====================================================================';
#say 'Creating album :';
#say '   title: ' . $self->title;
#say '   local_path: ' . $self->local_path;
#say '   link_album: ' . ($album && $album->link_self?$album->link_self : '');

  my $tx = $ua->post(
    $self->sync->albums_url => {
      'Content-Type'  => 'application/atom+xml; charset=utf-8; type=entry',
      'Authorization' => 'OAuth ' . $self->sync->token
    } => $atom_album
  );

  warn "Album create error: " . $tx->error . "\nBody: " . $tx->res->body
    and return $tx->res->code
    if $tx->error;

  $self->parse($tx->res->body);
  $self->build_local_path;
  #say '   result: ' . $tx->res->code;
  #say '   link_self: ' . $self->link_self;
  say 'Album "' . $self->local_path . '" created';
  return $self;
}

sub load_photos {
  my $self = shift;

  warn 'Album "'
    . $self->local_path
    . '": load_photos while empty link_photos!' and return
    unless $self->link_photos;

  $self->photos({});
  my $tmp_url = $self->link_photos;

  while ($tmp_url) {
    my $tx =
      $self->sync->ua->get(
      $tmp_url => {'Authorization' => 'OAuth ' . $self->sync->token});

    warn "Album load photos error: "
      . $tx->error
      . "\nBody: "
      . $tx->res->body
      and return $tx->res->code
      if $tx->error;

    my $entries = $tx->res->dom->find('entry');
    for my $entry (@{$entries}) {
      my $photo =
        Yandex::Fotki::Photo->new(sync => $self->sync, xml => $entry->to_xml);
      
      $photo->build_local_path;
      $self->photos->{$photo->local_path} = $photo;

    }

    if (my $next = $tx->res->dom->at('link[rel="next"]')) {
      $tmp_url = $next->{href};
    }
    else {
      $tmp_url = '';
      last;
    }

  }
}

sub build_local_path {
  my $self = shift;
  $self->SUPER::build_local_path;
  $self->sync->albums_by_path->{$self->local_path} = $self
    if $self->local_path;
}

1;
