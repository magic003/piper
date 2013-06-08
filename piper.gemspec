# encoding: utf-8
$:.push File.expand_path("../lib",__FILE__)
require "piper/version"

Gem::Specification.new do |s|
  s.name = "piper"
  s.version = Piper::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ["Minjie Zha"]
  s.email = ["minjiezha@gmail.com"]
  s.homepage = "https://github.com/magic003/piper"
  s.summary = %q{Piper}
  s.description = %q{Piper is a rack style lib for crawling social data.}

  s.add_runtime_dependency "faraday"
  s.add_runtime_dependency "rake"
  s.add_development_dependency "yard"
  s.add_development_dependency "redcarpet"
  s.add_development_dependency "rdoc"

  s.files = Dir['Rakefile', '{lib,test}/**/*', 'README*', '.yardopts', 
    'Gemfile']
  s.test_files = Dir['test/**/*']
  s.require_paths = ["lib"]
end
