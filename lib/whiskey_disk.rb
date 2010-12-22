require File.expand_path(File.join(File.dirname(__FILE__), 'whiskey_disk', 'config'))

class WhiskeyDisk
  class << self
    attr_writer :configuration
    attr_reader :results
    
    def reset
      @configuration = nil
      @buffer = nil
      @staleness_checks = nil
      @results = nil
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
      !! self[:domain]
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
      
      check += "if [[ $ml != ${mr%%\t*} ]] " +
               (self[:deploy_config_to] ? "|| [[ $cl != ${cr%%\t*} ]]" : '') +
               "; then #{commands}; else echo \"No changes to deploy.\"; fi"
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
      self[:domain].each do |domain|
        status = system('ssh', '-v', domain, "set -x; " + cmd)
        record_result(domain, status)
      end
    end
    
    def record_result(domain, status)
      @results ||= []
      @results << { :domain => domain, :status => status }
    end
    
    def flush
      remote? ? run(bundle) : system(bundle)
    end
    
    def if_file_present(path, cmd)
      "if [ -e #{path} ]; then #{cmd}; fi"
    end
    
    def if_task_defined(task, cmd)
      %Q{if [[ `#{env_vars} rake -P | grep #{task}` != "" ]]; then #{cmd}; fi}
    end
    
    def clone_repository(repo, path)
      enqueue "cd #{parent_path(path)}"
      enqueue("if [ -e #{path} ]; then echo 'Repository already cloned to [#{path}].  Skipping.'; " +
              "else git clone --depth 1 #{repo} #{tail_path(path)} ; fi")
    end
   
    def refresh_checkout(path, repo_branch)
      enqueue "cd #{path}"
      enqueue "git fetch origin +refs/heads/#{repo_branch}:refs/remotes/origin/#{repo_branch}"
      enqueue "git reset --hard origin/#{repo_branch}"
    end

    def run_rake_task(path, task_name)
      enqueue "cd #{path}"
      enqueue(if_file_present("#{self[:deploy_to]}/Rakefile", 
        if_task_defined(task_name, "#{env_vars} rake --trace #{task_name} to=#{self[:environment]}")))
    end
    
    def build_path(path)
      return path if path =~ %r{^/}
      File.join(self[:deploy_to], path)
    end

    def run_script(script)
      return unless script
      path = build_path(script)
      enqueue("if [ -e #{path} ]; then sh -x #{path}; fi ")
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
      clone_repository(self[:repository], self[:deploy_to])
    end
    
    def checkout_configuration_repository
      needs(:deploy_config_to, :config_repository)
      clone_repository(self[:config_repository], self[:deploy_config_to])
    end
    
    def update_main_repository_checkout
      needs(:deploy_to)
      refresh_checkout(self[:deploy_to], branch)
    end
    
    def update_configuration_repository_checkout
      needs(:deploy_config_to)
      refresh_checkout(self[:deploy_config_to], config_branch)
    end
    
    def refresh_configuration
      needs(:deploy_to, :deploy_config_to)
      raise "Must specify project name when using a configuration repository." unless project_name_specified?
      enqueue("rsync -av --progress #{self[:deploy_config_to]}/#{self[:project]}/#{self[:environment]}/ #{self[:deploy_to]}/")
    end
    
    def run_post_setup_hooks
      needs(:deploy_to)
      run_script(self[:post_setup_script])
      run_rake_task(self[:deploy_to], "deploy:post_setup")
    end
    
    def run_post_deploy_hooks
      needs(:deploy_to)
      run_script(self[:post_deploy_script])
      run_rake_task(self[:deploy_to], "deploy:post_deploy")
    end
  end
end