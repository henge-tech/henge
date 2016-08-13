#! /usr/bin/env python

from wordfreq import word_frequency, iter_wordlist
import regex

iter = iter_wordlist('en', 'large')

re_nonlatin = regex.compile('[^-_\p{Latin}\d\.\']')
re_alphabet = regex.compile('[a-z]', regex.IGNORECASE)
re_underscore = regex.compile('_')

last_freq = -1
position = 0
current_line = 0
for word in iter:
    current_line += 1

    # skip non english words, emoji, etc.
    if re_nonlatin.search(word):
        continue

    # skip '123.45', 'ŭ', etc.
    if not re_alphabet.search(word):
        continue

    # skip 'x_x', 'r_e_t_w_e_e_t', etc.
    if re_underscore.search(word):
        continue

    freq = word_frequency(word, 'en', 'large')

    if freq != last_freq:
        last_freq = freq
        position = current_line
    print("%d\t%s\t%f" % (position, word, freq * 1e6))
