#!/usr/bin/perl

#
# Notes for anybody trying to read this code:
#
# 1. Hands are saved as arrays of numbers 0-51. See @DECK for what those cards 
#    actually are.
#
# 2. A bunch of data is stored in the hash GAME_DATA. It's global and basically
#    every sub will use something in it.
#
# 3. There are many places where code could be optimized. But perl is fast
#    and this is so low on memory usage so it wasn't worth it when creating.
#
# 4. CPUs don't try and shoot the moon yet.
#

###############################################################################
# SET UP
###############################################################################

use strict;
use warnings;
use sigtrap 'handler' => \&end_game, 'INT', 'ABRT', 'QUIT', 'TERM';
use Data::Dumper;
use POSIX;

binmode STDOUT, ":utf8"; # supresses 'wide character' messages.

open(TTY, "+</dev/tty") or die "no tty: $!";
system "stty  cbreak </dev/tty >/dev/tty 2>&1";
system("stty -echo");
system("tput civis");

open(my $FH, '>', 'tmp.txt');
print $FH "\n";
close $FH;

$|=1;

#
# Special variables:
#

my $cols=qx(tput cols); my $rows=qx(tput lines);

my $HEIGHT = 45;
my $WIDTH = 100;

print "\e[H\e[2J";
print "\e[8;$HEIGHT;$WIDTH;t";

my $left_edge = 1;
my $right_edge = $HEIGHT;
my $top_edge = 1;
my $bottom_edge = $WIDTH;

#
# Global variables:
#

use constant BOTTOM   => 0;
use constant LEFT     => 1;
use constant TOP      => 2;
use constant RIGHT    => 3;

use constant CLUBS    => 0;
use constant DIAMONDS => 1;
use constant SPADES   => 2;
use constant HEARTS   => 3;

my %GAME_DATA;
my @PERSONS = ( 0 .. 3 );
my @PASS_CARDS = ();
my @POINT_CARDS = (39..51); push(@POINT_CARDS, 36);

my $black     = "\e[30m";
my $red       = "\e[31m";
my $green     = "\e[32m";
my $yellow    = "\e[33m";
my $blue      = "\e[34m";
my $purple    = "\e[35m";
my $cyan      = "\e[36m";
my $bold      = "\e[1m";
my $underline = "\e[4m";
my $reset     = "\e[0m";

my $club    = "\x{2663}";
my $diamond = "\x{2666}";
my $heart   = "\x{2665}";
my $spade   = "\x{2660}";

my @DECK = ();
push(@DECK, ("2$club","3$club","4$club","5$club","6$club","7$club","8$club","9$club","\x{277F}$club","J$club","Q$club","K$club","A$club"));
push(@DECK, ("${red}2$diamond$black","${red}3$diamond$black","${red}4$diamond$black","${red}5$diamond$black","${red}6$diamond$black","${red}7$diamond$black","${red}8$diamond$black","${red}9$diamond$black","${red}\x{277F}$diamond$black","${red}J$diamond$black","${red}Q$diamond$black","${red}K$diamond$black","${red}A$diamond$black"));
push(@DECK, ("2$spade","3$spade","4$spade","5$spade","6$spade","7$spade","8$spade","9$spade","\x{277F}$spade","J$spade","Q$spade","K$spade","A$spade"));
push(@DECK, ("${red}2$heart$black","${red}3$heart$black","${red}4$heart$black","${red}5$heart$black","${red}6$heart$black","${red}7$heart$black","${red}8$heart$black","${red}9$heart$black","${red}\x{277F}$heart$black","${red}J$heart$black","${red}Q$heart$black","${red}K$heart$black","${red}A$heart$black"));

my @POINTS = (0) x 39;
$POINTS[36] = 13;
push(@POINTS, (1) x 13);

my @NAMES = ('You', 'West', 'North', 'East');

###############################################################################
# SETUP / OUTPUT SUBS
###############################################################################

