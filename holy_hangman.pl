#!/usr/bin/perl

use sigtrap 'handler' => \&exit_game, 'INT';

$bible_file="/usr/games/bible.txt";

# Make sure Bible exists
unless ( -e $bible_file ) {
	print "\nERROR: $bible_file does not exist.\n";
	exit 1;
}

print "\e[8;30;100;t";

# Parse options for: book, group, or help
if ( $#ARGV != -1 ) {

	# User chooses book option
	# Takes spaces in input into account
	if ( $ARGV[0] eq "-b" || $ARGV[0] eq "--book" ) {
		if ( $ARGV[1] =~ /[123]$/ ) {
			$ARGV[2] =~ tr/A-Z/a-z/;
			&get_indices("$ARGV[1] $ARGV[2]");
		} elsif ( $ARGV[1] =~ /[Ss][Oo][Nn][Gg]/ ) {
			&get_indices("song of songs");
		} else {
			$ARGV[1] =~ tr/A-Z/a-z/;
			&get_indices($ARGV[1]);
		}
		$it_is_a_book=1;
	}

	# User chooses group option
	# Handles spaces by concatenating all arguments passed
	elsif ( $ARGV[0] eq "-g" || $ARGV[0] eq "--group" ) {
		$i=1;
		$param="";
		while ( $ARGV[$i] ne "" ) {
			$param="$param$ARGV[$i] ";
			$i++;
		}
		$param =~ s/ $//;
		$param =~ tr/A-Z/a-z/;
		&get_group_indices($param);
		$it_is_a_group=1;
	}

	elsif ( $ARGV[0] eq "-h" || $ARGV[0] eq "--help" ) {
			print "\e[1mUsage:\e[0m [OPTION] [STRING]\n";
			print "\n";
			print "\e[1mOptions:\e[0m\n";
			print "\t-b, --book\tOnly get verses from one book of the Bible.\n";
			print "\t\t\tValid strings are books of the Bible.\n";
			print "\n";
			print "\t-g, --group\tOnly get verses from a group of books of the Bible.\n";
			print "\t\t\tValid groups are:\n\t\t\t    \e[1mOld Testament\n\t\t\t    New Testament\e[0m\n\t\t\t    \e[1mLaw\e[0m\t\t(Gen, Exo, Lev, Num, Deu)\n\t\t\t    \e[1mHistory\e[0m\t(Jos, Jud, Rut, 1&2 Sam, 1&2 Kin, 1&2 Chr, Ezr, Neh, Est)\n\t\t\t    \e[1mWisdom\e[0m, \e[1mWisdom no Job\e[0m\t (Job, Pro, Ecc, Son)\n\t\t\t    \e[1mPoetry\e[0m\t(Psa, Lam)\n\t\t\t    \e[1mMajor Prophets\e[0m\n\t\t\t    \e[1mMinor Prophets\e[0m\n\t\t\t    \e[1mGospels\e[0m\n\t\t\t    \e[1mGospels with Acts\e[0m\n\t\t\t    \e[1mEpistles\e[0m, \e[1mEpistles Paul only\e[0m, \e[1mEpistles non-Paul\e[0m\n\t\t\t    \e[1mApocalyptic\e[0m\t(Eze, Dan, Rev)\n";
			print "\n";
			print "\t-h, --help\tDisplay help and exit.\n";
			print "\n";
			print "\e[1mNotes:\e[0m\n";
			print "\t1. If no options are specified, verses are pulled from the whole Bible.\n";
			print "\t2. Books and groups don't need to be in quotes AND they're not case sensitive.\n";
			print "\t3. Use \"Song of Songs\", not \"Song of Solomon.\"\n";
			print "\t4. If you choose the \e[1mbook\e[0m option, you will have 8 guesses instead of 10.\n";
			print "\t5. If you choose the \e[1mgroup\e[0m option, you will have 9 guesses instead of 10.\n";
			exit;

	}
} else {
	$beg=1;
	$end=31103;
}

# Misc initializations
print "\e[2J";
system("stty -echo");
print "\e[?25l";
$right=0;$wrong=0;$win=0;

open (BIBLE, $bible_file);
@verses = <BIBLE>;
close (BIBLE);

open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";

$file="/home/james/tmp/tmp";
open(my $fh, '>', $file) or die "Could not open debug file";

