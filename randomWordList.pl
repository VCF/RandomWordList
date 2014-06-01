#!/usr/bin/perl -w

use strict;

=head1 randomWordList.pl

This script is designed to generate a cryptogrphic-quality random list
of words on Linux and Linux-like systems. It filters your system's
spellcheck dictionary for reasonable-length words, then randomizes
them with /dev/random.

The goal is to produce an unbiased list of words that you can choose
from in order to construct high quality AND memorable passwords. This
is the "correcthorsebatterystaple" mechanism popularized by XKCD:

     https://xkcd.com/936/>.

The strength of this method will be diminished if the words chosen are
not picked randomly, however. Humans are generally terrible at
randomizing information. Just "thinking of good words to use" will
generally end up selecting from a dangerously small pool of words.

=head2 Usage

You may run the script without any arguments if the default settings
are acceptable. Otherwise, you may provide:

   randomWordList.pl <NumberOfWords> <MaxWordLength> <MinWordLength> <FileOfWords>

For example:

   ./randomWordList.pl 200 12 4 /usr/share/dict/american-english-insane

=head2 Dictionary Choice

There are multiple dictionary options available in most
repositories. If no dictionary path is specified (first command line
argument) then the program will look for "default" dictionaries. The
code currently is presuming "american-english"; obviously for much of
the world that will need to be altered to something locale
appropriate.

The default dictionary used by your system is likely a good choice:

 1. You want to generate a password that you can remember. There are
    'expanded' dictionaries available with more words (greater
    entropy) but these extra words are often quite obscure. If a word
    is unfamiliar ("rancescent"? "nudzhed"?!?), it is harder to
    remember the correct spelling or build a meaningful memory device
    for recalling it.

 2. On my system, the default dictionary weighs in at ~40,000 words
    (3-8 letters), which means two bytes are sufficient to cover all
    entries; This will be 50% faster at pulling information from
    /dev/random than a dictionary with more than 65,535 words (3
    bytes)

=head2 Some Observations

  1. I am not a cryptographer. I may have made some dangerous
     presumptions here. I believe this code should generate high
     quality randomization. I am happy to hear feedback on flaws or
     suggestions for improvement.

  2. By choosing words you are reducing the entropy. I believe this is
     unavoidable in order to assure a reasonably "rememberable"
     phrase.

  3. Randall Munroe (XKCD author) advises against using permuted
     passwords (substituting odd characters or changing case), as it
     makes the result harder to remember. However, if you've got the
     memory, case permutation and special character substitution will
     GREATLY increase the strength of any password you design. I am
     intentionally not automatically 'munging' passwords in this
     script; you should come up with simple rules yourself. For some
     ideas, see:

         https://en.wikipedia.org/wiki/Munged_password

  4. If you're worried about your memory, I strongly recommend an
     encrypted password store. Personally, I am quite fond of
     KeePassX:

         https://www.keepassx.org/downloads

     Password managers do represent a single point of failure; if an
     attacker compromises your password database, you will lose ALL
     the credentials stored there (barring second factor
     authentication). For this reason, the manger's master password
     should be VERY strong, and the password file should probably not
     be stored on an open network. More information:

         https://en.wikipedia.org/wiki/Password_manager
         https://en.wikipedia.org/wiki/List_of_password_managers

=cut

my $num  = $ARGV[0] || 120;  # Number of words to display
my $max  = $ARGV[1] || 8;    # Maximum length of word
my $min  = $ARGV[2] || 3;    # Minimum length of word
my $file = $ARGV[3] || '';   # File path of dictionary

if ($min > $max) {
    warn "Swapping Min/Max...\n";
    ($min, $max) = ($max, $min);
}

my $randSrc  = "/dev/random";
my $hardcore = 1; # If true, use $randSrc to pick each word
                  # If false, use $randSrc only for srand()

my $dictDir = "/usr/share/dict";
# Word counts are for Dec 2013, length 3-8 characters
my @try = map { "$dictDir/$_" }
    (
     'american-english',        # Ubuntu    ~40,000 words
     'american-english-large',  # Ubuntu    ~66,000 words
     'american-english-huge',   # Ubuntu   ~120,000 words
     'american-english-insane', # Ubuntu   ~200,000 words
     'web2',                    # FreeBSD   ~85,000 words
     'words',                   # symlink in both Ubuntu/FreeBSD
    );


unless ($file) {
    # See if we can locate a reasonable word list
    foreach my $t (@try) {
        if (-s $t) {
            $file = $t;
            last;
        }
    }
}

