#!/usr/bin/perl

open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";

$DICTIONARY="/usr/games/words.txt";

#http://stackoverflow.com/questions/7651/how-do-i-remove-duplicate-items-from-an-array-in-perl

#
# Gets user input for size of board and what letters to use.
#
sub setup {
	print "How many rows and columns does this board have?\n";
	$input=<STDIN>; chomp($input);
	$SIZE=$input;
	
	print "Enter the board as is, with lines between rows, but no spaces between letters:\n";

	$main_index=0;
	for ($i=0;$i<$SIZE;$i++) {
	
		$display=$i+1;
		$input=<STDIN>; chomp($input);
	
		$SIZE == length($input) or die "Number of rows and columns must match.";
	
		for ($j=0;$j<$SIZE;$j++) {
			@board[$main_index]=substr($input, $j, 1);
			$main_index++
		}
	}
	
	#print "@board\n";
}

#
# Creates the "links" array that contains adjacent letters.
#
sub get_links {

	$length=$SIZE*$SIZE;
	$link_index=0;

	for ($i=0;$i<$length;$i++) {
		for ($j=-1;$j<2;$j++) {
			for ($k=-1;$k<2;$k++) {

				$index=$i+$SIZE*$j+$k;

				#
				# We want to exclude indices that aren't valid.
				# That is, all edge cases of the board.
				# This is a bit tricky since the array is 1D.
				#
				if    ($index == $i) {}      # Ignore self
				elsif ($index < 0) {}        # Ignore negative entries
				elsif ($index >= $length) {} # Ignore indices that are obviously OOB

				# If $i is on the left edge, ignore all right edge cells.
				elsif ( ($i % $SIZE) == 0 && (($index+1) % $SIZE) == 0 ) {}

				# If $i is on the right edge, ignore all left edge cells.
				elsif ( (($i+1) % $SIZE) == 0 && ($index % $SIZE) == 0 ) {}

				# Cell is valid.
				else {
					@links[$link_index]="$board[$i]$board[$index]";
					$link_index++;
				}
			}
		}
	}
	print "@links\n";
	print "\n";
}

sub search_dictionary {

	open my $fh, '<', $DICTIONARY or die;

	# Go through each line of the dictionary file. If every 2 letters match any pattern in
	#+the "links" array, then it's good.
	while (my $line = <$fh>) {

		$j=0;
		chomp($line);

		for ($i=0;$i<scalar(@links);$i++) {
print "i: $i, \@links[\$i]: $links[$i]\n";
			$broken=0;
			if ($line !~ /$links[$i]/) {
print "$line does not contain $links[$i]\n";
				$broken=1;
				last;
			}
			if ($broken == 0) {
print "$line does contain $links[$i]\n";
				@winner[$j]=$line;
				$j++;
			}
		}
	}
	print "@winner\n";
	exit;
}

&setup;
&get_links;
&search_dictionary;
