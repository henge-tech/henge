require 'yaml'

class GeneratePrompt
  DATA_DIR = File.join(File.dirname(__FILE__), '../../data/circles')

  def execute
    files = Dir.glob(File.join(DATA_DIR, '*.yml'))
    files.sort.each do |file|
      newfile = File.join(__dir__, 'data', File.basename(file).sub(/\.yml$/, '.txt'))
      if File.exist?(newfile)
        # puts "Skipping #{newfile}"
        # next
      end

      open(newfile, 'w') do |out|
        out << "source: #{File.basename(file)}\n"
        out << "generator: ChatGPT\n"
        out << "---\n"
        words = YAML.load_file(file)
        unit = words.length / 4
        4.times do |i|
          out << "Please create a short sentence using all these words: "
          out << words[i * unit, unit].join(', ')
          out << "\n"
        end
        out << "---\n@@@\n"
      end
    end
  end
end

GeneratePrompt.new.execute