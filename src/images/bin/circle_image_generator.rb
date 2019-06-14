require 'yaml'
require 'json'
require 'uri'
require 'fileutils'
require 'digest/md5'
require 'open-uri'
require 'awesome_print'
require 'dotenv/load'
require 'RMagick'
require File.join(__dir__, 'image_downloader_common.rb')

class CircleImageGenerator
  include ImageDownloaderCommon

  def generate
    load_list
    circle_files = Dir.chdir(CIRCLES_DIR) { Dir.glob('*.yml') }.sort
    circle_files.each.with_index do |circle_file, i|
      words = YAML.load(File.read(File.join(CIRCLES_DIR, circle_file)))
      image_files = words.map do |word|
        thumb = Dir.chdir(THUMBS_DIR) do
          Dir.glob("#{encode_to_s3_key(word)}.{png,jpg,gif}")[0]
        end
        if thumb.nil?
          thumb = '../empty.png'
        end
        thumb
      end
      generate_circle_image(circle_file, words, image_files)
    end
    save_list
  end

  def load_list
    @list = {}
    list_file = File.join(CACHE_DIR, 'circle_images.yml')
    return unless File.exist?(list_file)
    @list = YAML.load(File.read(list_file))
  end

  def save_list
    list_file = File.join(CACHE_DIR, 'circle_images.yml')
    YAML.dump(@list, File.open(list_file, 'w'))
  end

  def generate_circle_image(circle_file, words, image_files)
    pattern = File.basename(circle_file, '.yml')

    digest = image_files.map {|f| Digest::MD5.file(File.join(THUMBS_DIR, f)).to_s + " " + f }.join("\n")
    digest = Digest::MD5.hexdigest(digest)
    if @list[pattern] == digest
      print '.'
      return
    end
    print '*'
    @list[pattern] = digest

    files = image_files.map {|f| File.join(THUMBS_DIR, f) }
    dst = File.join(CIRCLE_IMAGES_DIR, pattern + '.png')

    zoom = 0.7
    csize = 300 * zoom
    if words.length == 20
      isize = 35
    elsif words.length == 16
      isize = 45
    elsif words.length == 12
      isize = 50
    else
      isize = 65
    end
    isize *= zoom
    r = 120 * zoom

    canvas = Magick::Image.new(csize, csize) do |c|
      c.background_color= "Transparent"
    end

    imgs = Magick::ImageList.new(*files)

    unit = Math::PI * 2 / imgs.length

    imgs.each.with_index do |img, i|
      img = img.resize(isize, isize)
      x = Math.cos(unit * i - Math::PI / 2) * r + csize / 2 - isize / 2
      y = Math.sin(unit * i - Math::PI / 2) * r + csize / 2 - isize / 2
      canvas = canvas.composite(img, x, y, Magick::OverCompositeOp)
    end

    canvas.write(dst)
  end
end

CircleImageGenerator.new.generate()
