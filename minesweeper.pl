#!/usr/bin/perl
#
use sigtrap 'handler' => \&end_game, 'INT', 'ABRT', 'QUIT', 'TERM';

$COLS=qx( tput cols );$ROWS=qx( tput lines );
print "\e[8;25;60;t";
open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";
system("stty -echo");

sub update {
	print "\e[?25l\e[H";
	for ($i=0;$i<$rows*$cols;$i++) {
		print "$out[$main[$i]]\e[0m ";
		if ( ! (($i+1)%$cols) ) { print "\n"; }
	}
	print "\nFlags: $flags out of $mines\n";
	print "Press h for controls";
	print "\e[?25h";
}
sub flag {
	$var=$main[$cols*$_[1]+$_[0]];
	   if ( $var == 9  ) { @main[$cols*$_[1]+$_[0]]=10; $flags++; }
	elsif ( $var == 10 ) { @main[$cols*$_[1]+$_[0]]=11; $flags--; }
	elsif ( $var == 11 ) { @main[$cols*$_[1]+$_[0]]=9; }
}
sub check_for_win {
	if ( $flags eq $mines ) {
		$count=0;
		for ($i=0;$i<$rows*$cols;$i++) {
			if ( $main[$i] == 10 && $mine[$i] == 1 ) {
				$count++;
			}
		}
		if ( $count == $mines ) {
			$CURR_TIME=time;$TOTAL_TIME=($CURR_TIME-$START_TIME);$mins=int($TOTAL_TIME/60);$secs=$TOTAL_TIME%60;
			print "\e[".($rows+2).";1H\e[1;32mWinner!\e[0;39m\e[K\n";
			print "Time: $mins min, $secs sec. \nPress n/c for new game or q to quit.\n";
			loop: while () {
				$input = getc(TTY);
				   if ($input eq "q") { end_game; }
				elsif ($input eq "n") { new_game ($difficulty);last; }
				elsif ($input eq "c") { new_game ($difficulty);last loop; }
				elsif ($input eq "1") { new_game (1);last; }
				elsif ($input eq "2") { new_game (2);last; }
				elsif ($input eq "3") { new_game (3);last; }
				elsif ($input eq "4") { new_game (4);last; }
			}
		}
	}
}
sub search {
	local $i;local $j;local $xtemp;local $ytemp;
	if ( $mine[$cols*$_[1]+$_[0]] == 1 ) {
		for ($p=0;$p<$rows*$cols;$p++) {
			if ( $mine[$p] == 1 ) {
				$main[$p]=12;
			}
		}
		update;
		print "\e[".($rows+2).";1HBOOM you lose.\e[K\n";
		print "Press n/c for new game or q to quit.\n\e[K";
		while () {
			$input = getc(TTY);
			   if ($input eq "q") { end_game; }
			elsif ($input eq "n") { new_game ($difficulty);last; }
			elsif ($input eq "c") { new_game ($difficulty);last; }
			elsif ($input eq "1") { new_game (1);last; }
			elsif ($input eq "2") { new_game (2);last; }
			elsif ($input eq "3") { new_game (3);last; }
			elsif ($input eq "4") { new_game (4);last; }
		}
	} else {
		# If a non-mine was flagged...
		if ( $main[$cols*$_[1]+$_[0]] == 10 ) { $flags--; }

		$number=$numb[$cols*$_[1]+$_[0]];
		# If the searched cell is a zero...
		if ( ! $number ) {
			@main[$cols*$_[1]+$_[0]]=0;
			for ($j=-1;$j<2;$j++) { for ($i=-1;$i<2;$i++) {
				# Check in-bounds surrounding cells recursively.
				if ( $i+$_[0] >= 0 && $j+$_[1] >= 0 && $i+$_[0] < $cols && $j+$_[1] < $rows && ($j != 0 || $i != 0) ) {
					$xtemp=$i+$_[0];$ytemp=$j+$_[1];
					if ( $main[$cols*$ytemp+$xtemp] ) {
						search ($i+$_[0], $j+$_[1]);
					}
				}
			}}
		} else {
			@main[$cols*$_[1]+$_[0]]=$number;
		}
	}
}
sub controls {
	$PAUSE_TIME=time;
	print "\e[2J\e[H";
	print "Movement : arrow keys.\n";
	print "Flag     : f\n";
	print "Search   : s\n";
	print "New game : n,c,1,2,3,4 (1-4: easy-hard)\n";
	print "Quit     : q\n";
	print "Pause    : p\n";
	print "\nPress any key to continue...";
	$useless=getc(TTY);
	$START_TIME+=(time-$PAUSE_TIME);
}
sub pause {
	print "\e[2J\e[H";
	$PAUSE_TIME=time;
	print "Press any key to continue...";
	$useless=getc(TTY);
	$START_TIME+=(time-$PAUSE_TIME);
}
sub new_game {
	print "\e[2J\e[HLoading...";
	$x=1;$y=1;
	$NUMBER=0;$flags=0;

	$difficulty=$_[0];
	   if ( $difficulty eq 1 ) { $rows=10;$cols=10;$mines=15; }
	elsif ( $difficulty eq 2 ) { $rows=15;$cols=15;$mines=35; }
	elsif ( $difficulty eq 3 ) { $rows=20;$cols=20;$mines=75; }
	elsif ( $difficulty eq 4 ) { $rows=20;$cols=30;$mines=100; }

	# Initialize arrays
	for ($i=0;$i<$rows*$cols;$i++) {
		@main[$i]='9';
		@mine[$i]='0';
		@numb[$i]='9';
	}

	# Set up mines
	$total=0;
	while ( $total < $mines ) {
		$index=int(rand($rows*$cols));
		if ( $mine[$index] eq 0 ) {
			@mine[$index]=1;
			$total++;
		}
	}

	# Set up number array
	for ($p=0;$p<$rows*$cols;$p++) {
		if ( $mine[$p] == 1 ) {
			@numb[$p]='*'; }
		else {
			$total=0;
			$tx=$p % $cols;$ty=int($p / $cols);
			for ($j=-1;$j<2;$j++) { for ($i=-1;$i<2;$i++) {
				if ( $tx+$i >= 0 && $ty+$j >= 0 && $tx+$i < $cols && $ty+$j < $rows && ($j != 0 || $i != 0) ) {
					$tx_tmp=$tx+$i;$ty_tmp=$ty+$j;
					if ( $mine[$cols*$ty_tmp + $tx_tmp] == 1 ) { $total++; }
				}
			}}
			@numb[$p]=$total;
		}
	}
	$START_TIME=time;$PAUSE_TIME=0;
	update;
}

