require File.expand_path(File.join(File.dirname(__FILE__), 'whiskey_disk', 'config'))

class WhiskeyDisk
  class << self
    def reset
      @configuration = nil
      @buffer = nil
      @staleness_checks = nil
    end
    
    def buffer
      @buffer ||= []
    end
    
    def configuration
      @configuration ||= WhiskeyDisk::Config.fetch
    end
    
    def [](key)
      configuration[key.to_s]
    end
    
    def check_staleness?
      WhiskeyDisk::Config.check_staleness?
    end
    
    def enable_staleness_checks
      @staleness_checks = true
    end
    
    def staleness_checks_enabled?
      !!@staleness_checks
    end    

    def enqueue(command)
      buffer << command
    end
    
    def remote?
      ! (self[:domain].nil? or self[:domain] == '')
    end
    
    def has_config_repo?
      ! (self[:config_repository].nil? or self[:config_repository] == '')
    end
    
    def project_name_specified?
      self[:project] != 'unnamed_project'
    end

    def branch
      (self[:branch] and self[:branch] != '') ? self[:branch] : 'master'
    end
    
    def config_branch
      (self[:config_branch] and self[:config_branch] != '') ? self[:config_branch] : 'master'
    end
    
    def env_vars
      return '' unless self[:rake_env]
      self[:rake_env].keys.inject('') do |buffer,k| 
        buffer += "#{k}='#{self[:rake_env][k]}' "
        buffer
      end
    end
    
    def parent_path(path)
      File.split(path).first
    end
    
    def tail_path(path)
      File.split(path).last
    end
    
    def needs(*keys)
      keys.each do |key|
        raise "No value for '#{key}' declared in configuration files [#{WhiskeyDisk::Config.configuration_file}]" unless self[key]
      end
    end

    def apply_staleness_check(commands)
      needs(:deploy_to, :repository)
      
      check = "cd #{self[:deploy_to]}; " +
              "ml=\`cat .git/refs/heads/#{branch}\`; " +
              "mr=\`git ls-remote #{self[:repository]} refs/heads/#{branch}\`; "
      
      if self[:deploy_config_to]
        check += "cd #{self[:deploy_config_to]}; " +
                 "cl=\`cat .git/refs/heads/#{config_branch}\`; " +
                 "cr=\`git ls-remote #{self[:config_repository]} refs/heads/#{config_branch}\`; "
      end
      
      check += "if [[ $ml != ${mr%%\t*} " +
               (self[:deploy_config_to] ? "-o $cl != ${cr%%\t*} " : '') +
               "]]; then #{commands}; fi"
    end
    
    def join_commands
      buffer.collect {|c| "{ #{c} ; }"}.join(' && ')
    end
    
    def bundle
      return '' if buffer.empty?
      (staleness_checks_enabled? and check_staleness?) ? apply_staleness_check(join_commands) : join_commands
    end
    
    def run(cmd)
      needs(:domain)
      system('ssh', '-v', self[:domain], "set -x; " + cmd)
    end
    
    def flush
      remote? ? run(bundle) : system(bundle)
    end
    
    def if_file_present(path, cmd)
      "if [ -e #{path} ]; then #{cmd}; fi"
    end
    
    def ensure_main_parent_path_is_present
      needs(:deploy_to)
      enqueue "mkdir -p #{parent_path(self[:deploy_to])}"
    end
    
    def ensure_config_parent_path_is_present
      needs(:deploy_config_to)
      enqueue "mkdir -p #{parent_path(self[:deploy_config_to])}"
    end
    
    def checkout_main_repository
      needs(:deploy_to, :repository)
      enqueue "cd #{parent_path(self[:deploy_to])}"
      enqueue "git clone #{self[:repository]} #{tail_path(self[:deploy_to])} ; true"
    end
    
    def checkout_configuration_repository
      needs(:deploy_config_to, :config_repository)
      enqueue "cd #{parent_path(self[:deploy_config_to])}"
      enqueue "git clone #{self[:config_repository]} #{tail_path(self[:deploy_config_to])} ; true"
    end
    
    def update_main_repository_checkout
      needs(:deploy_to)
      enqueue "cd #{self[:deploy_to]}"
      enqueue "git fetch origin +refs/heads/#{branch}:refs/remotes/origin/#{branch}"
      enqueue "git reset --hard origin/#{branch}"
    end
    
    def update_configuration_repository_checkout
      needs(:deploy_config_to)
      enqueue "cd #{self[:deploy_config_to]}"
      enqueue "git fetch origin +refs/heads/#{config_branch}:refs/remotes/origin/#{config_branch}"
      enqueue "git reset --hard origin/#{config_branch}"
    end
    
    def refresh_configuration
      needs(:deploy_to, :deploy_config_to)
      raise "Must specify project name when using a configuration repository." unless project_name_specified?
      enqueue("rsync -av --progress #{self[:deploy_config_to]}/#{self[:project]}/#{self[:environment]}/ #{self[:deploy_to]}/")
    end
    
    def run_post_setup_hooks
      needs(:deploy_to)
      enqueue "cd #{self[:deploy_to]}"
      enqueue(if_file_present("#{self[:deploy_to]}/Rakefile", 
                               "#{env_vars} rake --trace deploy:post_setup to=#{self[:environment]}"))
    end

    def run_post_deploy_hooks
      needs(:deploy_to)
      enqueue "cd #{self[:deploy_to]}"
      enqueue(if_file_present("#{self[:deploy_to]}/Rakefile", 
                               "#{env_vars} rake --trace deploy:post_deploy to=#{self[:environment]}"))
    end
  end
end