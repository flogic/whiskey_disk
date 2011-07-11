require File.expand_path(File.join(File.dirname(__FILE__), 'whiskey_disk', 'config'))
require File.expand_path(File.join(File.dirname(__FILE__), 'whiskey_disk', 'repository'))

class WhiskeyDisk
  attr_writer :configuration, :config
  attr_reader :results
  
  def initialize(options = {})
    @staleness_checks = true if options[:staleness_checks]
  end
  
  def setup
    ensure_main_parent_path_is_present
    ensure_config_parent_path_is_present      if has_config_repo?
    checkout_main_repository
    checkout_configuration_repository         if has_config_repo?
    update_main_repository_checkout
    update_configuration_repository_checkout  if has_config_repo?
    refresh_configuration                     if has_config_repo?
    initialize_all_changes
    run_post_setup_hooks
    flush
    summarize
    success?
  end
  
  def deploy
    @staleness_checks = true
    update_main_repository_checkout
    update_configuration_repository_checkout  if has_config_repo?
    refresh_configuration                     if has_config_repo?
    run_post_deploy_hooks
    flush
    summarize
    success?
  end
  
  def buffer
    @buffer ||= []
  end
  
  def config
    @config ||= WhiskeyDisk::Config.new
  end
  
  def configuration
    @configuration ||= config.fetch
  end
  
  def debugging?
    config.debug?
  end
  
  def setting(key)
    configuration[key.to_s]
  end
  
  def check_staleness?
    config.check_staleness?
  end
  
  def staleness_checks_enabled?
    !! @staleness_checks
  end    

  def enqueue(commands)
    [ commands ].flatten.each {|command| buffer << command }
  end
  
  def remote?(domain)
    return false unless domain
    return false if domain == 'local'
    limit = config.domain_limit 
    return false if limit and domain_limit_match?(domain, limit)

    true
  end
  
  def has_config_repo?
    !! setting(:config_repository)
  end
  
  def project_name_specified?
    setting(:project) != 'unnamed_project'
  end

  def branch
    setting(:branch)
  end
  
  def config_branch
    setting(:config_branch)
  end
  
  def env_vars
    return '' unless setting(:rake_env)
    setting(:rake_env).keys.inject('') do |buffer,k| 
      buffer += "#{k}='#{setting(:rake_env)[k]}' "
      buffer
    end
  end
  
  def apply_staleness_check(commands)
    check = "cd #{setting(:deploy_to)}; " +
            "ml=\`git log -1 --pretty=format:%H\`; " +
            "mr=\`git ls-remote #{setting(:repository)} refs/heads/#{branch}\`; "
    
    if setting(:deploy_config_to)
      check += "cd #{setting(:deploy_config_to)}; " +
               "cl=\`git log -1 --pretty=format:%H\`; " +
               "cr=\`git ls-remote #{setting(:config_repository)} refs/heads/#{config_branch}\`; "
    end
    
    check += "if [[ $ml != ${mr%%\t*} ]] " +
             (setting(:deploy_config_to) ? "|| [[ $cl != ${cr%%\t*} ]]" : '') +
             "; then #{commands}; else echo \"No changes to deploy.\"; fi"
  end
  
  def join_commands
    buffer.collect {|c| "{ #{c} ; }"}.join(' && ')
  end
  
  def bundle
    return '' if buffer.empty?
    (staleness_checks_enabled? and check_staleness?) ? apply_staleness_check(join_commands) : join_commands
  end

  def domain_limit_match?(domain, limit)
    domain.sub(%r{^.*@}, '') == limit
  end
  
  def domain_of_interest?(domain)
    return true unless limit = config.domain_limit
    domain_limit_match?(domain, limit)
  end
  
  def encode_roles(roles)
    return '' unless roles and !roles.empty?
    "export WD_ROLES='#{roles.join(':')}'; "
  end

  def build_command(domain, cmd)
    "#{'set -x; ' if debugging?}" + encode_roles(domain['roles']) + cmd
  end
  
  def run(domain, cmd)
    ssh(domain, cmd)
  end

  def ssh(domain, cmd)
    args = []
    args << domain['name']
    args << '-v' if debugging?
    args += domain['ssh_options'] if domain['ssh_options']
    args << build_command(domain, cmd)

    puts "Running: ssh #{args.join(' ')}" if debugging?
    system('ssh', *args)
  end
  
  def shell(domain, cmd)
    puts "Running command locally: [#{cmd}]" if debugging?
    system('bash', '-c', build_command(domain, cmd))
  end
  
  def flush
    setting(:domain).each do |domain|
      next unless domain_of_interest?(domain['name'])
      puts "Deploying #{domain['name']}..."
      status = remote?(domain['name']) ? run(domain, bundle) : shell(domain, bundle)
      record_result(domain['name'], status)
    end
  end
  
  def record_result(domain, status)
    @results ||= []
    @results << { 'domain' => domain, 'status' => status }
  end

  def summarize_results(results)
    successes = failures = 0
    results.each do |result|
      puts "#{result['domain']} => #{result['status'] ? 'succeeded' : 'failed'}."
      if result['status']
        successes += 1 
      else
        failures += 1
      end
    end
    [successes + failures, successes, failures]
  end
  
  def summarize
    puts "\nResults:"
    if results and not results.empty?
      total, successes, failures = summarize_results(results)
      puts "Total: #{total} deployment#{total == 1 ? '' : 's'}, " +
        "#{successes} success#{successes == 1 ? '' : 'es'}, " +
        "#{failures} failure#{failures == 1 ? '' : 's'}."
    else
      puts "No deployments to report."
    end       
  end
  
  def success?
    return true if !results or results.empty?
    results.all? {|result| result['status'] }
  end
  
  def if_file_present(path, cmd)
    "if [ -e #{path} ]; then #{cmd}; fi"
  end
  
  def if_task_defined(task, cmd)
    %Q(rakep=`#{env_vars} rake -P` && if [[ `echo "${rakep}" | grep #{task}` != "" ]]; then #{cmd}; fi )
  end
  
  def run_rake_task(path, task_name)
    enqueue "echo Running rake #{task_name}..."
    enqueue "cd #{path}"
    enqueue(if_file_present("#{setting(:deploy_to)}/Rakefile", 
      if_task_defined(task_name, "#{env_vars} rake #{'--trace' if debugging?} #{task_name} to=#{setting(:environment)}")))
  end
  
  def build_path(path)
    return path if path =~ %r{^/}
    File.join(setting(:deploy_to), path)
  end

  def run_script(script)
    return unless script
    enqueue(%Q<cd #{setting(:deploy_to)}; echo "Running post script..."; #{env_vars} bash #{'-x' if debugging?} #{build_path(script)}>)
  end

  def config_repo
    @config_repo ||= 
      Repository.new(self, 
        'url'    => setting(:config_repository),
        'branch' => config_branch,
        'deploy_to' => setting(:deploy_config_to))
  end
  
  def main_repo
    @main_repo ||= 
      Repository.new(self, 
        'url'    => setting(:repository),
        'branch' => branch,
        'deploy_to' => setting(:deploy_to))
  end

  def clone_repository(repo)
    enqueue repo.clone
  end
  
  def refresh_checkout(repo)
    enqueue repo.refresh_checkout
  end
  
  def ensure_parent_path_is_present(repo)
    enqueue repo.ensure_parent_path_is_present
  end

  def ensure_main_parent_path_is_present
    ensure_parent_path_is_present(main_repo)
  end
  
  def ensure_config_parent_path_is_present
    ensure_parent_path_is_present(config_repo)
  end

  def checkout_main_repository
    clone_repository(main_repo)
  end
  
  def checkout_configuration_repository
    clone_repository(config_repo)
  end
  
  def snapshot_git_revision
    enqueue "cd #{setting(:deploy_to)}"
    enqueue %Q{ml=\`git log -1 --pretty=format:%H\`}
  end
  
  def initialize_git_changes
    enqueue "rm -f #{setting(:deploy_to)}/.whiskey_disk_git_changes"
    snapshot_git_revision
  end
  
  def initialize_rsync_changes
    enqueue "rm -f #{setting(:deploy_to)}/.whiskey_disk_rsync_changes"
  end
  
  def initialize_all_changes
    initialize_git_changes
    initialize_rsync_changes
  end
  
  def capture_git_changes
    enqueue "git diff --name-only ${ml}..HEAD > #{setting(:deploy_to)}/.whiskey_disk_git_changes"
  end
  
  def update_main_repository_checkout
    initialize_git_changes
    refresh_checkout(main_repo)
    capture_git_changes
  end
  
  def update_configuration_repository_checkout
    initialize_rsync_changes
    refresh_checkout(config_repo)
  end
  
  def refresh_configuration
    raise "Must specify project name when using a configuration repository." unless project_name_specified?
    enqueue "echo Rsyncing configuration..."
    enqueue("rsync -a#{'v --progress' if debugging?} " + '--log-format="%t [%p] %i %n" ' +
            "#{setting(:deploy_config_to)}/#{setting(:project)}/#{setting(:config_target)}/ #{setting(:deploy_to)}/ " + 
            "> #{setting(:deploy_to)}/.whiskey_disk_rsync_changes")
  end
  
  def run_post_setup_hooks
    run_script(setting(:post_setup_script))
    run_rake_task(setting(:deploy_to), "deploy:post_setup")
  end
  
  def run_post_deploy_hooks
    run_script(setting(:post_deploy_script))
    run_rake_task(setting(:deploy_to), "deploy:post_deploy")
  end
end
