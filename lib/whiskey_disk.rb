require File.expand_path(File.join(File.dirname(__FILE__), 'tasks', 'deploy'))
require File.expand_path(File.join(File.dirname(__FILE__), 'whiskey_disk', 'config'))

class WhiskeyDisk
  class << self
    def reset
      @configuration = nil
      @buffer = nil
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
    
    def enqueue(command)
      buffer << command
    end
    
    def remote?
      ! (self[:domain].nil? or self[:domain] == '')
    end
    
    def parent_path(path)
      File.split(path).first
    end
    
    def tail_path(path)
      File.split(path).last
    end
    
    def register_configuration
      configuration.each_pair {|k,v| set k, v }
    end
    
    def needs(*keys)
      keys.each do |key|
        raise "No value for '#{key}' declared in configuration file [#{WhiskeyDisk::Config.filename}]" unless self[key]
      end
    end
    
    def bundle
      return '' if buffer.empty?
      buffer.collect {|c| "(#{c})" }.join(' && ')
    end
    
    def flush
      if remote?
        register_configuration
        run(bundle)
      else
        system(bundle)
      end
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
      enqueue "git clone #{self[:repository]} #{tail_path(self[:deploy_to])} || true"
    end
    
    def install_hooks
      needs(:deploy_to)
      # FIXME - TODO: MORE HERE
    end

    def checkout_configuration_repository
      needs(:deploy_config_to, :config_repository)
      enqueue "cd #{parent_path(self[:deploy_config_to])}"
      enqueue "git clone #{self[:config_repository]} #{tail_path(self[:deploy_config_to])} || true"
    end
    
    def update_main_repository_checkout
      needs(:deploy_to)
      branch = (self[:branch] and self[:branch] != '') ? self[:branch] : 'master'
      enqueue "cd #{self[:deploy_to]}"
      enqueue "git fetch origin +refs/heads/#{branch}:refs/remotes/origin/#{branch}"
      enqueue "git reset --hard origin/#{branch}"
    end
    
    def update_configuration_repository_checkout
      needs(:deploy_config_to)
      enqueue "cd #{self[:deploy_config_to]}"
      enqueue "git fetch origin +refs/heads/master:refs/remotes/origin/master"
      enqueue "git reset --hard origin/master"
    end
    
    def refresh_configuration
      needs(:deploy_to, :deploy_config_to)
      enqueue "rsync -av --progress #{self[:deploy_config_to]}/#{self[:project]}/#{self[:environment]}/ #{self[:deploy_to]}/"
    end
    
    def run_post_setup_hooks
      needs(:deploy_to)
      enqueue "cd #{self[:deploy_to]}"
      enqueue "rake deploy:post_setup"
    end

    def run_post_deploy_hooks
      needs(:deploy_to)
      enqueue "cd #{self[:deploy_to]}"
      enqueue "rake deploy:post_deploy"
    end
  end
end