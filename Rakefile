require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test RubyCloud'
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.pattern = 'spec/**/*_spec.rb'
  t.verbose = true
end


begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "whiskey_disk"
    gemspec.summary = "embarrassingly fast deployments."
    gemspec.description = "Opinionated gem for doing fast git-based server deployments."
    gemspec.email = "rick@rickbradley.com"
    gemspec.homepage = "http://github.com/flogic/whiskey_disk"
    gemspec.authors = ["Rick Bradley"]
    gemspec.add_dependency('vlad', '>= 1.3.2')
  end
  Jeweler::GemcutterTasks.new  
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install technicalpickles-jeweler -s http://gems.github.com"
end

