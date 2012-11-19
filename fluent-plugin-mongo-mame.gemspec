# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fluent-plugin-mongo-mame/version'

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-mongo-mame"
  gem.version       = Fluent::Plugin::Mongo::Mame::VERSION
  gem.authors       = ["sutetotanuki"]
  gem.email         = ["sutetotanuki@gmail.com"]
  gem.description   = %q{mamemae}
  gem.summary       = %q{mamemame}
  gem.homepage      = ""

#  gem.files         = `git ls-files`.split($/)
  gem.files         = Dir["lib/**/*"]
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "fluentd"
  gem.add_runtime_dependency "mongo"
  gem.add_runtime_dependency "bson_ext"
end
