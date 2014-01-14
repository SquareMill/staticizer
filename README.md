# Staticizer

A tool to create a static version of a website for hosting on S3.

## Rationale

One of our clients needed a reliable emergency backup for a
website. If the website goes down this backup would be available
with reduced functionality.

S3 and Route 53 provide an great way to host a static emergency backup for a website.
See this article - http://aws.typepad.com/aws/2013/02/create-a-backup-website-using-route-53-dns-failover-and-s3-website-hosting.html 
. In our experience it works very well and is incredibly cheap at less than US$1 a month (depending on the size of the website).

We tried using exsisting tools httrack/wget to crawl and create a static version
of the site to upload to S3, but we found that they did not work well with S3 hosting. 
We wanted the site uploaded to S3 to respond to the *exact* same URLs (where possible) as 
the existing site. This way when the  site goes down incoming links from Google search 
results etc. will still work.

## TODO

* Abillity to specify AWS credentials via file or environment options
* Tests!
* Decide what to do with URLs with query strings. Currently they are crawled and uploaded to S3, but those keys cannot be accessed. ex http://squaremill.com/file?test=1 will be uploaded with the key file?test=1, but can only be accessed by encoding the ? like this %3Ftest=1
* Create a 404 file on S3
* Provide the option to rewrite absolute URLs to relative urls so that hosting can work on a different domain.
* Multithread the crawler
* Check for too many redirects
* Provide regex options for what urls are scraped
* Better handling of incorrect server mime types (ex. server returns text/plain for css instead of text/css)
* Provide more options for uploading (upload via scp, ftp, custom etc.). Split out save/uploading into an interface.
* Handle large files in a more memory efficient way by streaming uploads/downloads

## Installation

Add this line to your application's Gemfile:

    gem 'staticizer'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install s3static

## Command line usage

The tool can either be used via the 'staticizer' commandline tool or via requiring the library.


### Crawl a website and write to disk

    staticizer http://squaremill.com -output-dir=/tmp/crawl

### Crawl a website and upload to AWS

    staticizer http://squaremill.com -aws-s3-bucket=squaremill.com --aws-access-key=HJFJS5gSJHMDZDFFSSDQQ --aws-secret-key=HIA7T189234aADfFAdf322Vs12duRhOHy+23mc1+s

### Crawl a website and allow several domains to be crawled

    staticizer http://squaremill.com --valid-domains=squaremill.com,www.squaremill.com,img.squaremill.com

## Code Usage

For all these examples you must first:

    require 'staticizer'

### Crawl a website and upload to AWS

This will only crawl urls in the domain squaremill.com

    s = Staticizer::Crawler.new("http://squaremill.com",
      :aws => {
        :bucket_name => "www.squaremill.com",
        :secret_access_key => "HIA7T189234aADfFAdf322Vs12duRhOHy+23mc1+s",
        :access_key_id => "HJFJS5gSJHMDZDFFSSDQQ"
      }
    )
    s.crawl

### Crawl a website and write to disk

    s = Staticizer::Crawler.new("http://squaremill.com", :output_dir => "/tmp/crawl")
    s.crawl

### Crawl a website and rewrite all non www urls to www

    s = Staticizer::Crawler.new("http://squaremill.com",
      :aws => {
        :bucket_name => "www.squaremill.com",
        :secret_access_key => "HIA7T189234aADfFAdf322Vs12duRhOHy+23mc1+s",
        :access_key_id => "HJFJS5gSJHMDZDFFSSDQQ"
      },
      :filter_url => lambda do |url, info|
        # Only crawl URL if it matches squaremill.com or www.squaremil.com
        if url =~ %r{https?://(www\.)?squaremill\.com}
          # Rewrite non-www urls to www
          return url.gsub(%r{https?://(www\.)?squaremill\.com}, "http://www.squaremill.com")
        end
        # returning nil here prevents the url from being crawled
      end
    )
    s.crawl

## Cralwer Options

* :aws - Hash of connection options passed to aws/sdk gem
* :filter_url - proc called to see if a discovered URL should be crawled, return nil to not crawl a url, return the url (can be modified) to crawl
* :output_dir - if writing a site to disk the directory to write to, will be created if it does not exist
* :logger - A logger object responding to the usual Ruby Logger methods.
* :log_level - Log level - defaults to INFO.
# :valid_domains - Array of domains that should be crawled. Domains not in this list will be ignored.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
