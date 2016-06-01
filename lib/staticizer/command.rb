require 'optparse'

module Staticizer
  class Command
    # Parse command line arguments and print out any errors
    def Command.parse(args)
      options = {}
      initial_page = nil

      parser = OptionParser.new do |opts|
        opts.banner = "Usage: staticizer initial_url [options]\nExample: staticizer http://squaremill.com --output-dir=/tmp/crawl"

        opts.separator ""
        opts.separator "Specific options:"

        opts.on("--aws-s3-bucket [STRING]", "Name of S3 bucket to write to") do |v|
          options[:aws] ||= {}
          options[:aws][:bucket_name] = v
        end

        opts.on("--aws-access-key [STRING]", "AWS Access Key ID") do |v|
          options[:aws] ||= {}
          options[:aws][:access_key_id] = v
        end

        opts.on("--aws-secret-key [STRING]", "AWS Secret Access Key") do |v|
          options[:aws] ||= {}
          options[:aws][:secret_access_key] = v
        end

        opts.on("-d", "--output-dir [DIRECTORY]", "Write crawl to disk in this directory, will be created if it does not exist") do |v|
          options[:output_dir] = v
        end

        opts.on("-v", "--verbose", "Run verbosely (sets log level to Logger::DEBUG)") do |v|
          options[:log_level] = Logger::DEBUG
        end

        opts.on("--log-level [NUMBER]", "Set log level 0 = most verbose to 4 = least verbose") do |v|
          options[:log_level] = v.to_i
        end

        opts.on("--log-file [PATH]", "Log file to write to") do |v|
          options[:logger] = Logger.new(v)
        end

        opts.on("--skip-write [PATH]", "Don't write out files to disk or s3") do |v|
          options[:skip_write] = true
        end

        opts.on("--valid-domains x,y,z", Array, "Comma separated list of domains that should be crawled, other domains will be ignored") do |v|
          options[:valid_domains] = v
        end

        opts.on_tail("-h", "--help", "Show this message") do
          puts "test"
          puts opts
          exit
        end
      end

      begin
        parser.parse!(args)
        initial_page = ARGV.pop
        raise ArgumentError, "Need to specify an initial URL to start the crawl" unless initial_page
      rescue StandardError => e
        puts e
        puts parser
        exit(1)
      end

      return options, initial_page
    end
  end
end


=begin

=end
