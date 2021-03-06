use strict;
use warnings;

package Yandex::Fotki::Base;
use Mojo::Base -base;
use Mojo::DOM;
use Mojo::Util qw(url_unescape);

has id         => '';
has author     => '';
has title      => '';
has summary    => '';
has edited     => '';
has updated    => '';
has published  => '';
has link_self  => '';
has link_edit  => '';
has link_album => '';

has local_path => '';
has io         => undef;
has sync       => undef;

sub new {
  my ($class, %args) = @_;

  my $self = $class->SUPER::new(%args);

  #$self->load_info if $self->link_self && !$self->id;

  $self->parse($args{xml}) if exists $args{xml};

  return $self;
}

#sub load_info {
#my $self = shift;

#my $tx =
#$self->sync->ua->get( $self->link_self =>
#{ 'Authorization' => 'OAuth ' . $self->sync->token } );
#$self->parse( $tx->res->body );

#return $self;
#}

sub parse {
  my ($self, $xml) = (shift, shift);
  return unless $xml;

  utf8::decode($xml);

  my $dom = Mojo::DOM->new($xml);

  if (my $entry = $dom->at('entry')) {
    
    say 'DOM hasnt id method: ' , $xml , '-------------------------' unless $entry->at('id');
    
    $self->id($entry->id->text);
    $self->author($entry->author->name->text);
    $self->title($entry->title->text);

    my $link = $dom->at('link[rel="self"]');
    $self->link_self($link->{href});
  }

  return $dom;
}

sub build_local_path {
  my $self = shift;
  my $path = $self->title;
  my $parent =
    $self->sync->albums_by_link->{$self->link_album || 'NOT_EXIST_LINK'};

  while ($parent) {
    $path = $parent->title . '/' . $path;
    $parent =
      $self->sync->albums_by_link->{$parent->link_album || 'NOT_EXIST_LINK'};
  }

  utf8::encode($path);

  #say 'ALBUM LOCALPATH: ' . $path;
  $self->local_path($path);

}

sub parent_path {
  my $self = shift;

  my $path = '';
  if ($self->io) {
    $path =
      File::Spec->abs2rel($self->io->abs_path->path, $self->sync->work_path);

  }
  elsif ($self->local_path) {
    $path = $self->local_path;
  }

  my @dir = File::Spec->splitdir($path);
  return unless @dir;

  @dir = grep {$_} @dir;

  $self->title($dir[-1]);

  pop @dir;

  my $parent_path = join '/', @dir;

  #say 'PARENT_PATH : ' . $parent_path;

  return $parent_path;
}

1;
