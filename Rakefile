require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test RubyCloud'
task :test do
  files = Dir['spec/**/*_spec.rb'].join(" ")
  system("bacon #{files}")
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
    gemspec.add_dependency('rake')
  end
  Jeweler::GemcutterTasks.new  
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler -s http://gemcutter.org"
end

