#! /usr/bin/env ruby

require 'yaml'

Dir.chdir(File.join(__dir__, '../../../data/circles')) do
  Dir.glob('*.yml').each do |file|
    list = YAML.load(File.read(file))
    s1 = list
    s2 = list.sort_by(&:downcase)

    s1.each.with_index do |w, i|
      if w != s2[i]
        puts "ERROR: #{file} #{i} #{w} #{s2[i]}"
        break
      end
    end
  end
end
