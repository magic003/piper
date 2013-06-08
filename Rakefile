require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rdoc/task'
require 'yard'

task :default => [:test]
CLOBBER.include('.yardoc','doc','piper-*.gem')

## Unit tests tasks
desc "Run all unit tests"
Rake::TestTask.new("test") do |t|
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.warning = true
end

## RDoc task
desc "Generate RDoc documentation"
Rake::RDocTask.new do |rd|
  rd.main = "README"
  rd.title = 'piper RDoc documentation'
  rd.rdoc_files.include("README", "lib/**/*.rb")
end

## Yard document task
desc "Generate Yard documentation"
YARD::Rake::YardocTask.new do |t|
  t.files = ['lib/**/*.rb', '-', 'README']
end