#
# Picks verse from Bible and outputs it
#
sub new_word {

	# Misc initializations
	@verse_output=(); @book_output=(); @chapter_output=(); @verse_number_output=(); @tmp_verse_output=(); @skipped_space=();
	$game_state=0;
	$wrong_chars="";
	$count=0;

	&draw_man(0);

	# Set up hanging man
	if ( $it_is_a_book ) {
		&draw_man(1);
		&draw_man(2);
		$wrong_guesses=2; }
	elsif ( $it_is_a_group ) {
		&draw_man(1);
		$wrong_guesses=1; }
	else {
		$wrong_guesses=0;
	}

	# Get a line
	if ($bleg) {
		$line="";
		$total=$end-$beg;
		while ( ! $line ) {
			$line=$beg+int(rand($total))-1;
			if ( $line >= $blbeg && $line < $blend ) {
				$line="";
			}
		} }
	else {
		$total=$end-$beg;
		$line=$beg+int(rand($total))-1;
	}

	# Get data from verse
	($book,$both_numbers,$verse) = split('@', $verses[$line]);
	($chapter,$verse_number) = split(':', $both_numbers);

	# Set up array: book_output
	for ($i=0; $i<length($book); $i++) {
		if ( substr($book, $i, 1) ne ' ' ) {
			@book_output[$i]='_'; }
		else {
			@book_output[$i]=' ';
		}
	}

	# Set up array: chapter_output
	for ($i=0; $i<length($chapter); $i++) {
		@chapter_output[$i]='_';
	}

	# Set up array: verse_number_output
	for ($i=0; $i<length($verse_number); $i++) {
		@verse_number_output[$i]='_';
	}

	# Set up array: tmp_verse_output
	chomp($verse);
	for ($i=0; $i<length($verse); $i++) {
		if ( substr($verse, $i, 1) =~ /[[:alpha:]]/ ) {
			@tmp_verse_output[$i]='_'; }
		elsif ( substr($verse, $i, 1) eq ' ' ) {
			@spaces[$count]=$i;
			$count++;
			@tmp_verse_output[$i]=' '; }
		else {
			@tmp_verse_output[$i]=substr($verse, $i, 1);
		}
	}

	# Annoying stuff to make the verse output display such that no word will
	#+be split up onto two lines.
	$j=0;
	$diff=0;
	# j indexes output array, i indexes string.
	for ( $i=0; $i<length($verse); $i++) {
		$the_next_one_should_not_be_copied=0;

		# last_space: used in determining how much to backtrack (later)
		if ( $tmp_verse_output[$i] eq ' ' ) {
			$last_space=$i;
		}

		# If the output (array index) reaches the terminal border...
		if ( $j%50 == 49 ) {
			$char=$tmp_verse_output[$i];
			$next=$tmp_verse_output[$i+1];

			# If a word is split up over two lines...
			if ( $char eq '_' ) {
				if ( $next =~ /[_,?\;:!\).]/ ) {
					$diff=$i-$last_space;
					$j=$j-$diff+1;
					for ($k=0; $k<$diff; $k++) {
						@verse_output[$j]=' ';
						$j++;
					}
					if ( $diff > 1 ) {
						for ($k=$diff-1; $k>0; $k--) {
							@verse_output[$j]=$tmp_verse_output[$i-$diff+1];
							$j++;
						}
					}
				}
			}

			# If the next line has a leading space, it doesn't need to be
			#+copied into the output array
			if ( $next eq ' ' ) {
				$the_next_one_should_not_be_copied=1;
				@skipped_space[$i+1]=1;
			}
		}

		@verse_output[$j]=$tmp_verse_output[$i];
		$j++;

		if ( $the_next_one_should_not_be_copied ) {
			$i++;
		}
	}

	print "\e[9;1H";
	print join(' ', @verse_output);

	print "\e7";
	print "\e[28;1HWins  : $right\nLosses: $wrong";

print $fh "$verses[$line]\n";
}

