#! /usr/bin/env ruby

#
# Generate ../../../data/circles.md list.
#

dir = File.join(__dir__, '../../../data/circles/')
require 'yaml'

files = nil
map = nil
Dir.chdir(dir) do
  lines = %x{wc -l *.yml}
  map = Hash[lines.split(/\n/).map {|line| line.strip}.map {|line| token = line.split(/\s/); [token[1], token[0].to_i] }]

  Dir.glob('*.yml').each do |file|
    data = YAML.load(File.read(file))
    if data.length != map[file] || ![8, 12, 16, 20].include?(map[file])
      puts "ERROR: #{file} #{data.length} #{map[file]}"
    end
  end
end

open(File.join(__dir__, '../../../data/circles.md'), 'w') do |out|
  out.puts "# Circles (#{map.length - 1})"
  out.puts
  out.puts "| File           | Entries        |"
  out.puts "|:---------------|:---------------|"

  map.keys.sort.each do |key|
    next if key == 'total'
    if map[key] == 12
      out.puts "|#{key.ljust(16)}|#{"**#{map[key]}**".ljust(16)}|"
    else
      out.puts "|#{key.ljust(16)}|#{map[key].to_s.ljust(16)}|"
    end
  end
end
