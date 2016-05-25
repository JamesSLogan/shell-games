#!/usr/bin/perl

@main_deck=("2\x{2663}","3\x{2663}","4\x{2663}","5\x{2663}","6\x{2663}","7\x{2663}","8\x{2663}","9\x{2663}","10\x{2663}","J\x{2663}","Q\x{2663}","K\x{2663}","A\x{2663}","\e[31m2\x{2666}\e[39m","\e[31m3\x{2666}\e[39m","\e[31m4\x{2666}\e[39m","\e[31m5\x{2666}\e[39m","\e[31m6\x{2666}\e[39m","\e[31m7\x{2666}\e[39m","\e[31m8\x{2666}\e[39m","\e[31m9\x{2666}\e[39m","\e[31m10\x{2666}\e[39m","\e[31mJ\x{2666}\e[39m","\e[31mQ\x{2666}\e[39m","\e[31mK\x{2666}\e[39m","\e[31mA\x{2666}\e[39m","\e[31m2\x{2665}\e[39m","\e[31m3\x{2665}\e[39m","\e[31m4\x{2665}\e[39m","\e[31m5\x{2665}\e[39m","\e[31m6\x{2665}\e[39m","\e[31m7\x{2665}\e[39m","\e[31m8\x{2665}\e[39m","\e[31m9\x{2665}\e[39m","\e[31m10\x{2665}\e[39m","\e[31mJ\x{2665}\e[39m","\e[31mQ\x{2665}\e[39m","\e[31mK\x{2665}\e[39m","\e[31mA\x{2665}\e[39m","2\x{2660}","3\x{2660}","4\x{2660}","5\x{2660}","6\x{2660}","7\x{2660}","8\x{2660}","9\x{2660}","10\x{2660}","J\x{2660}","Q\x{2660}","K\x{2660}","A\x{2660}");
@deck=("2\x{2663}","3\x{2663}","4\x{2663}","5\x{2663}","6\x{2663}","7\x{2663}","8\x{2663}","9\x{2663}","\x{277F}\x{2663}","J\x{2663}","Q\x{2663}","K\x{2663}","A\x{2663}","\e[31m2\x{2666}\e[39m","\e[31m3\x{2666}\e[39m","\e[31m4\x{2666}\e[39m","\e[31m5\x{2666}\e[39m","\e[31m6\x{2666}\e[39m","\e[31m7\x{2666}\e[39m","\e[31m8\x{2666}\e[39m","\e[31m9\x{2666}\e[39m","\e[31m\x{277F}\x{2666}\e[39m","\e[31mJ\x{2666}\e[39m","\e[31mQ\x{2666}\e[39m","\e[31mK\x{2666}\e[39m","\e[31mA\x{2666}\e[39m","\e[31m2\x{2665}\e[39m","\e[31m3\x{2665}\e[39m","\e[31m4\x{2665}\e[39m","\e[31m5\x{2665}\e[39m","\e[31m6\x{2665}\e[39m","\e[31m7\x{2665}\e[39m","\e[31m8\x{2665}\e[39m","\e[31m9\x{2665}\e[39m","\e[31m\x{277F}\x{2665}\e[39m","\e[31mJ\x{2665}\e[39m","\e[31mQ\x{2665}\e[39m","\e[31mK\x{2665}\e[39m","\e[31mA\x{2665}\e[39m","2\x{2660}","3\x{2660}","4\x{2660}","5\x{2660}","6\x{2660}","7\x{2660}","8\x{2660}","9\x{2660}","\x{277F}\x{2660}","J\x{2660}","Q\x{2660}","K\x{2660}","A\x{2660}");

$money_file=$ENV{"HOME"}."/Games/data/cash_money_50.txt";
unless ( -e $money_file ) {
	qx(touch $money_file);
	qx(chmod 666 $money_file);
	open(my $fh, '>', $money_file);
	print $fh "100\n0\n";
	close $fh;
}
open(MONEY, $money_file);
@stats=<MONEY>;
close(MONEY);
$cash=@stats[0]; chomp($cash);
$total_games=@stats[1]; chomp($total_games);

