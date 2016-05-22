#!/usr/bin/perl

###############################################################################
#                         Variable Initializations                            #
###############################################################################

use strict;
use warnings;
use sigtrap 'handler' => \&exit_game, 'INT';
use Time::HiRes qw(usleep gettimeofday);
use Term::ReadKey;

my $black="\e[30m";
my $red="\e[31m";
my $green="\e[32m";
my $yellow="\e[33m";
my $blue="\e[34m";
my $purple="\e[35m";
my $cyan="\e[36m";
my $bold="\e[1m";
my $reset="\e[0m";

#open(TTY, "+</dev/tty") or die "no tty: $!";
#system "stty cbreak </dev/tty >/dev/tty 2>&1";
#system("stty -echo");

my $DICTIONARY="/usr/games/words.txt";

open (TMP, $DICTIONARY);
my @WORDS = <TMP>;
close (TMP);
my $NUM_WORDS = @WORDS;

print "\e[8;40;80;t";

# Game setup
my @active=();my $active_index=0;my $word_index=0;
my $alive=1;
my $prev=1;my $curr=1;my $diff=1;
my $input="";
my $x=1;my $y=1;

ReadMode 3;


###############################################################################
#                              Main functions                                 #
###############################################################################

# Main
sub main {
	&clear_screen;
	&run_game;
	&end_game;
}

sub run_game {

	while ( $alive ) {
		# Add a word to array of active words.
		my $word = &generate_word; chomp $word;
		push ( @active, $word );

		# Print with new word
		&output;
		$y++;

		# Move cursor to correct position
		print "\e[$y;$xH";
		
		# Make sure game isn't over
		if ( scalar(@active) > 10 ) {
			$alive=0;
		}

		# Get input
		$diff = 0;
		while ( $diff < .9 ) {
			$prev = gettimeofday;

			# Get non-blocking input
			$input = ReadKey(-1);

			# Is it the right letter?
			if ( $input eq substr($active[0], $word_index, 1) ) {
				$x++;
				$word_index++;
				if ( $word_index >= length($active[0])-1 ) {
					shift @active;
					&output;
				}
			}

			$curr = gettimeofday;
			$diff = $curr - $prev;
		}
	}
}

sub output {
	&clear_screen;
	print join("\n", reverse @active),"\n\n";
}

sub get_empty_index {
	print "\n";
}

sub generate_word {
	my $rand = int(rand($NUM_WORDS));
	return "$WORDS[$rand]";
}

# Exits and restores sane terminal settings
sub end_game {
	system("stty echo");
#	print "Thanks for playing!\n";
#	ReadMode 0;
	exit 0;
}

###############################################################################
#                               Helper subs                                   #
###############################################################################
sub clear_screen {
	print "\e[2J";
}

sub cursor_on {
	print "\e[?25h";
}

sub cursor_off {
	print "\e[?25l";
}

sub debug {
	print "@_\n";
}

###############################################################################
#                          Why is this so far down                            #
###############################################################################
&main
