# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'zebris/version'

Gem::Specification.new do |spec|
  spec.name          = "zebris"
  spec.version       = Zebris::VERSION
  spec.authors       = ["Jeremy Gailor"]
  spec.email         = ["jgailor@gmail.com"]
  spec.description   = %q{Zebris is a library to persist your object data to Redis.  Its goal is to be as unobtrusive as possible.}
  spec.summary       = %q{Zebris makes persisting your objects to Redis easy.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 2.14.1"
  spec.add_development_dependency "uuid"
end
