#! /usr/bin/env ruby

unless File.exist?('count_1w.txt')
  %x{wget http://norvig.com/ngrams/count_1w.txt}
end

open('count_1w.txt') do |io|
  last_score = nil
  current_rank = 0
  result = ''
  out = open('rank-1w.txt', 'w')
  io.each_line.with_index do |line, i|
    line.chomp!
    (word, score) = line.split(/\t/)
    if last_score != score
      last_score = score
      current_rank = i + 1
    end
    out.puts "#{current_rank}\t#{word}"
  end
  out.close
end
