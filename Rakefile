require 'rake'
require 'rake/testtask'

desc 'Default: run unit tests.'
task :default => :test

desc 'Test RubyCloud'
task :test do
  files = Dir['spec/**/*_spec.rb'].join(" ")
  system("bacon #{files}")
end

namespace :integration do
  def say(mesg)
    STDERR.puts mesg
  end
  
  def vagrant_path
    File.expand_path(File.join(File.dirname(__FILE__), 'scenarios', 'setup', 'vagrant'))
  end
  
  def root_path
    File.expand_path(File.dirname(__FILE__))
  end
  
  def pidfile
    File.join(vagrant_path, 'pids', 'git-daemon.pid')
  end
  
  def start_git_daemon
    stop_git_daemon
    say "Starting git daemon..."
    run(root_path, "git daemon --base-path=#{root_path}/scenarios/git_repositories/ --reuseaddr --verbose --detach --pid-file=#{pidfile}")
  end
  
  def stop_git_daemon
    return unless File.exists?(pidfile)
    pid = File.read(pidfile).chomp
    return if pid == ''
    say "Stopping git daemon..."
    run(root_path, "kill #{pid}")
  end
  
  def start_vm
    say "Bringing up vagrant vm..."
    run(vagrant_path, 'vagrant up')
    copy_ssh_config
  end

  def stop_vm
    say "Shutting down vagrant vm..."
    run(vagrant_path, 'vagrant halt')
  end
  
  def copy_ssh_config
    say "Capturing vagrant ssh_config data..."
    run(vagrant_path, "vagrant ssh_config > #{vagrant_path}/ssh_config")
  end
  
  def run(path, cmd)
    Dir.chdir(path)
    say "running: #{cmd} [cwd: #{Dir.pwd}]"
    system(cmd)
  end
    
  desc 'Start a vagrant VM and git-daemon server to support running integration specs'
  task :up do
    start_vm
    start_git_daemon
  end
  
  desc 'Shut down integration vagrant VM and git-daemon server'
  task :down do
    stop_git_daemon
    stop_vm
  end
  
  desc 'Completely remove the vagrant VM files used by the integration spec suite'
  task :destroy do
    stop_git_daemon
    stop_vm
    run(vagrant_path, 'vagrant destroy')
  end
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
    
    # I've decided that the integration spec shizzle shouldn't go into the gem
    gemspec.files.exclude 'scenarios', 'spec/integration'
    gemspec.test_files.exclude 'scenarios', 'spec/integration'
  end
  Jeweler::GemcutterTasks.new  
rescue LoadError
  # if you get here, you need Jeweler installed to do packaging and gem installation, yo.
end

