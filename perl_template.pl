#!/usr/bin/perl

###############################################################################
#                         Variable Initializations                            #
###############################################################################

$black="\e[30m";
$red="\e[31m";
$green="\e[32m";
$yellow="\e[33m";
$blue="\e[34m";
$purple="\e[35m";
$cyan="\e[36m";
$bold="\e[1m";
$reset="\e[0m";

use sigtrap 'handler' => \&end_game, 'INT';

open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";
system("stty -echo");




# Exits and restores sane terminal settings
sub end_game {
	system("stty echo");
	print "Thanks for playing!\n";
	exit 0;
}

###############################################################################
#                              Helper methods                                 #
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
