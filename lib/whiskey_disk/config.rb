require 'yaml'
require 'uri'
require 'open-uri'

class WhiskeyDisk
  class Config
    class << self
      def environment_name
        return false unless (ENV['to'] && ENV['to'] != '')
        return ENV['to'] unless ENV['to'] =~ /:/
        ENV['to'].split(/:/)[1]
      end

      def specified_project_name
        return false unless (ENV['to'] && ENV['to'] =~ /:/)
        ENV['to'].split(/:/).first
      end

      def override_project_name!(data)
        return if ENV['to'] && ENV['to'] =~ /:/
        ENV['to'] = data[environment_name]['project'] + ':' + ENV['to'] if data[environment_name]['project']
      end

      def path
        (ENV['path'] && ENV['path'] != '') ? ENV['path'] : false
      end

      def check_staleness?
        !!(ENV['check'] && ENV['check'] =~ /^(?:t(?:rue)?|y(?:es)?|1)$/)
      end

      def debug?
        !!(ENV['debug'] && ENV['debug'] =~ /^(?:t(?:rue)?|y(?:es)?|1)$/)
      end
      
      def domain_limit
        return false unless ENV['only'] and ENV['only'] != ''
        ENV['only']
      end

      def contains_rakefile?(path)
        File.exists?(File.expand_path(File.join(path, 'Rakefile')))
      end

      def find_rakefile_from_current_path
        original_path = Dir.pwd
        while (!contains_rakefile?(Dir.pwd))
          return File.join(original_path, 'config') if Dir.pwd == '/'
          Dir.chdir('..')
        end
        File.join(Dir.pwd, 'config')
      ensure
        Dir.chdir(original_path)
      end

      def base_path
        return path if path
        find_rakefile_from_current_path
      end

      def valid_path?(path)
        if path
          uri = URI.parse(path)
          return path if uri.scheme
          return path if File.file?(path)
        end
        
        false
      end

      def configuration_file
        return path if valid_path?(path)
        
        files = []

        files += [
          File.join(base_path, 'deploy', specified_project_name, "#{environment_name}.yml"),  # /deploy/foo/staging.yml
          File.join(base_path, 'deploy', "#{specified_project_name}.yml") # /deploy/foo.yml
        ] if specified_project_name

        files += [
          File.join(base_path, 'deploy', "#{environment_name}.yml"),  # /deploy/staging.yml
          File.join(base_path, "#{environment_name}.yml"), # /staging.yml
          File.join(base_path, 'deploy.yml') # /deploy.yml
        ]

        files.each { |file|  return file if File.exists?(file) }

        raise "Could not locate configuration file in path [#{base_path}]"
      end

      def configuration_data
        open(configuration_file) {|f| f.read }
      end

      def project_name
        specified_project_name || 'unnamed_project'
      end

      def repository_depth(data, depth = 0)
        raise 'no repository found' unless data.respond_to?(:has_key?)
        return depth if data.has_key?('repository')
        repository_depth(data.values.first, depth + 1)
      end

      # is this data hash a bottom-level data hash without an environment name?
      def needs_environment_scoping?(data)
        repository_depth(data) == 0
      end

      # is this data hash an environment data hash without a project name?
      def needs_project_scoping?(data)
        repository_depth(data) == 1
      end

      def add_environment_scoping(data)
        return data unless needs_environment_scoping?(data)
        { environment_name => data }
      end

      def add_project_scoping(data)
        return data unless needs_project_scoping?(data)
        override_project_name!(data)
        { project_name => data }
      end

      def localize_domain_list(list)
        [ list ].flatten.collect { |d| (d.nil? or d == '') ? 'local' : d }
      end
      
      def compact_list(list)
        [ list ].flatten.delete_if { |d| d.nil? or d == '' }
      end
      
      def normalize_domain(data)
        compacted = localize_domain_list(data)
        compacted = [ 'local' ] if compacted.empty?
        
        compacted.collect do |d|
          if d.respond_to?(:keys)
            row = { :name => (d['name'] || d[:name]) }
            roles = compact_list(d['roles'] || d[:roles])
            row[:roles] = roles unless roles.empty?
            row
          else
            { :name => d }
          end
        end
      end
      
      def check_duplicates(project, target, domain_list)
        seen = {}
        domain_list.each do |domain|
          raise "duplicate domain [#{domain[:name]}] in configuration file for project [#{project}], target [#{target}]" if seen[domain[:name]]
          seen[domain[:name]] = true
        end
      end
      
      def normalize_domains(data)
        data.each_pair do |project, project_data|
          project_data.each_pair do |target, target_data|
            target_data['domain'] = check_duplicates(project, target, normalize_domain(target_data['domain']))
          end
        end
      end

      def normalize_data(data)
        normalize_domains(add_project_scoping(add_environment_scoping(data.clone)))
      end

      def load_data
        normalize_data(YAML.load(configuration_data))
      rescue Exception => e
        raise %Q{Error reading configuration file [#{configuration_file}]: "#{e}"}
      end

      def filter_data(data)
        current = data[project_name][environment_name] rescue nil
        raise "No configuration file defined data for project `#{project_name}`, environment `#{environment_name}`" unless current

        current.merge!({
          'environment' => environment_name,
          'project' => project_name,
        })
        
        current['config_target'] ||= environment_name
        current
      end

      def fetch
        raise "Cannot determine current environment -- try rake ... to=staging, for example." unless environment_name
        filter_data(load_data)
      end
    end
  end
end