# Draws hung man.
# Game ends when he falls to his death.
sub draw_man {
	   if ( $_[0] == 0 ) { print "\e[2J\e[H____\n|\n|\n|\n|\n|_"; }
	elsif ( $_[0] == 1 ) { print "\e[2;4H|"; }
	elsif ( $_[0] == 2 ) { print "\e[3;4HO"; }
	elsif ( $_[0] == 3 ) { print "\e[3;4H\e[4mO\e[0m"; }
	elsif ( $_[0] == 4 ) { print "\e[4;4H|"; }
	elsif ( $_[0] == 5 ) { print "\e[4;3H/"; }
	elsif ( $_[0] == 6 ) { print "\e[4;5H\\"; }
	elsif ( $_[0] == 7 ) { print "\e[5;3H/"; }
	elsif ( $_[0] == 8 ) { print "\e[5;5H\\"; }
	elsif ( $_[0] == 9 ) { print "\e[2;4H "; }
	elsif ( $_[0] == 10) { print "\e[2;1H|\n|   \n|\e[31m  O \n\e[0m|\e[31m /|\\ \n \b\e[0m|\e[4m \e[0;31m/ \\ \e[0m"; &they_lost }

	   if ( $game_state == "0" ) { print "\e[1;7HGuess the : verse\e[K"; }
	elsif ( $game_state == "1" ) { print "\e[1;7HGuess the : book\e[K"; }
	elsif ( $game_state == "2" ) { print "\e[1;7HGuess the : chapter\e[K"; }
	elsif ( $game_state == "3" ) { print "\e[1;7HGuess the : verse number\e[K"; }
}

# Handles outputting the right characters at the right place.
sub draw_word {

	# Player is guessing the verse
	if ( $game_state == 0 ) {

		# If the guess is correct, output it
		if ( $verse =~ $_[0] ) {
			print "\e[9;1H";
			$game_state=1;
			$j=0;

			# Loops through verse (string) but outputs verse_output (array).
			# Confusing, I know.
			for ($i=0;$i<length($verse)-1;$i++) {
				if (($verse_output[$j] eq ' ') && ($verse_output[$j+1] eq ' ')) {
					$j++;
					$i--;
					print "  ";
					next;
				}
				if ($skipped_space[$i]) {
					next;
				}

				if (substr($verse, $i, 1) eq $_[0]) {
					@verse_output[$j]=$_[0]; }
				elsif ($verse_output[$j] eq '_') {
					$game_state=0;
				}

				print "$verse_output[$j] ";
				$j++;
			}

			# Sets up guessing for a book if user makes it
			if ($game_state == 1) {
				print "\e[9;1H\e[32m";
				print join(' ', @verse_output);
				print "\e[0m";

				$wrong_chars="";
				print "\e[6;10H\e[K";

				if ($it_is_a_book) { 
					$game_state=2;

					print "\e[1;7HGuess the : chapter.\e[K";

					print "\e8\n\n\e[36m$book\e[K\e[0m";

					print "\e8\n\n\n\n";
					print join('', @chapter_output);
					print "\e[K"; }
				else {
					print "\e[1;7HGuess the : book.\e[K";

					print "\e8\n\n";
					print join('', @book_output);
					print "\e[K"; 
				}
			}
		}
		else {
			$wrong_guesses++;
			$wrong_chars="$wrong_chars$_[0]";
			print "\e[6;10H$wrong_chars";
			&draw_man($wrong_guesses);
		}
	}

	# Player is guessing the book
	elsif ( $game_state == 1 ) {

		# If the guess is correct, output it
		if ( $book =~ $_[0] ) {
			print "\e8\n\n";
			$game_state=2;

			for ($i=0;$i<length($book);$i++) {
				if ( substr($book, $i, 1) eq $_[0]) {
					@book_output[$i]=$_[0];
				}
				if ( $book_output[$i] eq '_' ) {
					$game_state=1;
				}
				print "$book_output[$i]";
			}

			# If they completed guessing book, prepare for chapter guessing
			if ( $game_state == 2 ) {
				print "\e8\n\n\e[32m$book\e[K\e[0m";

				print "\e[1;7HGuess the : chapter.\e[K";

				$wrong_chars="";
				print "\e[6;10H\e[K";

				print "\e8\n\n\n\n";
				print join('', @chapter_output);
				print "\e[K";
			}
		}
		else {
			$wrong_guesses++;
			$wrong_chars="$wrong_chars$_[0]";
			print "\e[6;10H$wrong_chars";
			&draw_man($wrong_guesses);
		}
	}

	# Player is guessing the chapter
	elsif ( $game_state == 2 ) {

		# If the guess is correct, output it
		if ( $chapter =~ $_[0] ) {
			print "\e8\n\n\n\n";
			$game_state=3;

			for ($i=0;$i<length($chapter);$i++) {
				if ( substr($chapter, $i, 1) eq $_[0]) {
					@chapter_output[$i]=$_[0];
				}
				if ( $chapter_output[$i] eq '_' ) {
					$game_state=2;
				}
				print "$chapter_output[$i]";
			}

			# If they completed guessing chapter, prepare for verse number guessing
			if ( $game_state == 3 ) {
				print "\e[1;7HGuess the : verse number.";

				$wrong_chars="";
				print "\e[6;10H\e[K";

				print "\e8\n\n\n\n\e[32m";
				print join('', @chapter_output);
				print "\e[K\e[0m";

				print ":".join('', @verse_number_output);
			}
		}
		else {
			$wrong_guesses++;
			$wrong_chars="$wrong_chars$_[0]";
			print "\e[6;10H$wrong_chars";
			&draw_man($wrong_guesses);
		}
	}

	# Player is guessing the verse number
	elsif ( $game_state == 3 ) {

		# If the guess is correct, output it
		if ( $verse_number =~ $_[0] ) {
			print "\e8\n\n\n\n\e[32m$chapter\e[0m:";

			$game_state=4;

			for ($i=0;$i<length($verse_number);$i++) {
				if ( substr($verse_number, $i, 1) eq $_[0]) {
					@verse_number_output[$i]=$_[0];
				}
				if ( $verse_number_output[$i] eq '_' ) {
					$game_state=3;
				}
				print "$verse_number_output[$i]";
			}

			# Winner, prompts for new game here
			if ( $game_state == 4 ) {
				print "\e8\n\n\n\n\e[32m$chapter:$verse_number\e[0m";

				print "\e[1;7H\e[K";

				$wrong_chars="";
				print "\e[6;10H\e[K";

				$right++;
				print "\e[28;1HWins  : $right";

				print "\e8\n\n\n\n\n\n";
				print "Good job!\nPress any key for another verse, or q to quit.";

				print "\e[?25h";
				$input = getc(TTY);
				if ( $input eq "q" ) {
					&exit_game; }
				else {
					&new_word;
				}
			}
		}
		else {
			$wrong_guesses++;
			$wrong_chars="$wrong_chars$_[0]";
			print "\e[6;10H$wrong_chars";
			&draw_man($wrong_guesses);
		}
	}
}

