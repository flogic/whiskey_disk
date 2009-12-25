require File.expand_path(File.join(File.dirname(__FILE__), '..', 'helpers'))
include WhiskeyDisk
require 'vlad'

# TODO: 
# - look at git-deploy for some hooks we might use
# - un-spike
# - some sort of generator to help with making config dirs (or does that belong to another project?)
# - improve the README to show the whole flow

namespace :deploy do
  task :load_configuration do evaluate_configuration end
  task :remote_setup => [ :load_configuration, :create_parent_paths, :pull_repository, :install_hooks, 
                          :remote_pull_config_repository, :remote_refresh, :remote_post_setup ]
  task :local_setup  => [ :load_configuration, :pull_config_repository, :refresh, :post_setup ]
  task :remote_now   => [ :load_configuration, :refresh_deployment, :remote_refresh, :remote_post_deploy ]
  task :local_now    => [ :load_configuration, :refresh, :post_deploy ]
  
  desc "set up host for deployment"
  task :setup => [ :load_configuration ] do
    if domain == ''
      Rake::Task['deploy:local_setup'].invoke
    else
      Rake::Task['deploy:remote_setup'].invoke
    end
  end

  desc "update the deployment immediately"
  task :now => [ :load_configuration ] do
    if domain == ''
      Rake::Task['deploy:local_now'].invoke
    else
      Rake::Task['deploy:remote_now'].invoke
    end
  end
  
  ### local operations

  task :pull_config_repository => [ :load_configuration ] do
    system "echo 'cloning repo: #{config_repository}'; " +
      "cd #{parent_path(deploy_config_to)} && git clone #{config_repository} #{config_path}"
  end

  desc "refresh configuration files"
  task :refresh => [ :load_configuration ] do
    puts "refreshing configuration files to [#{deploy_to}] from [#{deploy_to}/project_config/]..."
    system "cd #{deploy_config_to} && git fetch origin && git reset --hard origin/master && " +
      "rsync -avz --progress #{deploy_config_to}/#{project_name}/#{environment_name}/ #{deploy_to}/"
  end
  
  task :post_setup => [ :load_configuration ] do
    if Rake::Task.task_defined? "deploy:#{environment_name}:post_setup"
      puts "Running deploy:#{environment_name}:post_setup task..."
      Rake::Task["deploy:#{environment_name}:post_setup"].invoke
    else
      puts "No task deploy:#{environment_name}:post_setup defined.  Skipping."
    end
  end

  task :post_deploy => [ :load_configuration ] do
    # crib various tasks from someplace like git-deploy, incl. db:migrate, any cache refreshing, asset stuff, TS bouncing, etc.
    if Rake::Task.task_defined? "deploy:#{environment_name}:post_deploy"
      puts "Running deploy:#{environment_name}:post_deploy task..."
      Rake::Task["deploy:#{environment_name}:post_deploy"].invoke
    else
      puts "No task deploy:#{environment_name}:post_deploy defined.  Skipping."
    end
  end

  ### remote operations
    
  remote_task :create_parent_paths, :roles => :app do
    run "echo 'creating: #{parent_path(deploy_to)} #{parent_path(deploy_config_to)}' && " +
      "mkdir -p #{parent_path(deploy_to)} && ls -al #{parent_path(deploy_to)} && " +
      "mkdir -p #{parent_path(deploy_config_to)} && ls -al #{parent_path(deploy_config_to)}"
  end

  remote_task :pull_repository, :roles => :app do
    run "echo 'cloning repo: #{repository}'; cd #{parent_path(deploy_to)} && git clone #{repository} #{deployment_path} || true"
  end

  remote_task :install_hooks, :roles => :app do
    puts "Would be installing our hooks on the remote repo."
  end

  remote_task :remote_pull_config_repository, :roles => :app do
    run "echo 'cloning repo: #{config_repository} on remote'; " +
      "cd #{parent_path(deploy_config_to)} && git clone #{config_repository} project_config"
  end

  remote_task :remote_refresh, :roles => :app do
    run "echo 'Refreshing remote configuration files...' && cd #{deploy_to} && rake deploy:refresh to=#{environment_name}"
    run "echo 'refreshing configuration files to [#{deploy_to}] from [#{deploy_to}/project_config/]...' && " +
      "cd #{deploy_config_to} && git fetch origin && git reset --hard origin/master && " +
      "rsync -avz --progress #{deploy_config_to}/#{project_name}/#{environment_name}/ #{deploy_to}/"
  end

  remote_task :refresh_deployment, :roles => :app do
    run "echo 'Updating checkout in [#{deploy_to}] on remote...' && " +
      "cd #{deploy_to} && git fetch origin +refs/heads/#{branch}:refs/remotes/origin/#{branch} && git reset --hard origin/#{branch}"
  end
  
  remote_task :remote_post_setup, :roles => :app do
    run "echo 'Running post setup tasks on remote...' && cd #{deploy_to} && rake deploy:post_setup to=#{environment_name}"
  end

  remote_task :remote_post_deploy, :roles => :app do
    run "echo 'Running post deployment tasks...' && cd #{deploy_to} && rake deploy:post_setup to=#{environment_name}"
  end
end
