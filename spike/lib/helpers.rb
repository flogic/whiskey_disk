module WhiskeyDisk
  def find_base_path
    start = Dir.pwd
    while (!File.exists?(File.join(Dir.pwd, 'Rakefile')))
      Dir.chdir('..')
      raise "Could not find Rakefile in the current directory tree!" if File.expand_path(Dir.pwd) == '/'
    end
    Dir.pwd
  end

  def build_filename(str)
    File.expand_path(File.join(find_base_path, 'config', "#{str}.yml"))
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
      raise "Using environment [#{environment_name}] but configuration file [#{configuration_file}] has no declarations for this environment." 
    end
    set_values
  end

  def parent_path(path)
    File.split(path).first
  end

  def deployment_path
    File.split(deploy_to).last
  end

  def config_path
    File.split(deploy_config_to).last
  end

  def project_name
    File.split(repository).last.sub(/\.git$/, '')
  end
end
