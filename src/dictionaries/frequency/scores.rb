#! /usr/bin/env ruby

# google/rank-1w.txt          333,333
# wordfreq/wordfreq-en.txt    419,809
# wiktionary/20050816.txt      98,898
# wiktionary/20060406.txt      36,662

score_data =
  [
   ['google/rank-1w.txt',           10.0],
   ['wordfreq/wordfreq-en.txt',      4.0],
   ['wiktionary/20050816.txt',       2.0],
   ['wiktionary/20060406.txt',       4.0],
  ]

words = {};

score_data.each do |data|
  file   = data[0]
  effect = data[1]

  lines = File.readlines(file)
  file_words = {}
  lines.each.with_index do |line, i|
    line.chomp!
    (rank, word) = line.split(/\t/)
    word.downcase!

    # Ignore duplicated words
    next if file_words[word]
    file_words[word] = 1

    unless words[word]
      words[word] = {
        word: word,
        score: 0.0,
        effects: 0.0,
      }
    end
    words[word][:score] += rank.to_i * effect
    words[word][:effects]  += effect
    # break if i > 1000
  end
end

words = words.values
  .reject {|w| w[:effects] <= 5 }
  .each {|w| w[:score] = w[:score] / w[:effects] }
  .sort do |a, b|
  if a[:score] != b[:score]
    a[:score] <=> b[:score]
  elsif a[:effects] != b[:effects]
    b[:effects] <=> a[:effects]
  else
    a[:word] <=> b[:word]
  end
end

last_score = -1
current_rank = nil
words.each.with_index do |data, i|
  # puts "#{i + 1}\t#{data[:word]}\t#{sprintf('%.2f', data[:score])}\t#{data[:effects]}"

  if last_score != data[:score]
    last_score = data[:score]
    current_rank = i + 1
  end
  puts "#{current_rank}\t#{data[:word]}"
end
