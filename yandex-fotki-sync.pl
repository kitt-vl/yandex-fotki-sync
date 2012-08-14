use strict;
use warnings;

use 5.016;
use utf8;
use Win32::API;
use Encode;
use File::Spec::Functions;
use Cwd;


binmode(STDOUT, ':unix');
#my $abc = 'Аа Бб Вв Гг Дд Ее Ёё Жж Зз Ии Йй Кк Лл Мм Нн Оо Пп Рр Сс Тт Уу Фф Хх Цц Чч Шш Щщ Ьь Ыы Ъъ Ээ Юю Яя';

#say STDOUT $abc;
#say STDOUT '-----------------------------------------------------------------';
#say STDOUT 'Valid = ' . utf8::valid($abc);

if ($^O eq 'MSWin32')
{
    #Must set the console code page to UTF8
    say 'SWITCH TO UTF8';
    my $SetConsoleOutputCP= new Win32::API( 'kernel32.dll', 'SetConsoleOutputCP', 'N','N' );
    $SetConsoleOutputCP->Call(65001);    
}

my $utf_path = 't\суб дир 2'; 
utf8::encode($utf_path);
#my $utf_path = 't\testdir 1'; 

Encode::from_to($utf_path,'utf8', 'cp1251');
opendir DH, $utf_path or die "OPEN DIR FILED!! " . $!;

while(readdir(DH))
{
    #say 'DIR CONTENT: '. $_;
    #utf8::decode($_);
    #utf8::encode($_);
    #Encode::from_to($_,'cp1251', 'utf8');
    say 'DIR ENCODED:' . $_ ;
}

closedir DH;








