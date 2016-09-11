#! /usr/bin/env ruby

require 'yaml'

Dir.chdir(File.join(__dir__, '../../..'))

count = {}
first_words = {}

Dir.chdir('data/circles') do
  Dir.glob('*.yml').each do |file|
    words = YAML.load(File.read(file))

    first_words[words[0]] = 0 if first_words[words[0]].nil?

    first_words[words[0]] += 1
    words.each do |word|
      count[word] = 0 if count[word].nil?
      count[word] += 1
    end
  end
end

command = ARGV[0]

if command == 'firstword'
  p first_words.select {|word,count| count > 1 }
elsif command == 'count'
  count.to_a.sort {|a, b| b[1] <=> a[1]}.each do |word, count|
    puts "#{count}\t#{word}"
  end
else
  scores = File.readlines('src/dictionaries/frequency/scores.txt')
  scores = Hash[scores.map { |line| a = line.chomp.split(/\t/); [a[1], a[0]] }]

  result = []

  words = count.keys

  if ARGV[1]
    Dir.chdir(File.join(__dir__, '..'))
    words = File.readlines(ARGV[1]).map {|line| line.chomp }
  end

  words.each do |word|
    if scores[word.downcase]
      result << [word, scores[word.downcase].to_i]
    else
      result << [word, 9_999_999]
    end
  end

  if command == 'all'
    result.sort {|a,b| a[1] <=> b[1] }.each do |e|
      puts "#{e[1]}\t#{e[0]}"
    end
  else
    freq = {}
    unit = 5000
    result.each do |word, count|
      next if count == 9_999_999
      freq[count / unit] = freq[count / unit].to_i + 1
    end

    Dir.chdir(File.join(__dir__, '..')) do
      File.open('tmp/freq.txt', 'w') do |out|
        freq.keys.sort.each do |range|
          out << "#{range * unit}\t#{freq[range]}\n"
        end
      end

      plot = %{set boxwidth 0.75 relative; set style fill solid;} #  border lc rgb "black"
      plot += %{set terminal png size 900,600; set datafile separator "\\t";}
      plot += %{set output "data/frequency.png";}
      plot += %{plot [-2000:300000] "tmp/freq.txt" with boxes lc rgb "red"}
      #  notitle  lw 2 using 0:2:xtic(1)
      %x{gnuplot -e '#{plot}'}
    end
  end
end
