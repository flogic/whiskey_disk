require File.expand_path(File.join(File.dirname(__FILE__), '..', 'whiskey_disk'))
require 'vlad'

namespace :deploy do
  task :setup do
    WhiskeyDisk.ensure_main_parent_path_is_present        if WhiskeyDisk.remote?
    WhiskeyDisk.ensure_config_parent_path_is_present     
    WhiskeyDisk.checkout_main_repository                  if WhiskeyDisk.remote?
    WhiskeyDisk.install_hooks                             if WhiskeyDisk.remote?
    WhiskeyDisk.checkout_configuration_repository
    WhiskeyDisk.refresh_configuration
    WhiskeyDisk.run_post_setup_hooks
    WhiskeyDisk.flush
  end
  
  task :now do
    WhiskeyDisk.update_main_repository_checkout           if WhiskeyDisk.remote?
    WhiskeyDisk.update_configuration_repository_checkout
    WhiskeyDisk.refresh_configuration
    WhiskeyDisk.run_post_deploy_hooks
    WhiskeyDisk.flush
  end
end