unless ($file) {
    warn "Failed to locate a dictionary. I tried:\n  ".
        join("\n  ", @try)."\n";
    exit;
}

# Perl cookbook - instantiate Perl's random seed
my $seed;
open(RAND, $randSrc) || die "Failed to read $randSrc\n  $!";
read(RAND, $seed, 4);
my $useed = unpack("L", $seed);
srand($useed);

# Recover word-like entries from dictionary
open(FILE, "<$file") || die "Failed to read file\n  $file\n  $!";
my %found = ();
while (<FILE>) {
    chomp;
    my $len = length($_);
    # Skip the entry if it is too short or too long:
    next if ($len < $min || $len > $max);
    # Only consider entries that are purely alphabetic:
    next unless (/^[a-z]+$/i);
    # Ignore capitalization:
    my $word = lc($_);
    $found{$word} ||= rand(100000);
}

# The initial order is established using Perl's non-cryptographic rand()
my @list = sort { $found{$a} <=> $found{$b} } keys %found;
my $listLen = $#list + 1;
unless ($listLen) {
    warn "Failed to find any words of length $min-$max!\n  Source: $file\n";
    exit;
}

# How many bits long is the list?
my $blen = int(log($listLen) / log(2)) + 1;
# How many bytes would cover that?
my $byteNum = int(0.99 + $blen / 8);

my $note = sprintf("\nRecovered %d words of length %d-%d\n  Source: %s\n",
                   $listLen, $min, $max, $file);

if ($hardcore) {
    $note .= sprintf("  %s will be read %d bytes at a time for enhanced randomness\n", $randSrc, $byteNum);
    if ($randSrc eq '/dev/random') {
        $note .= "    This is a 'blocking' random source, it may take a while.\n    You can speed up the process by 'doing things' in other windows.\n";
    }
}

warn $note;

=head3 List Bias

Filtering the dictionary for size and removing entries that are not
purely alphabetical gives a word list of size $listLen. srand() is
then initialized with a 64-bit number from /dev/random, and the list
then sorted by rand(). At this point, the list is not
cryptographically random.

Words are then drawn off from the list by extracting more random bits
from /dev/random. These numbers will be in the range of
0-(256^$byteNum-1), where $byteNum is chosen such that the maximum
bound is at least as large as $listLen (so $byteNum will usually be 2,
and sometimes 3 for large lists). However, it is unlikely to be
*exactly* as large as $listLen. This means that the integer generated
from /dev/random needs to be scaled/translated into a value from
1-$listLen, such that all values have an equal likelihood of being
chosen.

I know of two methods that are biased:

  1. Using a simple modulus ($randomNumber % $listLen). This will
     result in entries at the front of the list being selected more
     often (due to the "wrapping" effect of the modulus).

  2. Scaling ala:

     $ind = int( $listLen * $devRandVal / 256 ** $byteNum )

     These values will result in some (predictable, given $listLen)
     entries being picked n times, and all other entries being picked
     n+1 times (picket fence).

The method I am using is to use a running sum of the decimal values
generated by /dev/random, and will use modulus on that. It should
avoid bias at the front of the list, and will not be affected by
scaling. However, it means that the (n+1)th word is related to the nth
word by the addition of a random value to this running sum. That
relationship is, hopefully, random, but it still makes me
uncomfortable.

=cut

my $lineLen = 999;
my $runningSum = 0;
for my $n (1..$num) {
    # In non-hardcore mode, the index used for this position is just
    # the $n-th entry in the rand()-sorted word list:
    my $ind = $n - 1;
    if ($hardcore) {
        # In hardcore mode, we will get a new random number for
        # each word reported, and use that to generate an index
        my $r; read(RAND, $r, $byteNum);        # Get $byteNum random bytes
        my $randNum  = hex(unpack( 'H*', $r )); # Decimalize

        # Ok, $randNum should be a high-value random number that has a
        # range of zero to something larger than the size of our list

        $runningSum += $randNum;        # Increase the running sum
        $ind  = $runningSum % $listLen; # Modulus to bring in range
    }
    my $word = $list[$ind];
    # Just trying to nicely wrap the output:
    my $wlen = length($word);
    $lineLen += $wlen + 1;
    if ($lineLen > 80) {
        $lineLen = $wlen + 1;
        print "\n$word";
    } else {
        print " $word";
    }
}
close RAND;
print "\n\n";