@out=("\e[37m0", "\e[36m1", "\e[32m2", "\e[31m3", "\e[35m4", "\e[33m5", "\e[34m6", "\e[36m7", "\e[36m8", "#", "\e[1mX", "?", "\e[1m*");

new_game 1;
print "\e[2J\e[H";
update;

while () {
	print "\e[${y};".(${x}*2-1)."H";
	$input = getc(TTY);
	   if ($input eq "A") { if ( $y > 1 ) { $y--; } }
	elsif ($input eq "B") { if ( $y < $rows ) { $y++; } }
	elsif ($input eq "C") { if ( $x < $cols ) { $x++; } }
	elsif ($input eq "D") { if ( $x > 1 ) { $x--; } }
	elsif ($input eq "q") { end_game; }
	elsif ($input eq "f") { flag ($x-1, $y-1); update; check_for_win; }
	elsif ($input eq "s") { search ($x-1, $y-1); update; }
	elsif ($input eq "1") { new_game (1); }
	elsif ($input eq "2") { new_game (2); }
	elsif ($input eq "3") { new_game (3); }
	elsif ($input eq "4") { new_game (4); }
	elsif ($input eq "h") { controls;print "\e[2J\e[H";update; }
	elsif ($input eq "p") { pause;print "\e[2J\e[H";update; }
	elsif ($input eq "n") { new_game ($difficulty); }
	elsif ($input eq "c") { new_game ($difficulty); }
}

sub end_game {
	print "\e[8;$ROWS;$COLS;t";
	print "\e[2J\e[H";
	system("stty echo");
	exit;
}
