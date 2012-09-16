use strict;
use warnings;

package Yandex::Fotki::Photo;

use Mojo::Base 'Yandex::Fotki::Base';
use Mojo::DOM;

has link_album => '';
has access => 'public';
has xxx => 'false';
has hide_original => 'false';
has disable_comments => 'false';

has link_original => '';


sub upload{
    my ($self, $album_id) = (shift, shift);
    my $ua = $self->sync->ua;
    
    my $tx = $ua->post_form($self->sync->photos_url,
                            {
                                  image => { filename => $self->io->abs_path },
                                  title => $self->io->name

                                  
                            },
                            {
                                'Authorization' => 'OAuth ' . $self->sync->token
                            }
    );
    
    say 'UPLOAD RESPONSE: '. $tx->res->body;
    say 'UPLOAD ERROR: '. $tx->error if $tx->error;
    
    return unless $tx->res->code == 201;
    
    $self->parse($tx->res->body);
    return $self;
}

1;
