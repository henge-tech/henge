# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wordcircle/version'

Gem::Specification.new do |spec|
  spec.name          = "wordcircle"
  spec.version       = WordCircle::VERSION
  spec.authors       = ["KOSEKI Kengo"]
  spec.email         = ["koseki@gmail.com"]

  spec.summary       = %q{Word circle viewer.}
  spec.description   = %q{Word circle viewer.}
  spec.homepage      = "https://github.com/koseki/wordcircle/"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.files        += Dir['data/circles/*.yml']
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "curses"
  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
