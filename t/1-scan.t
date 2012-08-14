use strict;
use warnings;
use utf8;
use lib 'lib';
use feature qw/say/;
use File::Spec::Functions;
use Win32::API;
use Test::More tests => 6;
binmode(STDOUT, ':unix :utf8');

if ($^O eq 'MSWin32')
{
    #Must set the console code page to UTF8
    say 'SWITCH TO UTF8';
    my $SetConsoleOutputCP= new Win32::API( 'kernel32.dll', 'SetConsoleOutputCP', 'N','N' );
    $SetConsoleOutputCP->Call(65001);    
}


use_ok 'Yandex::Fotki::Sync';

my $sync = Yandex::Fotki::Sync->new;
is $sync->scan('t')->isa('Mojo::Collection'), 1, 'Right class of scan result';

#11 pics
is $sync->scan()->size, 11, 'Right number of total pictures current dir';
is $sync->scan('t')->size, 11, 'Right number of total pictures in "t" directory';

my $utf_path = 'суб дир 2'; 

is $sync->scan(catfile('t', 'testdir 1'))->size, 3, 'Right number of total pictures subdir';
say 'PATH IS "' . catfile('t', $utf_path) . '" end of PATH; length = ' . length($utf_path);
is $sync->scan(catfile('t', $utf_path))->size, 6, 'Right number of total pictures in subdir with non ASCII chars';