sub they_lost {
	$wrong++;
	print "\e[29;1HLosses: $wrong";

	print "\e[6;10H\e[K";

	# Output verse
	print "\e[9;1H";
	$j=0;
	for ($i=0;$i<length($verse)-1;$i++) {
		# Instances of extra spaces in verse_output must be outputted
		if (($verse_output[$j] eq ' ') && ($verse_output[$j+1] eq ' ')) {
			$j++;
			$i--;
			print "  ";
			next;
		}

		# If there is an instance where verse_output does NOT contain a space
		#+between a word, nothing should be outputted.
		if ($skipped_space[$i]) {
			next;
		}

		if ( $verse_output[$j] eq '_' ) {
			print "\e[31m".substr($verse, $i, 1)." "; }
		else {
			print "\e[32m".substr($verse, $i, 1)." ";
		}

		$j++;
	}
	print "\e[0m\n\n";

	# Output book
	if ($it_is_a_book) {
		print "\e[36m$book"; }
	else {
		for ($i=0;$i<length($book);$i++) {
			if ($book_output[$i] eq '_') {
				print "\e[31m".substr($book, $i, 1); }
			else {
				print "\e[32m".substr($book, $i, 1);
			}
		}
	}
	print "\e[0m\e[K\n\n";

	# Output chapter
	for ($i=0;$i<length($chapter);$i++) {
		if ($chapter_output[$i] eq '_') {
			print "\e[31m".substr($chapter, $i, 1); }
		else {
			print "\e[32m".substr($chapter, $i, 1);
		}
	}
	print "\e[0m:";

	# Output verse number
	for ($i=0;$i<length($verse_number);$i++) {
		if ($verse_number_output[$i] eq '_') {
			print "\e[31m".substr($verse_number, $i, 1); }
		else {
			print "\e[32m".substr($verse_number, $i, 1);
		}
	}
	print "\e[0m\e[K\n\n";

	# Prompt for new game
	print "Press any key for another verse, or q to quit.\e[?25h";
	$input = getc(TTY);
	if ($input eq "q") {
		&exit_game; }
	else {
		&new_word;
	}
}

