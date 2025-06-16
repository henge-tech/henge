# Dictionaries

 * [scowl](./scowl/)
   * http://wordlist.aspell.net/dicts/
   * `en_US-large.txt` - 167,299 entries
 * [basic](./basic/)
   * https://en.wiktionary.org/wiki/Appendix:1000_basic_English_words
   * `wiktionary-1000.txt` - 997 entries ([not 1,000](https://en.wiktionary.org/wiki/Appendix_talk:1000_basic_English_words))
 * [dict/web2](./dict/)
   * http://web.mit.edu/freebsd/head/share/dict/
   * http://www.puzzlers.org/dokuwiki/doku.php?id=solving:wordlists:about:mcilroy (History)
   * `web2` - 235,924 entries
   * `web2a` - 76,205 entries
 * [wordnet](./wordnet/)
   * https://wordnet.princeton.edu/
   * https://github.com/doches/rwordnet
   * `wordnet.txt` - 147,999 entries
   * `wordnet-1.txt` - 84,169 entries (words)
   * `wordnet-a.txt` - 63,830 entries (phrases)

[Scowl](http://wordlist.aspell.net/) seems to be the best one. There is a nice checking tool.

 * http://app.aspell.net/lookup

`web2` doesn't include some basic words (`anytime`, `box`).

```console
$ ruby ./bin/word-diff.rb basic/wiktionary-1000.txt dict/web2
File1: 997
File2: 235924
Only in file1: 6 (0.60%)
Only in file2: 234884 (99.56%)

$ ruby ./bin/word-diff.rb --list1 basic/wiktionary-1000.txt dict/web2
anytime
box
colour
goodbye
neighbour
pleased
```

Wordnet also has problem for this purpose. There may be a reason, but I don't know why lacking these words.

```console
$ ruby ./bin/word-diff.rb basic/wiktionary-1000.txt wordnet/wordnet-1.txt
File1: 997
File2: 84169
Only in file1: 46 (4.61%)
Only in file2: 82991 (98.60%)

$ ruby bin/word-diff.rb --list1 basic/wiktionary-1000.txt wordnet/wordnet-1.txt
and
anyone
anything
anytime
children
else
everyone
everybody
for
from
goodbye
her
hers
him
his
how
if
into
:
```

## Frequency data

 * [`frequency/scores.txt`](frequency/scores.txt) - 341,746 entries

`scores.txt` includes frequency rank (not score) and words. This was generated from 4 frequency lists using `scores.rb`.

 * [Google Web Trillion Word Corpus, the 1/3 million most frequent words](./frequency/google/)
   * http://norvig.com/ngrams/
   * `count_1w.txt` - 333,333 entries
 * [wiktionary](./frequency/wiktionary/)
   * https://en.wiktionary.org/wiki/Wiktionary:Frequency_lists
   * `20050816.txt` - 98,898 entries
   * `20060406.txt` - 36,662 entries ([rank 2781 is missing](https://en.wiktionary.org/wiki/Wiktionary_talk:Frequency_lists/PG/2006/04/1-10000))
 * [wordfreq-en](./frequency/wordfreq/)
   * https://github.com/LuminosoInsight/wordfreq
   * `wordfreq-en.txt` - 419,809 entries

I set the weights for these lists.

```ruby
score_data =
 [
   ['google/rank-1w.txt',           10.0],
   ['wordfreq/wordfreq-en.txt',      4.0],
   ['wiktionary/20050816.txt',       2.0],
   ['wiktionary/20060406.txt',       4.0],
 ]
```

All entries in the `scores.txt` have at least the sum of weight > 5.0.

Example:

 * `the` ... (1 * 10.0 + 1 * 4.0 + 1 * 2.0 + 1 * 4.0) / 20.0 = score 1.0
 * `tutankhamon` ... (36633 * 4.0) / 4.0 = score 36633.0
   * This word is dropped because the sum of weight less than 5.0.

See [scores.rb](./frequency/scores.rb) for detail.

## Other resources

 * allwords2
   * http://www.puzzlers.org/dokuwiki/doku.php?id=solving:wordlists:about:start
   * `allwords2.txt` - 776,522 entries
 * google-10000-english
   * https://github.com/first20hours/google-10000-english
   * `20k.txt` - 20,000 entries (subset of the `count_1w.txt`)
