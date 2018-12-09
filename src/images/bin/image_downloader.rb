#! /usr/bin/env ruby

require 'nokogiri'

STDOUT.sync = true

require File.join(__dir__, 'image_downloader_common.rb')

#
# Generate data/images.yml file
#
class ImageDownloader
  include ImageDownloaderCommon

  def execute
    data = load_merged_data
    result = {}
    data.each do |word, entries|
      result[word] = []
      entries.each.with_index do |entry, i|
        if entry['ext']
          filename = image_file_name(word, i, entry['ext'])
          image_file = File.join(IMAGES_DIR, filename)
          if File.exist?(image_file)
            generate_thumbnail(filename, false)
            result[word] << Marshal.load(Marshal.dump(entry))
            next
          end
        end
        puts "Update: #{word}"
        new_entry = download_image(word, entry['url'], i)
        next if new_entry.nil?
        new_entry.delete('cache_path')
        result[word] << new_entry
      end
    end

    save_yaml(result)
  end

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

  def query_api(url)
    if url =~ %r{\Ahttps://pixabay\.com/photo-(\d+)/\z}
      return query_pixabay_api(url, $1)
    elsif url =~ %r{\Ahttps://pixabay\.com/en/(.+)-(\d+)/\z}
      data = query_pixabay_api(url, $1)
      return data unless data.nil?
      return query_pixabay_api2(url, $1, $2)
    elsif url =~ %r{\Ahttps?://www\.irasutoya\.com/\d{4}/\d{2}/.+\.html(#\d+)?\z}
      return query_irasutoya_api(url)
    elsif url =~ %r{\Ahttps://commons\.wikimedia\.org/wiki/(File:[^&\?/#]+\.(?:jpe?g|png|gif|svg))\z}i
      return query_wikipedia_api(url, $1)
    else
      abort "ERROR: unknown url pattern #{url}"
    end
  end

  #
  # Old Pixabay API with ID query
  #
  def query_pixabay_api(url, id)
    cache_url = "https://pixabay.com/api/?id=#{id}&key="
    real_url = cache_url + ENV['PIXABAY_API_KEY']
    cache_path = save_url('pba-', 'json', real_url, cache_url, true)
    return nil if cache_path.nil?

    data = JSON.parse(File.read(cache_path))
    data = data['hits'][0]
    image_url = data['webformatURL']
    ext = image_url[/\.([a-zA-Z]{2,4})\z/, 1].downcase
    return nil if ext.empty?
    cache_path = save_url('pbi-', ext, image_url, nil, true)
    return nil if cache_path.nil?

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

  #
  # New Pixabay API without ID query
  #
  def query_pixabay_api2(url, keywords, id)
    q = URI.decode(keywords).split(/-/)
    q = URI.encode(q.join(' '))

    cache_url = "https://pixabay.com/api/?id=#{id}&key="
    real_url = "https://pixabay.com/api/?key=#{ENV['PIXABAY_API_KEY']}&per_page=200&q=#{q}"
    cache_path = save_url('pbb-', 'json', real_url, cache_url)
    return nil if cache_path.nil?

    search_result = JSON.parse(File.read(cache_path))
    data = search_result['hits'].find do |hit|
      hit['id'].to_s == id.to_s
    end
    return nil if data.nil?

    image_url = data['webformatURL']
    ext = image_url[/\.([a-zA-Z]{2,4})\z/, 1].downcase

    return nil if ext.empty?
    cache_path = save_url('pbi-', ext, image_url)
    return nil if cache_path.nil?

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
    page_url = url.sub(/\Ahttp:/, 'https:')
    # cache_url = url.sub(/\Ahttps:/, 'http:')

    img_pos_str = nil
    if page_url =~ /#(\d+)\z/
      img_pos_str = $1
      img_pos = img_pos_str.to_i - 1
      page_url = page_url.sub(/#(\d+)\z/, '')
    end

    cache_path = save_url('iya-', 'html', page_url)
    doc = Nokogiri::HTML.parse(File.read(cache_path))

    atags = doc.css('.entry').css('a')
    urls = []
    atags.each do |a|
      image_url = a.attr('href')
      image_url = image_url.sub(%r{/s\d+/([^/]+)\z}, '/s640/\1')
      image_url = image_url.sub(%r{\A//}, 'https://')
      urls << image_url
    end
    image_url = urls[img_pos]
    ext = image_url[/\.([a-zA-Z]{2,4})\z/, 1].downcase
    cache_path = save_url('iyi-', ext, image_url) unless ext.empty?

    key_url = page_url
    if img_pos_str
      key_url += "##{img_pos_str}"
    end
    return {
      'url' => key_url,
      'cache_path' => cache_path,
      'site' => 'irasutoya',
      'ext' => ext,
      'original' => image_url,
      'api' => page_url,
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
end

ImageDownloader.new.execute
