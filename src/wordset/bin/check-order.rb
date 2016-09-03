#! /usr/bin/env ruby

require 'yaml'

Dir.chdir(File.join(__dir__, '../../../data/circles')) do
  Dir.glob('*.yml').each do |file|
    list = YAML.load(File.read(file))
    s1 = list
    s2 = list.sort_by(&:downcase).uniq

    if s1.length != s2.length
      puts "ERROR: #{file}"
    end
    unless [8,12,16,20].include?(s1.length)
      puts "ERROR: #{file}"
    end

    s1.each.with_index do |w, i|
      if w != s2[i]
        puts "ERROR: #{file} #{i} #{w} #{s2[i]}"
        break
      end
    end
  end
end
