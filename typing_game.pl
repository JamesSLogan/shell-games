#!/usr/bin/perl

# NOTE: This code is not 100% portable. If you notice that words are not being
#       recognized as complete, change this offset variable to equal 1.
my $offset=0;

###############################################################################
#                         Variable Initializations                            #
###############################################################################

use strict;
use warnings;
use Time::HiRes qw(usleep gettimeofday);
use Term::ReadKey;

use sigtrap 'handler' => \&end_game, 'INT';

$|=1;

my $DICTIONARY="/usr/games/words.txt";

unless ( -e $DICTIONARY ) {
	print "\nERROR: $DICTIONARY does not exist. Get it from github.\n";
	exit 1;
}

open (TMP, $DICTIONARY);
my @WORDS = <TMP>;
close (TMP);
my $num_words = @WORDS;

# Game setup
my $increment=10; # How often speed goes up.
my $word_limit=23; # Lose if there are this many words on screen

my @active=();my $word_index=0;
my $alive=1;
my $prev=1;my $curr=1;my $diff=1;
my $input="";
my $x=1;my $y=0; # Determine where cursor is
my $start_time=gettimeofday;
my @template=(3.0, 2.6, 2.4, 2.2, 2.1, 2.0, 1.9, 1.8, 1.7, 1.6, 1.5, 1.4, 1.3, 1.2, 1.1, 1.0);
my @wait=();
my $wait_index=0;

ReadMode 3; # No echo, but you can still send signals.

###############################################################################
#                              Main functions                                 #
###############################################################################

# Main
sub main {
	&setup_wait;
	&clear_screen;
	&run_game;
	&end_game;
}

sub run_game {

	while ( $alive ) {
		&set_speed;

		# Add a word to array of active words.
		my $word = &generate_word; chomp $word;
		push ( @active, $word );

		# Print with new word
		&output;
		$y++;

		# Move cursor to correct position
		print "\e[$y;${x}H";
		
		# Make sure game isn't over
		if ( scalar(@active) > $word_limit ) {
			$alive=0;
			next;
		}

		# Wait for 1-3 seconds before adding next word.
		$diff = 0;
		$prev = gettimeofday;
		while ( $diff < $wait[$wait_index] ) {

			# Get non-blocking input
			$input = ReadKey(-1);

			# Is it the right letter?
			if ( defined($input) && defined($active[0]) ) { #prevents error msg
				if ( $input eq substr($active[0], $word_index, 1) ) {
					$word_index++;
					$x++;
					print "\e[$y;${x}H";
					if ( $word_index >= length($active[0])+$offset ) {
						$y--;
						$x=1;
						$word_index=0;
						shift @active;
						&output;
						print "\e[$y;${x}H";
					}
				}
			}

			usleep 100; # So that cpu can do other stuff I guess.
			$curr = gettimeofday;
			$diff = $curr - $prev;
		}
	}
}

sub output {
	&clear_screen;
	print "\e[1;1H";
	print join("\n", reverse @active),"\n\n";
	my $speed=int($wait_index/$increment);
	print "\e[1;72HSpeed: $speed";
}

# One-time sub that takes values from @template and assigns them to @wait.
# This is kind of cryptic, so here goes an explanation:
# 1. The game should get faster every 10 ($increment) seconds.
# 2. @template holds the (decreasing) values that the games uses to know how
#    long to wait for in between words.
# 3. This method copies those values to @wait 10 times, so that every second
#    that goes by while the game is running correlates to an element of @wait.
#    Then, every 10 seconds, the wait will go down.
sub setup_wait {
	for my $i (0 .. $#template) {
		for my $j ($i*$increment .. $i*$increment+$increment-1) {
			@wait[$j]=$template[$i];
		}
	}
}

# Sets "wait_index" variable which determines how long the program waits before
# adding another word.
sub set_speed {
	$curr = gettimeofday;
	$wait_index = int($curr - $start_time);

	# Don't increment if it's at max speed.
	if ( $wait_index >= scalar(@wait) ) {
		$wait_index=scalar(@wait)-1;
	}
}

sub generate_word {
	my $rand = int(rand($num_words));
	return "$WORDS[$rand]";
}

sub clear_screen {
	print "\e[2J";
}

# Exits and restores sane terminal settings
sub end_game {

	$curr = gettimeofday;
	my $elapsed = int($curr - $start_time);
	print "\e[24;1HYou made it for $elapsed seconds.\n";

	system("stty echo");
	exit 0;
}

###############################################################################
#                          Why is this so far down                            #
###############################################################################
&main
