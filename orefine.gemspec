# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'orefine/version'

Gem::Specification.new do |s|
  s.name          = "orefine"
  s.version       = Orefine::VERSION
  s.authors       = ["Michael Bianco"]
  s.email         = ["info@cliffsidedev.com"]
  s.description   = %q{TODO: Write a gem description}
  s.summary       = %q{TODO: Write a gem summary}
  s.homepage      = ""
  s.license       = "MIT"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency 'google-refine', '~> 0.1.1'

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
