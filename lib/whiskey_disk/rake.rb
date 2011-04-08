require 'rake'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'whiskey_disk'))

namespace :deploy do
  desc "Perform initial setup for deployment"
  task :setup do
    WhiskeyDisk.ensure_main_parent_path_is_present
    WhiskeyDisk.ensure_config_parent_path_is_present      if WhiskeyDisk.has_config_repo?
    WhiskeyDisk.checkout_main_repository
    WhiskeyDisk.checkout_configuration_repository         if WhiskeyDisk.has_config_repo?
    WhiskeyDisk.update_main_repository_checkout
    WhiskeyDisk.update_configuration_repository_checkout  if WhiskeyDisk.has_config_repo?
    WhiskeyDisk.refresh_configuration                     if WhiskeyDisk.has_config_repo?
    WhiskeyDisk.initialize_all_changes
    WhiskeyDisk.run_post_setup_hooks
    WhiskeyDisk.flush
    WhiskeyDisk.summarize

    exit(1) unless WhiskeyDisk.success?
  end
  
  desc "Deploy now."
  task :now do
    WhiskeyDisk.enable_staleness_checks
    WhiskeyDisk.update_main_repository_checkout
    WhiskeyDisk.update_configuration_repository_checkout  if WhiskeyDisk.has_config_repo?
    WhiskeyDisk.refresh_configuration                     if WhiskeyDisk.has_config_repo?
    WhiskeyDisk.run_post_deploy_hooks
    WhiskeyDisk.flush
    WhiskeyDisk.summarize

    exit(1) unless WhiskeyDisk.success?
  end
  
  task :post_setup do
    env = WhiskeyDisk[:environment]
    Rake::Task["deploy:#{env}:post_setup"].invoke if Rake::Task.task_defined? "deploy:#{env}:post_setup"      
  end

  task :post_deploy do
    env = WhiskeyDisk[:environment]
    Rake::Task["deploy:#{env}:post_deploy"].invoke if Rake::Task.task_defined? "deploy:#{env}:post_deploy"      
  end
end
