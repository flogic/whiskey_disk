require 'rake'
require File.expand_path(File.join(File.dirname(__FILE__), '..', 'whiskey_disk'))

namespace :deploy do
  desc "Perform initial setup for deployment"
  task :setup do
    @whiskey_disk = WhiskeyDisk.new
    @whiskey_disk.ensure_main_parent_path_is_present
    @whiskey_disk.ensure_config_parent_path_is_present      if @whiskey_disk.has_config_repo?
    @whiskey_disk.checkout_main_repository
    @whiskey_disk.checkout_configuration_repository         if @whiskey_disk.has_config_repo?
    @whiskey_disk.update_main_repository_checkout
    @whiskey_disk.update_configuration_repository_checkout  if @whiskey_disk.has_config_repo?
    @whiskey_disk.refresh_configuration                     if @whiskey_disk.has_config_repo?
    @whiskey_disk.initialize_all_changes
    @whiskey_disk.run_post_setup_hooks
    @whiskey_disk.flush
    @whiskey_disk.summarize

    exit(1) unless @whiskey_disk.success?
  end
  
  desc "Deploy now."
  task :now do
    @whiskey_disk = WhiskeyDisk.new
    @whiskey_disk.enable_staleness_checks
    @whiskey_disk.update_main_repository_checkout
    @whiskey_disk.update_configuration_repository_checkout  if @whiskey_disk.has_config_repo?
    @whiskey_disk.refresh_configuration                     if @whiskey_disk.has_config_repo?
    @whiskey_disk.run_post_deploy_hooks
    @whiskey_disk.snapshot_git_revision
    @whiskey_disk.flush
    @whiskey_disk.summarize

    exit(1) unless @whiskey_disk.success?
  end
  
  task :post_setup do
    @whiskey_disk = WhiskeyDisk.new
    env = @whiskey_disk.setting(:environment)
    Rake::Task["deploy:#{env}:post_setup"].invoke if Rake::Task.task_defined? "deploy:#{env}:post_setup"      
  end

  task :post_deploy do
    @whiskey_disk = WhiskeyDisk.new
    env = @whiskey_disk.setting(:environment)
    Rake::Task["deploy:#{env}:post_deploy"].invoke if Rake::Task.task_defined? "deploy:#{env}:post_deploy"      
  end
end
