use strict;
use warnings;

package Yandex::Fotki::Sync;
use Yandex::Fotki::Album;
use Yandex::Fotki::Photo;

use Mojo::Base -base;
use Mojo::UserAgent;
use Mojo::Collection;
use IO::Easy;
use File::Spec;
use File::Spec::Functions;
use File::HomeDir;
use YAML::Tiny;
use Getopt::Long qw(GetOptionsFromArray);
use Encode;
use Data::Dumper;
#my $auth_id = 'f6612965aba347c986dc52361b655f08';
has version => '1.0';

has file_qr => sub{ qr/\.(jpg|png|bmp|gif)$/i };

has base_url => 'api-fotki.yandex.ru';
has auth_url => 'https://oauth.yandex.ru/authorize?response_type=token&client_id=5e0c4dfec7104aba81a35bd7678a993b&redirect_uri=https://oauth.yandex.ru/verification_code';

has base_user_url => sub { my $self = shift; return join('/', $self->base_url, 'api', 'users', $self->login); };

has albums_url => sub{ 	
            my $self = shift; 
						$self->load_service_document unless $self->service_document;
						my $dom = Mojo::DOM->new($self->service_document);
						my $link = $dom->at('collection[id="album-list"]');
						return $link->{href} if $link;
						
};

has photos_url => sub{ 
            my $self = shift; 
						$self->load_service_document unless $self->service_document;
						my $dom = Mojo::DOM->new($self->service_document);
						my $link = $dom->at('collection[id="photo-list"]');
						return $link->{href} if $link; 
};

has ua => sub { my $ua = Mojo::UserAgent->new;
                $ua->max_redirects(50);
                #$ua->inactivity_timeout(100);
                $ua->name('Yandex::Fotki::Sync/' . shift->version);
                return $ua; 
};

has home_path => sub{ File::HomeDir->my_home };
has config_path => sub{ catfile(shift->home_path, '.yf-sync.yml') };
has work_path => '';

has login => '';
has password => '';
has token => '';

has options => sub { \@ARGV };

has service_document => '';
has albums => sub { Mojo::Collection->new; };

sub start{
  binmode(STDOUT, ':unix');    
	my $self = shift;
    $self->auth;
}

=head 3
Scanning directory path passed as arg
returns Mojo::Collection with image files
=cut
sub scan{
    
	my ($self, $path) = (shift, shift);
	$path = '.' unless defined $path;
	
	my $res = Mojo::Collection->new;
	my $io = IO::Easy->new($path);
	
	$io->as_dir->scan_tree(sub{
			my $file = shift;

			push @$res, Yandex::Fotki::Photo->new(local_path => $file->rel_path, io => $file, sync => $self)
												if -f $file->abs_path && $file->abs_path =~ $self->file_qr;
			return 1 if -d $file->abs_path;
	});
	
	return $res;
}

sub load_config{
    my $self = shift;
    my $yaml = YAML::Tiny->read($self->config_path);

    $self->token($yaml->[0]->{$self->login}->{token});
    $self->password('') if $self->token;
}


sub save_config{
    my $self = shift;
    my $yaml = YAML::Tiny->read($self->config_path) // YAML::Tiny->new;
    
    $yaml->[0]->{$self->login} = { token => $self->token};
    $yaml->write( $self->config_path );    
}

sub auth{
    my $self = shift;
      
    die 'Empty login!' unless $self->login;
    
    my $ua = $self->ua;    
    my $tx = $ua->get( $self->auth_url);
    
    my $node = $tx->res->dom->at('form.b-authorize-form');
    die "Cant find AUTHORIZE FORM!" unless $node;
    
    my $auth2_url = $node->{action};
    
    unless($auth2_url =~ /^http/)
    {
		my $auth_full = Mojo::URL->new($tx->req->url);
		$auth_full->path($auth2_url);
		$auth2_url =  $auth_full;
		
	}
    
    $tx = $ua->post_form($auth2_url => {login => $self->login, passwd => $self->password, allow => ''});
    my ($_token) = ($tx->req->url->fragment // '') =~ /access_token\=(.*?)\&/; 

    $self->token($_token // '');
}

sub parse_options{
    my $self = shift;
    my $opt = $self->options;
    my ($login, $password, $dir);
    my $ret = GetOptionsFromArray( $opt, 
                                'login=s' => \$login,
                                'password=s' => \$password,
                                'dir=s' => \$dir);
    $self->login($login);
    $self->password($password);
    $self->work_path($dir);
}

sub load_service_document{
    my $self = shift;
    die 'Empty login!' unless $self->login;
    
    my $ua = $self->ua;
    my $service_url =  $self->base_user_url . '/';
    my $tx = $ua->get($service_url);
    
    my $tmp = $tx->res->body;    
    utf8::decode($tmp);    
    $self->service_document($tmp) if $tx->success;
}

sub load_albums{
	my $self = shift;
	
	my $ua = $self->ua;
	my $tmp_url = $self->albums_url;
	$self->albums(Mojo::Collection->new);
	
	while($tmp_url)
	{
		my $tx = $ua->get($tmp_url);
		my $entries = $tx->res->dom->find('entry');
		
		for my $entry( @$entries)
		{
			my $album = Yandex::Fotki::Album->new( xml => $entry->to_xml, sync => $self);
			push @{$self->albums}, $album;
			#say 'Album link: '.$album->link_self;
		}
		
		my $next_page = $tx->res->dom->at('link[rel="next"]');
		
		if($next_page)
		{
			$tmp_url = $next_page->{href};
		}
		else
		{
			$tmp_url = '';
		}			
	}
	
	#build hierarhy
	for my $cur_album (@{$self->albums})
	{
		next unless $cur_album->link_parent;
		
    $cur_album->hierarhy;
	}
	
	#build local path from parents
	for my $cur_album (@{$self->albums})
	{
		$cur_album->build_local_path;
	}
	
}

sub find_album_by_path{
	my ($self, $path) = (shift, shift);

	#my (undef, $dir, undef) = File::Spec->splitpath(File::Spec->abs2rel($path));
	$path = join '\\', File::Spec->splitdir($path);

	return $self->albums->first( sub{ $_->local_path eq $path } );	
	
}
1;
