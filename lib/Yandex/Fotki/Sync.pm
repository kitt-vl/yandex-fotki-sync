package Yandex::Fotki::Sync;
use strict;
use warnings;
use feature qw/say/;
use Carp;
use Mojo::Base -base;
use Mojo::Collection;
use IO::Easy;
use Data::Dumper;

has file_qr => sub{ qr/\.(jpg|png|bmp|gif)/i };

sub start{
	#croak 'Not implemented yet!';
	my $self = shift;
	my @img = $self->scan;
	
	say Dumper @img;
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
			#say $file->abs_path;
			push @$res, $file->abs_path if -f $file->abs_path && $file->abs_path =~ $self->file_qr;
			return 1 if -d $file->abs_path;
	});
	
	return $res;
}


1
