#!/usr/bin/perl

use sigtrap 'handler' => \&exit_game, 'INT';

print "\e[2J";
$dictionary="/usr/games/words.txt";
$right=0; $wrong=0; $win=0;

unless ( -e $dictionary ) {
	print "\nERROR: $dictionary does not exist.\n";
	print "Find at http://www-01.sil.org/linguistics/wordlists/english/wordlist/wordsEn.txt";
	exit 1;
}

open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";
system("stty -echo");

open (DATAFILE, $dictionary);
@words= <DATAFILE>;
close(DATAFILE);
$lines=@words;

$file="/home/james/tmp/tmp";
open(my $fh, '>', $file);

sub new_word {
	draw_man( 0 );
	$wrong_guesses=0; $wrong_chars="";
	$line=int(rand($lines));
	$word=$words[$line]; chomp($word);
	$length=length($word);

	for ($i=0;$i<$length;$i++) {
		@output[$i]='_';
	}
	print "\e[9;1H";
	for ($i=0;$i<$length;$i++) {
		print "$output[$i] ";
	}
	print "\e[14;1HWins  : $right\nLosses: $wrong";
}
sub draw_man {
	   if ( $_[0] eq 0 ) { print "\e[2J\e[H____\n|  |\n|\n|\n|\n|_"; }
	elsif ( $_[0] eq 1 ) { print "\e[3;4HO"; }
	elsif ( $_[0] eq 2 ) { print "\e[3;4H\e[4mO\e[0m"; }
	elsif ( $_[0] eq 3 ) { print "\e[4;4H|"; }
	elsif ( $_[0] eq 4 ) { print "\e[4;3H/"; }
	elsif ( $_[0] eq 5 ) { print "\e[4;5H\\"; }
	elsif ( $_[0] eq 6 ) { print "\e[5;3H/"; }
	elsif ( $_[0] eq 7 ) { print "\e[5;5H\\"; &end_game; }
}
sub draw_word {
	if ( $word =~ $_[0] ) {
		$win=1;
		print "\e[9;1H";
		for ($i=0;$i<$length;$i++) {
			$char=substr($word, $i, 1);
			if ( $char eq $_[0] ) {
				@output[$i]=$_[0]; }
			elsif ( $output[$i] eq "_" ) {
				$win=0;
			}
			print "$output[$i] ";
		}
		if ( $win == 1 ) { &end_game; } }
	else {
		$wrong_guesses++;
		$wrong_chars="$wrong_chars$_[0]";
		print "\e[6;10H$wrong_chars";
		draw_man( $wrong_guesses );
	}
}
sub end_game {
print $fh "made it\n"; close $fh;
	if ( $win == 0 ) {
		print "\e[9;1H";
		for ($i=0;$i<$length;$i++) {
			if ( $output[$i] eq '_' ) {
				$char=substr($word, $i, 1);
				@output[$i]="\e[31m$char\e[39m";
			}
			print "$output[$i] ";
		}
		$wrong++; 
		print "\e[15;9H$wrong";
		print "\e[11;1HYou died."; }
	else {
		print "\e[9;1H";
		for ($i=0;$i<$length;$i++) {
			print "\e[32m$output[$i]\e[39m ";
		}
		$right++; 
		print "\e[14;9H$right";
		print "\e[11;1HWinner!";
	}
	print "\nPress q to quit or n for another word.\n";
	while () {
		$input=getc(TTY);
		if (($input eq 'q') || ($input eq 'Q')) {
			exit_game; }
		elsif (($input eq 'n') || ($input eq 'N') || ($input eq 'c') || ($input eq 'C')) {
			new_word;
			last;
		}
	}
}
sub exit_game {
	system("stty echo");
	print "\e[17;1HThanks for playing!\n";
	exit 0
}

new_word;

while () {
	print "\e[11;1HGuess:";
	$input = getc(TTY);
	if ( $input =~ /[[:alpha:]]/ ) {
		unless ( $wrong_chars =~ $input ) { 
			draw_word( $input );
		}
	}
}

exit_game;
