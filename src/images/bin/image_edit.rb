#! /usr/bin/env ruby

require 'yaml'

STDOUT.sync = true

class ImageEdit

  def initialize
    @images_data_file = File.expand_path('../../../../data/images.yml', __FILE__)
    @source_file = File.expand_path('../../images.txt', __FILE__)
    @circles_dir = File.expand_path('../../../../data/circles', __FILE__)
    @floor = ARGV[0].to_i
    @mode = ARGV[1]
  end

  def execute
    words = load_source_file
    files = Dir.chdir(@circles_dir) do
      Dir.glob('*.yml').sort
    end
    size = @floor == 83 ? 16 : 12
    files = files[(@floor - 1) * 12, size]
    files.each.with_index do |f, i|
      puts "# #{(@floor - 1) * 12 + i + 1}\n\n"
      YAML.load(File.read(File.join(@circles_dir, f))).each do |w|
        if @mode
          puts w
          puts "https://www.google.co.jp/search?q=site:pixabay.com+#{w}&tbm=isch"
          puts "https://www.google.co.jp/search?q=site:wikipedia.org+#{w}&tbm=isch"
          puts "https://www.google.co.jp/search?q=#{w}&tbm=isch"
          puts "https://pixabay.com/en/photos/?q=#{w}"
          puts "https://www.shutterstock.com/search?language=en&searchterm=#{w}&image_type=all"
          puts
          puts "https://eow.alc.co.jp/search?q=#{w}&ref=sa"
          puts "https://ejje.weblio.jp/content/#{w}"
          puts "https://www.merriam-webster.com/dictionary/#{w}"
          puts "https://en.wikipedia.org/w/index.php?search=#{w}&title=Special%3ASearch&go=Go"
          puts "https://www.brainyquote.com/search_results?q=#{w}"
          puts
          puts
        else
          puts "- #{w}" unless words.include?(w)
        end
      end
      puts "\n\n"
    end
  end

  def load_source_file
    source = File.read(@source_file)
    data = {}
    word = ''
    source.split(/\n/).each.with_index do |line, i|
      line.strip!
      next if line.empty?
      next if line =~ /\A#/

      if line =~ %r{\Ahttps?://}
        data[word] << { 'url' => line }
      else
        word = line
        word.sub!(/^-\s+/, '')
        if data[word]
          puts "ERROR: duplicated: #{word}"
          exit
        end
        data[word] ||= []
      end
    end

    data.keys
  end

end

ImageEdit.new.execute