sub new_game
{
    %GAME_DATA = ();

    $GAME_DATA{STATE} = 0; # See what this means in main sub.
    $GAME_DATA{HANDCOUNT} = 0;

    new_hand();

    for (@PERSONS)
    {
        $GAME_DATA{$_}{POINTS} = 0;
    }
}

sub new_hand
{
    $GAME_DATA{TURN} = 1;

    $GAME_DATA{MSG} = "";
    $GAME_DATA{MSGCOLOR} = "";

    $GAME_DATA{HEARTSBROKEN} = 0;

    $GAME_DATA{HANDCOUNT}++;

    my @shuffled = shuffle();

    # Give each person 13 cards and 0 points.
    for (@PERSONS)
    {
        my $start_idx = $_ * 13;
        my $end_idx = ($_+1) * 13 - 1;
        
        $GAME_DATA{$_}{HAND} = ();
        my @hand = @shuffled[$start_idx..$end_idx];
        push @{$GAME_DATA{$_}{HAND}}, sort { $a <=> $b } @hand;

        $GAME_DATA{$_}{CURRENTCARD} = undef;
    }
}

sub shuffle
{
    my @deck = ( 0 .. 51 );
    my $tmp;
    my $rand;

    # Loop through the deck once, swapping the current value with a random one.
    for (@deck)
    {
        $rand = int(rand(52));
        $tmp = $deck[$_];

        $deck[$_] = $deck[$rand];
        $deck[$rand] = $tmp;
    }

    return @deck;
}

# Currently draws cpu hands with 1 extra card if they play a card before human.
sub draw_board
{
    my $top = "______";
    my $mid = "|    |";
    my $bot = "$underline|    |$reset";

    my $num_spaces;

    my $num_cards = scalar(@{$GAME_DATA{&BOTTOM}{HAND}});

    # Used for top and bottom hands
    $num_spaces = ceil(($WIDTH - $num_cards*7) / 2);
    my $spaces = " " x $num_spaces;

    # Print top hand
    print "\e[H\e[2J";
    print "$spaces", "$top " x $num_cards, "\n";
    print "$spaces", "$mid " x $num_cards, "\n";
    print "$spaces", "$mid " x $num_cards, "\n";
    print "$spaces", "$mid " x $num_cards, "\n";
    print "$spaces", "$bot " x $num_cards, "\n";

    # Print left and right hands
    my $num_lines = 14 - $num_cards;
    print "\n" x $num_lines;

    $num_spaces = $WIDTH - (2*length($top)) - 2;
    for ( 0 .. $num_cards )
    {
        print " $top", " " x $num_spaces, "$top", "\n";
        print " $mid", " " x $num_spaces, "$mid", "\n";
    }

    print "\n" x $num_lines;

    # Print bottom hand
    print "$spaces", "$top " x $num_cards, "\n";
    print "$spaces";
#    for ( @{$GAME_DATA{&BOTTOM}{HAND}} ) { print "|  $DECK[$_]| "; }
    for ( @{$GAME_DATA{&LEFT}{HAND}} ) { print "|  $DECK[$_]| "; }
    print "\n";
    print "$spaces", "$mid " x $num_cards, "\n";
    print "$spaces", "$mid " x $num_cards, "\n";
    print "$spaces";
#    for ( @{$GAME_DATA{&BOTTOM}{HAND}} ) { print "$underline|$DECK[$_]  |$reset "; }
    for ( @{$GAME_DATA{&LEFT}{HAND}} ) { print "$underline|$DECK[$_]  |$reset "; }

    # Print any cards that have been played.
    for (@PERSONS)
    {
        if (defined($GAME_DATA{$_}{CURRENTCARD}))
        {
            draw_card_in_middle($_, $GAME_DATA{$_}{CURRENTCARD});
        }
    }

    return $spaces;
}

sub pass_print
{
    return if ($GAME_DATA{STATE} > 1);

    my $hand = shift;
    my $hand_mod = $hand % 4;

    return unless($hand_mod); # No pass = no print

    print "Pass: ";

       if ($hand_mod == 1) { print "Left";   }
    elsif ($hand_mod == 2) { print "Right";  }
    elsif ($hand_mod == 3) { print "Across"; }
}

