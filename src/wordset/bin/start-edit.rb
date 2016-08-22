#! /usr/bin/env ruby

require 'yaml'

require 'optparse'
require 'shellwords'

opts = ARGV.getopts('wsS')

opts[:write] = opts['w']
opts[:skip] = opts['s']
opts[:sort] = opts['S']

data_dir = File.join(__dir__, '../data/')

skipfile = File.join(data_dir, 'skip.yml')
skips = YAML.load(File.read(skipfile))

pattern = ARGV[0]
if opts[:write] and skips.include?(pattern)
  puts "Skip: #{pattern}"
  exit
end

file = File.join(data_dir, 'yml', pattern + '.yml')
data = YAML.load(File.read(file))

words = {hi: [], low: [], zero: []}

outfile = nil

out_dir = File.join(__dir__, '../../../data/circles/')
outfile = File.join(out_dir, pattern + '.yml')
if opts[:write]
  if File.exist?(outfile)
    puts "File already exists: #{ outfile }"
    exit
  end
elsif opts[:skip]
  if File.exist?(outfile)
    puts File.read(outfile)
    File.delete(outfile)
    puts "Delete: #{outfile}"
    skips << pattern
    open(skipfile, 'w') do |out|
      out << YAML.dump(skips.sort.uniq)
    end
  else
    puts "No such file: #{outfile}"
  end
  exit
end

hi_scored_words = data['hi_scored_words'].to_a
if opts[:sort]
  hi_scored_words = hi_scored_words.sort {|a,b| a[1] <=> b[1]}
end

hi_scored_words.each do |word, score|
  dict = %x{osx-dictionary -d Japanese-English #{Shellwords.shellescape(word)}}
  (header,definition) = dict.split(/\n\n/, 2)
  definition.strip!

  puts "----------------------------------------------------------------"
  if definition.empty?
    puts "#{ word }: #{score}"
    puts "(empty)"
  else
    puts "#{ word }: #{score}"
    puts definition

    words[:hi] << word
  end
end

puts "================================================================"

scored_words = data['scored_words'].to_a
if opts[:sort]
  scored_words = scored_words.sort {|a,b| a[1] <=> b[1]}
end

scored_words.each do |word, score|
  dict = %x{osx-dictionary -d Japanese-English #{Shellwords.shellescape(word)}}
  (header,definition) = dict.split(/\n\n/, 2)
  definition.strip!

  puts "----------------------------------------------------------------"
  if definition.empty?
    puts "#{ word }: #{score}"
    puts "(empty)"
  else
    puts "#{ word }: #{score}"
    puts definition

    words[:low] << word
  end
end

puts "================================================================"

data['not_scored_words'].each do |word|
  dict = %x{osx-dictionary -d Japanese-English #{Shellwords.shellescape(word)}}
  (header,definition) = dict.split(/\n\n/, 2)
  begin
    definition.strip!
  rescue Exception => e
    puts word
    p e
  end

  puts "----------------------------------------------------------------"
  if definition.empty?
    puts "#{ word }"
    puts "(empty)"
  else
    puts "#{ word }"
    puts definition
    words[:zero] << word
  end
end

if opts[:write]
  open(outfile, 'w') do |out|
    [:hi, :low, :zero].each do |key|
      unless words[key].empty?
        words[key].each do |w|
          out.puts "- #{w}"
        end
        out.puts
      end
    end
  end
end
