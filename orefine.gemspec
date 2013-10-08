# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'orefine/version'

Gem::Specification.new do |s|
  s.name          = "orefine"
  s.version       = Orefine::VERSION
  s.authors       = ["Michael Bianco"]
  s.email         = ["info@cliffsidedev.com"]
  s.description   = %q{Easily modify CSVs from the command line using Open Refine}
  s.summary       = %q{Easily modify CSVs from the command line using Open Refine}
  s.homepage      = "http://github.com/iloveitaly/orefine"
  s.license       = "MIT"

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.require_paths = ["lib"]

  s.add_dependency 'google-refine', '~> 0.1.1'
  s.add_dependency 'slop', '~> 3.4.6'

  s.add_development_dependency "bundler", "~> 1.3"
  s.add_development_dependency "rake"
end
