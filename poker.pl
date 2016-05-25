#!/usr/bin/perl

@deck=("2\x{2663}","3\x{2663}","4\x{2663}","5\x{2663}","6\x{2663}","7\x{2663}","8\x{2663}","9\x{2663}","10\x{2663}","J\x{2663}","Q\x{2663}","K\x{2663}","A\x{2663}","\e[31m2\x{2666}\e[39m","\e[31m3\x{2666}\e[39m","\e[31m4\x{2666}\e[39m","\e[31m5\x{2666}\e[39m","\e[31m6\x{2666}\e[39m","\e[31m7\x{2666}\e[39m","\e[31m8\x{2666}\e[39m","\e[31m9\x{2666}\e[39m","\e[31m10\x{2666}\e[39m","\e[31mJ\x{2666}\e[39m","\e[31mQ\x{2666}\e[39m","\e[31mK\x{2666}\e[39m","\e[31mA\x{2666}\e[39m","\e[31m2\x{2665}\e[39m","\e[31m3\x{2665}\e[39m","\e[31m4\x{2665}\e[39m","\e[31m5\x{2665}\e[39m","\e[31m6\x{2665}\e[39m","\e[31m7\x{2665}\e[39m","\e[31m8\x{2665}\e[39m","\e[31m9\x{2665}\e[39m","\e[31m10\x{2665}\e[39m","\e[31mJ\x{2665}\e[39m","\e[31mQ\x{2665}\e[39m","\e[31mK\x{2665}\e[39m","\e[31mA\x{2665}\e[39m","2\x{2660}","3\x{2660}","4\x{2660}","5\x{2660}","6\x{2660}","7\x{2660}","8\x{2660}","9\x{2660}","10\x{2660}","J\x{2660}","Q\x{2660}","K\x{2660}","A\x{2660}");

$money_file=$ENV{"HOME"}."/Games/data/cash_money.txt";
unless ( -e $money_file ) {
	qx(touch $money_file);
	qx(chmod 777 $money_file);
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

binmode STDOUT, ":utf8";
$cols=qx( tput cols );$rows=qx( tput lines );
print "\e[8;24;80;t";
print "\e[?25l";
$bet=1;
$x=2;

open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";
system("stty -echo");

print "\e[2J";

$file="/home/james/tmp/tmp/";
open(my $fh, '>', $file);

sub setup {
	for ($i=0;$i<5;$i++) {
		$tmpx=(10*$i+18);
		print "\e[13;${tmpx}H\e[4m      \e[0m";
		print "\e[14;${tmpx}H|    |\n";
		print "\e[15;${tmpx}H|    |\n";
		print "\e[16;${tmpx}H|    |\n";
		print "\e[17;${tmpx}H\e[4m|    |\e[0m";
	}
}
sub new_game {
	$total_games++;
	$x=2;
	@held_cards=(0,0,0,0,0);
	$cash=$cash-$bet;

	# Pick 10 cards at random.
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
	for ($i=0;$i<5;$i++) {
		$xa=$i*10+20;
		$xb=$i*10+19;
		if ( $current_cards[$i]%13 != 8 ) {
			print "\e[14;${xa}H $deck[$current_cards[$i]]";
			print "\e[17;${xb}H\e[4m$deck[$current_cards[$i]] \e[0m"; }
		else {
			print "\e[14;${xa}H$deck[$current_cards[$i]]";
			print "\e[17;${xb}H\e[4m$deck[$current_cards[$i]]\e[0m";
		}
	}
	print "\e[6;35HMoney: $cash\e[K";
	print "\e[7;35HBet  : $bet\e[K";
}
sub toggle_hold {
	print "\e[13;".(10*$_[0]+19)."H";
	if ( $held_cards[$_[0]] == 0 ) {
		print "\e[1;4mHELD\e[0m";
		@held_cards[$_[0]]=1; }
	else {
		print "\e[1;4m    \e[0m";
		@held_cards[$_[0]]=0;
	}
}
sub deal {
	$current_index=5;
	for ($i=0;$i<5;$i++) {
		if ( $held_cards[$i] == 0 ) {
			@current_cards[$i]=$current_cards[$current_index++];
		}
	}
	&output;

	$straight=0;$flush=0;$four_kind=0;$three_kind=0;$num_pairs=0;$starts_with_10=0;$jacks_or_better=0;
	@sorted=@current_cards;
	
	&sort_cards;
	&count_repeats;
	&count_suits;

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

	# Report back winnings/losses
	if ($hand eq "worthless") {
		print "\e[11;26HBetter luck next time.";
		print "\e[12;11HPress any key to continue, q to quit, or b to update your bet."; }
	else {
		$payment=$payout*$bet;
		$cash=$cash+$payment;
		print "\e[11;25H\e[32m$hand!\e[39m Payout: $payment";
		print "\e[6;35HMoney: $cash\e[K";
		print "\e[12;11HPress any key to continue, q to quit, or b to update your bet.";
	}
	while () {
		$input=getc(TTY);
		   if ($input eq "q") { &end_game; }
		elsif ($input eq "b") { &get_bet; &clean_up; &new_game; last; }
		else { &clean_up; &new_game; last; }
	}






#print "\e[20;1H";
#for ($i=0;$i<10;$i++){ print "$sorted[$i] "; } print ".\n";
#for ($i=0;$i<13;$i++){ print "$card_totals[$i] "; } print ".\n";
#for ($i=0;$i<4;$i++){ print "$suit_totals[$i] "; } print ".\n";
}
sub sort_cards {
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
}
sub count_repeats {
	@card_totals=(0,0,0,0,0,0,0,0,0,0,0,0,0);
	for ($i=0;$i<5;$i++) {
		$card_totals[$sorted[$i]%13]++;
	}
}
sub count_suits {
	@suit_totals=(0,0,0,0);
	for ($i=0;$i<5;$i++) {
		$suit_totals[$sorted[$i]/13]++;
	}
}
sub get_bet {
	print "\e[20;1HEnter new bet below\n";
	$changed=0;
	print "\e[?25h"; system("stty echo");
	while () {
		print "\e[21;1H\e[K";
		$input=<STDIN>; chomp($input);
		if ($input+0 ne $input) {
			print "\e[22;1HInvalid bet, use only numbers you dummy."; }
		elsif ($input > $cash) {
			print "\e[22;1HYou can't bet more than you have!\e[K"; }
		else {
			$bet=$input;
			last;
		}
	}
	print "\e[?25l"; system("stty -echo");
	print "\e[20;1H\e[K\n\e[K\n\e[K";
}
sub clean_up {
	print "\e[11;2H\e[2K\n\e[2K";
	for ($i=0;$i<5;$i++) {
		print "\e[13;".($i*10+19)."H\e[4m    \e[0m";
	}
}
sub end_game {
	open(my $fh, '>', $money_file);
	print $fh "$cash\n$total_games\n";
	close $fh;
	system("stty echo");
	print "\e[19;1H\e[?25h\n";
	exit 0
}

&setup;
&new_game;
use sigtrap 'handler' => \&end_game, 'INT';

while () {
	print "\e[18;".($x*10 + 18)."H\e[2K\e[4m      \e[0m";
	#print "\e[18
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

end_game
