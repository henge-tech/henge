#! /usr/bin/env ruby

require 'yaml'
require 'json'
require 'uri'
require 'fileutils'
require 'digest/md5'
require 'open-uri'
require 'awesome_print'
require 'nokogiri'
require 'dotenv/load'
require 'RMagick'

STDOUT.sync = true

#
# Generate data/images.yml file
#
class ImageDownloader

  def initialize
    @images_data_file = File.expand_path('../../../../data/images.yml', __FILE__)
    @images_dir = File.expand_path('../../images/', __FILE__)
    @thumbs_dir = File.expand_path('../../thumbs/', __FILE__)
    @lowrez1_dir = File.expand_path('../../thumbs-low1/', __FILE__)
    @lowrez2_dir = File.expand_path('../../thumbs-low2/', __FILE__)
    @lowrez3_dir = File.expand_path('../../thumbs-low3/', __FILE__)
    @cache_dir = File.expand_path('../../cache/', __FILE__)
    @source_file = File.expand_path('../../images.txt', __FILE__)
  end

  # crab.jpg crab.thumb.jpg crab.1.jpg crab.1.thumb.jpg
  def execute
    data = load_merged_data
    result = {}
    data.each do |word, entries|
      result[word] = []
      entries.each.with_index do |entry, i|
        if entry['ext']
          filename = image_file_name(word, i, entry['ext'])
          image_file = File.join(@images_dir, filename)
          if File.exist?(image_file)
            generate_thumbnail(filename, false)
            result[word] << Marshal.load(Marshal.dump(entry))
            next
          end
        end
        puts word
        new_entry = download_image(word, entry['url'], i)
        new_entry.delete('cache_path')
        result[word] << new_entry
      end
    end

    save_yaml(result)
  end

  def download_image(word, url, index)
    api_result = query_api(url)
    ext = api_result['ext']
    cache_path = api_result['cache_path']
    filename = image_file_name(word, index, ext)
    image_file = File.join(@images_dir, filename)
    FileUtils.cp(cache_path, image_file)
    generate_thumbnail(filename, true)

    return api_result
  end

  def generate_thumbnail(filename, force = false)
    src = File.join(@images_dir, filename)
    dst = File.join(@thumbs_dir, filename)
    puts dst
    if force || !File.exist?(dst)
      img = Magick::ImageList.new(src).first
      img.resize_to_fill(128,128).write(dst)
    end

    src = File.join(@thumbs_dir, filename)
    dst = File.join(@lowrez1_dir, filename)
    if force || !File.exist?(dst)
      img = Magick::ImageList.new(src).first
      resolution = 8 * 2
      img.resize(img.columns / resolution, img.rows / resolution)
         .resize(img.columns, img.rows, Magick::PointFilter)
         .write(dst)
    end

    src = File.join(@thumbs_dir, filename)
    dst = File.join(@lowrez2_dir, filename)
    if force || !File.exist?(dst)
      img = Magick::ImageList.new(src).first
      resolution = 8 * 3
      img.resize(img.columns / resolution, img.rows / resolution)
         .resize(img.columns, img.rows, Magick::PointFilter)
         .write(dst)
    end

    src = File.join(@thumbs_dir, filename)
    dst = File.join(@lowrez3_dir, filename)
    if force || !File.exist?(dst)
      img = Magick::ImageList.new(src).first
      resolution = 128
      img.resize(img.columns / resolution, img.rows / resolution)
         .resize(img.columns, img.rows, Magick::PointFilter)
         .write(dst)
    end
  end

  def query_api(url)
    if url =~ %r{\Ahttps://pixabay\.com/photo-(\d+)/\z}
      return query_pixabay_api(url, $1)
    elsif url =~ %r{\Ahttps://pixabay\.com/en/.+-(\d+)/\z}
      return query_pixabay_api(url, $1)
    elsif url =~ %r{\Ahttp://www\.irasutoya\.com/\d{4}/\d{2}/.+\.html(#\d+)?\z}
      return query_irasutoya_api(url)
    elsif url =~ %r{\Ahttps://commons\.wikimedia\.org/wiki/(File:[^&\?/#]+\.(?:jpe?g|png|gif|svg))\z}i
      return query_wikipedia_api(url, $1)
    else
      puts "ERROR: unknown url pattern #{url}"
      exit
    end
  end

  def query_pixabay_api(url, id)
    cache_url = "https://pixabay.com/api/?id=#{id}&key="
    real_url = cache_url + ENV['PIXABAY_API_KEY']
    cache_path = save_url('pba-', 'json', real_url, cache_url)
    data = JSON.parse(File.read(cache_path))
    data = data['hits'][0]
    image_url = data['webformatURL']
    ext = image_url[/\.([a-zA-Z]{2,4})\z/, 1].downcase
    cache_path = save_url('pbi-', ext, image_url) unless ext.empty?

    return {
      'url' => url,
      'cache_path' => cache_path,
      'site' => 'pixabay',
      'ext' => ext,
      'original' => image_url,
      'api' => cache_url,
      'credit' => {
        'name' => data['user'],
        'id' => data['user_id']
      },
    }
  end

  def query_irasutoya_api(url)
    img_pos = 0
    page_url = url
    if page_url =~ /#(\d+)\z/
      img_pos = $1.to_i - 1
      page_url = page_url.sub(/#(\d+)\z/, '')
    end

    cache_path = save_url('iya-', 'json', page_url)
    doc = Nokogiri::HTML.parse(File.read(cache_path))

    atags = doc.css('.entry').css('a')
    urls = []
    atags.each do |a|
      image_url = a.attr('href')
      image_url = image_url.sub(%r{/s\d+/([^/]+)\z}, '/s640/\1')
      urls << image_url
    end
    image_url = urls[img_pos]
    ext = image_url[/\.([a-zA-Z]{2,4})\z/, 1].downcase
    cache_path = save_url('iyi-', ext, image_url) unless ext.empty?

    return {
      'url' => url,
      'cache_path' => cache_path,
      'site' => 'irasutoya',
      'ext' => ext,
      'original' => image_url,
      'api' => url,
    }
  end

  def query_wikipedia_api(url, title)
    api_url = 'https://commons.wikimedia.org/w/api.php?action=query&format=json'
    api_url += '&prop=imageinfo%7cpageimages&pithumbsize=640&iiprop=extmetadata'
    api_url += '&titles=' + title
    cache_path = save_url('wpa-', 'json', api_url)
    data = JSON.parse(File.read(cache_path))
    data = data['query']['pages'].first[1]
    image_url = data['thumbnail']['source']
    ext = image_url[/\.([a-zA-Z]{2,4})\z/, 1].downcase
    cache_path = save_url('wpi-', ext, image_url) unless ext.empty?

    meta = data['imageinfo'][0]['extmetadata']
    license_name = meta['LicenseShortName']['value'] if meta['LicenseShortName']
    license_url = meta['LicenseUrl']['value'] if meta['LicenseUrl']

    return {
      'url' => url,
      'cache_path' => cache_path,
      'site' => 'wikipedia',
      'ext' => ext,
      'original' => image_url,
      'api' => api_url,
      'license' => {
        'name' => license_name,
        'url' => license_url,
      }
    }
  end

  def save_url(prefix, ext, real_url, cache_url = nil)
    cache_url ||= real_url
    cache_file = prefix + Digest::MD5.hexdigest(cache_url) + '.' + ext
    cache_path = File.join(@cache_dir, cache_file)
    if File.exist?(cache_path)
      puts cache_url + "\t" + cache_file
      return cache_path
    end

    open(cache_path, 'wb') do |output|
      open(real_url) do |input|
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
        if data[word]
          puts "ERROR: duplicated: #{word}"
          exit
        end
        data[word] ||= []
      end
    end

    Hash[data.to_a.select {|a| !a[1].empty? }]
  end

  def load_yaml
    unless File.exist?(@images_data_file)
      return {}
    end
    return YAML.load(File.read(@images_data_file))
  end

  def save_yaml(data)
    File.open(@images_data_file, 'w') do |io|
      io << YAML.dump(data).sub(/\A---\n/, '')
    end
  end
end

ImageDownloader.new.execute