sub exit_game {
	system("stty echo");
	print "\n\e[?25h";
	close $fh;
	exit 0;
}

&new_word;

while () {
	print "\e8";
	   if ($game_state == 0) { print "\n\n"; }
	elsif ($game_state == 1) { print "\n\n\n\n"; }
	else  { print "\n\n\n\n\n\n"; }

	print "Guess:\e[K";
	print "\e[?25h";
	$input = getc(TTY);
	print "\e[?25l";

	if ($input =~ /[[:alnum:]]/) {
		unless ($wrong_chars =~ $input) {
			&draw_word($input);
		}
	}
}

sub get_indices {
	print "$_[0].\n";
	$blbeg="";
	$blend="";
	   if ( $_[0] eq "genesis"         ) { $beg=1; $end=1534; }
	elsif ( $_[0] eq "exodus"          ) { $beg=1534; $end=2747; }
	elsif ( $_[0] eq "leviticus"       ) { $beg=2747; $end=3606; }
	elsif ( $_[0] eq "numbers"         ) { $beg=3606; $end=4894; }
	elsif ( $_[0] eq "deuteronomy"     ) { $beg=4894; $end=5853; }
	elsif ( $_[0] eq "joshua"          ) { $beg=5853; $end=6411; }
	elsif ( $_[0] eq "judges"          ) { $beg=6411; $end=7129; }
	elsif ( $_[0] eq "ruth"            ) { $beg=7129; $end=7214; }
	elsif ( $_[0] eq "1 samuel"        ) { $beg=7214; $end=8024; }
	elsif ( $_[0] eq "2 samuel"        ) { $beg=8024; $end=8719; }
	elsif ( $_[0] eq "1 kings"         ) { $beg=8719; $end=9535; }
	elsif ( $_[0] eq "2 kings"         ) { $beg=9535; $end=10254; }
	elsif ( $_[0] eq "1 chronicles"    ) { $beg=10254; $end=11196; }
	elsif ( $_[0] eq "2 chronicles"    ) { $beg=11196; $end=12018; }
	elsif ( $_[0] eq "ezra"            ) { $beg=12018; $end=12298; }
	elsif ( $_[0] eq "nehemiah"        ) { $beg=12298; $end=12704; }
	elsif ( $_[0] eq "esther"          ) { $beg=12704; $end=12871; }
	elsif ( $_[0] eq "job"             ) { $beg=12871; $end=13941; }
	elsif ( $_[0] eq "psalms"          ) { $beg=13941; $end=16402; }
	elsif ( $_[0] eq "proverbs"        ) { $beg=16402; $end=17317; }
	elsif ( $_[0] eq "ecclesiastes"    ) { $beg=17317; $end=17539; }
	elsif ( $_[0] eq "song of songs"   ) { $beg=17539; $end=17656; }
	elsif ( $_[0] eq "isaiah"          ) { $beg=17656; $end=18948; }
	elsif ( $_[0] eq "jeremiah"        ) { $beg=18948; $end=20312; }
	elsif ( $_[0] eq "lamentations"    ) { $beg=20312; $end=20466; }
	elsif ( $_[0] eq "ezekiel"         ) { $beg=20466; $end=21739; }
	elsif ( $_[0] eq "daniel"          ) { $beg=21739; $end=22096; }
	elsif ( $_[0] eq "hosea"           ) { $beg=22096; $end=22293; }
	elsif ( $_[0] eq "joel"            ) { $beg=22293; $end=22366; }
	elsif ( $_[0] eq "amos"            ) { $beg=22366; $end=22512; }
	elsif ( $_[0] eq "obadiah"         ) { $beg=22512; $end=22533; }
	elsif ( $_[0] eq "jonah"           ) { $beg=22533; $end=22581; }
	elsif ( $_[0] eq "micah"           ) { $beg=22581; $end=22686; }
	elsif ( $_[0] eq "nahum"           ) { $beg=22686; $end=22733; }
	elsif ( $_[0] eq "habakkuk"        ) { $beg=22733; $end=22789; }
	elsif ( $_[0] eq "zephaniah"       ) { $beg=22789; $end=22842; }
	elsif ( $_[0] eq "haggai"          ) { $beg=22842; $end=22880; }
	elsif ( $_[0] eq "zechariah"       ) { $beg=22880; $end=23091; }
	elsif ( $_[0] eq "malachi"         ) { $beg=23091; $end=23146; }
	elsif ( $_[0] eq "matthew"         ) { $beg=23146; $end=24217; }
	elsif ( $_[0] eq "mark"            ) { $beg=24217; $end=24895; }
	elsif ( $_[0] eq "luke"            ) { $beg=24895; $end=26046; }
	elsif ( $_[0] eq "john"            ) { $beg=26046; $end=26925; }
	elsif ( $_[0] eq "acts"            ) { $beg=26925; $end=27932; }
	elsif ( $_[0] eq "romans"          ) { $beg=27932; $end=28365; }
	elsif ( $_[0] eq "1 corinthians"   ) { $beg=28365; $end=28802; }
	elsif ( $_[0] eq "2 corinthians"   ) { $beg=28802; $end=29059; }
	elsif ( $_[0] eq "galatians"       ) { $beg=29059; $end=29208; }
	elsif ( $_[0] eq "ephesians"       ) { $beg=29208; $end=29363; }
	elsif ( $_[0] eq "philippians"     ) { $beg=29363; $end=29467; }
	elsif ( $_[0] eq "colossians"      ) { $beg=29467; $end=29562; }
	elsif ( $_[0] eq "1 thessalonians" ) { $beg=29562; $end=29651; }
	elsif ( $_[0] eq "2 thessalonians" ) { $beg=29651; $end=29698; }
	elsif ( $_[0] eq "1 timothy"       ) { $beg=29698; $end=29811; }
	elsif ( $_[0] eq "2 timothy"       ) { $beg=29811; $end=29894; }
	elsif ( $_[0] eq "titus"           ) { $beg=29894; $end=29940; }
	elsif ( $_[0] eq "philemon"        ) { $beg=29940; $end=29965; }
	elsif ( $_[0] eq "hebrews"         ) { $beg=29965; $end=30268; }
	elsif ( $_[0] eq "james"           ) { $beg=30268; $end=30376; }
	elsif ( $_[0] eq "1 peter"         ) { $beg=30376; $end=30481; }
	elsif ( $_[0] eq "2 peter"         ) { $beg=30481; $end=30542; }
	elsif ( $_[0] eq "1 john"          ) { $beg=30542; $end=30647; }
	elsif ( $_[0] eq "2 john"          ) { $beg=30647; $end=30660; }
	elsif ( $_[0] eq "3 john"          ) { $beg=30660; $end=30674; }
	elsif ( $_[0] eq "jude"            ) { $beg=30674; $end=30699; }
	elsif ( $_[0] eq "revelation"      ) { $beg=30699; $end=31103; }
	else { print "Invalid book selection\n"; exit 1; }
}
sub get_group_indices {
	print "$_[0].\n";
	$blbeg="";
	$blend="";
	   if ( $_[0] eq "law"                ) { $beg=1;     $end=5853; }
	elsif ( $_[0] eq "history"            ) { $beg=5853;  $end=12871; }
	elsif ( $_[0] eq "wisdom"             ) { $beg=12871; $end=17656; $blbeg=13941; $blend=16402; }
	elsif ( $_[0] eq "wisdom no job"      ) { $beg=16402; $end=17656; }
	elsif ( $_[0] eq "poetry"             ) { $beg=13941; $end=20466; $blbeg=16402; $blend=20312; }
	elsif ( $_[0] eq "major prophets"     ) { $beg=17656; $end=22096; $blbeg=20312; $blend=20466; }
	elsif ( $_[0] eq "minor prophets"     ) { $beg=22096; $end=23146; }
	elsif ( $_[0] eq "gospels"            ) { $beg=23146; $end=26925; }
	elsif ( $_[0] eq "gospels with acts"  ) { $beg=23146; $end=27932; }
	elsif ( $_[0] eq "epistles"           ) { $beg=27932; $end=30699; }
	elsif ( $_[0] eq "epistles paul only" ) { $beg=27932; $end=29965; }
	elsif ( $_[0] eq "epistles non-paul"  ) { $beg=29965; $end=30699; }
	elsif ( $_[0] eq "apocalyptic"        ) { $beg=20466; $end=31103; $blbeg=22096; $blend=30699; }
	elsif ( $_[0] eq "old testament"      ) { $beg=1; $end=23146; }
	elsif ( $_[0] eq "new testament"      ) { $beg=23146; $end=31103; }
	else { print "Invalid group selection\n"; exit 1; }
}
