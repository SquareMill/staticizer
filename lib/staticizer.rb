require_relative "staticizer/version"
require_relative 'staticizer/crawler'

module Staticizer
  def Staticizer.crawl(url, options = {}, &block)
    cralwer = Staticizer::Crawler.new(url, options)
    crawler.crawl
  end
end
