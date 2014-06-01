# randomWordList.pl

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

## Usage

You may run the script without any arguments if the default settings
are acceptable. Otherwise, you may provide:

    randomWordList.pl <NumberOfWords> <MaxWordLength> <MinWordLength> <FileOfWords>

For example:

    ./randomWordList.pl 200 12 4 /usr/share/dict/american-english-insane

## Dictionary Choice

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

## Some Observations

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
