require 'rake'
require 'rake/clean'
require 'rake/testtask'
require 'rdoc/task'
require 'yard'

task :default => [:test]
CLOBBER.include('.yardoc','doc','piper-*.gem')

## Unit tests tasks
namespace :test do
  desc "Run unit tests without internet accessing"
  Rake::TestTask.new("nointernet") do |t|
    t.test_files = FileList['test/dispatcher/test_*.rb', 'test/interface/test_*.rb', 'test/linkstore/test_*.rb', 'test/thread_pool/test_*.rb', 'test/test_db_helper.rb']
    t.verbose = true
    t.warning = true
  end

  desc "Run unit tests with internet accessing only"
  Rake::TestTask.new("internet") do |t|
    t.test_files = FileList['test/clients/test_*.rb', 'test/tasks/test_*.rb']
    t.verbose = true
    t.warning = true
  end
end

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
