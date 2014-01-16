require 'minitest/autorun'
require 'ostruct'

lib = File.expand_path(File.dirname(__FILE__) + '/../lib')
$LOAD_PATH.unshift(lib) if File.directory?(lib) && !$LOAD_PATH.include?(lib)

require 'staticizer'

class TestFilePaths < MiniTest::Unit::TestCase
  def setup
    @crawler = Staticizer::Crawler.new("http://test.com")
    @crawler.log_level = Logger::FATAL
    @fake_page = File.read(File.expand_path(File.dirname(__FILE__) + "/fake_page.html"))
  end

  def test_save_page_to_disk
    fake_response = OpenStruct.new(:read_body => "test", :body => "test")
    file_paths = {
      "http://test.com" => "index.html",
      "http://test.com/" => "index.html",
      "http://test.com/asdfdf/dfdf" => "/asdfdf/dfdf",
      "http://test.com/asdfdf/dfdf/" => ["/asdfdf/dfdf","/asdfdf/dfdf/index.html"],
      "http://test.com/asdfad/asdffd.test" => "/asdfad/asdffd.test",
      "http://test.com/?asdfsd=12312" => "/?asdfsd=12312",
      "http://test.com/asdfad/asdffd.test?123=sdff" => "/asdfad/asdffd.test?123=sdff",
    }

    # TODO: Stub out file system using https://github.com/defunkt/fakefs?
    outputdir = "/tmp/staticizer_crawl_test"
    FileUtils.rm_rf(outputdir)
    @crawler.output_dir = outputdir

    file_paths.each do |k,v|
      @crawler.save_page_to_disk(fake_response, URI.parse(k))
      [v].flatten.each do |file|
        expected = File.expand_path(outputdir + "/#{file}")
        assert File.exists?(expected), "File #{expected} not created for url #{k}"
      end
    end
  end

  def test_save_page_to_aws
  end

  def test_add_url_with_valid_domains
    test_url = "http://test.com/test"
    @crawler.add_url(test_url)
    assert(@crawler.url_queue[-1] == [test_url, {}], "URL #{test_url} not added to queue")
  end

  def test_add_url_with_filter
  end

  def test_initialize_options
  end

  def test_process_url
  end

  def test_make_absolute
  end

  def test_link_extraction
  end

  def test_href_extraction
  end

  def test_css_extraction
  end

  def test_css_url_extraction
  end

  def test_image_extraction
  end

  def test_script_extraction
  end
end