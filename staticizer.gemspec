# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'staticizer/version'

Gem::Specification.new do |spec|
  spec.name          = "staticizer"
  spec.version       = Staticizer::VERSION
  spec.authors       = ["Conor Hunt"]
  spec.email         = ["conor.hunt+git@gmail.com"]
  spec.description   = %q{TODO: A tool to create a static version of a website for hosting on S3.}
  spec.summary       = %q{TODO: A tool to create a static version of a website for hosting on S3.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"

  spec.add_runtime_dependency 'nokogiri'
  spec.add_runtime_dependency 'aws-sdk'
end
