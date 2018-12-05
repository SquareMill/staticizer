require 'net/http'
require 'fileutils'
require 'nokogiri'
require 'aws-sdk'
require 'logger'

module Staticizer
  class Crawler
    attr_reader :url_queue
    attr_accessor :output_dir

    def initialize(initial_page, opts = {})
      if initial_page.nil?
        raise ArgumentError, "Initial page required"
      end

      @opts = opts.dup
      @url_queue = []
      @processed_urls = []
      @output_dir = @opts[:output_dir] || File.expand_path("crawl/")
      @log = @opts[:logger] || Logger.new(STDOUT)
      @log.level = @opts[:log_level] || Logger::INFO

      if @opts[:aws]
        bucket_name = @opts[:aws].delete(:bucket_name)
        Aws.config.update(opts[:aws])
        @s3_bucket = Aws::S3::Resource.new.bucket(bucket_name)
      end

      if @opts[:valid_domains].nil?
        uri = URI.parse(initial_page)
        @opts[:valid_domains] ||= [uri.host]
      end

      if @opts[:process_body]
        @process_body = @opts[:process_body]
      end

      add_url(initial_page)
    end

    def log_level
      @log.level
    end

    def log_level=(level)
      @log.level = level
    end

    def crawl
      @log.info("Starting crawl")
      while(@url_queue.length > 0)
        url, info = @url_queue.shift
        @processed_urls << url
        process_url(url, info)
      end
      @log.info("Finished crawl")
    end

    def extract_hrefs(doc, base_uri)
      doc.xpath("//a/@href").map {|href| make_absolute(base_uri, href) }
    end

    def extract_images(doc, base_uri)
      doc.xpath("//img/@src").map {|src| make_absolute(base_uri, src) }
    end

    def extract_links(doc, base_uri)
      doc.xpath("//link/@href").map {|href| make_absolute(base_uri, href) }
    end

    def extract_scripts(doc, base_uri)
      doc.xpath("//script/@src").map {|src| make_absolute(base_uri, src) }
    end

    def extract_css_urls(css, base_uri)
      css.scan(/url\(\s*['"]?(.+?)['"]?\s*\)/).map {|src| make_absolute(base_uri, src[0]) }
    end

    def add_urls(urls, info = {})
      urls.compact.uniq.each {|url| add_url(url, info.dup) }
    end

    def make_absolute(base_uri, href)
      dup_uri = base_uri.dup
      dup_uri.query = nil
      if href.to_s =~ /https?/i
        href.to_s.gsub(" ", "+")
      else
        URI::join(dup_uri.to_s, href).to_s
      end
    rescue StandardError => e
      @log.error "Could not make absolute #{dup_uri} - #{href}"
      nil
    end

    def add_url(url, info = {})
      if @opts[:filter_url]
        url = @opts[:filter_url].call(url, info)
        return if url.nil?
      else
        regex = "(#{@opts[:valid_domains].join(")|(")})"
        return if url !~ %r{^https?://#{regex}}
      end

      url = url.sub(/#.*$/,'') # strip off any fragments
      return if @url_queue.index {|u| u[0] == url } || @processed_urls.include?(url)
      @url_queue << [url, info]
    end

    def save_page(response, uri)
      return if @opts[:skip_write]
      if @opts[:aws]
        save_page_to_aws(response, uri)
      else
        save_page_to_disk(response, uri)
      end
    end

    def save_page_to_disk(response, uri)
      path = uri.path
      path += "?#{uri.query}" if uri.query

      path_segments = path.scan(%r{[^/]*/})
      filename = path.include?("/") ? path[path.rindex("/")+1..-1] : path

      current = @output_dir
      FileUtils.mkdir_p(current) unless File.exist?(current)

      # Create all the directories necessary for this file
      path_segments.each do |segment|
        current = File.join(current, "#{segment}").sub(%r{/$},'')
        if File.file?(current)
          # If we are trying to create a directory and there already is a file
          # with the same name add a .d to the file since we can't create
          # a directory and file with the same name in the file system
          dirfile = current + ".d"
          FileUtils.mv(current, dirfile)
          FileUtils.mkdir(current)
          FileUtils.cp(dirfile, File.join(current, "/index.html"))
        elsif !File.exists?(current)
          FileUtils.mkdir(current)
        end
      end

      body = response.respond_to?(:read_body) ? response.read_body : response
      body = process_body(body, uri, {})
      outfile = File.join(current, "/#{filename}")
      if filename == ""
        indexfile = File.join(outfile, "/index.html")
        @log.info "Saving #{indexfile}"
        File.open(indexfile, "wb") {|f| f << body }
      elsif File.directory?(outfile)
        dirfile = outfile + ".d"
        @log.info "Saving #{dirfile}"
        File.open(dirfile, "wb") {|f| f << body }
        FileUtils.cp(dirfile, File.join(outfile, "/index.html"))
      else
        @log.info "Saving #{outfile}"
        File.open(outfile, "wb") {|f| f << body }
      end
    end

    def save_page_to_aws(response, uri)
      key = uri.path
      key += "?#{uri.query}" if uri.query
      key = key.gsub(%r{/$},"/index.html")
      key = key.gsub(%r{^/},"")
      key = "index.html" if key == ""
      # Upload this file directly to AWS::S3
      opts = {:acl => "public-read"}
      opts[:content_type] = response['content-type'] rescue "text/html"
      @log.info "Uploading #{key} to s3 with content type #{opts[:content_type]}"
      if response.respond_to?(:read_body)
        body = process_body(response.read_body, uri, opts)
        @s3_bucket.object(key).put(opts.merge(body: body))
      else
        body = process_body(response, uri, opts)
        @s3_bucket.object(key).put(opts.merge(body: body))
      end
    end

    def process_success(response, parsed_uri)
      url = parsed_uri.to_s
      if @opts[:filter_process]
        return if @opts[:filter_process].call(response, parsed_uri)
      end
      case response['content-type']
      when /css/
        save_page(response, parsed_uri)
        add_urls(extract_css_urls(response.body, url), {:type_hint => "css_url"})
      when /html/
        save_page(response, parsed_uri)
        doc = Nokogiri::HTML(response.body)
        add_urls(extract_links(doc, url), {:type_hint => "link"})
        add_urls(extract_scripts(doc, url), {:type_hint => "script"})
        add_urls(extract_images(doc, url), {:type_hint => "image"})
        add_urls(extract_css_urls(response.body, url), {:type_hint => "css_url"})
        add_urls(extract_hrefs(doc, url), {:type_hint => "href"}) unless @opts[:single_page]
      else
        save_page(response, parsed_uri)
      end
    end

    # If we hit a redirect we save the redirect as a meta refresh page
    # TODO: for AWS S3 hosting we could instead create a redirect?
    def process_redirect(url, destination_url)
      body = "<html><head><META http-equiv='refresh' content='0;URL=\"#{destination_url}\"'></head><body>You are being redirected to <a href='#{destination_url}'>#{destination_url}</a>.</body></html>"
      save_page(body, url)
    end

    def process_body(body, uri, opts)
      if @process_body
        body = @process_body.call(body, uri, opts)
      end
      body
    end

    # Fetch a URI and save it to disk
    def process_url(url, info)
      @http_connections ||= {}
      parsed_uri = URI(url)

      @log.debug "Fetching #{parsed_uri}"
  
      # Attempt to use an already open Net::HTTP connection
      key = parsed_uri.host + parsed_uri.port.to_s
      connection = @http_connections[key]
      if connection.nil?
        connection = Net::HTTP.new(parsed_uri.host, parsed_uri.port)
        connection.use_ssl = true if parsed_uri.scheme.downcase == "https"
        @http_connections[key] = connection
      end

      request = Net::HTTP::Get.new(parsed_uri.request_uri)
      begin
        connection.request(request) do |response|
          case response
          when Net::HTTPSuccess
            process_success(response, parsed_uri)
          when Net::HTTPRedirection
            redirect_url = response['location']
            @log.debug "Processing redirect to #{redirect_url}"
            process_redirect(parsed_uri, redirect_url)
            add_url(redirect_url)
          else
            @log.error "Error #{response.code}:#{response.message} fetching url #{url}"
          end
        end
      rescue OpenSSL::SSL::SSLError => e
        @log.error "SSL Error #{e.message} fetching url #{url}"
      rescue Errno::ECONNRESET => e
        @log.error "Error #{e.class}:#{e.message} fetching url #{url}"
      end
    end

  end
end
