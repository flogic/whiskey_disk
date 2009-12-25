require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'spec/rake/spectask'

desc 'Default: run specs.'
task :default => :spec

desc 'Test the whiskey_disk library.'
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
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

