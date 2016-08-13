#! /usr/bin/env ruby

#
# Generate data/yml/*.yml
#

require 'yaml'
require 'zlib'

scores = {}

File.open(File.join(__dir__, '../../dictionaries/frequency/scores.txt')) do |io|
  io.each_line do |line|
    line.chomp!
    (pos, word) = line.split(/\t/)
    scores[word] = pos.to_i
  end
end

counts = {}
count_file = File.join(__dir__, '../data/count.txt.gz')

Zlib::GzipReader.open(count_file) do |io|
  io.each_line.with_index do |line, i|
    line.chomp!
    (pat, count) = line.split(/\t/)
    counts[pat] = count.to_i
  end
end

words = File.read(File.join(__dir__, '../../dictionaries/scowl/en_US-large.txt'))
words.gsub!(/^.*'s\n/, '')

counts_len = counts.length

counts.each.with_index do |(pat, count), i|
  next if count < 5 || 200 < count

  print '.' if i % 10 == 0
  if i % 100 == 0
    puts "#{i}/#{counts_len}"
  end

  pat_rex = pat.split(/\_/)
  pat_rex = /^#{pat_rex[0]}.*#{pat_rex[1]}$/i

  match_words = words.scan(pat_rex)

  word_scores = {}
  total_score = 0
  scored_words = {}
  hi_scored_words = {}
  not_scored_words = []

  match_words.each do |w|
    sc = scores[w] || 0
    word_scores[w] = sc
    total_score += sc

    if sc == 0
      not_scored_words << w
    elsif sc <= 100_000
      hi_scored_words[w] = sc
    else
      scored_words[w] = sc
    end
  end

  out_file = pat + '.yml'
  out_file = File.join(__dir__, '../data/yml', out_file)

  hi_scored_words_count = hi_scored_words.length
  scored_words_count = scored_words.length

  if 8 <= hi_scored_words_count && hi_scored_words_count <= 30
    data = {}
    data['pattern'] = pat
    data['hi_scored_words_count'] = hi_scored_words_count
    data['scored_words_count'] = scored_words_count
    data['total_words'] = match_words.length
    data['score'] = total_score
    if (scored_words_count + hi_scored_words_count) > 0
      data['score_per_word'] = total_score / (scored_words_count + hi_scored_words_count)
    else
      data['score_per_word'] = 0
    end
    data['hi_scored_words'] = hi_scored_words
    data['scored_words'] = scored_words
    data['not_scored_words'] = not_scored_words

    File.open(out_file, 'w') do |out|
      out << YAML.dump(data)
    end
  end
end
