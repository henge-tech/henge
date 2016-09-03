module WordCircle

  class Runner

    RAD = Math::PI / 180.0
    DIRECT_KEYS = %w{0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J}

    def initialize
      @o = [40, 18]
      @circles_dir = File.join(__dir__, '../../data/circles')
    end

    def load_words

      if ARGV[0]
        @pattern = ARGV[0]
        ARGV[0] = nil
      else
        Dir.chdir(@circles_dir) do
          file = Dir.glob('*.yml').shuffle.first
          @pattern = file[/(.+)\.yml/, 1]
        end
      end

      file = File.join(@circles_dir, "#{@pattern}.yml")
      @words = YAML.load(File.read(file))
      @unit = 360 / @words.length
      @square = @words.length / 4
    end

    def intro(say_word)
      @words.each.with_index do |w, i|
        move_cursor(i)
        draw_word(@cursor, @cursor % @square == 0)
        draw_center_label(@cursor, @cursor % @square == 0)
        Curses.refresh
        say if say_word
      end
      move_cursor(0)
    end

    def move_cursor(index)
      @cursor = index
      if @cursor < 0
        @cursor = @words.length - 1
      elsif @cursor >= @words.length
        @cursor = @cursor - @words.length
      end
    end

    def get_key_input
      Curses.noecho()
      c = Curses.getch
      Curses.echo()

      if c == 'q'
        @key = :quit
        return
      end

      if @cursor.nil?
        # First key pressed
        @words.length.times {|i| draw_word(i, false) }
        @cursor = 0
        @last_cursor = nil
        @key = :cursor
        return
      end

      if c == 'j'
        @key = :cursor
        move_cursor(@cursor + 1)
      elsif c == 'k'
        @key = :cursor
        move_cursor(@cursor - 1)
      elsif DIRECT_KEYS.include?(c)
        @key = :cursor
        move_cursor(DIRECT_KEYS.index(c))
      elsif c == ' '
        @key = :dictionary
      elsif c == 'c'
        @key = :erase
      elsif c == 'p'
        @key = :play
      elsif c == 'a'
        @key = :say_all
      elsif c == 'r'
        @key = :reload
      elsif c == 'i'
        @key = :image
      end
    end

    def init
      load_words

      Curses.clear()
      Curses.curs_set(0)

      @cursor = nil
      @key = nil
      @screen_mode = nil
      @last_cursor = nil
      @visible_words = []

      intro(false)
    end

    def run
      begin
        Curses.init_screen
        init

        loop do
          get_key_input

          if @key == :quit
            break
          elsif @key == :erase
            erase_all_words
            next
          elsif @key == :play
            erase_all_words
            intro(true)
          elsif @key == :dictionary
            if @screen_mode == :dictionary
              @screen_mode = :circle
              redraw_words
              say
            else
              @screen_mode = :dictionary
              draw_dictionary
              say
            end
          elsif @key == :cursor
            if @screen_mode == :dictionary
              draw_dictionary
              @visible_words[@cursor] = true
            else
              draw_moved_cursor
            end
            say
            @last_cursor = @cursor
          elsif @key == :say_all
            say_all
          elsif @key == :reload
            init
          elsif @key == :image
            open_image
          end
        end
      ensure
        Curses.close_screen
      end
    end

    def draw_moved_cursor
      unless @last_cursor.nil?
        draw_word(@last_cursor, false)
      end

      draw_word(@cursor, true)
      draw_center_label(@cursor, false)
      Curses.refresh
    end

    def draw_dictionary
      Curses.clear()
      Curses.setpos(5, 0)
      Curses.addstr(%x{osx-dictionary #{Shellwords.shellescape(@words[@cursor])}})
      Curses.refresh
    end

    def redraw_words
      Curses.clear()
      @visible_words.each.with_index do |visible, i|
        draw_word(i, @cursor == i) if visible
      end
      draw_center_label(@cursor.to_i, false)
      Curses.refresh
    end

    def erase_all_words
      @cursor = -1
      @last_cursor = nil
      @visible_words = []
      Curses.clear()
      Curses.refresh
      draw_center_label(0, false)
    end

    def draw_word(index, marker)
      word = @words[index]
      rad = (index * @unit - 90) * RAD

      x = 32 * Math.cos(rad) + @o[0]
      y = 16 * Math.sin(rad) + @o[1]

      if marker
        Curses.attron(Curses::A_REVERSE)
      else
        Curses.attroff(Curses::A_REVERSE)
      end

      Curses.setpos(y.to_i, x.to_i)
      Curses.addstr(word)
      Curses.attroff(Curses::A_REVERSE)

      @visible_words[index] = true
    end

    def say
      %x{say #{Shellwords.shellescape(@words[@cursor])}}
    end

    def say_all
      text = ''
      unit = @words.length / 4
      unit = 4 if unit == 2

      @words.each_with_index do |w, i|
        text += w

        if i != @words.length - 1
          if i != 0 && (i + 1) % unit == 0
            text += ', '
          else
            text += ' '
          end
        end
      end
      # puts text

      # text = @words.join(' ')
      %x{say #{Shellwords.shellescape(text)}}
    end

    def open_image
      word = Shellwords.shellescape(@words[@cursor])
      %x{open 'https://www.google.co.jp/search?q=#{word}&tbm=isch'}

      # @words.each do |word|
      #   word = Shellwords.shellescape(word)
      #   %x{open 'https://www.google.co.jp/search?q=#{word}&tbm=isch'}
      #   sleep 0.5
      # end
    end

    def draw_center_label(index, marker)
      if marker
        Curses.attron(Curses::A_REVERSE)
      else
        Curses.attroff(Curses::A_REVERSE)
      end

      Curses.setpos(@o[1], @o[0])

      key = DIRECT_KEYS[index]

      Curses.addstr("#{@pattern}:#{key}")

      Curses.attroff(Curses::A_REVERSE)
    end
  end
end
