#!/usr/bin/perl

###############################################################################
#                         Variable Initializations                            #
###############################################################################

use strict;
use warnings;
use sigtrap 'handler' => \&exit_game, 'INT';
use Time::HiRes qw(usleep gettimeofday);

my $black="\e[30m";
my $red="\e[31m";
my $green="\e[32m";
my $yellow="\e[33m";
my $blue="\e[34m";
my $purple="\e[35m";
my $cyan="\e[36m";
my $bold="\e[1m";
my $reset="\e[0m";

open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";
system("stty -echo");

my $DICTIONARY="/usr/games/words.txt";

open (TMP, $DICTIONARY);
my @WORDS = <TMP>;
close (TMP);
my $NUM_WORDS = @WORDS;

print "\e[8;40;80;t";

# Game setup
my @active=();
my $alive=1;
my $input="";


###############################################################################
#                              Main functions                                 #
###############################################################################

# Main
sub main {
	&run_game;
	&end_game;
}

sub run_game {

	while ( $alive ) {
		# Add a word to array of active words.
		my $word = &generate_word; chomp $word;
		push ( @active, $word );

		# Print with new word
		print join("\n", reverse @active),"\n\n";
		
		# Make sure game isn't over
		if ( scalar(@active) > 10 ) {
			$alive=0;
		}

		# Get input
		my $diff = 0;
		while ( $diff < .9 ) {
			my $prev = gettimeofday;

			# 			
			$input = getc(TTY);

			my $curr = gettimeofday;
			my $diff = $curr - $prev;
		}
	}
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