if ( $ARGV[0] eq "-g" ) {
	print "You have played $total_games games.\n";
	exit 0
}
elsif ( $ARGV[0] eq "-e" ) {
	print "What would you like to set your cash to?\n";
	print "Enter a number between 1 and 100000 without decimals or strange characters.\n";
	$input=<STDIN>; chomp($input);
	if ( $input <= 100000 && $input > 0 && $input+0 eq $input) {
		$cash=$input; }
	else {
		print "Enter a real value next time nerd.\n";
		exit 2;
	}
}
$cols=qx(tput cols); $rows=qx(tput lines);
$bet=.02;
$|=1;

print "\e[?25l";
system("stty -echo");
open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";
binmode STDOUT, ":utf8";

print "\e[H\e[2J";
print "\e[8;35;90;t";

sub setup {
	for ($i=0;$i<5;$i++) {
		$tmpx=10*$i+22;
		print "\e[24;${tmpx}H\e[4m      \e[0m";
		print "\e[25;${tmpx}H|    |";
		print "\e[26;${tmpx}H|    |";
		print "\e[27;${tmpx}H|    |";
		print "\e[28;${tmpx}H\e[4m|    |\e[0m";
	}
}
sub new_game {
	@little=('  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ','  ');
	$x=2;
	@held_cards=(0,0,0,0,0);
	$payment=0;
	$cash=$cash-$bet*50;
	$total_games++;

	$count=0; @current_cards=(-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1);
	while ( $count < 10 ) {
		$random_card=int(rand(52));
		$card_is_not_used=1;
		for ($i=0;$i<=$count;$i++) {
			if ( $current_cards[$i] == $random_card ) {
				$card_is_not_used=0;
				last;
			}
		}
		if ( $card_is_not_used ) {
			@current_cards[$count++]=$random_card;
		}
	}

	&output;
}
sub output {
	# Main hand
	for ($i=0;$i<5;$i++) {
		if ($current_cards[$i]%13 != 8) {
			print "\e[25;".($i*10+24)."H $main_deck[$current_cards[$i]]";
			print "\e[28;".($i*10+23)."H\e[4m$main_deck[$current_cards[$i]] \e[0m"; }
		else {
			print "\e[25;".($i*10+24)."H$main_deck[$current_cards[$i]]";
			print "\e[28;".($i*10+23)."H\e[4m$main_deck[$current_cards[$i]]\e[0m";
		}
	}

	# Little hands
	if (! $_[0]) {
	print "\e[2;1H";
	for ($i=0;$i<240;$i+=35) {
		for ($j=0;$j<31;$j+=5) {
			print "|";
			for ($k=0;$k<5;$k++) {
				print "$little[$i+$j+$k]";
			}
			print "| ";
		}
		print "\n\n";
	} }

	# Misc
	print "\e[25;1HPayout: $payment         \n";
	print "Money : $cash      ";
}
sub toggle_hold {
	print "\e[24;".(10*$_[0]+23)."H";
	if ($held_cards[$_[0]] == 0) {
		print "\e[1;4mHELD\e[0m";
		@held_cards[$_[0]]=1;
		$put=$current_cards[$_[0]];
		for ($i=0;$i<7;$i++) {
			for ($j=0;$j<7;$j++) {
				print "\e[".($i*3+2).";".($j*13+$_[0]*2+2)."H$deck[$put]";
			}
		} }
	else {
		print "\e[4m    \e[0m";
		@held_cards[$_[0]]=0;
		for ($i=0;$i<7;$i++) {
			for ($j=0;$j<7;$j++) {
				print "\e[".($i*3+2).";".($j*13+$_[0]*2+2)."H  ";
			}
		}
	}
}
sub deal {
	$index=0;
	for ($i=0;$i<5;$i++) {
		if ($held_cards[$i] == 1) {
			$held[$i]=$current_cards[$i]; }
		else {
			$held[$i]="";
		}
	}

	# Deal the main hand
	for ($i=0;$i<5;$i++) {
		if ($held_cards[$i] == 0) {
			while () {
				$random_card=int(rand(52));
				$card_is_not_used=1;
				for ($j=0;$j<5;$j++) {
					if ($current_cards[$j] == $random_card) {
						$card_is_not_used=0;
						last
					}
				}
				if ($card_is_not_used) {
					@current_cards[$i]=$random_card;
					last
				}
			}
		}
	}
	&check_main;
	&output(1);

	# Do the rest of the hands.
	for ($p=0;$p<49;$p++) {
		&deal_mini($p);
	}

	$cash=$cash+$payment;

	&output;

	while () {
		$rand_color=int(rand(6))+1;
		print "\e[32;24H\e[3${rand_color}mPress space or 0 to continue, or q to quit.\e[39m";
	
		# Executes until a character is pressed.
		local $SIG{ALRM} = sub {
			$rand_color=int(rand(6))+1;
			print "\e[32;24H\e[3${rand_color}mPress space or 0 to continue, or q to quit.\e[39m";
			alarm 1;
		};
		alarm 1;
		$input=getc(TTY);
		alarm 0;
		   if ($input eq "q") { &end_game; }
		elsif ($input eq " ") { &clean_up; &new_game; last; }
		elsif ($input eq "0") { &clean_up; &new_game; last; }
	}
}
sub deal_mini {
	@main=@held;
	# Fill in rest of hand
	for ($i=0;$i<5;$i++) {
		if ($held_cards[$i] == 1) {
			@little[5*$_[0]+$i]=$deck[$main[$i]]; }
		else {
			while ($little[5*$_[0]+$i] eq "  ") {
				$card_is_not_used=1;
				$random_card=int(rand(52));
				for ($j=0;$j<5;$j++) {
					if ($main[$j] == $random_card) {
						$card_is_not_used=0;
						last;
					}
				}
				if ($card_is_not_used) {
					@little[5*$_[0]+$i]=$deck[$random_card];
					@main[$i]=$random_card;
				}
			}
		}
	}

	$straight=0;$flush=0;$four_kind=0;$three_kind=0;$num_pairs=0;$starts_with_ten=0;$jacks_or_better=0;
	@sorted=@main;

	# Sort
	for ($i=0;$i<5;$i++) {
		$min=$sorted[$i]; $mindex=$i;
		for ($j=$i+1;$j<5;$j++) {
			if ( $sorted[$j] < $min ) {
				$min=$sorted[$j];
				$mindex=$j;
			}
		}
		if ( $mindex != $i ) {
			@sorted[$mindex]=$sorted[$i];
			@sorted[$i]=$min;
		}
	}

	# Count card repeats
	@card_totals=(0,0,0,0,0,0,0,0,0,0,0,0,0);
	for ($i=0;$i<5;$i++) {
		$card_totals[$sorted[$i]%13]++;
	}

	# Count suit totals
	@suit_totals=(0,0,0,0);
	for ($i=0;$i<5;$i++) {
		$suit_totals[$sorted[$i]/13]++;
	}

	# Straight
    STRAIGHT: for ($i=0;$i<13;$i++) {
        if ($card_totals[$i] == 1) {
            for ($j=1;$j<5;$j++) {
                if ($card_totals[$i+$j] ne 1) {
                    $j=0; last STRAIGHT;
                }
            }
            if ($j == 5) {
                $straight=1;
            }
        }
    }

    # Flush
    for ($i=0;$i<4;$i++) {
        if ($suit_totals[$i] == 5) {
            $flush=1;
        }
    }

    # 4 of a kind, 3 of a kind, and pairs.
    for ($i=0;$i<13;$i++) {
        if ($card_totals[$i] == 2) {
            $num_pairs++; }
        elsif ($card_totals[$i] == 3) {
            $three_kind=1; }
        elsif ($card_totals[$i] == 4) {
            $four_kind=1;
        }
    }

    # Jacks or better
    if ($num_pairs == 1) {
        for ($i=9;$i<13;$i++) {
            if ($card_totals[$i] == 2) {
                $jacks_or_better=1;
            }
        }
    }

    # Starts with ten (to distinguish straight flushes from royal flushes)
    if ($sorted[0]%13 == 8) {
        $starts_with_ten=1;
    }

	# Put all the tests together...
    $hand="worthless";
    $payout=0;

    if ($straight == 1) {
        if ($flush == 1) {
            if ($starts_with_ten == 1) {
                $hand="Royal Flush"; $payout=250; }
            else {
                $hand="Straight Flush"; $payout=50;
            } }
        else {
            $hand="Straight"; $payout=4;
        } }
    elsif ($four_kind == 1) {
        $hand="4 of a Kind"; $payout=25; }
    elsif ($flush == 1) {
        $hand="Flush"; $payout=6; }
    elsif ($three_kind == 1) {
        if ($num_pairs == 1) {
            $hand="Full House"; $payout=7; }
        else {
            $hand="3 of a Kind"; $payout=3;
        } }
    elsif ($num_pairs == 2) {
        $hand="Two Pair"; $payout=2; }
    elsif ($jacks_or_better == 1) {
        $hand="Jacks or Better"; $payout=1;
    }

	# Update the hand
	$tmpy=2+int($_[0]/7)*3;
	$tmpx=2+int($_[0]%7)*13;
	print "\e[$tmpy;${tmpx}H";
	for ($i=0;$i<5;$i++) {
		print "$deck[$main[$i]]";
		#print "\e[1;1H$tmpy, $tmpx\e[K";
#$useless=<STDIN>;
	}

	# Add text below hand describing value.
	if ($hand ne "worthless") {
		if ($hand eq "Royal Flush" || $hand eq "4 of a Kind") {
			print "\e[".(1+$tmpy).";${tmpx}H\e[1;36m$hand\e[0;39m";
			sleep .9; }
		elsif ($hand eq "Straight Flush") {
			print "\e[".(1+$tmpy).";".(1+$tmpx)."H\e[1;36mStraight";
			print "\e[".(2+$tmpy).";".(2+$tmpx)."HFlush\e[0;39m";
			sleep .9; }
		elsif ($hand eq "Jacks or Better") {
			print "\e[".(1+$tmpy).";".(1+$tmpx)."HJacks or";
			print "\e[".(2+$tmpy).";".(2+$tmpx)."HBetter"; }
		elsif ($hand eq "Full House") {
			print "\e[".(1+$tmpy).";${tmpx}H\e[1;34m$hand\e[0;39m"; }
		elsif ($hand eq "Flush") {
			print "\e[".(1+$tmpy).";".(2+$tmpx)."H\e[1;31m$hand\e[0;39m"; }
		elsif ($hand eq "Straight") {
			print "\e[".(1+$tmpy).";".(1+${tmpx})."H\e[1;32m$hand\e[0;39m"; }
		elsif ($hand eq "3 of a Kind") {
			print "\e[".(1+$tmpy).";${tmpx}H\e[1;35m$hand\e[0;39m"; }
		else {
			print "\e[".(1+$tmpy).";".(1+$tmpx)."H\e[33m$hand\e[39m";
		}
	}

	# Update Payout
	$payment=$payment+$bet*$payout;
	print "\e[25;1HPayout: $payment    ";

	select(undef, undef, undef, 0.1);
}
sub check_main {
	$straight=0;$flush=0;$four_kind=0;$three_kind=0;$num_pairs=0;$starts_with_ten=0;$jacks_or_better=0;
	@sorted=@current_cards;

	# Sort "current_card" and use "sorted" from here on out.
	for ($i=0;$i<5;$i++) {
		$min=$sorted[$i]; $mindex=$i;
		for ($j=$i+1;$j<5;$j++) {
			if ( $sorted[$j] < $min ) {
				$min=$sorted[$j];
				$mindex=$j;
			}
		}
		if ( $mindex != $i ) {
			@sorted[$mindex]=$sorted[$i];
			@sorted[$i]=$min;
		}
	}

	@card_totals=(0,0,0,0,0,0,0,0,0,0,0,0,0);
	for ($i=0;$i<5;$i++) {
		$card_totals[$sorted[$i]%13]++;
	}

	@suit_totals=(0,0,0,0);
	for ($i=0;$i<5;$i++) {
		$suit_totals[$sorted[$i]/13]++;
	}

	# Straight
    STRAIGHT: for ($i=0;$i<13;$i++) {
        if ($card_totals[$i] == 1) {
            for ($j=1;$j<5;$j++) {
                if ($card_totals[$i+$j] ne 1) {
                    $j=0; last STRAIGHT;
                }
            }
            if ($j == 5) {
                $straight=1;
            }
        }
    }

    # Flush
    for ($i=0;$i<4;$i++) {
        if ($suit_totals[$i] == 5) {
            $flush=1;
        }
    }

    # 4 of a kind, 3 of a kind, and pairs.
    for ($i=0;$i<13;$i++) {
        if ($card_totals[$i] == 2) {
            $num_pairs++; }
        elsif ($card_totals[$i] == 3) {
            $three_kind=1; }
        elsif ($card_totals[$i] == 4) {
            $four_kind=1;
        }
    }

    # Jacks or better
    if ($num_pairs == 1) {
        for ($i=9;$i<13;$i++) {
            if ($card_totals[$i] == 2) {
                $jacks_or_better=1;
            }
        }
    }

    # Starts with ten (to distinguish straight flushes from royal flushes)
    if ($sorted[0]%13 == 8) {
        $starts_with_ten=1;
    }

	# Put all the tests together...
    $hand="worthless";
    $payout=0;

    if ($straight == 1) {
        if ($flush == 1) {
            if ($starts_with_ten == 1) {
                $hand="Royal Flush"; $payout=250; }
            else {
                $hand="Straight Flush"; $payout=50;
            } }
        else {
            $hand="Straight"; $payout=4;
        } }
    elsif ($four_kind == 1) {
        $hand="4 of a Kind"; $payout=25; }
    elsif ($flush == 1) {
        $hand="Flush"; $payout=6; }
    elsif ($three_kind == 1) {
        if ($num_pairs == 1) {
            $hand="Full House"; $payout=7; }
        else {
            $hand="3 of a Kind"; $payout=3;
        } }
    elsif ($num_pairs == 2) {
        $hand="Two Pair"; $payout=2; }
    elsif ($jacks_or_better == 1) {
        $hand="Jacks or Better"; $payout=1;
    }

    # Output hand if it won.
    if ($hand ne "worthless") {
		$tmpx=45-int(length($hand)/2);
		print "\e[30;${tmpx}H";
		#print "\e[30;38H";
		if ($hand eq "Royal Flush" || $hand eq "Straight Flush" || $hand eq "4 of a Kind") {
			print "\e[1;36m$hand\e[0;39m"; }
		else {
			print "$hand";
		}
    }

	# Update payout
	$payment=$payment+$bet*$payout;
	print "\e[25;1HPayout: $payment       ";
}
sub clean_up {
	@lines=("3","4","6","7","9","10","12","13","15","16","18","19","21","22","30","32");
	for (@lines) {
		print "\e[$_;1H\e[K";
	}
	for ($i=0;$i<5;$i++) {
		$tmpx=10*$i+22;
		print "\e[24;${tmpx}H\e[4m      \e[0m";
	}
}
sub end_game {
	open(my $fh, '>', $money_file);
	print $fh "$cash\n$total_games\n";
	close $fh;
	system("stty echo");
	print "\e[32;1H\e[?25h\n";
	exit 0
}

&setup;
&new_game;
use sigtrap 'handler' => \&end_game, 'INT';

while () {
	print "\e[29;".($x*10+22)."H\e[2K\e[4m      \e[0m";
	$input=getc(TTY);

	   if ( $input eq "C" ) { if ($x < 4) { $x++; } }
	elsif ( $input eq "D" ) { if ($x > 0) { $x--; } }
	elsif ( $input eq " " ) { &toggle_hold($x); }
	elsif ( $input eq "1" ) { &toggle_hold(0); }
	elsif ( $input eq "2" ) { &toggle_hold(1); }
	elsif ( $input eq "3" ) { &toggle_hold(2); }
	elsif ( $input eq "4" ) { &toggle_hold(3); }
	elsif ( $input eq "5" ) { &toggle_hold(4); }
	elsif ( $input eq "\n") { &deal; }
	elsif ( $input eq "q" ) { &end_game; }
}

&end_game;
