#! /usr/bin/env ruby

require 'optparse'

opts = ARGV.getopts('lh', 'list', 'list1', 'list2', 'help')
opts[:list] = opts['l'] || opts['list']
opts[:list1] = opts['list1']
opts[:list2] = opts['list2']

opts[:help] = opts['h'] || opts['help']

if opts[:help]
  puts <<'EOT'
Find words only exists in file1.

  word-diff.rb [--list|--list1|--list2] file1 file2
EOT
  exit
end

file1 = ARGV[0]
file2 = ARGV[1]

words1 = File.readlines(file1).map { |line| line.chomp }
words2 = File.readlines(file2).map { |line| line.chomp }

map1 = Hash[words1.map { |line| [line.chomp.downcase, 1] }]
map2 = Hash[words2.map { |line| [line.chomp.downcase, 1] }]

count1 = 0
words1.each do |word|
  unless map2[word.downcase]
    puts word if opts[:list] or opts[:list1]
    count1 += 1
  end
end

count2 = 0
words2.each do |word|
  unless map1[word.downcase]
    puts word if opts[:list] or opts[:list2]
    count2 += 1
  end
end

unless opts[:list] or opts[:list1] or opts[:list2]
  puts "File1: #{words1.length}"
  puts "File2: #{words2.length}"
  percent1 = count1.to_f / words1.length * 100
  percent2 = count2.to_f / words2.length * 100

  printf("Only in file1: %d (%.2f%%)\n", count1, percent1)
  printf("Only in file2: %d (%.2f%%)\n", count2, percent2)
end
