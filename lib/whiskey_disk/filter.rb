class WhiskeyDisk
  class Config
    class AbstractFilter
      attr_reader :config
      
      def initialize(config)
        @config = config
      end
      
      def project_name
        config.project_name
      end
      
      def environment_name
        config.environment_name
      end
    end

    module ScopeHelper
      def repository_depth(data, depth = 0)
        raise 'no repository found' unless data.respond_to?(:has_key?)
        return depth if data.has_key?('repository')
        repository_depth(data.values.first, depth + 1)
      end
    end
    
    class EnvironmentScopeFilter < AbstractFilter      
      include ScopeHelper

      # is this data hash a bottom-level data hash without an environment name?
      def needs_environment_scoping?(data)
        repository_depth(data) == 0
      end
      
      def filter(data)
        return data unless needs_environment_scoping?(data)
        { environment_name => data }
      end
    end
    
    class ProjectScopeFilter < AbstractFilter
      include ScopeHelper

      def repository_depth(data, depth = 0)
        raise 'no repository found' unless data.respond_to?(:has_key?)
        return depth if data.has_key?('repository')
        repository_depth(data.values.first, depth + 1)
      end
      
      # is this data hash an environment data hash without a project name?
      def needs_project_scoping?(data)
        repository_depth(data) == 1
      end
      
      def filter(data)
        return data unless needs_project_scoping?(data)
        config.override_project_name!(data)
        { project_name => data }
      end
    end
    
    class NormalizeDomainsFilter < AbstractFilter
      def localize_domain_list(list)
        [ list ].flatten.collect { |d| (d.nil? or d == '') ? 'local' : d }
      end

      def compact_list(list)
        [ list ].flatten.delete_if { |d| d.nil? or d == '' }
      end

      # called only by normalize_domains
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

      # called only by normalize_domains
      def check_duplicates(project, target, domain_list)
        seen = {}
        domain_list.each do |domain|
          raise "duplicate domain [#{domain[:name]}] in configuration file for project [#{project}], target [#{target}]" if seen[domain[:name]]
          seen[domain[:name]] = true
        end
      end

      def filter(data)
        data.each_pair do |project, project_data|
          project_data.each_pair do |target, target_data|
            target_data['domain'] = check_duplicates(project, target, normalize_domain(target_data['domain']))
          end
        end
        data
      end
    end
    
    class SelectProjectAndEnvironmentFilter < AbstractFilter
      def filter(data)
        raise "No configuration file defined data for project `#{project_name}`, environment `#{environment_name}`" unless data and data[project_name] and data[project_name][environment_name]
        data[project_name][environment_name]
      end
    end
    
    class Filter
      attr_reader :config
  
      def initialize(config)
        @config = config
      end
  
      def filter_data(data)
        current = EnvironmentScopeFilter.new(config).filter(data.clone)
        current = ProjectScopeFilter.new(config).filter(current)
        current = NormalizeDomainsFilter.new(config).filter(current)
        current = SelectProjectAndEnvironmentFilter.new(config).filter(current)
        current = config.add_environment_name(current)
        current = config.add_project_name(current)
        current = config.default_config_target(current)
      end    
    end
  end
end
