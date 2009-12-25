require 'vlad'

def build_filename(str)
  File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'config', "#{str}.yml"))
end

def configuration_file
  @config_file ||= build_filename("deploy")
end

def per_environment_file
  build_filename("deploy-#{initial_environment_name}")
end

def load_global_configuration
  YAML.load(File.read(configuration_file))
rescue Exception => e
  raise "Cannot load configuration file [#{configuration_file}]: #{e.to_s}"
end  

def load_environment_configuration
  return {} unless File.exists?(per_environment_file)
  puts "Overriding global configuration with environment [#{initial_environment_name}] settings from [#{per_environment_file}]"
  YAML.load(File.read(per_environment_file)) if File.exists?(per_environment_file)
rescue Exception => e
  raise "Cannot load per-environment configuration file [#{per_environment_file}]: #{e.to_s}"
end  

def loaded_configuration 
  @loaded_configuration ||= load_global_configuration.merge(load_environment_configuration)
end

def initial_environment_name
  @deploy_to ||= (ENV['to'].blank? ? 'staging' : ENV['to'])
end

def environment_name
  @environment_name ||= loaded_configuration.has_key?(initial_environment_name) ? initial_environment_name : 'default'
end

def set_values
  loaded_configuration[environment_name].each_pair do |k,v| 
    puts "setting [#{k}] => [#{v}]"
    set k, v
  end
end

def evaluate_configuration
  unless loaded_configuration.has_key?(environment_name)
    raise "Using environment [#{environment_name}] but configuration file [#{config_file}] has no declarations for this environment." 
  end
  set_values
end

def parent_path(path)
  File.split(path).first
end

def deployment_path
  File.split(deploy_to).last
end

def project_name
  File.split(repository).last.sub(/\.git$/, '')
end

namespace :deploy do
  # initialize our configuration
  task :load_configuration do
    evaluate_configuration
  end
  
  desc "set up host for deployment"
  task :setup => [ 
    'deploy:load_configuration', 
    'deploy:create_parent_paths', 
    'deploy:pull_repository',
    'deploy:install_hooks',
    'deploy:pull_config_repository',
    'deploy:refresh_config_files',
    'deploy:post_setup',
  ]

  desc "update the deployment immediately"
  task :now => [ 
    'deploy:load_configuration', 
    'deploy:refresh_deployment',
    'deploy:refresh_config_files',
    'deploy:post_deploy'
  ]
    
  # make sure that the parent directories for our repos exist
  remote_task :create_parent_paths, :roles => :app do
    run "echo 'creating: #{parent_path(deploy_to)} #{parent_path(deploy_config_to)}' && " +
      "mkdir -p #{parent_path(deploy_to)} && ls -al #{parent_path(deploy_to)} && " +
      "mkdir -p #{parent_path(deploy_config_to)} && ls -al #{parent_path(deploy_config_to)}"
  end

  # clone repo, if it doesn't exist already; don't fail if it exists
  remote_task :pull_repository, :roles => :app do
    run "echo 'cloning repo: #{repository}'; cd #{parent_path(deploy_to)} && git clone #{repository} #{deployment_path} || /bin/true"
  end

  # install our post-receive hook to the remote repo
  remote_task :install_hooks, :roles => :app do
    puts "Would be installing our hooks on the remote repo."
  end

  # clone configuration repo, if it doesn't exist already; don't fail if it exists
  remote_task :pull_config_repository, :roles => :app do
    run "echo 'cloning repo: #{config_repository}'; cd #{parent_path(deploy_config_to)} && git clone #{config_repository} project_config || /bin/true"
  end

  # make sure the repo checkout is up-to-date
  remote_task :refresh_deployment, :roles => :app do
    run "echo 'Updating checkout in [#{deploy_to}]...' && " +
      "cd #{deploy_to} && git fetch origin +refs/heads/#{branch}:refs/remotes/origin/#{branch} && git reset --hard origin/#{branch}"
  end

  # update configuration files, overlay onto repo checkout
  desc "refresh remote configuration files"
  remote_task :refresh_config_files, :roles => :app do
    run "echo 'refreshing configuration files to [#{deploy_to}] from [#{deploy_config_to}/#{environment_name}]...' && " +
      "cd #{deploy_config_to} && git fetch origin && git reset --hard origin/master && " +
      "rsync -avz --progress #{deploy_config_to}/#{project_name}/#{environment_name}/ #{deploy_to}/"
  end
  
  desc "run any post-setup tasks for this environment"
  task :post_setup do
    if Rake::Task.task_defined? "deploy:#{environment_name}:post_setup"
      puts "Running deploy:#{environment_name}:post_setup task..."
      Rake::Task["deploy:#{environment_name}:post_setup"].invoke
    else
      puts "No task deploy:#{environment_name}:post_setup defined.  Skipping."
    end
  end

  desc "run any post-deployment tasks for this environment"
  task :post_deploy do
    # crib various tasks from someplace like git-deploy, incl. db:migrate, any cache refreshing, asset stuff, TS bouncing, etc.
    if Rake::Task.task_defined? "deploy:#{environment_name}:post_deploy"
      puts "Running deploy:#{environment_name}:post_deploy task..."
      Rake::Task["deploy:#{environment_name}:post_deploy"].invoke
    else
      puts "No task deploy:#{environment_name}:post_deploy defined.  Skipping."
    end
  end
end