sub draw_card_in_middle
{
    my ($player, $card) = @_;
    my $card_out = $DECK[$GAME_DATA{$player}{HAND}[$card]];

    my $top = "______";
    my $mid = "|    |";
    my $bot = "$underline|    |$reset";

    my $x = 43;
    my $y = 13;
       if ($player == BOTTOM) { $x += 5;  $y += 12; }
    elsif ($player == LEFT  ) { $x += 0;  $y += 6;  }
    elsif ($player == TOP   ) { $x += 5;  $y += 0;  }
    elsif ($player == RIGHT ) { $x += 10; $y += 6;  }

    # Print the card line by line. Notice the y++.
    print "\e[$y;${x}H$top";                             $y++;
    print "\e[$y;${x}H|  $card_out|";                 $y++;
    print "\e[$y;${x}H$mid";                             $y++;
    print "\e[$y;${x}H$mid";                             $y++;
    print "\e[$y;${x}H$underline|$card_out  |$reset";
}

# Toggles a card to be passed or not. Writes to @PASS_CARDS
sub toggle
{
    my $selection = shift;

    # Go through the array and remove the element if it's already in there.
    for my $i (0 .. $#PASS_CARDS)
    {
        if ( $PASS_CARDS[$i] == $selection )
        {
            splice(@PASS_CARDS, $i, 1);
            $GAME_DATA{STATE} = 0;
            return 0;
        }
    }

    if (scalar(@PASS_CARDS) == 3)
    {
        msg("You can only pass 3 cards.", $red);
        return 1;
    }

    # If we've made it this far, add the selection to PASS_CARDS.
    push(@PASS_CARDS, $selection);

    $GAME_DATA{STATE} = 1 if (scalar(@PASS_CARDS) == 3);
}

# If we want to display total points AND points per hand, we'll need to track
# both. Total is all that is displayed currently.
sub display_points
{
    print "\e[H\e[2J";

    my $x = 45;
    my $y = 14;

    my $longest_name = 0;
    for (@PERSONS)
    {
        my $len = length($NAMES[$_]);
        $longest_name = $len if ($len > $longest_name);
    }

    for (@PERSONS)
    {
        print  "\e[$y;${x}H";
        printf "%*s: %d", $longest_name, $NAMES[$_], $GAME_DATA{$_}{POINTS};
        $y++;
    }

    wait_for_input("Points this round below. Any key to continue.", $green);
}

###############################################################################
# MAIN GAME SUBS
###############################################################################

# This is the main gameplay sub.
sub play
{
    my $selection = shift;
    my $turn = $GAME_DATA{TURN};
    my $state = $GAME_DATA{STATE};

    # State 1: card passing
    if ($state == 1)
    {
        pass();
        $GAME_DATA{STATE}++;
        $state++;
    }

    # State 2: Play all cpu moves that come before the user.
    if ($state == 2)
    {
        # If this is the 1st turn, get the leader (whoever has the 2 of clubs).
        if ($turn == 1)
        {
            for (@PERSONS)
            {
                if ( $GAME_DATA{$_}{HAND}[0] == 0 )
                {
                    $GAME_DATA{LEADER} = $_;
                    $GAME_DATA{LEADSUIT} = 0;
                    last;
                }
            }
        }

        my $player = $GAME_DATA{LEADER};

        # Get cpu's played cards one by one. Stop when we reach the user.
        until ($player == BOTTOM) # Note that it might already be == BOTTOM.
        {
            my $selection = cpu_choose_card($player);
            $GAME_DATA{$player}{CURRENTCARD} = $selection;

            # Set lead suit if this is the first card played this turn.
            if (!defined($GAME_DATA{LEADSUIT}))
            {
                $GAME_DATA{LEADSUIT} =
                    suit_of(@{$GAME_DATA{$player}{HAND}}[$selection]);
            }

            $player = get_next($player);
        }

        $GAME_DATA{STATE}++;
        return;
    }

    # State 3: Do human move.
    if ($state == 3)
    {
        # This sub calls itself before getting user input after each turn so
        # make sure user has chosen something first.
        return if (!defined($selection));

        # Go back to main if player chose illegal first-turn cards.
        if ($turn == 1) { return 1 if first_turn($selection); }

        # Go back to main if player chose illegal cards.
        return 1 if (user_chose_illegal_cards($selection));

        $GAME_DATA{&BOTTOM}{CURRENTCARD} = $selection;

        # Set lead suit if this is the first card played this turn.
        if (!defined($GAME_DATA{LEADSUIT}))
        {
            $GAME_DATA{LEADSUIT} = 
                suit_of(@{$GAME_DATA{&BOTTOM}{HAND}}[$selection]);
        }

        $GAME_DATA{STATE}++;
        $state++;
    }

    # State 4: Do any remaining cpu moves.
    if ($state == 4)
    {
        my $player = LEFT;
        until (defined($GAME_DATA{$player}{CURRENTCARD}))
        {
            $GAME_DATA{$player}{CURRENTCARD} = cpu_choose_card($player);
            $player = get_next($player);
        }

        draw_board();

        $GAME_DATA{STATE}++;
        $state++;
    }

    # State 5: Calculate points and reset a few variables.
    if ($state == 5)
    {
        my $lead_suit = $GAME_DATA{LEADSUIT};
        my $trick_winner;
        my $highest_card = -1;
        my $points = 0;

        # Figure out who took the trick and calculate points in the trick.
        for (@PERSONS)
        {
            my $card = @{$GAME_DATA{$_}{HAND}}[$GAME_DATA{$_}{CURRENTCARD}];
            my $curr_suit = suit_of($card);

            $GAME_DATA{HEARTSBROKEN} = 1 if ($curr_suit == HEARTS);

            $points += $POINTS[$card];

            if ($curr_suit == $lead_suit && $card > $highest_card)
            {
                $highest_card = $card;
                $trick_winner = $_;
            }
        }

        # Update points and mark who will start next turn.
        $GAME_DATA{$trick_winner}{POINTS} += $points;
        $GAME_DATA{LEADER} = $trick_winner;

        # Clean up for this turn.
        $GAME_DATA{TURN}++;
        $GAME_DATA{LEADSUIT} = undef;

        for (@PERSONS)
        {
            splice(@{$GAME_DATA{$_}{HAND}}, $GAME_DATA{$_}{CURRENTCARD}, 1);
            $GAME_DATA{$_}{CURRENTCARD} = undef;
        }

        if ($turn < 13)
        {
            wait_for_input("Press any button to continue...", $green);

            $GAME_DATA{STATE} = 2;

            # Start back at state 2, which is any cpu moves that come before
            # the user.
            play(undef);
        }
        else
        {
            # Check if the game is over.
            for (@PERSONS)
            {
                if ($GAME_DATA{$_}{POINTS} >= 100)
                {
                    display_points();
                    msg("GAME OVER: $NAMES[$_] LOST", $green);
                    sleep 2;
                    end_game();
                }
            }

            # Display points starts a separate screen.
            display_points();
            new_hand();

            # Go to passing state (or not, if it's a no-pass round).
            $GAME_DATA{STATE} = ($GAME_DATA{HANDCOUNT} % 4) ? 0 : 2;

            # At this point we return control to main, which will start the
            # passing process (or not, if it's a no-pass round).
            return;
        }
    }
}

sub pass
{
    my $hand = $GAME_DATA{HANDCOUNT};
    my $hand_mod = $hand % 4;

    return unless($hand_mod);

    #
    # Passing setup
    #

    # Set up who gets cards from whom. It's kind of confusing...
    my @pass_array;
       if ($hand_mod == 1) { @pass_array = ( 3, 0, 1, 2 ); } # Pass left
    elsif ($hand_mod == 2) { @pass_array = ( 1, 2, 3, 0 ); } # Pass right
    elsif ($hand_mod == 3) { @pass_array = ( 2, 3, 0, 1 ); } # Pass across

    # Create hash of arrays of each player's passed cards.
    my %passes = get_cpu_passes($hand_mod);
    $passes{&BOTTOM} = [@PASS_CARDS];
#    @PASS_CARDS = ();
    @PASS_CARDS = @{$passes{&LEFT}};
return;

    #
    # Actually pass the cards.
    #

    # Make a copy of all hands. We have to do all hands since we don't
    # know the order in which they'll be copied...basically.
    my %hand_copies;
    $hand_copies{$_} = [@{$GAME_DATA{$_}{HAND}}] for (@PERSONS);

    # Remove cards from each persons' hand that will be passed.
    for (@PERSONS)
    {
        # Remove cards that the current person passed.
        for my $rm_card (@{$passes{$_}})
        {
            $GAME_DATA{$_}{HAND}[$rm_card] = undef;
        }
        remove_undef(\@{$GAME_DATA{$_}{HAND}});

        # Add cards passed to the current person.
        my @opp_hand = @{$hand_copies{$pass_array[$_]}}; # Another copy!

        for my $passed_card (@{$passes{$pass_array[$_]}})
        {
            push @{$GAME_DATA{$_}{HAND}}, $opp_hand[$passed_card];
        }

        # Sort the hand. It's helpful.
        $GAME_DATA{$_}{HAND} = [sort { $a <=> $b } @{$GAME_DATA{$_}{HAND}}];
    }
}

# The first turn is special...
sub first_turn
{
    my $selection = shift;

    # Check for bad selection part 1: user didn't choose 2 of clubs.
    if ($GAME_DATA{LEADER} == BOTTOM && $selection != 0)
    {
        msg("You must lead the $black$DECK[0]$red.", $red);
        return 1;
    }

    # Check for bad selection part 2: user chose a point card.
    my $card = $GAME_DATA{&BOTTOM}{HAND}[$selection];
    if (grep(/^$card$/, @POINT_CARDS))
    {
        msg("Point cards are not allowed on the first turn.", $red);
        return 1;
    }

    return 0;
}

sub user_chose_illegal_cards
{
    my $selection = shift;

    my $user_suit = suit_of($GAME_DATA{&BOTTOM}{HAND}[$selection]);
    my $lead_suit = $GAME_DATA{LEADSUIT};

    # Check for an illegal suit based on lead.
    if ($user_suit != $lead_suit && defined($lead_suit))
    {
        for (@{$GAME_DATA{&BOTTOM}{HAND}})
        {
            if ( suit_of($_) == $lead_suit )
            {
                msg("You have to play the suit that was lead.", $red);
                return 1;
            }
        }
    }

    # Check for a hearts lead before hearts have been broken.
    if ($user_suit == HEARTS && $GAME_DATA{LEADER} == BOTTOM &&
        !$GAME_DATA{HEARTSBROKEN})
    {
        # Make sure user has anything other than a heart
        for (@{$GAME_DATA{&BOTTOM}{HAND}})
        {
            if ( suit_of($_) != HEARTS )
            {
                msg("Hearts have not been broken yet", $red);
                return 1;
            }
        }
    }

    return 0;
}

###############################################################################
# CPU PASSING AI SUBS
###############################################################################

# General strategy: weigh the different suits against each other, then pass
# mostly from the worst suit.
sub get_cpu_passes
{
    my $hand_mod = shift;
    my %return_hash = ();

    my @values = get_values($hand_mod);

    for (@PERSONS)
    {
        next if ($_ == BOTTOM);

        my @suit_weights = calculate_suit_weights($_, @values);
debug(Dumper(@suit_weights));

        my @passes = actually_get_passes($_, @suit_weights);
push @{$return_hash{$_}}, @passes;
    }

    return %return_hash;
}

# returns array of 52 ints which are relative weights of all cards.
sub get_values
{
    my $hand_mod = shift;

    my $two_club = 0;
    my $ace_club = 12;
    my $que_spad = 36;

    # Base values: twos are lowest, aces are highest. High hearts are weighted
    # more.
    my @values = (-50, -10, 0, 20, 30, 40, 60, 70, 80, 90, 100, 110, 120) x 3;
    push (@values, (-50, -10, 0, 20, 30, 40, 60, 70, 120, 130, 170, 180, 200));

    $values[$two_club] = 65; # 2 of clubs isn't that good...

    # Passing to the left.
    if ($hand_mod == 1)
    {
        $values[$ace_club] = 200; # it's most helpful when passed to the left.
    }
    # Passing to the right.
    elsif ($hand_mod == 2)
    {
        $values[$que_spad] = 200; # it's most helpful when passed to the right.
    }
    return @values;
}

# returns array of 4 values representing that suit's weight.
# weight is basically high cards over length.
sub calculate_suit_weights
{
    my $player = shift;
    my @values = @_;

    # As suit lengths increase, their weight should drop a lot.
    my @length_adjustments = (-1, 1, 2, 3, 5, 8, 10, 10, 10, 10, 10, 10, 10);

    # Get length and strength of each suit.
    my @weights = (0, 0, 0, 0);
#debug(Dumper(@{$GAME_DATA{$player}{HAND}}));
    for (0..3)
    {
        # Get the length of the suit and convert it to adjusted length.
        my $length = $length_adjustments[count($player, $_)];
        my $strength = 0;

        for my $card (@{$GAME_DATA{$player}{HAND}})
        {
            $strength += $values[$card] if (suit_of($card) == $_);
        }

        # Multiply by 3 for use in the actually_get_passes sub. it's somewhat
        # arbitrary.
        $weights[$_] = int($strength / $length);
#debug("player $player, suit $_, weight = $weights[$_] (=$strength/$length)");
    }

    return @weights;
}

sub actually_get_passes
{
    my $player = shift;
    my @suit_weights = @_;

    
}

sub has_queen_of_spades
{
    for (@{$GAME_DATA{$_[0]}{HAND}})
    {
        return 1 if ($_ == 36);
    }
    return 0
}

# Super useful; returns the length of a user's suit. 
# usage: count(user, suit), ex: count(BOTTOM, HEARTS);
sub count
{
    my $player = shift;
    my $suit   = shift;

    my $count = 0;

    for (@{$GAME_DATA{$player}{HAND}})
    {
        $count++ if (suit_of($_) == $suit);
    }

    return $count;
}

###############################################################################
# CPU PLAYING AI SUBS
###############################################################################

sub cpu_choose_card
{
    my $cpu = shift;

    my @hand = @{$GAME_DATA{$cpu}{HAND}};
    my $lead_suit = $GAME_DATA{LEADSUIT};

    return 0 if ($GAME_DATA{TURN} == 1 && $hand[0] == 0); # 2 of clubs

    for (0..scalar(@hand)-1)
    {
        my $suit = suit_of($hand[$_]);
        return $_ if ($suit == $lead_suit);
    }

    my $size = scalar(@{$GAME_DATA{$cpu}{HAND}});
    my $selection = int(rand($size-1)); 
    return $selection;
}

###############################################################################
# MINOR HELPER SUBS
###############################################################################

sub suit_of { return int($_[0]/13); }

sub wait_for_input
{
    msg(@_) if (@_);
    getc(TTY);
    $GAME_DATA{MSG} = "";
}

# Removes all 'undef' elements from an array.
sub remove_undef
{
    # This sub is just stupid. Plain stupid. Hands should be hashes to avoid
    # this. Or, quite possibly, it's just that I can't think of a non-brutish
    # way of doing this sub.
    #
    # The reason this exists is because we want to remove cards that are passed
    # from a hand. Removing more than one element of an array is problematic
    # because after you remove one, some/all of the rest of the elements'
    # indices change.

    my $ref = shift;
    my $no_elements_are_undef;

    for (0..2)
    {
        $no_elements_are_undef = 1;
        for my $i (0..scalar(@{$ref})-1)
        {
            if (!defined(@{$ref}[$i]))
            {
                $no_elements_are_undef = 0;
                splice(@{$ref}, $i, 1);
                last;
            }
        }
        last if ($no_elements_are_undef);
    }
}

# returns who goes next in a clockwise manner.
sub get_next
{
    my $person = shift;

    return 0 if ($person == 3);
    return ++$person;
}

# Usage: msg("message to be displayed", "optional color: $red, etc");
#
# Max message length is ~85 characters but we don't check for it.
sub msg
{
    my $msg = shift;
    my $color = shift;

    return if (!$msg);

    $color = "" if (!$color);

    # Center the message
    my $spaces = ceil(($WIDTH - length($msg)) / 2)+1;
    print "\e[12;${spaces}H";

    print "$color$msg$reset";

    $GAME_DATA{MSG} = "$msg";
    $GAME_DATA{MSGCOLOR} = "$color";
}

sub end_game
{
    print "\e[H\e[2J";
#    print "\e[8;$rows;$cols;t";
    system("stty echo");
    system("tput cvvis");
    exit;
}

sub debug
{
    open(my $FH, '>>', 'tmp.txt');
    print $FH "@_\n";
    close $FH;
}

sub main
{
    my $turn; my $turn_pos = "\e[9;47H";  # ex: "Turn: 1"
    my $pass; my $pass_pos = "\e[10;47H"; # ex: "Pass: Left"
    my $hand_pos; my $hand_index = 0;     # underline under selected card
    my $pass_str_pos;                     # ex: "PASS" over chosen cards
    my $hand;

    my $spaces;
    my $state;
    my $input;
    my $x;

    new_game();

    #
    # GAME STATE REFERENCE:
    # 0 = players are passing
    # 1 = done passing  (program will move cards around)
    # 2 = cpus playing  (will be skipped if user is first)
    # 3 = user playing
    # 4 = cpus playing  (will be skipped if user was last)
    # 5 = trick cleanup (goes to 2 unless hand is over)
    # 6 = hand cleanup  (goes to 0 unless game is over)
    # 7 = game cleanup
    #
    while(1)
    {
        $hand  = $GAME_DATA{HANDCOUNT};
        $state = $GAME_DATA{STATE};
        $turn  = $GAME_DATA{TURN};
        $x     = 13 - $turn; # used to limit how far the cursor can go.

        # Clears screen and draws board.
        $spaces = draw_board();

        # Write basic info.
        print $turn_pos, "Turn: $turn";
        print $pass_pos; pass_print($hand);

        # Without this the cursor will be one to the right if the last selection
        # was the last card in the user's hand.
        $hand_index-- if($hand_index > $x);

        # Draw underline representing user's selection.
        $hand_pos = "\e[41;".($hand_index*7+length($spaces)+1)."H";
        print $hand_pos, "$underline      $reset";

        # Draw PASS or PLAY over a user's selection.
#        for (@PASS_CARDS) # need to undo where this gets set in sub pass
        for (@PASS_CARDS)
        {
            print "\e[36;".($_*7+length($spaces)+2)."H";
            print "$bold${underline}PASS$reset";
        }

        # Draw messages here because of poor design.
        msg($GAME_DATA{MSG}, $GAME_DATA{MSGCOLOR});

        $GAME_DATA{MSG} = "";
        $GAME_DATA{MSGCOLOR} = "";

        $input = getc(TTY);
           if ( $input eq "C" ) { if ($hand_index < $x) { $hand_index++; } }
        elsif ( $input eq "D" ) { if ($hand_index > 0) { $hand_index--; } }
        elsif ( $input eq " " ) { toggle($hand_index) if($state < 2); }
#        elsif ( $input eq "\n") { play($hand_index) if($state); }
        elsif ( $input eq "\n") { play($hand_index); }
        elsif ( $input eq "q" ) { end_game(); }
        elsif ( $input eq "p" ) { debug(Dumper(%GAME_DATA)); }
    }
    end_game();
}

main();
