require 'rake'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'whiskey_disk'))

namespace :deploy do
  desc "Perform initial setup for deployment"
  task :setup do
    exit(1) unless WhiskeyDisk.new.setup
  end

  desc "Deploy now."
  task :now do
    exit(1) unless WhiskeyDisk.new(:staleness_checks => true).deploy
  end

  task :post_setup do
    env = WhiskeyDisk.new.setting(:environment)
    Rake::Task["deploy:#{env}:post_setup"].invoke if Rake::Task.task_defined? "deploy:#{env}:post_setup"
  end

  task :post_deploy do
    env = WhiskeyDisk.new.setting(:environment)
    Rake::Task["deploy:#{env}:post_deploy"].invoke if Rake::Task.task_defined? "deploy:#{env}:post_deploy"
  end
end
