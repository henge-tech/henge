#! /usr/bin/env ruby

#
# Find wordset/data/*.yml files, which has not yet been edited.
#

require 'yaml'
require File.join(__dir__, 'superset.rb')

Dir.chdir(File.join(__dir__, '../../..'))

circles_dir = 'data/circles'
wordset_dir = 'src/wordset/data/yml'

wordsets = nil
Dir.chdir(wordset_dir) do
  wordsets = Dir.glob('*.yml').map {|f| f.sub(/\.yml\z/, '') }
end

skips = YAML.load(File.read('src/wordset/data/skip.yml'))

wordsets -= skips

circles = nil
Dir.chdir(circles_dir) do
  circles = Dir.glob('*.yml').map {|f| f.sub(/\.yml\z/, '') }
end

wordsets -= circles

concat = wordsets.join("\n")

supersets = []
subsets = []
circles.each do |cf|
  super_rex = superset_rex(cf)
  sub_rex = subset_rex(cf)

  supersets += concat.scan(super_rex)
  subsets += concat.scan(sub_rex)
end

wordsets -= supersets
wordsets -= subsets

wordsets = wordsets.reject { |w| w =~ /(?:s|ing|ed|er|est)\z/ }
wordsets = wordsets.select { |w| w =~ /#{ARGV[0]}/ }

tmp = []
wordsets.each do |pat|
  data = YAML.load(File.read(File.join(wordset_dir, "#{pat}.yml")))

  hi = data['hi_scored_words_count']
  sc = data['scored_words_count']
  total = data['score']
  spw = total / (hi + sc)

  next if hi < 12
  tmp << {pat: pat, hi: hi, sc: sc, total: total, spw: spw}
end
wordsets = tmp

wordsets = wordsets.sort do |a,b|
  x = (a[:hi] - 12).abs <=> (b[:hi] - 12).abs
  if x != 0
    x
  else
    a[:spw] <=> b[:spw]
  end
end

wordsets.each do |w|
  puts "#{w[:pat]}\thi:#{w[:hi]}\tsc:#{w[:sc]}\tspw:#{w[:spw]}"
end
