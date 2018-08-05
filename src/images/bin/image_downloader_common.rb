require 'yaml'
require 'json'
require 'uri'
require 'fileutils'
require 'digest/md5'
require 'open-uri'
require 'awesome_print'
require 'RMagick'

module ImageDownloaderCommon

  ROOT = File.expand_path('../../../..', __FILE__)
  IMAGES_ROOT = File.join(ROOT, 'src/images')

  IMAGES_DATA_FILE = File.join(ROOT, 'data/images.yml')
  IMAGES_DIR = File.join(IMAGES_ROOT, 'images/')
  THUMBS_DIR = File.join(IMAGES_ROOT, 'thumbs/')
  LOWRES1_DIR = File.join(IMAGES_ROOT, 'thumbs-low1/')
  LOWRES2_DIR = File.join(IMAGES_ROOT, 'thumbs-low2/')
  LOWRES3_DIR = File.join(IMAGES_ROOT, 'thumbs-low3/')
  CACHE_DIR = File.join(IMAGES_ROOT, 'cache/')
  SOURCE_FILE = File.join(IMAGES_ROOT, 'images.txt')

  def download_image(word, url, index)
    api_result = query_api(url)
    return nil if api_result.nil?

    ext = api_result['ext']
    cache_path = api_result['cache_path']
    filename = image_file_name(word, index, ext)
    image_file = File.join(IMAGES_DIR, filename)
    FileUtils.cp(cache_path, image_file)
    generate_thumbnail(filename, true)

    return api_result
  end

  def generate_thumbnail(filename, force = false)
    src = File.join(IMAGES_DIR, filename)
    dst = File.join(THUMBS_DIR, filename)
    if force || !File.exist?(dst)
      img = Magick::ImageList.new(src).first
      img.resize_to_fill(128,128).write(dst)
      puts "Generated: #{dst}"
    end

    src = File.join(THUMBS_DIR, filename)
    dst = File.join(LOWRES1_DIR, filename)
    if force || !File.exist?(dst)
      img = Magick::ImageList.new(src).first
      resolution = 8 * 2
      img.resize(img.columns / resolution, img.rows / resolution)
         .resize(img.columns, img.rows, Magick::PointFilter)
         .write(dst)
      puts "Generated: #{dst}"
    end

    src = File.join(THUMBS_DIR, filename)
    dst = File.join(LOWRES2_DIR, filename)
    if force || !File.exist?(dst)
      img = Magick::ImageList.new(src).first
      resolution = 8 * 3
      img.resize(img.columns / resolution, img.rows / resolution)
         .resize(img.columns, img.rows, Magick::PointFilter)
         .write(dst)
      puts "Generated: #{dst}"
    end

    src = File.join(THUMBS_DIR, filename)
    dst = File.join(LOWRES3_DIR, filename)
    if force || !File.exist?(dst)
      img = Magick::ImageList.new(src).first
      resolution = 128
      img.resize(img.columns / resolution, img.rows / resolution)
         .resize(img.columns, img.rows, Magick::PointFilter)
         .write(dst)
      puts "Generated: #{dst}"
    end
  end

  def save_url(prefix, ext, real_url, cache_url = nil, cache_only = false)
    cache_url ||= real_url
    cache_file = prefix + Digest::MD5.hexdigest(cache_url) + '.' + ext
    cache_path = File.join(CACHE_DIR, cache_file)
    if File.exist?(cache_path)
      puts cache_url + "\t" + cache_file
      return cache_path
    end

    return nil if cache_only

    puts real_url

    open(real_url) do |input|
      open(cache_path, 'wb') do |output|
        output.write(input.read)
      end
    end
    puts cache_url + "\t" + cache_file
    sleep 0.25

    cache_path
  end

  def encode_to_s3_key(string)
    # from CGI.escape
    string.gsub(/([^-a-zA-Z0-9]+)/) do
      '%' + $1.unpack('H2' * $1.bytesize).join('%').upcase
    end.tr('%', '_')
  end

  def image_file_name(word, index, ext, type = '')
    name = encode_to_s3_key(word)
    if index > 0
      name += ".#{index}"
    end
    unless type.empty?
      name += ".#{type}"
    end
    name + '.' + ext
  end

  # merge images.txt and images.yml
  def load_merged_data
    source = load_source_file
    data = load_yaml

    url_data = {}
    data.each do |word, entries|
      entries.each do |entry|
        url_data[entry['url']] = entry
      end
    end

    merged = {}

    source.each do |word, entries|
      merged[word] = []
      entries.each do |entry|
        if url_data[entry['url']]
          entry = url_data[entry['url']]
        end
        merged[word] << entry
      end
    end
    return merged
  end

  def load_source_file
    source = File.read(SOURCE_FILE)
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
        if data[word]
          abort "ERROR: duplicated: #{word}"
        end
        data[word] ||= []
      end
    end

    Hash[data.to_a.select {|a| !a[1].empty? }]
  end

  def load_yaml
    unless File.exist?(IMAGES_DATA_FILE)
      return {}
    end
    return YAML.load(File.read(IMAGES_DATA_FILE))
  end

  def save_yaml(data)
    File.open(IMAGES_DATA_FILE, 'w') do |io|
      io << YAML.dump(data).sub(/\A---\n/, '')
    end
  end

end
